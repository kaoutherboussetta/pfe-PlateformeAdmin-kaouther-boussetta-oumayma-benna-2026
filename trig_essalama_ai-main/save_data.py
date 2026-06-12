import json
import os
from copy import deepcopy

try:
    from pymongo import MongoClient
except Exception:
    MongoClient = None

from app.config import MONGO_DB, MONGO_URI

_collection = None
if MongoClient and MONGO_URI:
    try:
        _client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=1500)
        _collection = _client[MONGO_DB]["risques"]
    except Exception:
        _collection = None


def _result_path():
    return os.path.join("data", "result.json")


def save_risques(data):
    payload = deepcopy(data)

    inserted_id = None
    if _collection is not None:
        try:
            result = _collection.insert_one(payload)
            inserted_id = str(result.inserted_id)
        except Exception:
            inserted_id = None

    try:
        os.makedirs("data", exist_ok=True)
        with open(_result_path(), "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
    except Exception:
        pass

    return inserted_id


def load_last_result():
    try:
        with open(_result_path(), "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        pass
    except Exception:
        pass

    if _collection is not None:
        try:
            last_doc = _collection.find_one(sort=[("timestamp", -1)])
            if last_doc:
                last_doc.pop("_id", None)
                return last_doc
        except Exception:
            pass

    return None
