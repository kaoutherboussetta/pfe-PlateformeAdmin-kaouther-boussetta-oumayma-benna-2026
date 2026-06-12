# 🚀 Trig Essalama AI

## 🧠 Description

**Trig Essalama AI** est un système intelligent d’analyse des risques environnementaux et routiers basé sur des données satellites.

Le projet utilise **Google Earth Engine (GEE)** pour récupérer des données (NDVI, NDWI), puis applique une **intelligence décisionnelle (scoring + règles)** pour détecter :

- 🌊 Inondations
- 🌵 Sécheresse
- 🚧 Risques routiers
- 🏙️ Zones urbaines

Les résultats sont exposés via une **API REST (FastAPI)** et peuvent être utilisés dans :

- 📱 Application mobile (Flutter)
- 🧑‍💼 Dashboard admin (Laravel)

---

## 🏗️ Architecture du projet


🛰️ Google Earth Engine
↓
📊 NDVI / NDWI
↓
🧠 IA (Python - scoring)
↓
🌐 FastAPI (API REST)
↓
🧑‍💼 Laravel (admin)
↓
📱 Flutter (utilisateur)


---

## 📁 Structure du projet


trig_essalama_ai/
│
├── app/
│ ├── main.py # API FastAPI
│ ├── pipeline.py # Pipeline (GEE -> IA)
│ ├── gee_service.py # Données satellites
│ ├── ai_model.py # Logique IA
│ ├── config.py # Configuration
│
├── data/ # Résultats (JSON, CSV, GeoJSON)
├── requirements.txt
├── env.example # Variables d'environnement (modèle)
├── README.md

---

## 🔐 Lier le projet à ton compte Google Earth Engine

### 1) Préparer ton compte GEE

- Vérifie que ton compte Google est bien inscrit sur [Google Earth Engine](https://earthengine.google.com/).
- Crée un projet Google Cloud et active l'API Earth Engine.
- Crée un **Service Account** et télécharge la clé JSON.
- Dans Earth Engine, accorde l'accès au service account (avec les permissions nécessaires).

### 2) Configurer le projet

- Définis les variables d'environnement suivantes (dans PowerShell):
  - `GEE_SERVICE_ACCOUNT`
  - `GEE_PRIVATE_KEY_PATH` (chemin absolu vers le fichier JSON)

Exemple PowerShell:

```powershell
$env:GEE_SERVICE_ACCOUNT="gee-bot@my-project.iam.gserviceaccount.com"
$env:GEE_PRIVATE_KEY_PATH="C:/Users/ASUS/Desktop/grand projet pfe/trig_essalama_ai/keys/gee-bot.json"
```

### 3) Lancer l'API

```powershell
cd "C:\Users\ASUS\Desktop\grand projet pfe\trig_essalama_ai"
.\venv\Scripts\activate
uvicorn app.main:app --reload
```

> Si les variables GEE ne sont pas définies, l'application essaie le mode local interactif (`ee.Authenticate()`).

### 4) Mise a jour automatique des donnees

- L'API lance un rafraichissement automatique en arriere-plan au demarrage.
- Le resultat est sauvegarde via le pipeline dans `data/result.json`.
- Intervalle configurable avec `AUTO_REFRESH_SECONDS` (par defaut: `300` secondes).
- Endpoint `GET /latest` pour lire le dernier resultat calcule.


