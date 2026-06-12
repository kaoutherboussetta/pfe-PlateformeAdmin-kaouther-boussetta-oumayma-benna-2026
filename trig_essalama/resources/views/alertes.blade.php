<!DOCTYPE html>
<html lang="fr" class="trig-app trig-native-light">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Municipal - Gestion des alertes</title>
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
        }

        /* Header */
        .header {
            background: white;
            padding: 20px 30px;
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

        .header-user {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .user-avatar {
            width: 45px;
            height: 45px;
            background: #2563eb;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: 600;
            font-size: 16px;
        }

        .user-info h3 {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 2px;
        }

        .user-info p {
            font-size: 12px;
            color: #64748b;
        }

        /* Main Container */
        .container {
            display: flex;
            min-height: calc(100vh - 80px);
        }

        /* Sidebar */
        .sidebar {
            width: 250px;
            background: white;
            padding: 20px 0;
            box-shadow: 2px 0 4px rgba(0,0,0,0.05);
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 15px 25px;
            color: #475569;
            text-decoration: none;
            transition: all 0.3s;
            cursor: pointer;
        }

        .nav-item:hover {
            background: #f1f5f9;
        }

        .nav-item.active {
            background: #2563eb;
            color: white;
        }

        .nav-icon {
            font-size: 20px;
        }

        /* Main Content */
        .main-content {
            flex: 1;
            padding: 30px;
            overflow-y: auto;
        }

        .page-title {
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }

        .page-title h2 {
            font-size: 28px;
            font-weight: 700;
            color: #1e293b;
            margin-bottom: 5px;
        }

        .page-title p {
            font-size: 14px;
            color: #64748b;
        }

        .btn-new-alert {
            background: #2563eb;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s;
        }

        .btn-new-alert:hover {
            background: #1d4ed8;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
        }

        /* Alert Statistics Cards */
        .alert-stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin: 30px 0;
        }

        .alert-stat-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            border-left: 4px solid;
        }

        .alert-stat-card.orange {
            border-left-color: #f59e0b;
        }

        .alert-stat-card.red {
            border-left-color: #ef4444;
        }

        .alert-stat-card.purple {
            border-left-color: #8b5cf6;
        }

        .alert-stat-card.green {
            border-left-color: #10b981;
        }

        .stat-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .stat-title {
            font-size: 13px;
            color: #64748b;
            font-weight: 500;
        }

        .stat-icon {
            font-size: 24px;
        }

        .stat-value {
            font-size: 36px;
            font-weight: 700;
            color: #1e293b;
        }

        .stat-value.orange {
            color: #f59e0b;
        }

        .stat-value.red {
            color: #ef4444;
        }

        .stat-value.purple {
            color: #8b5cf6;
        }

        .stat-value.green {
            color: #10b981;
        }

        /* AI Analysis Section */
        .ai-analysis-section {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            margin-bottom: 30px;
        }

        .ai-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .ai-title {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .ai-title h3 {
            font-size: 18px;
            font-weight: 600;
            color: #1e293b;
        }

        .ai-title p {
            font-size: 13px;
            color: #64748b;
            margin-top: 2px;
        }

        .ai-status {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 13px;
            color: #8b5cf6;
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #8b5cf6;
            animation: pulse 2s ease-in-out infinite;
        }

        @keyframes pulse {
            0%, 100% {
                opacity: 1;
                transform: scale(1);
            }
            50% {
                opacity: 0.5;
                transform: scale(1.2);
            }
        }

        .ai-cards-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }

        .ai-card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            border: 2px solid;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .ai-card.purple {
            border-color: #8b5cf6;
        }

        .ai-card.red {
            border-color: #ef4444;
        }

        .ai-card.orange {
            border-color: #f59e0b;
        }

        .ai-card.blue {
            border-color: #3b82f6;
        }

        .ai-card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
        }

        .ai-card-title {
            font-size: 13px;
            color: #64748b;
            font-weight: 500;
        }

        .ai-card-icon {
            font-size: 20px;
        }

        .ai-card-value {
            font-size: 32px;
            font-weight: 700;
            color: #1e293b;
        }

        .ai-card-value.red {
            color: #ef4444;
        }

        .ai-card-value.orange {
            color: #f59e0b;
        }

        .ai-card-value.blue {
            color: #3b82f6;
        }

        /* Tabs */
        .tabs {
            display: flex;
            gap: 5px;
            border-bottom: 2px solid #e2e8f0;
            margin-bottom: 20px;
        }

        .tab {
            padding: 12px 24px;
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
            min-height: 200px;
        }

        /* Sources Data Section */
        .sources-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }

        .traffic-section-full {
            margin-top: 20px;
        }

        .source-card {
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .source-card-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 15px;
        }

        .source-card-icon {
            font-size: 24px;
        }

        .source-card-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
        }

        .source-update-time {
            font-size: 12px;
            color: #64748b;
            margin-bottom: 15px;
        }

        .zone-data-list {
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .zone-data-card {
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid;
        }

        .zone-data-card.critical {
            background: #fef2f2;
            border-left-color: #ef4444;
        }

        .zone-data-card.moderate {
            background: #fffbeb;
            border-left-color: #f59e0b;
        }

        .zone-data-card.low {
            background: #f0fdf4;
            border-left-color: #10b981;
        }

        .zone-name {
            font-size: 14px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 8px;
        }

        .severity-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            margin-bottom: 8px;
        }

        .severity-badge.critical {
            background: #fee2e2;
            color: #dc2626;
        }

        .severity-badge.moderate {
            background: #fef3c7;
            color: #d97706;
        }

        .severity-badge.low {
            background: #d1fae5;
            color: #059669;
        }

        .zone-metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
            font-size: 13px;
        }

        .zone-metric-label {
            color: #64748b;
        }

        .zone-metric-value {
            font-weight: 600;
            color: #1e293b;
        }

        .weather-alert-box {
            background: #fef2f2;
            border: 2px solid #ef4444;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
        }

        .weather-alert-title {
            font-size: 14px;
            font-weight: 600;
            color: #dc2626;
            margin-bottom: 8px;
        }

        .weather-alert-text {
            font-size: 13px;
            color: #475569;
            line-height: 1.5;
        }

        .weather-metrics-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        .weather-metric-card {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px;
        }

        .weather-metric-label {
            font-size: 12px;
            color: #64748b;
            margin-bottom: 6px;
        }

        .weather-metric-value {
            font-size: 18px;
            font-weight: 600;
            color: #1e293b;
        }

        .weather-metric-value.highlight {
            color: #f59e0b;
        }

        /* Traffic Data Section */
        .traffic-section {
            margin-top: 20px;
        }

        .traffic-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .traffic-header h4 {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
        }

        .traffic-update-time {
            font-size: 12px;
            color: #64748b;
        }

        .traffic-route-card {
            background: white;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
            border-left: 4px solid;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .traffic-route-card.red {
            border-left-color: #ef4444;
        }

        .traffic-route-card.orange {
            border-left-color: #f59e0b;
        }

        .traffic-route-card.green {
            border-left-color: #10b981;
        }

        .traffic-route-name {
            font-size: 15px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 12px;
        }

        .traffic-congestion-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 10px;
        }

        .traffic-congestion-badge.red {
            background: #fee2e2;
            color: #dc2626;
        }

        .traffic-congestion-badge.orange {
            background: #fef3c7;
            color: #d97706;
        }

        .traffic-congestion-badge.green {
            background: #d1fae5;
            color: #059669;
        }

        .traffic-metric {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
            font-size: 13px;
        }

        .traffic-metric-label {
            color: #64748b;
        }

        .traffic-metric-value {
            font-weight: 600;
            color: #1e293b;
        }

        .traffic-incidents-bar {
            height: 6px;
            border-radius: 3px;
            margin-top: 8px;
            background: #e2e8f0;
            overflow: hidden;
        }

        .traffic-incidents-fill {
            height: 100%;
            border-radius: 3px;
            transition: width 0.3s ease;
        }

        .traffic-incidents-fill.red {
            background: #ef4444;
        }

        .traffic-incidents-fill.orange {
            background: #f59e0b;
        }

        .traffic-incidents-fill.green {
            background: #10b981;
        }

        /* AI Recommendation Cards */
        .recommendation-cards {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        .recommendation-card {
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            border-left: 4px solid;
        }

        .recommendation-card.high-priority {
            background: #fff5f5;
            border-left-color: #ef4444;
        }

        .recommendation-card.medium-priority {
            background: #fff7ed;
            border-left-color: #f59e0b;
        }

        .recommendation-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 15px;
        }

        .recommendation-title {
            font-size: 18px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 8px;
        }

        .confidence-badge {
            display: inline-block;
            background: #f1f5f9;
            color: #475569;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }

        .recommendation-location {
            font-size: 14px;
            color: #64748b;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .recommendation-description {
            font-size: 14px;
            color: #475569;
            line-height: 1.6;
            margin-bottom: 15px;
        }

        .recommendation-sources {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 15px;
        }

        .source-tag {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #e0e7ff;
            color: #2563eb;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }

        .recommendation-action {
            font-size: 14px;
            color: #1e293b;
            margin-bottom: 10px;
        }

        .recommendation-action strong {
            color: #2563eb;
        }

        .recommendation-impact {
            font-size: 13px;
            color: #64748b;
            margin-bottom: 15px;
        }

        .recommendation-buttons {
            display: flex;
            gap: 10px;
        }

        .btn-create-alert {
            background: #8b5cf6;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 6px;
            transition: all 0.3s;
        }

        .btn-create-alert:hover {
            background: #7c3aed;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
        }

        .btn-ignore {
            background: white;
            color: #475569;
            border: 1px solid #e2e8f0;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-ignore:hover {
            background: #f1f5f9;
            border-color: #cbd5e1;
        }

        /* Alerts List */
        .alerts-section {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }

        .alerts-header {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 20px;
        }

        .alerts-header h3 {
            font-size: 18px;
            font-weight: 600;
            color: #1e293b;
        }

        .alert-item {
            background: #fff5f5;
            border-radius: 8px;
            padding: 18px 20px;
            margin-bottom: 12px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-left: 4px solid #ef4444;
            transition: all 0.3s;
        }

        .alert-item:hover {
            transform: translateX(5px);
            box-shadow: 0 4px 12px rgba(239, 68, 68, 0.15);
        }

        .alert-item-content {
            flex: 1;
        }

        .alert-title {
            font-size: 16px;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 4px;
        }

        .alert-meta {
            font-size: 13px;
            color: #64748b;
        }

        .alert-confidence {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
            font-weight: 600;
            color: #8b5cf6;
        }

        .alert-actions {
            display: flex;
            gap: 10px;
        }

        .btn-action {
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-view {
            background: #e0e7ff;
            color: #2563eb;
        }

        .btn-view:hover {
            background: #c7d2fe;
        }

        .btn-resolve {
            background: #d1fae5;
            color: #10b981;
        }

        .btn-resolve:hover {
            background: #a7f3d0;
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }

        .modal.active {
            display: flex;
        }

        .modal-content {
            background: white;
            border-radius: 12px;
            padding: 30px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }

        .modal-header h3 {
            font-size: 20px;
            font-weight: 600;
            color: #1e293b;
        }

        .btn-close {
            background: none;
            border: none;
            font-size: 24px;
            color: #64748b;
            cursor: pointer;
            padding: 0;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            font-size: 14px;
            font-weight: 500;
            color: #1e293b;
            margin-bottom: 8px;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
        }

        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }

        .form-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            margin-top: 25px;
        }

        .btn-cancel {
            background: #f1f5f9;
            color: #475569;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
        }

        .btn-submit {
            background: #2563eb;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
        }

        /* Responsive */
        @media (max-width: 1200px) {
            .alert-stats-grid,
            .ai-cards-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            .sources-grid {
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
            .alert-stats-grid,
            .ai-cards-grid {
                grid-template-columns: 1fr;
            }
            .page-title {
                flex-direction: column;
                gap: 15px;
            }
            .sources-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <!-- Header -->
    <div class="header">
        <div class="header-left">
            <div class="header-icon">☰</div>
            <div class="header-title">
                <h1>Dashboard Municipal</h1>
                <p>Gestion du réseau routier</p>
            </div>
        </div>
        <div class="header-user">
            <div class="user-avatar">MD</div>
            <div class="user-info">
                <h3>Marie Dubois</h3>
                <p>Administrateur</p>
            </div>
        </div>
    </div>

    <!-- Main Container -->
    <div class="container">
        <!-- Sidebar -->
        <div class="sidebar">
            <a href="/dashboard" class="nav-item">
                <span class="nav-icon">☰</span>
                <span>Supervision</span>
            </a>
            <a href="/alertes" class="nav-item active">
                <span class="nav-icon">⚠</span>
                <span>Alertes</span>
            </a>
            <a href="#" class="nav-item">
                <span class="nav-icon">🚧</span>
                <span>Interventions</span>
            </a>
            <a href="#" class="nav-item">
                <span class="nav-icon">👥</span>
                <span>Citoyens</span>
            </a>
            <a href="#" class="nav-item">
                <span class="nav-icon">📊</span>
                <span>Analyse</span>
            </a>
        </div>

        <!-- Main Content -->
        <div class="main-content">
            <div class="page-title">
                <div>
                    <h2>Gestion des alertes catastrophiques</h2>
                    <p>Alertes automatiques IA et création manuelle</p>
                </div>
                <button class="btn-new-alert" onclick="openModal()">
                    <span>+</span>
                    <span>Nouvelle alerte manuelle</span>
                </button>
            </div>

            <!-- Alert Statistics -->
            <div class="alert-stats-grid">
                <div class="alert-stat-card orange">
                    <div class="stat-header">
                        <span class="stat-title">Alertes actives</span>
                        <span class="stat-icon">⚠</span>
                    </div>
                    <div class="stat-value orange">3</div>
                </div>

                <div class="alert-stat-card red">
                    <div class="stat-header">
                        <span class="stat-title">Alertes critiques</span>
                        <span class="stat-icon">✕</span>
                    </div>
                    <div class="stat-value red">2</div>
                </div>

                <div class="alert-stat-card purple">
                    <div class="stat-header">
                        <span class="stat-title">Alertes IA</span>
                        <span class="stat-icon">🧠</span>
                    </div>
                    <div class="stat-value purple">2</div>
                </div>

                <div class="alert-stat-card green">
                    <div class="stat-header">
                        <span class="stat-title">Alertes résolues (24h)</span>
                        <span class="stat-icon">✓</span>
                    </div>
                    <div class="stat-value green">1</div>
                </div>
            </div>

            <!-- AI Analysis Section -->
            <div class="ai-analysis-section">
                <div class="ai-header">
                    <div class="ai-title">
                        <div>
                            <h3 style="display: flex; align-items: center; gap: 8px;">
                                <span>🧠</span>
                                <span>Analyse IA SmartRoad</span>
                            </h3>
                            <p>Recommandations automatiques basées sur l'analyse multi-sources</p>
                        </div>
                    </div>
                    <div class="ai-status">
                        <div class="status-dot"></div>
                        <span>Analyse en temps réel</span>
                    </div>
                </div>

                <div class="ai-cards-grid">
                    <div class="ai-card purple">
                        <div class="ai-card-header">
                            <span class="ai-card-title">Recommandations</span>
                            <span class="ai-card-icon">🧠</span>
                        </div>
                        <div class="ai-card-value">6</div>
                    </div>

                    <div class="ai-card red">
                        <div class="ai-card-header">
                            <span class="ai-card-title">Critiques</span>
                            <span class="ai-card-icon">!</span>
                        </div>
                        <div class="ai-card-value red">2</div>
                    </div>

                    <div class="ai-card orange">
                        <div class="ai-card-header">
                            <span class="ai-card-title">Haute priorité</span>
                            <span class="ai-card-icon">↑</span>
                        </div>
                        <div class="ai-card-value orange">2</div>
                    </div>

                    <div class="ai-card blue">
                        <div class="ai-card-header">
                            <span class="ai-card-title">Confiance moyenne</span>
                            <span class="ai-card-icon">✓</span>
                        </div>
                        <div class="ai-card-value blue">86%</div>
                    </div>
                </div>

                <div class="tabs">
                    <button class="tab active" onclick="switchTab('recommendations', this)">Recommandations IA</button>
                    <button class="tab" onclick="switchTab('sources', this)">Sources de données</button>
                </div>

                <div class="tab-content" id="recommendations-tab">
                    <div class="recommendation-cards">
                        <!-- High Priority Alert Card -->
                        <div class="recommendation-card high-priority">
                            <div class="recommendation-header">
                                <div style="flex: 1;">
                                    <div class="recommendation-title">Inondation majeure détectée - Zone Sud</div>
                                    <div class="recommendation-location">
                                        <span>📍</span>
                                        <span>Route de Lyon, Km 12-15</span>
                                    </div>
                                </div>
                                <span class="confidence-badge">Confiance: 94%</span>
                            </div>
                            <div class="recommendation-description">
                                L'analyse satellite combinée aux données météorologiques indique une inondation active avec un niveau d'eau de 2.8m. Fermeture immédiate recommandée.
                            </div>
                            <div style="margin-bottom: 12px;">
                                <span style="font-size: 13px; color: #64748b; font-weight: 500;">Sources:</span>
                                <div class="recommendation-sources">
                                    <span class="source-tag">
                                        <span>🛰️</span>
                                        <span>satellite</span>
                                    </span>
                                    <span class="source-tag">
                                        <span>☁️</span>
                                        <span>weather</span>
                                    </span>
                                </div>
                            </div>
                            <div class="recommendation-action">
                                <strong>Action suggérée:</strong> Fermeture immédiate de la route et mise en place de déviations
                            </div>
                            <div class="recommendation-impact">
                                Impact estimé: ~3,500 véhicules/jour affectés
                            </div>
                            <div class="recommendation-buttons">
                                <button class="btn-create-alert">
                                    <span>✓</span>
                                    <span>Créer l'alerte</span>
                                </button>
                                <button class="btn-ignore">Ignorer</button>
                            </div>
                        </div>

                        <!-- Medium Priority Alert Card -->
                        <div class="recommendation-card medium-priority">
                            <div class="recommendation-header">
                                <div style="flex: 1;">
                                    <div class="recommendation-title">Risque d'inondation imminent - Centre-ville</div>
                                    <div class="recommendation-location">
                                        <span>📍</span>
                                        <span>Avenue de la République</span>
                                    </div>
                                </div>
                                <span class="confidence-badge">Confiance: 87%</span>
                            </div>
                            <div class="recommendation-description">
                                Les prévisions météo et l'analyse du terrain indiquent un risque d'inondation dans les 2 prochaines heures.
                            </div>
                            <div style="margin-bottom: 12px;">
                                <span style="font-size: 13px; color: #64748b; font-weight: 500;">Sources:</span>
                                <div class="recommendation-sources">
                                    <span class="source-tag">
                                        <span>🛰️</span>
                                        <span>satellite</span>
                                    </span>
                                    <span class="source-tag">
                                        <span>☁️</span>
                                        <span>weather</span>
                                    </span>
                                    <span class="source-tag">
                                        <span>📍</span>
                                        <span>gps</span>
                                    </span>
                                </div>
                            </div>
                            <div class="recommendation-action">
                                <strong>Action suggérée:</strong> Surveillance renforcée et préparation des équipes d'intervention
                            </div>
                            <div class="recommendation-impact">
                                Impact estimé: ~1,200 véhicules/jour potentiellement affectés
                            </div>
                            <div class="recommendation-buttons">
                                <button class="btn-create-alert">
                                    <span>✓</span>
                                    <span>Créer l'alerte</span>
                                </button>
                                <button class="btn-ignore">Ignorer</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="tab-content" id="sources-tab" style="display: none;">
                    <div class="sources-grid">
                        <!-- Left Column: Satellite Analysis -->
                        <div class="source-card">
                            <div class="source-card-header">
                                <span class="source-card-icon">📡</span>
                                <h3 class="source-card-title">Analyse satellite (Google Earth Engine)</h3>
                            </div>
                            <div class="source-update-time">
                                Dernière mise à jour: <span id="satellite-update-time">11:51:41</span>
                            </div>
                            <div class="zone-data-list">
                                <!-- Zone Sud -->
                                <div class="zone-data-card critical">
                                    <div class="zone-name">Zone Sud - Route de Lyon</div>
                                    <span class="severity-badge critical">critical</span>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Niveau d'eau:</span>
                                        <span class="zone-metric-value">2.8m</span>
                                    </div>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Confiance IA:</span>
                                        <span class="zone-metric-value">94%</span>
                                    </div>
                                </div>

                                <!-- Centre-ville -->
                                <div class="zone-data-card moderate">
                                    <div class="zone-name">Centre-ville - Avenue République</div>
                                    <span class="severity-badge moderate">moderate</span>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Niveau d'eau:</span>
                                        <span class="zone-metric-value">1.2m</span>
                                    </div>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Confiance IA:</span>
                                        <span class="zone-metric-value">87%</span>
                                    </div>
                                </div>

                                <!-- Route des Monts -->
                                <div class="zone-data-card moderate">
                                    <div class="zone-name">Route des Monts</div>
                                    <span class="severity-badge moderate">moderate</span>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Niveau d'eau:</span>
                                        <span class="zone-metric-value">0.8m</span>
                                    </div>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Confiance IA:</span>
                                        <span class="zone-metric-value">91%</span>
                                    </div>
                                </div>

                                <!-- Périphérique Nord -->
                                <div class="zone-data-card low">
                                    <div class="zone-name">Périphérique Nord</div>
                                    <span class="severity-badge low">low</span>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Niveau d'eau:</span>
                                        <span class="zone-metric-value">0.3m</span>
                                    </div>
                                    <div class="zone-metric">
                                        <span class="zone-metric-label">Confiance IA:</span>
                                        <span class="zone-metric-value">96%</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Right Column: Weather Data -->
                        <div class="source-card">
                            <div class="source-card-header">
                                <span class="source-card-icon">☁️</span>
                                <h3 class="source-card-title">Données météorologiques</h3>
                            </div>
                            <div class="source-update-time">
                                Dernière mise à jour: <span id="weather-update-time">11:51:41</span>
                            </div>
                            
                            <!-- Weather Alert -->
                            <div class="weather-alert-box">
                                <div class="weather-alert-title">Alerte: danger</div>
                                <div class="weather-alert-text">
                                    Fortes pluies continues prévues pour les prochaines 6 heures. Risque d'inondations élevé.
                                </div>
                            </div>

                            <!-- Weather Metrics -->
                            <div class="weather-metrics-grid">
                                <div class="weather-metric-card">
                                    <div class="weather-metric-label">Précipitations</div>
                                    <div class="weather-metric-value highlight">45 mm/h</div>
                                </div>
                                <div class="weather-metric-card">
                                    <div class="weather-metric-label">Vent</div>
                                    <div class="weather-metric-value">35 km/h</div>
                                </div>
                                <div class="weather-metric-card">
                                    <div class="weather-metric-label">Mise à jour</div>
                                    <div class="weather-metric-value" style="font-size: 12px;">11:51:41</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Traffic Data Section - Below Satellite and Weather -->
                    <div class="traffic-section-full">
                        <div class="source-card">
                            <div class="source-card-header">
                                <span class="source-card-icon">🚗</span>
                                <h3 class="source-card-title">État du trafic (Google Maps API)</h3>
                            </div>
                            <div class="source-update-time">
                                Dernière mise à jour: <span id="traffic-update-time">12:26:41</span>
                            </div>
                            
                            <div class="traffic-section">
                                <!-- Route de Lyon -->
                                <div class="traffic-route-card red">
                                    <div class="traffic-route-name">Route de Lyon</div>
                                    <span class="traffic-congestion-badge red">95%</span>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Vitesse moyenne:</span>
                                        <span class="traffic-metric-value">15 km/h</span>
                                    </div>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Incidents:</span>
                                        <span class="traffic-metric-value">3</span>
                                    </div>
                                    <div class="traffic-incidents-bar">
                                        <div class="traffic-incidents-fill red" style="width: 100%;"></div>
                                    </div>
                                </div>

                                <!-- Avenue République -->
                                <div class="traffic-route-card orange">
                                    <div class="traffic-route-name">Avenue République</div>
                                    <span class="traffic-congestion-badge orange">68%</span>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Vitesse moyenne:</span>
                                        <span class="traffic-metric-value">35 km/h</span>
                                    </div>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Incidents:</span>
                                        <span class="traffic-metric-value">1</span>
                                    </div>
                                    <div class="traffic-incidents-bar">
                                        <div class="traffic-incidents-fill orange" style="width: 33%;"></div>
                                    </div>
                                </div>

                                <!-- Bd Jean Jaurès -->
                                <div class="traffic-route-card green">
                                    <div class="traffic-route-name">Bd Jean Jaurès</div>
                                    <span class="traffic-congestion-badge green">45%</span>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Vitesse moyenne:</span>
                                        <span class="traffic-metric-value">50 km/h</span>
                                    </div>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Incidents:</span>
                                        <span class="traffic-metric-value">0</span>
                                    </div>
                                    <div class="traffic-incidents-bar">
                                        <div class="traffic-incidents-fill green" style="width: 0%;"></div>
                                    </div>
                                </div>

                                <!-- Périphérique Nord -->
                                <div class="traffic-route-card red">
                                    <div class="traffic-route-name">Périphérique Nord</div>
                                    <span class="traffic-congestion-badge red">72%</span>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Vitesse moyenne:</span>
                                        <span class="traffic-metric-value">40 km/h</span>
                                    </div>
                                    <div class="traffic-metric">
                                        <span class="traffic-metric-label">Incidents:</span>
                                        <span class="traffic-metric-value">2</span>
                                    </div>
                                    <div class="traffic-incidents-bar">
                                        <div class="traffic-incidents-fill red" style="width: 67%;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Alerts List -->
            <div class="alerts-section">
                <div class="alerts-header">
                    <span style="color: #ef4444; font-size: 20px;">⚠</span>
                    <h3>Alertes détectées automatiquement</h3>
                </div>

                <div class="alert-item">
                    <div class="alert-item-content">
                        <div class="alert-title">Inondation majeure détectée - Zone Sud</div>
                        <div class="alert-meta">Détectée il y a 15 minutes • Source: IA + Capteurs</div>
                    </div>
                    <div class="alert-confidence">
                        <span>Confiance: 94%</span>
                    </div>
                    <div class="alert-actions">
                        <button class="btn-action btn-view">Voir détails</button>
                        <button class="btn-action btn-resolve">Résoudre</button>
                    </div>
                </div>

                <div class="alert-item">
                    <div class="alert-item-content">
                        <div class="alert-title">Dégradation de la chaussée - Route de Lyon</div>
                        <div class="alert-meta">Détectée il y a 32 minutes • Source: IA + Analyse satellite</div>
                    </div>
                    <div class="alert-confidence">
                        <span>Confiance: 87%</span>
                    </div>
                    <div class="alert-actions">
                        <button class="btn-action btn-view">Voir détails</button>
                        <button class="btn-action btn-resolve">Résoudre</button>
                    </div>
                </div>

                <div class="alert-item">
                    <div class="alert-item-content">
                        <div class="alert-title">Risque d'effondrement - Pont du Centre</div>
                        <div class="alert-meta">Détectée il y a 1 heure • Source: Capteurs structurels</div>
                    </div>
                    <div class="alert-confidence">
                        <span>Confiance: 92%</span>
                    </div>
                    <div class="alert-actions">
                        <button class="btn-action btn-view">Voir détails</button>
                        <button class="btn-action btn-resolve">Résoudre</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal for New Alert -->
    <div class="modal" id="alertModal">
        <div class="modal-content">
            <div class="modal-header">
                <h3>Nouvelle alerte manuelle</h3>
                <button class="btn-close" onclick="closeModal()">×</button>
            </div>
            <form id="alertForm">
                <div class="form-group">
                    <label for="alertType">Type d'alerte</label>
                    <select id="alertType" required>
                        <option value="">Sélectionner un type</option>
                        <option value="inondation">Inondation</option>
                        <option value="degradation">Dégradation de chaussée</option>
                        <option value="accident">Accident</option>
                        <option value="fermeture">Fermeture de route</option>
                        <option value="autre">Autre</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="alertLocation">Localisation</label>
                    <input type="text" id="alertLocation" placeholder="Ex: Zone Sud, Route de Lyon..." required>
                </div>
                <div class="form-group">
                    <label for="alertSeverity">Niveau de gravité</label>
                    <select id="alertSeverity" required>
                        <option value="">Sélectionner un niveau</option>
                        <option value="critique">Critique</option>
                        <option value="haute">Haute priorité</option>
                        <option value="moyenne">Priorité moyenne</option>
                        <option value="basse">Basse priorité</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="alertDescription">Description</label>
                    <textarea id="alertDescription" placeholder="Décrivez l'alerte en détail..." required></textarea>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn-cancel" onclick="closeModal()">Annuler</button>
                    <button type="submit" class="btn-submit">Créer l'alerte</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        function openModal() {
            document.getElementById('alertModal').classList.add('active');
        }

        function closeModal() {
            document.getElementById('alertModal').classList.remove('active');
        }

        function switchTab(tabId, btn) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            btn.classList.add('active');
            
            document.getElementById('recommendations-tab').style.display = tabId === 'recommendations' ? 'block' : 'none';
            document.getElementById('sources-tab').style.display = tabId === 'sources' ? 'block' : 'none';
        }

        document.getElementById('alertForm').addEventListener('submit', function(e) {
            e.preventDefault();
            alert('Alerte créée avec succès!');
            closeModal();
            this.reset();
        });

        // Close modal when clicking outside
        document.getElementById('alertModal').addEventListener('click', function(e) {
            if (e.target === this) {
                closeModal();
            }
        });

        // Update time every second
        function updateTime() {
            const now = new Date();
            const timeString = now.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
            const satelliteTime = document.getElementById('satellite-update-time');
            const weatherTime = document.getElementById('weather-update-time');
            const trafficTime = document.getElementById('traffic-update-time');
            if (satelliteTime) satelliteTime.textContent = timeString;
            if (weatherTime) weatherTime.textContent = timeString;
            if (trafficTime) trafficTime.textContent = timeString;
        }

        // Update time immediately and then every second
        updateTime();
        setInterval(updateTime, 1000);
    </script>
@include('partials.theme-toggle')
</body>
</html>
