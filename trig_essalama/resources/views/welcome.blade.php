<!DOCTYPE html>
<html lang="fr" class="trig-app trig-native-light">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Municipal - Gestion du réseau routier</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
            color: #333;
            overflow-x: hidden;
        }

        /* ===== HEADER ===== */
        .header {
            background: white;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .header-left {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .header-icon {
            width: 40px;
            height: 40px;
            background: #2563eb;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
        }

        .header-title h1 {
            font-size: 24px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 2px;
        }

        .header-title p {
            font-size: 14px;
            color: #64748b;
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .user-avatar {
            width: 40px;
            height: 40px;
            background: #2563eb;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 14px;
        }

        .user-info {
            display: flex;
            flex-direction: column;
        }

        .user-name {
            font-weight: 600;
            font-size: 14px;
            color: #1e293b;
        }

        .user-role {
            font-size: 12px;
            color: #64748b;
        }

        /* ===== MAIN LAYOUT ===== */
        .main-container {
            display: flex;
            min-height: calc(100vh - 70px);
        }

        /* ===== SIDEBAR ===== */
        .sidebar {
            width: 250px;
            background: white;
            padding: 20px 0;
            box-shadow: 2px 0 4px rgba(0,0,0,0.05);
            height: calc(100vh - 70px);
            position: sticky;
            top: 70px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 25px;
            color: #64748b;
            cursor: pointer;
            transition: all 0.3s;
            border-left: 3px solid transparent;
        }

        .nav-item:hover {
            background: #f1f5f9;
            color: #2563eb;
        }

        .nav-item.active {
            background: #eff6ff;
            color: #2563eb;
            border-left-color: #2563eb;
            font-weight: 600;
        }

        .nav-icon {
            font-size: 20px;
            width: 24px;
            text-align: center;
        }

        /* ===== CONTENT AREA ===== */
        .content {
            flex: 1;
            padding: 30px;
            overflow-y: auto;
        }

        .page-title {
            margin-bottom: 10px;
        }

        .page-title h2 {
            font-size: 28px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 5px;
        }

        .page-subtitle {
            font-size: 14px;
            color: #64748b;
            margin-bottom: 25px;
        }

        /* ===== METRICS CARDS ===== */
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .metric-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .metric-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .metric-title {
            font-size: 13px;
            color: #64748b;
            font-weight: 500;
        }

        .metric-icon {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
        }

        .metric-value {
            font-size: 28px;
            font-weight: 700;
            color: #1e293b;
        }

        .metric-detail {
            font-size: 12px;
            color: #64748b;
        }

        .metric-card.green .metric-icon {
            background: #dcfce7;
            color: #16a34a;
        }

        .metric-card.red .metric-icon {
            background: #fee2e2;
            color: #dc2626;
        }

        .metric-card.orange .metric-icon {
            background: #fed7aa;
            color: #ea580c;
        }

        .metric-card.blue .metric-icon {
            background: #dbeafe;
            color: #2563eb;
        }

        /* ===== MAIN CONTENT GRID ===== */
        .content-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }

        .content-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .card-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #e2e8f0;
        }

        .card-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
        }

        .card-icon {
            font-size: 18px;
            color: #64748b;
        }

        /* ===== MAP SECTION ===== */
        .map-container {
            height: 400px;
            background: linear-gradient(135deg, #e0f2fe 0%, #f0f9ff 100%);
            border-radius: 8px;
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
        }

        .map-legend {
            position: absolute;
            bottom: 15px;
            left: 15px;
            background: white;
            padding: 12px 15px;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            display: flex;
            gap: 15px;
            font-size: 12px;
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .legend-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }

        .legend-dot.red {
            background: #dc2626;
        }

        .legend-dot.orange {
            background: #ea580c;
        }

        .legend-dot.green {
            background: #16a34a;
        }

        .map-markers {
            position: absolute;
            width: 100%;
            height: 100%;
        }

        .map-marker {
            position: absolute;
            font-size: 24px;
        }

        .map-location {
            position: absolute;
            bottom: 15px;
            right: 15px;
            background: white;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 11px;
            color: #64748b;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        /* ===== WEATHER DATA ===== */
        .weather-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid #e2e8f0;
        }

        .weather-item:last-child {
            border-bottom: none;
        }

        .weather-label {
            font-size: 14px;
            color: #64748b;
        }

        .weather-value {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
        }

        .weather-value.highlight-red {
            color: #dc2626;
            font-weight: 700;
        }

        /* ===== SATELLITE ANALYSIS ===== */
        .satellite-info {
            font-size: 13px;
            color: #64748b;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* ===== RISK ZONES ===== */
        .risk-zones {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .risk-zone-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px;
            background: #f8fafc;
            border-radius: 8px;
            border-left: 4px solid;
        }

        .risk-zone-item.red {
            border-left-color: #dc2626;
        }

        .risk-zone-item.orange {
            border-left-color: #ea580c;
        }

        .risk-zone-name {
            font-weight: 600;
            font-size: 14px;
            color: #1e293b;
            margin-bottom: 4px;
        }

        .risk-zone-status {
            font-size: 12px;
            color: #64748b;
        }

        /* ===== ANOMALIES CARD ===== */
        .anomalies-card {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .anomalies-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
        }

        .anomalies-count {
            font-size: 32px;
            font-weight: 700;
            color: #ea580c;
        }

        /* ===== TABS SECTION ===== */
        .tabs-section {
            margin-top: 20px;
        }

        .tabs {
            display: flex;
            gap: 5px;
            border-bottom: 2px solid #e2e8f0;
            margin-bottom: 20px;
        }

        .tab {
            padding: 12px 20px;
            background: none;
            border: none;
            cursor: pointer;
            font-size: 14px;
            color: #64748b;
            font-weight: 500;
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: all 0.3s;
        }

        .tab:hover {
            color: #2563eb;
        }

        .tab.active {
            color: #2563eb;
            border-bottom-color: #2563eb;
            font-weight: 600;
        }

        .tab-content {
            background: white;
            border-radius: 12px;
            padding: 40px;
            min-height: 300px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            background: linear-gradient(135deg, #f0fdf4 0%, #fefce8 100%);
        }

        .tab-content-text {
            color: #94a3b8;
            font-size: 16px;
        }

        /* ===== RESPONSIVE ===== */
        @media (max-width: 1200px) {
            .content-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 768px) {
            .sidebar {
                width: 70px;
            }

            .nav-item span {
                display: none;
            }

            .metrics-grid {
                grid-template-columns: 1fr;
            }

            .header-title p {
                display: none;
            }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <!-- HEADER -->
    <div class="header">
        <div class="header-left">
            <div class="header-icon">☰</div>
            <div class="header-title">
                <h1>Dashboard Municipal</h1>
                <p>Gestion du réseau routier</p>
            </div>
        </div>
        <div class="header-right">
            <div class="user-avatar">MD</div>
            <div class="user-info">
                <div class="user-name">Marie Dubois</div>
                <div class="user-role">Administrateur</div>
            </div>
        </div>
    </div>

    <!-- MAIN CONTAINER -->
    <div class="main-container">
        <!-- SIDEBAR -->
        <div class="sidebar">
            <div class="nav-item active">
                <div class="nav-icon">☐</div>
                <span>Supervision</span>
            </div>
            <div class="nav-item">
                <div class="nav-icon">⚠</div>
                <span>Alertes</span>
            </div>
            <div class="nav-item">
                <div class="nav-icon">🚧</div>
                <span>Interventions</span>
            </div>
            <div class="nav-item">
                <div class="nav-icon">👥</div>
                <span>Citoyens</span>
            </div>
            <div class="nav-item">
                <div class="nav-icon">📊</div>
                <span>Analyse</span>
            </div>
        </div>

        <!-- CONTENT -->
        <div class="content">
            <div class="page-title">
                <h2>Supervision du réseau routier</h2>
                <p class="page-subtitle">Vue d'ensemble et surveillance en temps réel</p>
            </div>

            <!-- METRICS CARDS -->
            <div class="metrics-grid">
                <div class="metric-card green">
                    <div class="metric-header">
                        <div class="metric-title">Routes en bon état</div>
                        <div class="metric-icon">✓</div>
                    </div>
                    <div class="metric-value">156 / 200</div>
                </div>

                <div class="metric-card red">
                    <div class="metric-header">
                        <div class="metric-title">Alertes actives</div>
                        <div class="metric-icon">⚠</div>
                    </div>
                    <div class="metric-value">8</div>
                    <div class="metric-detail">3 critiques</div>
                </div>

                <div class="metric-card orange">
                    <div class="metric-header">
                        <div class="metric-title">Interventions en cours</div>
                        <div class="metric-icon">🚧</div>
                    </div>
                    <div class="metric-value">12</div>
                    <div class="metric-detail">5 terminées aujourd'hui</div>
                </div>

                <div class="metric-card red">
                    <div class="metric-header">
                        <div class="metric-title">Routes fermées</div>
                        <div class="metric-icon">✕</div>
                    </div>
                    <div class="metric-value">4</div>
                    <div class="metric-detail">Diversions actives</div>
                </div>

                <div class="metric-card blue">
                    <div class="metric-header">
                        <div class="metric-title">Zones à risque inondation</div>
                        <div class="metric-icon">🌊</div>
                    </div>
                    <div class="metric-value">6</div>
                    <div class="metric-detail">Surveillance active</div>
                </div>
            </div>

            <!-- MAIN CONTENT GRID -->
            <div class="content-grid">
                <!-- MAP SECTION -->
                <div class="content-card">
                    <div class="card-header">
                        <div class="card-icon">🗺️</div>
                        <div class="card-title">Carte interactive du réseau</div>
                    </div>
                    <div class="map-container">
                        <div class="map-markers">
                            <div class="map-marker" style="top: 30%; left: 20%;">⚠</div>
                            <div class="map-marker" style="top: 50%; right: 25%;">🚧</div>
                            <div class="map-marker" style="top: 60%; right: 30%;">🚧</div>
                        </div>
                        <div class="map-legend">
                            <div class="legend-item">
                                <div class="legend-dot red"></div>
                                <span>Critique</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-dot orange"></div>
                                <span>En cours</span>
                            </div>
                            <div class="legend-item">
                                <div class="legend-dot green"></div>
                                <span>Normal</span>
                            </div>
                        </div>
                        <div class="map-location">
                            Ville de Lyon<br>
                            45.7640° N, 4.8357° E
                        </div>
                    </div>
                </div>

                <!-- RIGHT COLUMN -->
                <div>
                    <!-- WEATHER DATA -->
                    <div class="content-card" style="margin-bottom: 20px;">
                        <div class="card-header">
                            <div class="card-icon">☁️</div>
                            <div class="card-title">Données météorologiques</div>
                        </div>
                        <div class="weather-item">
                            <div class="weather-label">Précipitations</div>
                            <div class="weather-value highlight-red">45 mm/h</div>
                        </div>
                        <div class="weather-item">
                            <div class="weather-label">Risque inondation</div>
                            <div class="weather-value highlight-red">Élevé</div>
                        </div>
                        <div class="weather-item">
                            <div class="weather-label">Vent</div>
                            <div class="weather-value">35 km/h</div>
                        </div>
                    </div>

                    <!-- SATELLITE ANALYSIS -->
                    <div class="content-card" style="margin-bottom: 20px;">
                        <div class="card-header">
                            <div class="card-icon">📡</div>
                            <div class="card-title">Analyse satellite</div>
                        </div>
                        <div class="satellite-info">
                            <span>Dernière mise à jour:</span>
                            <strong>Il y a 15 min</strong>
                        </div>
                    </div>

                    <!-- ANOMALIES -->
                    <div class="content-card" style="margin-bottom: 20px;">
                        <div class="anomalies-card">
                            <div class="anomalies-title">Anomalies détectées</div>
                            <div class="anomalies-count">3</div>
                        </div>
                    </div>

                    <!-- RISK ZONES -->
                    <div class="content-card">
                        <div class="card-header">
                            <div class="card-icon">📍</div>
                            <div class="card-title">Zones à risque</div>
                        </div>
                        <div class="risk-zones">
                            <div class="risk-zone-item red">
                                <div>
                                    <div class="risk-zone-name">Zone Sud</div>
                                    <div class="risk-zone-status">Risque inondation élevé</div>
                                </div>
                            </div>
                            <div class="risk-zone-item orange">
                                <div>
                                    <div class="risk-zone-name">Centre-ville</div>
                                    <div class="risk-zone-status">Surveillance renforcée</div>
                                </div>
                            </div>
                            <div class="risk-zone-item orange">
                                <div>
                                    <div class="risk-zone-name">Route de Lyon</div>
                                    <div class="risk-zone-status">Vulnérabilité moyenne</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <script>
        // Navigation sidebar
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', function() {
                document.querySelectorAll('.nav-item').forEach(nav => nav.classList.remove('active'));
                this.classList.add('active');
            });
        });
    </script>
@include('partials.theme-toggle')
</body>
</html>
