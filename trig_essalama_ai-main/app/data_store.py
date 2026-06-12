import json
import os
from datetime import datetime


def _ensure_data_dir():
    os.makedirs("data", exist_ok=True)


def _read_json(path, default_value):
    _ensure_data_dir()
    if not os.path.exists(path):
        return default_value
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default_value


def _write_json(path, payload):
    _ensure_data_dir()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)


def get_field_reports():
    data = _read_json("data/field_reports.json", [])
    return data if isinstance(data, list) else []


def append_field_report(report):
    reports = get_field_reports()
    row = dict(report)
    row.setdefault("timestamp", datetime.utcnow().isoformat() + "Z")
    reports.append(row)
    _write_json("data/field_reports.json", reports)
    return row


def get_mobile_stream():
    data = _read_json("data/mobile_stream.json", {})
    return data if isinstance(data, dict) else {}


def upsert_mobile_stream(mobile_payload):
    stream = get_mobile_stream()
    stream.update(dict(mobile_payload))
    stream["timestamp"] = datetime.utcnow().isoformat() + "Z"
    _write_json("data/mobile_stream.json", stream)
    return stream


def get_historical_incidents():
    data = _read_json("data/historical_incidents.json", [])
    return data if isinstance(data, list) else []


def append_historical_incident(incident, max_records=1000):
    history = get_historical_incidents()
    row = dict(incident)
    row.setdefault("timestamp", datetime.utcnow().isoformat() + "Z")
    history.append(row)
    history = history[-max_records:]
    _write_json("data/historical_incidents.json", history)
    return row


def get_analysis_results():
    data = _read_json("data/results_history.json", [])
    return data if isinstance(data, list) else []


def append_analysis_result(result, max_records=300):
    history = get_analysis_results()
    row = dict(result) if isinstance(result, dict) else {"result": result}
    row.setdefault("saved_at", datetime.utcnow().isoformat() + "Z")
    history.append(row)
    history = history[-max_records:]
    _write_json("data/results_history.json", history)
    return row