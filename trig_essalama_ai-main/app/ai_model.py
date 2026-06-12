from datetime import datetime
import math
import statistics


def _clamp(value, min_value=0.0, max_value=1.0):
    return max(min_value, min(max_value, value))


def _risk_level(score):
    if score >= 80:
        return "critique"
    if score >= 55:
        return "eleve"
    if score >= 30:
        return "moyen"
    return "faible"


def _anomaly_score(current_value, historical_values):
    if len(historical_values) < 3:
        return 0.0
    sigma = statistics.pstdev(historical_values)
    if sigma == 0:
        return 0.0
    z_score = abs((current_value - statistics.mean(historical_values)) / sigma)
    return _clamp(z_score / 3.0) * 100


def _detect_dangers(ndwi, ndvi, field_reports):
    dangers = []

    if ndwi >= 0.55:
        dangers.append(
            {
                "type": "route_inondee",
                "source": "satellite_multispectral",
                "confidence": round(_clamp((ndwi - 0.55) * 2.2) * 100, 2),
            }
        )

    if ndwi >= 0.35 and ndvi <= 0.22:
        dangers.append(
            {
                "type": "zone_glissante",
                "source": "fusion_satellite",
                "confidence": round(_clamp(ndwi * (1 - ndvi)) * 100, 2),
            }
        )

    for report in field_reports:
        for detected_object in report.get("detections", []):
            score = float(detected_object.get("score", 0.0))
            label = detected_object.get("label", "inconnu")
            if label in {"obstacle", "fissure", "vehicule_en_panne"}:
                dangers.append(
                    {
                        "type": label,
                        "source": "vision_yolov8",
                        "confidence": round(_clamp(score) * 100, 2),
                    }
                )

    dangers.sort(key=lambda item: item["confidence"], reverse=True)
    return dangers


def _generate_alerts(dangers, incident_probability):
    alerts = []
    for danger in dangers[:5]:
        priority = "high" if danger["confidence"] >= 70 else "medium"
        alerts.append(
            {
                "canal": "mobile_push",
                "priority": priority,
                "message": f"Alerte {danger['type']} detectee ({danger['confidence']}%)",
            }
        )

    if incident_probability >= 75:
        alerts.append(
            {
                "canal": "autorites_dashboard",
                "priority": "critical",
                "message": "Probabilite elevee d'incident routier: intervention prioritaire",
            }
        )
    return alerts


def _recommendations(global_score, traffic_density, rainfall_mm):
    recos = []
    if global_score >= 70:
        recos.append("Activer un plan d'intervention d'urgence sur les axes critiques.")
    if rainfall_mm >= 20:
        recos.append("Renforcer la signalisation temporaire sur zones sujettes aux inondations.")
    if traffic_density >= 0.65:
        recos.append("Mettre en place des deviations preventives aux heures de pointe.")
    if not recos:
        recos.append("Maintenir la surveillance proactive et la collecte continue des donnees.")
    return recos


def analyse_risque(water, vegetation, context=None):
    """
    Moteur IA hybride (supervise + non supervise):
    - fusion de donnees geospatiales/terrain/mobile
    - detection de dangers routiers
    - score global de risque
    - prediction d'incident et alertes intelligentes
    """

    context = context or {}
    ndwi = float(water.get("NDWI", 0.0))
    ndvi = float(vegetation.get("NDVI", 0.0))
    traffic_density = float(context.get("traffic_density", 0.35))
    rainfall_mm = float(context.get("rainfall_mm", 0.0))
    field_reports = context.get("field_reports", [])
    historical_incidents = context.get("historical_incidents", [])

    # Supervised-like score (weighted risk model)
    supervised_score = (
        (ndwi * 100 * 0.35)
        + ((1 - ndvi) * 100 * 0.25)
        + (_clamp(traffic_density) * 100 * 0.2)
        + (_clamp(rainfall_mm / 50.0) * 100 * 0.2)
    )

    historical_ndwi = [float(item.get("ndwi", 0.0)) for item in historical_incidents]
    historical_ndvi = [float(item.get("ndvi", 0.0)) for item in historical_incidents]
    anomaly_ndwi = _anomaly_score(ndwi, historical_ndwi)
    anomaly_ndvi = _anomaly_score(ndvi, historical_ndvi)
    unsupervised_score = round((anomaly_ndwi * 0.6) + (anomaly_ndvi * 0.4), 2)

    global_score = round((supervised_score * 0.75) + (unsupervised_score * 0.25), 2)
    global_level = _risk_level(global_score)

    dangers = _detect_dangers(ndwi, ndvi, field_reports)
    incident_probability = round(_clamp(global_score / 100.0 + (len(dangers) * 0.03)) * 100, 2)

    alerts = _generate_alerts(dangers, incident_probability)
    recommendations = _recommendations(global_score, traffic_density, rainfall_mm)

    risk_map_update = {
        "updated_at": datetime.utcnow().isoformat() + "Z",
        "layers": [
            {"name": "flood_risk", "value": round(ndwi, 4)},
            {"name": "vegetation_stress", "value": round(1 - ndvi, 4)},
            {"name": "traffic_pressure", "value": round(traffic_density, 4)},
            {"name": "incident_probability", "value": round(incident_probability / 100.0, 4)},
        ],
    }

    return {
        "scores": {
            "supervised": round(supervised_score, 2),
            "unsupervised": unsupervised_score,
            "global": global_score,
            "niveau_global": global_level,
        },
        "indicators": {
            "ndwi": round(ndwi, 4),
            "ndvi": round(ndvi, 4),
            "traffic_density": round(traffic_density, 4),
            "rainfall_mm": round(rainfall_mm, 2),
        },
        "dangers_detected": dangers,
        "prediction": {
            "incident_probability": incident_probability,
            "horizon": "24h",
        },
        "alerts": alerts,
        "recommendations": recommendations,
        "risk_map_update": risk_map_update,
        "model_details": {
            "computer_vision": "YOLOv8 integration expected from field report detections",
            "multispectral_analysis": "Sentinel-2 NDWI/NDVI",
            "deep_learning": "hybrid scoring ready for CNN/YOLO outputs",
        },
    }