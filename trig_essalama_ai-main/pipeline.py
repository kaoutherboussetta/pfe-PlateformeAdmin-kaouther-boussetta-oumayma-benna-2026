from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
import os

from app.config import ZONE
from app.gee_service import get_satellite_data
from app.ai_model import analyse_risque
from save_data import save_risques

_GEE_TIMEOUT_SECONDS = int(os.getenv("GEE_TIMEOUT_SECONDS", "8"))
_GRID_STEP_DEG = float(os.getenv("TN_GRID_STEP_DEG", "0.6"))
_MAX_PLACES = int(os.getenv("TN_MAX_PLACES", "12"))
_executor = ThreadPoolExecutor(max_workers=1)


def _build_tunisia_places():
    xmin, ymin, xmax, ymax = ZONE["coords"]
    places = []
    row = 0
    y = ymin
    while y < ymax:
        col = 0
        x = xmin
        while x < xmax:
            x2 = min(x + _GRID_STEP_DEG, xmax)
            y2 = min(y + _GRID_STEP_DEG, ymax)
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


def _get_indices_with_timeout(coords):
    future = _executor.submit(get_satellite_data, coords)
    try:
        return future.result(timeout=_GEE_TIMEOUT_SECONDS), None
    except FuturesTimeoutError:
        return ({"NDWI": 0.0}, {"NDVI": 0.0}), f"GEE timeout after {_GEE_TIMEOUT_SECONDS}s"
    except Exception as exc:
        return ({"NDWI": 0.0}, {"NDVI": 0.0}), f"GEE error: {exc}"


def run_pipeline():
    place_results = []
    all_places = _build_tunisia_places()
    places = all_places[:_MAX_PLACES] if _MAX_PLACES > 0 else all_places

    for place in places:
        (water, vegetation), gee_status = _get_indices_with_timeout(place["coords"])
        risques = analyse_risque(water, vegetation)
        place_result = {
            "place": place["name"],
            "coords": place["coords"],
            "risques": risques,
        }
        if gee_status:
            place_result["gee_status"] = gee_status
        place_results.append(place_result)

    result = {
        "zone": "Tunisie",
        "places_count": len(place_results),
        "total_places_available": len(all_places),
        "max_places_applied": _MAX_PLACES if _MAX_PLACES > 0 else None,
        "grid_step_deg": _GRID_STEP_DEG,
        "places": place_results,
    }

    # Enregistrer dans MongoDB sans modifier l'objet renvoye par l'API
    save_risques(result)

    return result
