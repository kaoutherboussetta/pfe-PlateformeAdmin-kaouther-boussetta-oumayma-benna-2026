import ee
import json
import time
from datetime import datetime
from pathlib import Path
from app.config import DATE, GEE_PRIVATE_KEY_PATH, GEE_PROJECT, GEE_SERVICE_ACCOUNT, ZONE


S2_COMMON_BANDS = [
    "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B8A", "B9", "B11", "B12",
    "AOT", "WVP", "SCL", "TCI_R", "TCI_G", "TCI_B", "MSK_CLDPRB", "MSK_SNWPRB",
]

# =====================================================
# 🔐 INITIALISATION GEE
# =====================================================
def init_gee():
    init_kwargs = {}
    if GEE_PROJECT:
        init_kwargs["project"] = GEE_PROJECT

    # Prefer service account for backend execution. It avoids interactive auth prompts.
    if GEE_SERVICE_ACCOUNT and GEE_PRIVATE_KEY_PATH:
        credentials = ee.ServiceAccountCredentials(
            GEE_SERVICE_ACCOUNT,
            GEE_PRIVATE_KEY_PATH,
        )
        ee.Initialize(credentials, **init_kwargs)
        return

    # If there is no explicit project, Earth Engine cannot initialize in server mode.
    if "project" not in init_kwargs:
        raise RuntimeError(
            "Configuration GEE incomplete: define GEE_PROJECT (or GOOGLE_CLOUD_PROJECT) "
            "in your .env."
        )

    # Local fallback: use existing credentials/ADC without forcing interactive auth.
    ee.Initialize(**init_kwargs)


def _get_info_with_retry(ee_object, retries=3, delay_seconds=2):
    """
    Retry getInfo calls for transient transport/server issues.
    """
    last_error = None
    for attempt in range(retries):
        try:
            return ee_object.getInfo()
        except Exception as exc:
            last_error = exc
            err = str(exc).lower()
            is_transient = (
                "connection aborted" in err
                or "remote end closed connection without response" in err
                or "timed out" in err
            )
            if not is_transient or attempt == retries - 1:
                raise
            time.sleep(delay_seconds * (attempt + 1))
    raise last_error


# =====================================================
# 🛰️ RÉCUPÉRATION DES DONNÉES SATELLITES
# =====================================================
def get_satellite_data(zone_coords=None):
    try:
        # Initialiser GEE
        init_gee()

        # Zone (depuis config)
        coords = zone_coords or ZONE["coords"]
        region = ee.Geometry.Rectangle(coords)

        # Charger Sentinel-2 harmonisee et normaliser les bandes.
        collection = (
            ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
            .filterBounds(region)
            .filterDate(DATE["start"], DATE["end"])
            .filter(ee.Filter.lt("CLOUDY_PIXEL_PERCENTAGE", 10))
            .select(S2_COMMON_BANDS)
            .median()
            .clip(region)
        )

        # Vérification image
        if collection is None:
            raise ValueError("Aucune image trouvée")

        # =====================================================
        # 📊 CALCUL DES INDICES
        # =====================================================
        ndvi = collection.normalizedDifference(['B8', 'B4']).rename('NDVI')
        ndwi = collection.normalizedDifference(['B3', 'B8']).rename('NDWI')

        # =====================================================
        # 📥 EXTRACTION DES VALEURS
        # =====================================================
        water_stats = ndwi.reduceRegion(
            reducer=ee.Reducer.mean(),
            geometry=region,
            scale=10,
            maxPixels=1e13
        )
        water = _get_info_with_retry(water_stats)

        vegetation_stats = ndvi.reduceRegion(
            reducer=ee.Reducer.mean(),
            geometry=region,
            scale=10,
            maxPixels=1e13
        )
        vegetation = _get_info_with_retry(vegetation_stats)

        # =====================================================
        # 🔒 SÉCURITÉ (éviter erreurs None)
        # =====================================================
        if water is None:
            water = {"NDWI": 0}

        if vegetation is None:
            vegetation = {"NDVI": 0}

        # Si clé absente
        water_value = water.get('NDWI', 0)
        vegetation_value = vegetation.get('NDVI', 0)

        return (
            {"NDWI": water_value},
            {"NDVI": vegetation_value}
        )

    except Exception as e:
        print("❌ Erreur GEE :", e)

        # Retour de secours (important pour éviter crash API)
        return (
            {"NDWI": 0},
            {"NDVI": 0}
        )


# =====================================================
# 🔁 VERSION TEST (SANS GEE)
# =====================================================
def get_mock_data():
    return (
        {"NDWI": 0.65},   # eau élevée → inondation
        {"NDVI": 0.15}    # faible végétation → sécheresse
    )


def _load_local_json(path, default_value):
    file_path = Path(path)
    if not file_path.exists():
        return default_value
    try:
        return json.loads(file_path.read_text(encoding="utf-8"))
    except Exception:
        return default_value


def _build_export_feature(dataset_name, item):
    payload = json.dumps(item, ensure_ascii=False)
    return ee.Feature(
        None,
        {
            "dataset": dataset_name,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "payload": payload[:90000],
        },
    )


def push_all_local_data_to_gee(asset_id):
    """
    Exporte les donnees locales vers un Asset table GEE.
    """
    init_gee()

    result = _load_local_json("data/result.json", {})
    field_reports = _load_local_json("data/field_reports.json", [])
    mobile_stream = _load_local_json("data/mobile_stream.json", {})
    historical_incidents = _load_local_json("data/historical_incidents.json", [])

    features = []
    features.append(_build_export_feature("result", result))
    features.append(_build_export_feature("mobile_stream", mobile_stream))
    for row in field_reports:
        features.append(_build_export_feature("field_report", row))
    for row in historical_incidents:
        features.append(_build_export_feature("historical_incident", row))

    if not features:
        raise ValueError("Aucune donnee locale a exporter.")

    collection = ee.FeatureCollection(features)
    task = ee.batch.Export.table.toAsset(
        collection=collection,
        description=f"trig_essalama_export_{int(datetime.utcnow().timestamp())}",
        assetId=asset_id,
    )
    task.start()

    return {
        "status": "started",
        "task_id": task.id,
        "asset_id": asset_id,
        "features_count": len(features),
    }


def get_gee_task_status(task_id):
    init_gee()
    statuses = ee.data.getTaskStatus(task_id)
    if not statuses:
        return {"task_id": task_id, "state": "UNKNOWN"}
    status = statuses[0]
    return {
        "task_id": task_id,
        "state": status.get("state", "UNKNOWN"),
        "error_message": status.get("error_message"),
        "description": status.get("description"),
    }