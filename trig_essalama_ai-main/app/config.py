import os
from pathlib import Path
from dotenv import load_dotenv


# Charger explicitement le fichier .env a la racine du projet.
ROOT_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = ROOT_DIR / ".env"
load_dotenv(dotenv_path=ENV_PATH, encoding="utf-8-sig")


ZONE = {
    "name": os.getenv("ZONE_NAME", "Tunisie"),
    # [xmin, ymin, xmax, ymax]
    "coords": [
        float(os.getenv("ZONE_XMIN", "8.0")),
        float(os.getenv("ZONE_YMIN", "30.0")),
        float(os.getenv("ZONE_XMAX", "11.8")),
        float(os.getenv("ZONE_YMAX", "37.5")),
    ],
}

DATE = {
    "start": os.getenv("DATE_START", "2024-01-01"),
    "end": os.getenv("DATE_END", "2024-12-31"),
}

# GEE auth via service account (recommended for API/server usage)
GEE_SERVICE_ACCOUNT = os.getenv("GEE_SERVICE_ACCOUNT", "")
GEE_PRIVATE_KEY_PATH = os.getenv("GEE_PRIVATE_KEY_PATH", "")
GEE_PROJECT = os.getenv("GEE_PROJECT", "")
GOOGLE_CLOUD_PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT", "")

if not GEE_PROJECT and not GOOGLE_CLOUD_PROJECT:
    raise Exception(
        "❌ Erreur GEE : Configuration GEE incomplete: define GEE_PROJECT (or GOOGLE_CLOUD_PROJECT) in your .env"
    )

if not GEE_PROJECT:
    GEE_PROJECT = GOOGLE_CLOUD_PROJECT

if bool(GEE_SERVICE_ACCOUNT) != bool(GEE_PRIVATE_KEY_PATH):
    raise Exception(
        "❌ Erreur GEE : define both GEE_SERVICE_ACCOUNT and GEE_PRIVATE_KEY_PATH together in your .env."
    )

if GEE_PRIVATE_KEY_PATH and not Path(GEE_PRIVATE_KEY_PATH).exists():
    print(
        f"GEE warning: private key file not found at '{GEE_PRIVATE_KEY_PATH}'. "
        "Falling back to default credentials."
    )
    GEE_SERVICE_ACCOUNT = ""
    GEE_PRIVATE_KEY_PATH = ""

# Auto-refresh interval for background data updates (seconds)
AUTO_REFRESH_SECONDS = int(os.getenv("AUTO_REFRESH_SECONDS", "300"))

# Maximum execution time allowed for one pipeline run (seconds).
# Set to 0 (or less) to disable timeout.
ANALYSE_TIMEOUT_SECONDS = int(os.getenv("ANALYSE_TIMEOUT_SECONDS", "25"))

# Maximum number of records kept in rolling historical dataset.
HISTORY_MAX_RECORDS = int(os.getenv("HISTORY_MAX_RECORDS", "1000"))

# Maximum number of saved analysis results.
ANALYSIS_MAX_RECORDS = int(os.getenv("ANALYSIS_MAX_RECORDS", "300"))

# Optional MongoDB persistence for dynamic pipeline results.
MONGO_URI = os.getenv("MONGO_URI", "")
MONGO_DB = os.getenv("MONGO_DB", "trig_essalama")