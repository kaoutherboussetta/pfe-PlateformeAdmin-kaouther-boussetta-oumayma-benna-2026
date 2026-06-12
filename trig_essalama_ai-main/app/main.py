import asyncio

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from app.config import ANALYSIS_MAX_RECORDS, AUTO_REFRESH_SECONDS
from app.dynamic_pipeline import run_pipeline_dynamic
from app.data_store import (
    append_analysis_result,
    append_field_report,
    append_historical_incident,
    get_analysis_results,
    get_field_reports,
    get_historical_incidents,
    get_mobile_stream,
    upsert_mobile_stream,
)
from app.gee_service import get_gee_task_status, push_all_local_data_to_gee
from save_data import load_last_result

# Création de l'application FastAPI
app = FastAPI(
    title="Trig Essalama AI API",
    description="API d'analyse des risques (inondation, sécheresse) basée sur Google Earth Engine",
    version="1.0.0"
)

# Last computed result cached in memory and auto-refreshed in background.
latest_result = None
pipeline_lock = asyncio.Lock()
analysis_task = None
last_error = None


async def _run_pipeline_once():
    """
    Run blocking pipeline in a thread, without API-level timeout.
    """
    return await asyncio.to_thread(run_pipeline_dynamic)


async def _run_pipeline_job(source: str = "manual"):
    global latest_result, last_error
    try:
        async with pipeline_lock:
            latest_result = await _run_pipeline_once()
            append_analysis_result(latest_result, max_records=ANALYSIS_MAX_RECORDS)
            last_error = None
        print(f"✅ Analyse terminee ({source})")
    except Exception as e:
        last_error = f"Erreur analyse ({source}): {e}"
        print(f"❌ {last_error}")


async def auto_refresh_loop():
    while True:
        await _run_pipeline_job(source="auto_refresh")
        await asyncio.sleep(max(10, AUTO_REFRESH_SECONDS))


@app.on_event("startup")
async def start_auto_refresh():
    app.state.refresh_task = asyncio.create_task(auto_refresh_loop())


@app.on_event("shutdown")
async def stop_auto_refresh():
    task = getattr(app.state, "refresh_task", None)
    if task:
        task.cancel()
        try:
            # Avoid blocking shutdown forever when a worker thread is stuck in I/O.
            await asyncio.wait_for(task, timeout=2)
        except asyncio.CancelledError:
            pass
        except asyncio.TimeoutError:
            pass

# =====================================================
# 🏠 ROUTE PRINCIPALE
# =====================================================
@app.get("/")
def home():
    return {
        "message": "Bienvenue dans l'API Trig Essalama AI",
        "status": "OK"
    }


# =====================================================
# ❤️ ROUTE SANTÉ (important pour test serveur)
# =====================================================
@app.get("/health")
def health_check():
    return {
        "status": "running"
    }


# =====================================================
# 🧠 ROUTE ANALYSE IA
# =====================================================
@app.get("/analyse")
async def analyse():
    global analysis_task
    if analysis_task and not analysis_task.done():
        return {
            "status": "running",
            "message": "Une analyse est deja en cours.",
        }

    analysis_task = asyncio.create_task(_run_pipeline_job(source="manual"))
    return {
        "status": "started",
        "message": "Analyse lancee en arriere-plan.",
    }


@app.get("/latest")
def latest():
    if latest_result is None:
        return {
            "status": "pending",
            "message": "La premiere mise a jour automatique est en cours."
        }
    return latest_result


@app.get("/result")
def result():
    if latest_result is None:
        persisted_result = load_last_result()
        if persisted_result is not None:
            return {
                "status": "ready",
                "last_error": last_error,
                "result": persisted_result,
            }
        return {
            "status": "pending",
            "message": "Aucun resultat disponible pour le moment.",
            "last_error": last_error,
        }
    return {
        "status": "ready",
        "last_error": last_error,
        "result": latest_result,
    }


@app.get("/results")
def results(limit: int = 20):
    rows = get_analysis_results()
    safe_limit = max(1, min(limit, 500))
    return {
        "status": "ok",
        "count": len(rows),
        "items": rows[-safe_limit:][::-1],
    }


@app.get("/analyse/status")
def analyse_status():
    running = bool(analysis_task and not analysis_task.done())
    return {
        "running": running,
        "has_result": latest_result is not None,
        "last_error": last_error,
    }


# =====================================================
# 📊 ROUTE TEST (optionnelle pour debug)
# =====================================================
@app.get("/test")
def test():
    return {
        "message": "API fonctionne correctement 🚀"
    }


class GeeExportRequest(BaseModel):
    asset_id: str


class MobileStreamPayload(BaseModel):
    traffic_density: float = 0.35
    rainfall_mm: float = 0.0
    speed_avg_kmh: float | None = None
    temperature_c: float | None = None


class DetectionPayload(BaseModel):
    label: str
    score: float


class FieldReportPayload(BaseModel):
    location: str
    reporter: str | None = None
    detections: list[DetectionPayload] = []
    comment: str | None = None


class HistoricalIncidentPayload(BaseModel):
    ndwi: float
    ndvi: float
    severity: str | None = None
    note: str | None = None


@app.post("/gee/export")
def export_to_gee(payload: GeeExportRequest):
    try:
        return push_all_local_data_to_gee(payload.asset_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Export GEE impossible: {e}")


@app.get("/gee/task/{task_id}")
def gee_task_status(task_id: str):
    try:
        return get_gee_task_status(task_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lecture statut GEE impossible: {e}")


@app.post("/ingest/mobile")
def ingest_mobile(payload: MobileStreamPayload):
    saved = upsert_mobile_stream(payload.model_dump(exclude_none=True))
    return {"status": "ok", "mobile_stream": saved}


@app.post("/ingest/field-report")
def ingest_field_report(payload: FieldReportPayload):
    saved = append_field_report(payload.model_dump(exclude_none=True))
    return {"status": "ok", "field_report": saved}


@app.post("/ingest/historical-incident")
def ingest_historical_incident(payload: HistoricalIncidentPayload):
    saved = append_historical_incident(payload.model_dump(exclude_none=True))
    return {"status": "ok", "historical_incident": saved}


@app.get("/data/live")
def live_data():
    return {
        "mobile_stream": get_mobile_stream(),
        "field_reports": get_field_reports(),
        "historical_incidents": get_historical_incidents(),
    }