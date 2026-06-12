from app.gee_service import get_satellite_data
from app.ai_model import analyse_risque
from app.config import DATE, HISTORY_MAX_RECORDS, ZONE
from app.data_store import (
    append_historical_incident,
    get_field_reports,
    get_historical_incidents,
    get_mobile_stream,
)
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor
import json
import os
import time


# =====================================================
# 💾 FONCTION SAUVEGARDE AUTOMATIQUE
# =====================================================
def save_result(result):
    try:
        # Créer dossier data/ s'il n'existe pas
        os.makedirs("data", exist_ok=True)

        with open("data/result.json", "w") as f:
            json.dump(result, f, indent=4)

    except Exception as e:
        print("Erreur sauvegarde :", e)


def _collect_context_data():
    """
    Ingestion multi-sources:
    - rapports terrain (data/field_reports.json)
    - flux mobile temps reel (data/mobile_stream.json)
    - historique incidents (data/historical_incidents.json)
    """
    field_reports = get_field_reports()
    mobile_stream = get_mobile_stream()
    historical_incidents = get_historical_incidents()

    traffic_density = float(mobile_stream.get("traffic_density", 0.35))
    rainfall_mm = float(mobile_stream.get("rainfall_mm", 0.0))

    return {
        "field_reports": field_reports,
        "mobile_stream": mobile_stream,
        "historical_incidents": historical_incidents,
        "traffic_density": traffic_density,
        "rainfall_mm": rainfall_mm,
    }


def _safe_float(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(default)


def _build_tunisia_places():
    """
    Build dynamic grid places from configured Tunisia bounding box.
    """
    grid_step_deg = _safe_float(os.getenv("TN_GRID_STEP_DEG", "0.6"), 0.6)
    if grid_step_deg <= 0:
        grid_step_deg = 0.6

    xmin, ymin, xmax, ymax = ZONE["coords"]
    places = []
    row = 0
    y = ymin

    while y < ymax:
        col = 0
        x = xmin
        y2 = min(y + grid_step_deg, ymax)
        while x < xmax:
            x2 = min(x + grid_step_deg, xmax)
            places.append(
                {
                    "name": f"zone_{row}_{col}",
                    "coords": [round(x, 6), round(y, 6), round(x2, 6), round(y2, 6)],
                }
            )
            x = x2
            col += 1
        y = y2
        row += 1

    return places


def _compute_global_score_from_places(place_results):
    if not place_results:
        return 0.0
    totals = []
    for item in place_results:
        score = (
            item.get("analysis", {})
            .get("scores", {})
            .get("global", 0)
        )
        totals.append(_safe_float(score, 0.0))
    if not totals:
        return 0.0
    return round(sum(totals) / len(totals), 2)


# =====================================================
# 🧠 PIPELINE PRINCIPAL
# =====================================================
def run_pipeline():
    try:
        # 1️⃣ Contexte multi-source (terrain / mobile / historique)
        context = _collect_context_data()

        # 2️⃣ Construire la grille dynamique Tunisie
        all_places = _build_tunisia_places()
        max_places = int(os.getenv("TN_MAX_PLACES", "0"))
        places_to_analyse = all_places[:max_places] if max_places > 0 else all_places

        gee_timeout_seconds = int(os.getenv("GEE_TIMEOUT_SECONDS", "10"))
        max_workers = int(os.getenv("PIPELINE_MAX_WORKERS", "6"))
        max_workers = max(1, max_workers)

        # 3️⃣ Soumettre toutes les zones en parallèle
        start_times = {}
        future_to_place = {}
        timed_out = set()
        zone_results = []

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            for place in places_to_analyse:
                future = executor.submit(get_satellite_data, place["coords"])
                future_to_place[future] = place
                start_times[future] = time.time()

            pending = set(future_to_place.keys())
            while pending:
                completed_now = []
                now = time.time()
                for future in list(pending):
                    place = future_to_place[future]
                    elapsed = now - start_times[future]

                    if future.done():
                        completed_now.append(future)
                        try:
                            water, vegetation = future.result()
                            gee_status = None
                        except Exception as exc:
                            water, vegetation = {"NDWI": 0.0}, {"NDVI": 0.0}
                            gee_status = f"GEE error: {exc}"
                    elif elapsed > gee_timeout_seconds:
                        completed_now.append(future)
                        timed_out.add(future)
                        water, vegetation = {"NDWI": 0.0}, {"NDVI": 0.0}
                        gee_status = f"GEE timeout after {gee_timeout_seconds}s"
                    else:
                        continue

                    # Ajout dynamique dans l'historique pour chaque zone traitée
                    append_historical_incident(
                        {
                            "zone": place["name"],
                            "ndwi": _safe_float(water.get("NDWI", 0.0)),
                            "ndvi": _safe_float(vegetation.get("NDVI", 0.0)),
                            "source": "auto_pipeline_dynamic",
                        },
                        max_records=HISTORY_MAX_RECORDS,
                    )

                    analysis = analyse_risque(water, vegetation, context)
                    zone_payload = {
                        "place": place["name"],
                        "coords": place["coords"],
                        "satellite_indicators": {
                            "NDWI": round(_safe_float(water.get("NDWI", 0.0)), 4),
                            "NDVI": round(_safe_float(vegetation.get("NDVI", 0.0)), 4),
                        },
                        "analysis": analysis,
                    }
                    if gee_status:
                        zone_payload["gee_status"] = gee_status
                    zone_results.append(zone_payload)

                for done_future in completed_now:
                    pending.discard(done_future)

                if pending:
                    time.sleep(0.05)

            # Best effort cancellation for futures that timed out at pipeline level.
            for timed_out_future in timed_out:
                timed_out_future.cancel()

        global_score = _compute_global_score_from_places(zone_results)
        top_dangers = []
        for place in zone_results:
            for danger in place.get("analysis", {}).get("dangers_detected", []):
                item = dict(danger)
                item["place"] = place.get("place")
                top_dangers.append(item)
        top_dangers.sort(key=lambda item: _safe_float(item.get("confidence", 0.0)), reverse=True)

        # 4️⃣ Résultat final dynamique
        result = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "zone": ZONE.get("name", "Tunisie"),
            "date_range": DATE,
            "sources": {
                "satellite": "Google Earth Engine / Sentinel-2",
                "field_reports_count": len(context.get("field_reports", [])),
                "mobile_stream_present": bool(context.get("mobile_stream")),
                "historical_incidents_count": len(context.get("historical_incidents", [])),
            },
            "pipeline": {
                "mode": "dynamic_multi_zone",
                "grid_step_deg": _safe_float(os.getenv("TN_GRID_STEP_DEG", "0.6"), 0.6),
                "gee_timeout_seconds": gee_timeout_seconds,
                "max_workers": max_workers,
                "total_places_available": len(all_places),
                "places_count": len(zone_results),
                "max_places_applied": max_places if max_places > 0 else None,
            },
            "analysis_overview": {
                "global_score_mean": global_score,
                "top_dangers": top_dangers[:10],
            },
            "places": zone_results,
        }

        # 💾 5️⃣ Sauvegarde auto
        save_result(result)

        return result

    except Exception as e:
        error_result = {
            "error": str(e),
            "status": "échec du pipeline"
        }

        # Sauvegarder même l'erreur
        save_result(error_result)

        return error_result


# =====================================================
# 🔁 VERSION TEST (sans GEE)
# =====================================================
def run_pipeline_mock():
    water = {"NDWI": 0.65}
    vegetation = {"NDVI": 0.15}
    context = {
        "field_reports": [
            {
                "location": "A1",
                "detections": [
                    {"label": "obstacle", "score": 0.89},
                    {"label": "fissure", "score": 0.73},
                ],
            }
        ],
        "mobile_stream": {"traffic_density": 0.72, "rainfall_mm": 18},
        "historical_incidents": [
            {"ndwi": 0.31, "ndvi": 0.28},
            {"ndwi": 0.22, "ndvi": 0.35},
            {"ndwi": 0.27, "ndvi": 0.3},
        ],
        "traffic_density": 0.72,
        "rainfall_mm": 18,
    }
    ia_result = analyse_risque(water, vegetation, context)

    result = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "zone": f"{ZONE.get('name', 'Tunisie')} (TEST)",
        "date_range": DATE,
        "sources": {
            "satellite": "mock",
            "field_reports_count": len(context["field_reports"]),
            "mobile_stream_present": True,
            "historical_incidents_count": len(context["historical_incidents"]),
        },
        "satellite_indicators": {
            "NDWI": water["NDWI"],
            "NDVI": vegetation["NDVI"],
        },
        "analysis": ia_result,
    }

    # 💾 Sauvegarde aussi en mode test
    save_result(result)

    return result