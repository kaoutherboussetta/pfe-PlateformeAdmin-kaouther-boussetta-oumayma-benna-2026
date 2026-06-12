<!DOCTYPE html>
<html lang="fr" class="trig-app trig-outfit">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trig-Essalama · Dashboard</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

        :root {
            --orange: #FF6B35;
            --orange-light: #FF8C5A;
            --orange-dark: #C2410C;
            --orange-glow: rgba(255, 107, 53, 0.22);
            /* Accents secondaires = nuances orange / noir (pas de bleu, vert néon, etc.) */
            --yellow: #FF925C;
            --cyan: #1A1A1A;
            --green: #EA580C;
            --red: #2A2A2A;
            --bg: #F4F4F5;
            --bg2: #FFFFFF;
            --bg3: #FFFFFF;
            --surface: rgba(0, 0, 0, 0.04);
            --surface2: rgba(0, 0, 0, 0.07);
            --border: rgba(0, 0, 0, 0.1);
            --border-accent: rgba(255, 107, 53, 0.45);
            --text: #0A0A0A;
            --text2: #525252;
            --text3: #737373;
            --sidebar-w: 240px;
            /* Noir pour contrastes forts (uniquement avec blanc + orange) */
            --black: #0A0A0A;
            --black-soft: #1A1A1A;
        }

        body { font-family: 'Outfit', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; overflow-x: hidden; }

        .bg-canvas { position: fixed; inset: 0; z-index: 0; overflow: hidden; pointer-events: none; }
        .bg-canvas::before { content: ''; position: absolute; width: 800px; height: 800px; top: -300px; left: -200px; background: radial-gradient(circle, rgba(255,107,53,0.14) 0%, transparent 65%); animation: pulse1 8s ease-in-out infinite; }
        .bg-canvas::after { content: ''; position: absolute; width: 600px; height: 600px; bottom: -200px; right: -100px; background: radial-gradient(circle, rgba(0,0,0,0.04) 0%, transparent 65%); animation: pulse2 10s ease-in-out infinite; }
        @keyframes pulse1 { 0%,100%{transform:scale(1)} 50%{transform:scale(1.1) translate(20px,15px)} }
        @keyframes pulse2 { 0%,100%{transform:scale(1)} 50%{transform:scale(1.1) translate(-15px,-20px)} }
        .grid-overlay { position: fixed; inset: 0; z-index: 0; pointer-events: none; background-image: linear-gradient(rgba(0,0,0,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,0.05) 1px, transparent 1px); background-size: 60px 60px; opacity: 0.45; }

        .app { position: relative; z-index: 1; display: flex; min-height: 100vh; }

        @include('partials.dashboard_shell_styles')
        @include('partials.equipes_dashboard_styles')

        /* MAIN */
        .main { flex: 1; display: flex; flex-direction: column; min-width: 0; overflow: hidden; }
        .page-title { display: flex; align-items: center; }
        .page-title h2 { font-size: 17px; font-weight: 700; color: var(--text); }
        .page-breadcrumb { font-size: 12px; color: var(--text2); margin-left: 12px; }
        .page-breadcrumb span { color: var(--orange); }
        .topbar-actions { display: flex; align-items: center; gap: 10px; }
        .topbar-btn { width: 38px; height: 38px; border-radius: 9px; background: var(--surface); border: 1px solid var(--border); color: var(--text2); display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; font-size: 14px; position: relative; }
        .topbar-btn:hover { background: var(--surface2); color: var(--text); border-color: var(--border-accent); }
        .notif-dot { position: absolute; top: 7px; right: 7px; width: 7px; height: 7px; border-radius: 50%; background: var(--orange); border: 2px solid var(--bg2); animation: blink 2s ease-in-out infinite; }
        @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.4} }
        /* Modern main navbar */
        .main-navbar { width: 100%; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .nav-left { display: flex; align-items: center; gap: 14px; min-width: 0; }
        .brand-chip { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 10px; background: var(--surface); border: 1px solid var(--border); color: var(--text); font-weight: 700; letter-spacing: .3px; }
        .brand-chip .dot { width: 10px; height: 10px; border-radius: 50%; background: var(--orange); box-shadow: 0 0 12px var(--orange-glow); }
        .nav-links { display: flex; align-items: center; gap: 6px; }
        .nav-link { display: inline-flex; align-items: center; gap: 8px; padding: 9px 14px; border-radius: 10px; color: var(--text2); border: 1px solid transparent; background: transparent; text-decoration: none; font-size: 13px; font-weight: 600; }
        .nav-link:hover { color: var(--text); background: var(--surface); border-color: var(--border); }
        .nav-link.active { color: var(--text); background: rgba(255,107,53,0.14); border-color: rgba(255,107,53,0.35); }
        .nav-badge { padding: 2px 8px; font-size: 11px; border-radius: 999px; background: rgba(255,107,53,0.12); color: var(--orange-dark); border: 1px solid rgba(255,107,53,0.35); }
        .nav-right { display: flex; align-items: center; gap: 8px; }
        .nav-search { position: relative; }
        .nav-search input { width: 220px; background: var(--surface); border: 1px solid var(--border); color: var(--text); padding: 9px 34px 9px 12px; border-radius: 10px; outline: none; font-size: 13px; }
        .nav-search i { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); color: var(--text3); font-size: 13px; }
        .avatar-btn { display: flex; align-items: center; gap: 8px; padding: 6px 10px; border-radius: 999px; background: var(--surface); border: 1px solid var(--border); color: var(--text2); cursor: pointer; }
        .avatar-btn .avatar { width: 22px; height: 22px; border-radius: 999px; background: linear-gradient(135deg, var(--orange), #C84B1F); }
        .dropdown { position: relative; }
        .dropdown-menu { position: absolute; right: 0; top: calc(100% + 8px); background: var(--bg2); border: 1px solid var(--border); border-radius: 10px; min-width: 200px; padding: 8px; display: none; box-shadow: 0 18px 40px rgba(0,0,0,0.12); }
        .dropdown-menu.show { display: block; }
        .dropdown-item { padding: 9px 10px; border-radius: 8px; color: var(--text2); font-size: 13px; display: flex; gap: 10px; align-items: center; text-decoration: none; }
        .dropdown-item:hover { background: var(--surface); color: var(--text); }
        .status-pill { display: flex; align-items: center; gap: 7px; padding: 7px 13px; border-radius: 20px; background: rgba(255,107,53,0.1); border: 1px solid rgba(255,107,53,0.28); }
        .status-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--orange); animation: blink 2s infinite; }
        .status-text { font-size: 11px; font-weight: 600; color: var(--orange-dark); }

        /* CONTENT */
        .content { padding: 24px 28px 36px; flex: 1; overflow-y: auto; overflow-x: hidden; }
        .section-header { margin-bottom: 22px; }
        .section-header h3 { font-size: 22px; font-weight: 800; color: var(--text); letter-spacing: -0.5px; }
        .section-header p { font-size: 13px; color: var(--text2); margin-top: 4px; }

        /* STATS */
        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 24px; }
        .stat-card { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; padding: 20px; position: relative; overflow: hidden; transition: all 0.3s; }
        .stat-card::before { content: ''; position: absolute; inset: 0; background: linear-gradient(135deg, var(--c1, transparent) 0%, transparent 60%); opacity: 0; transition: opacity 0.3s; }
        .stat-card:hover { transform: translateY(-3px); border-color: var(--c2, var(--border)); box-shadow: 0 16px 32px rgba(0,0,0,0.08), 0 0 24px var(--c3, transparent); }
        .stat-card:hover::before { opacity: 1; }
        .stat-card.orange { --c1: rgba(255,107,53,0.1); --c2: rgba(255,107,53,0.4); --c3: rgba(255,107,53,0.14); }
        .stat-card.yellow { --c1: rgba(255,146,92,0.1); --c2: rgba(255,146,92,0.38); --c3: rgba(255,146,92,0.12); }
        .stat-card.cyan { --c1: rgba(26,26,26,0.06); --c2: rgba(26,26,26,0.28); --c3: rgba(26,26,26,0.08); }
        .stat-card.green { --c1: rgba(234,88,12,0.1); --c2: rgba(234,88,12,0.38); --c3: rgba(234,88,12,0.12); }
        .stat-card.red { --c1: rgba(42,42,42,0.08); --c2: rgba(42,42,42,0.32); --c3: rgba(42,42,42,0.1); }
        .stat-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }
        .stat-label { font-size: 10px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: var(--text3); }
        .stat-icon-wrap { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
        .stat-card.orange .stat-icon-wrap { background: rgba(255,107,53,0.15); color: var(--orange); }
        .stat-card.yellow .stat-icon-wrap { background: rgba(255,146,92,0.18); color: var(--yellow); }
        .stat-card.cyan .stat-icon-wrap { background: rgba(26,26,26,0.08); color: var(--cyan); }
        .stat-card.green .stat-icon-wrap { background: rgba(234,88,12,0.15); color: var(--green); }
        .stat-card.red .stat-icon-wrap { background: rgba(42,42,42,0.1); color: var(--red); }
        .stat-value { font-family: 'Bebas Neue', sans-serif; font-size: 40px; letter-spacing: 2px; line-height: 1; }
        .stat-card.orange .stat-value { color: var(--orange); }
        .stat-card.yellow .stat-value { color: var(--yellow); }
        .stat-card.cyan .stat-value { color: var(--cyan); }
        .stat-card.green .stat-value { color: var(--green); }
        .stat-card.red .stat-value { color: var(--red); }
        .stat-sub { font-size: 11px; color: var(--text2); margin-top: 5px; }
        .stat-bar { height: 3px; border-radius: 2px; margin-top: 12px; background: rgba(0,0,0,0.06); overflow: hidden; }
        .stat-bar-fill { height: 100%; border-radius: 2px; animation: fillBar 1.5s ease forwards; }
        @keyframes fillBar { from{width:0} }
        .stat-card.orange .stat-bar-fill { background: var(--orange); width: 65%; }
        .stat-card.yellow .stat-bar-fill { background: var(--yellow); width: 40%; }
        .stat-card.cyan .stat-bar-fill { background: var(--cyan); width: 98%; }
        .stat-card:nth-child(1) { animation: slideUp 0.4s 0.05s ease forwards; opacity: 0; }
        .stat-card:nth-child(2) { animation: slideUp 0.4s 0.1s ease forwards; opacity: 0; }
        .stat-card:nth-child(3) { animation: slideUp 0.4s 0.15s ease forwards; opacity: 0; }
        @keyframes slideUp { to { opacity: 1; transform: translateY(0); } }

        /* LAYOUT — carte pleine largeur, widgets météo / satellite / risques en dessous */
        .layout-grid { display: block; }
        .map-widgets-below {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 18px;
            padding: 0 20px 20px;
            align-items: stretch;
        }
        .map-widgets-below .weather-section,
        .map-widgets-below .satellite-section,
        .map-widgets-below .risk-zones-section { margin-bottom: 0; min-height: 100%; }
        @media (max-width: 1200px) {
            .map-widgets-below { grid-template-columns: 1fr; }
        }

        /* CARD */
        .card { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; transition: border-color 0.2s; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .card:hover { border-color: rgba(255,107,53,0.25); }
        .card-head { padding: 15px 20px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; background: rgba(0,0,0,0.03); gap: 10px; flex-wrap: wrap; }
        .card-title-wrap { display: flex; align-items: center; gap: 9px; }
        .card-icon { width: 30px; height: 30px; border-radius: 8px; background: rgba(255,107,53,0.12); color: var(--orange); display: flex; align-items: center; justify-content: center; font-size: 12px; }
        .card-title { font-size: 14px; font-weight: 700; color: var(--text); }

        .btn-create { display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; border-radius: 8px; background: var(--orange); color: #fff; font-size: 12px; font-weight: 700; border: none; cursor: pointer; transition: all 0.2s; box-shadow: 0 0 14px rgba(255,107,53,0.3); white-space: nowrap; }
        .btn-create:hover { background: var(--orange-light); transform: translateY(-1px); }

        /* MAP SECTION — palette stricte : blanc, noir, orange */
        .map-section {
            position: relative;
            border-radius: 14px;
            padding: 0;
            overflow: hidden;
            background: #FFFFFF;
            border: 1px solid rgba(0,0,0,0.1);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            transition: border-color 0.2s;
        }
        .map-section:hover {
            border-color: rgba(255,107,53,0.45);
            box-shadow: 0 2px 12px rgba(255,107,53,0.12);
        }
        .map-section::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 4px;
            background: linear-gradient(180deg, var(--orange) 0%, var(--orange-dark) 100%);
            pointer-events: none;
            z-index: 2;
            border-radius: 14px 0 0 14px;
        }
        .map-section-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px 16px;
            padding: 15px 20px;
            border-bottom: 1px solid rgba(0,0,0,0.08);
            background: #FFFFFF;
        }
        .map-section-brand {
            display: flex;
            align-items: center;
            gap: 12px;
            min-width: 0;
        }
        .map-section-head .card-icon {
            width: 40px;
            height: 40px;
            border-radius: 10px;
            font-size: 16px;
            flex-shrink: 0;
            background: rgba(255,107,53,0.12) !important;
            color: var(--orange-dark) !important;
            border: 1px solid rgba(255,107,53,0.35);
        }
        .map-section-text { min-width: 0; }
        .map-section-kicker {
            display: block;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: var(--orange);
            margin-bottom: 2px;
        }
        .map-section-title {
            margin: 0;
            font-size: 1.05rem;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: var(--black);
            line-height: 1.25;
            font-family: 'Outfit', sans-serif;
        }
        .map-section-title span { color: var(--orange-dark); font-weight: 600; font-size: 0.88rem; opacity: 0.92; }
        .map-status-legend {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
            padding: 0;
            background: transparent;
            border: none;
        }
        .map-status-legend--head { position: relative; top: auto; right: auto; }
        .status-legend-item {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 11px;
            border-radius: 9px;
            font-size: 11px;
            font-weight: 600;
            color: var(--black);
            background: #FFFFFF;
            border: 1px solid rgba(0,0,0,0.1);
        }
        .status-legend-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            flex-shrink: 0;
            box-shadow: 0 0 0 2px rgba(255,107,53,0.25);
        }
        .status-legend-dot.red { background: var(--black-soft); animation: mapLegendPulse 2s ease-in-out infinite; }
        .status-legend-dot.orange { background: var(--orange); animation: mapLegendPulse 2.5s ease-in-out infinite; }
        .status-legend-dot.green { background: var(--orange-dark); }
        @keyframes mapLegendPulse { 0%,100%{ transform: scale(1); opacity: 1; } 50%{ transform: scale(1.15); opacity: 0.85; } }

        .map-frame {
            position: relative;
            margin: 0 20px 20px;
            border-radius: 12px;
            overflow: hidden;
            background: #E8EDE4;
            border: 1px solid rgba(0,0,0,0.1);
            box-shadow: inset 0 0 0 1px rgba(255,107,53,0.15);
        }
        .map-frame::after {
            content: '';
            position: absolute;
            inset: 0;
            border-radius: 12px;
            pointer-events: none;
            box-shadow: inset 0 0 0 1px rgba(0,0,0,0.04);
            z-index: 400;
        }
        @media (max-width: 640px) {
            .map-section-head { padding: 14px 16px; }
            .map-section-head .card-icon { width: 36px; height: 36px; font-size: 14px; }
            .map-section-title { font-size: 1rem; }
            .map-frame { margin: 0 16px 16px; border-radius: 10px; }
            .map-widgets-below { padding: 0 16px 16px; gap: 14px; }
        }

        /* WEATHER & SATELLITE SECTIONS */
        .weather-section, .satellite-section, .risk-zones-section { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; padding: 20px; margin-bottom: 16px; }
        .weather-item { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-bottom: 1px solid var(--border); }
        .weather-item:last-child { border-bottom: none; }
        .weather-label { font-size: 14px; color: var(--text2); }
        .weather-value { font-size: 16px; font-weight: 600; color: var(--text); }
        .weather-value.high { color: var(--orange-dark); }
        .weather-value.medium { color: var(--orange); }
        .weather-meta {
            margin-top: 4px;
            padding-top: 12px;
            border-top: 1px solid var(--border);
            font-size: 11px;
            color: var(--text3);
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
        }
        .weather-meta #wx-status { color: var(--text2); flex: 1; min-width: 0; display: flex; flex-wrap: wrap; align-items: center; gap: 4px 6px; line-height: 1.35; }
        .weather-meta #wx-status .wx-status-link { color: var(--orange-dark); font-weight: 600; text-decoration: underline; text-underline-offset: 2px; }
        .weather-meta #wx-status .wx-status-link:hover { color: var(--orange); }
        .weather-meta #wx-status .wx-status-coords { color: var(--text2); font-weight: 500; }
        .weather-meta #wx-status .wx-status-time { color: var(--text3); font-size: 11px; }
        .weather-meta #wx-status .wx-status-need-gps { color: var(--text2); font-size: 12px; font-weight: 500; line-height: 1.4; }
        .weather-meta #wx-error { color: var(--orange-dark); font-weight: 600; width: 100%; }
        .wx-refresh-btn {
            flex-shrink: 0;
            padding: 6px 12px;
            border-radius: 8px;
            border: 1px solid rgba(255,107,53,0.45);
            background: #fff;
            color: var(--orange-dark);
            font-size: 11px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
        }
        .wx-refresh-btn:hover { background: rgba(255,107,53,0.1); }
        .wx-refresh-btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .satellite-info { font-size: 14px; color: var(--text2); margin-bottom: 12px; }
        .satellite-info-item { margin-bottom: 10px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .satellite-value { font-weight: 600; color: var(--text); }
        .satellite-value.orange { color: var(--orange); font-size: 16px; }
        .satellite-submeta {
            margin-top: 8px;
            padding-top: 12px;
            border-top: 1px solid var(--border);
            font-size: 12px;
            color: var(--text2);
            display: flex;
            flex-direction: column;
            gap: 6px;
            line-height: 1.4;
        }
        .satellite-meta { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--border); font-size: 12px; color: var(--text2); }
        .satellite-meta #sat-error { color: var(--orange-dark); font-weight: 600; width: 100%; }
        .zone-card { background: var(--surface); border-radius: 8px; padding: 15px; margin-bottom: 12px; display: flex; align-items: center; gap: 15px; border-left: 4px solid; transition: transform 0.2s; }
        .zone-card:hover { transform: translateX(5px); }
        .zone-card.red { border-left-color: var(--red); }
        .zone-card.orange { border-left-color: var(--orange); }
        .zone-name { font-size: 16px; font-weight: 600; color: var(--text); margin-bottom: 4px; }
        .zone-place { font-size: 13px; color: var(--text); margin-bottom: 6px; font-weight: 500; }
        .zone-place a {
            color: var(--orange-dark);
            font-weight: 600;
            text-decoration: underline;
            text-underline-offset: 2px;
        }
        .zone-place a:hover { color: var(--orange); }
        .zone-place-hint { color: var(--text2); font-weight: 400; }
        .zone-status { font-size: 13px; color: var(--text2); }
        .zone-category {
            display: inline-flex;
            align-items: center;
            margin-top: 8px;
            font-size: 11px;
            font-weight: 700;
            color: var(--orange-dark);
            border: 1px solid rgba(255, 107, 53, 0.35);
            background: rgba(255, 107, 53, 0.1);
            border-radius: 999px;
            padding: 4px 10px;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }

        /* ANALYSE SECTION (onglets + graphiques) */
        .analyse-header h3 { font-size: 24px; }
        .analyse-header p { font-size: 14px; }

        .analyse-tabs { margin-top: 8px; }
        .analyse-tabs-nav { display: flex; gap: 8px; margin-bottom: 14px; }
        .analyse-tab-btn { padding: 10px 22px; border-radius: 999px; border: 1px solid var(--border); background: var(--surface); color: var(--text2); font-size: 13px; cursor: pointer; font-weight: 500; }
        .analyse-tab-btn.active { background: var(--orange); border-color: var(--orange); color: #fff; box-shadow: 0 0 16px rgba(255,107,53,0.3); }

        .analyse-tab-panels { background: transparent; border-radius: 14px; border: none; padding: 0; }
        .analyse-tab-panel { display: none; }
        .analyse-tab-panel.active { display: block; }

        .analyse-main-grid { display: grid; grid-template-columns: 2.1fr 1.1fr; gap: 18px; align-items: flex-start; }

        /* Layout spécifique onglet Interventions :
           - graphique en haut pleine largeur
           - cartes "Durée moyenne" et "Interventions par statut" en dessous */
        .interventions-layout {
            display: flex;
            flex-direction: column;
            gap: 18px;
            width: 100%;
        }
        .interventions-bottom-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 18px;
            align-items: stretch;
        }
        .interventions-bottom-grid .analyse-mini-card {
            background: radial-gradient(circle at top left, rgba(255,107,53,0.12), transparent 55%),
                        radial-gradient(circle at bottom right, rgba(0,0,0,0.04), transparent 55%),
                        var(--bg2);
            border-radius: 16px;
            border: 1px solid var(--border);
            box-shadow: 0 8px 28px rgba(0,0,0,0.06);
        }
        .interventions-bottom-grid .analyse-mini-title {
            font-size: 15px;
        }
        @media (max-width: 900px) {
            .interventions-bottom-grid {
                grid-template-columns: 1fr;
            }
        }

        .analyse-chart-card { background: var(--bg2); border-radius: 16px; padding: 18px 18px 20px; border: 1px solid var(--border); box-shadow: 0 8px 28px rgba(0,0,0,0.06); }
        .analyse-chart-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; gap: 12px; }
        .analyse-chart-title { font-size: 15px; font-weight: 600; }
        .analyse-chart-sub { font-size: 12px; color: var(--text2); }

        /* Graphique ligne interventions – style maquette */
        .interventions-line-chart { display: flex; flex-direction: column; gap: 12px; }
        .interventions-line-chart .chart-legend { display: flex; gap: 16px; align-items: center; font-size: 12px; color: var(--text2); margin-top: 4px; }
        .interventions-line-chart .legend-item { display: flex; align-items: center; gap: 6px; }
        .interventions-line-chart .ldot { width: 10px; height: 10px; border-radius: 999px; }

        .line-chart-wrapper {
            position: relative;
            height: 260px;
            border-radius: 16px;
            padding: 18px 24px 24px;
            background: radial-gradient(circle at top left, rgba(255,107,53,0.1), transparent 50%),
                        radial-gradient(circle at top right, rgba(0,0,0,0.03), transparent 55%),
                        #FAFAFA;
            border: 1px solid var(--border);
            overflow: hidden;
        }

        .line-chart-y {
            position: absolute;
            left: 12px;
            top: 20px;
            bottom: 32px;
            display: flex;
            flex-direction: column-reverse;
            justify-content: space-between;
            font-size: 11px;
            color: var(--text3);
        }

        .line-chart-x {
            position: absolute;
            left: 52px;
            right: 16px;
            bottom: 10px;
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            color: var(--text3);
        }

        .line-chart-svg {
            position: absolute;
            inset: 12px 16px 32px 52px;
        }

        .line-chart-grid line {
            stroke: rgba(0,0,0,0.08);
            stroke-width: 1;
        }

        .line-chart-path-travaux {
            fill: none;
            stroke: #1A1A1A;
            stroke-width: 2.2;
            stroke-linecap: round;
        }

        .line-chart-path-reparations {
            fill: none;
            stroke: #FF6B35;
            stroke-width: 2.2;
            stroke-linecap: round;
        }

        .line-chart-path-maintenance {
            fill: none;
            stroke: #C2410C;
            stroke-width: 2.2;
            stroke-linecap: round;
        }

        .line-chart-dot-travaux { fill: #1A1A1A; }
        .line-chart-dot-reparations { fill: #FF6B35; }
        .line-chart-dot-maintenance { fill: #C2410C; }

        /* Faux bar chart for "Évolution interventions" */
        .analyse-bar-chart { position: relative; height: 220px; padding: 10px 0 4px; display: flex; align-items: flex-end; gap: 18px; }
        .analyse-bar-month { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; position: relative; }
        .analyse-bar-stack { width: 26px; display: flex; flex-direction: column; justify-content: flex-end; gap: 2px; }
        .bar-blue { background: #1A1A1A; border-radius: 6px 6px 0 0; }
        .bar-orange { background: #FF6B35; border-radius: 6px 6px 0 0; }
        .bar-green { background: #C2410C; border-radius: 6px 6px 0 0; }
        .bar-grey { background: #E5E7EB; border-radius: 8px; }
        .analyse-bar-label { font-size: 11px; color: var(--text2); }
        /* surbrillance du mois d'octobre comme sur la maquette */
        .analyse-bar-month.highlight::before {
            content: '';
            position: absolute;
            inset: -8px -10px 18px;
            background: #E5E7EB;
            border-radius: 10px;
            z-index: -1;
        }

        /* Tooltip valeurs mois (comme sur la capture) */
        .analyse-tooltip {
            position: absolute;
            bottom: 105%;
            left: 50%;
            transform: translateX(-50%);
            background: #FFFFFF;
            color: #111827;
            padding: 10px 12px;
            border-radius: 8px;
            box-shadow: 0 10px 25px rgba(15,23,42,0.18);
            font-size: 11px;
            min-width: 140px;
            text-align: left;
            border: 1px solid #E5E7EB;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.15s ease, transform 0.15s ease;
            z-index: 10;
            white-space: nowrap;
        }
        .analyse-tooltip-title {
            font-weight: 600;
            margin-bottom: 6px;
        }
        .analyse-tooltip-row {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-bottom: 3px;
        }
        .analyse-tooltip-dot {
            width: 8px;
            height: 8px;
            border-radius: 999px;
            flex-shrink: 0;
        }
        .analyse-bar-month:hover .analyse-tooltip {
            opacity: 1;
            transform: translateX(-50%) translateY(-2px);
        }
        .analyse-bar-legend { display: flex; gap: 14px; margin-top: 8px; font-size: 12px; color: var(--text2); }
        .analyse-bar-legend-item { display: flex; align-items: center; gap: 6px; }
        .legend-dot { width: 10px; height: 10px; border-radius: 999px; }

        /* Cards colonne droite (durée moyenne + statut) */
        .analyse-mini-card { background: var(--bg2); border-radius: 12px; border: 1px solid var(--border); padding: 16px 16px 18px; margin-bottom: 12px; }
        .analyse-mini-title { font-size: 14px; font-weight: 600; margin-bottom: 10px; display: flex; align-items: center; gap: 8px; }
        .analyse-mini-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; font-size: 13px; }
        .analyse-mini-row-label { color: var(--text2); }
        .analyse-mini-row-value { font-weight: 600; }
        .analyse-mini-bar { height: 6px; border-radius: 999px; background: rgba(0,0,0,0.08); overflow: hidden; margin-top: 4px; }
        .analyse-mini-bar-fill { height: 100%; border-radius: inherit; background: linear-gradient(90deg, #FF6B35, #1A1A1A); }

        /* Mise en forme vue Alertes (camembert + cartes temps de résolution) */
        .alerts-grid {
            display: grid;
            grid-template-columns: 1.4fr 1.1fr;
            gap: 24px;
            align-items: stretch;
        }
        .alerts-card {
            background: var(--bg3);
            border-radius: 18px;
            border: 1px solid var(--border);
            box-shadow: 0 8px 28px rgba(0,0,0,0.06);
            padding: 22px 24px 26px;
        }
        .alerts-title {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 14px;
            font-weight: 600;
            font-size: 15px;
        }
        .alerts-title-icon {
            width: 26px;
            height: 26px;
            border-radius: 999px;
            background: rgba(255,107,53,0.12);
            color: var(--orange);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
        }
        .alerts-pie-wrapper {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 18px 0 8px;
        }
        .alerts-pie {
            position: relative;
            width: 260px;
            height: 260px;
            border-radius: 999px;
            background:
                    conic-gradient(
                        #1A1A1A 0 35%,
                        #FF6B35 35% 63%,
                        #FF925C 63% 83%,
                        #C2410C 83% 100%
                    );
            box-shadow: 0 12px 28px rgba(0,0,0,0.08);
        }
        .alerts-pie::after {
            content: '';
            position: absolute;
            inset: 18%;
            border-radius: inherit;
            background: var(--bg2);
        }
        .alerts-pie-label {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 600;
            color: var(--text);
        }
        .alerts-pie-tooltip {
            position: absolute;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -10px);
            background: var(--bg3);
            border-radius: 10px;
            padding: 10px 14px;
            box-shadow: 0 12px 32px rgba(0,0,0,0.12);
            border: 1px solid var(--border);
            font-size: 13px;
            white-space: nowrap;
        }
        .alerts-pie-tooltip strong {
            font-weight: 600;
        }
        .alerts-legend-label {
            position: absolute;
            font-size: 13px;
            font-weight: 600;
        }
        .alerts-legend-label.blue { color: #1A1A1A; top: 18%; right: -40%; }
        .alerts-legend-label.orange { color: #FF6B35; top: 38%; left: -42%; }
        .alerts-legend-label.green { color: #FF925C; bottom: -6%; left: -6%; }
        .alerts-legend-label.red { color: #C2410C; bottom: -4%; right: -10%; }

        .alerts-time-card {
            background: var(--bg3);
            border-radius: 16px;
            border: 1px solid var(--border);
            padding: 16px 18px;
            margin-bottom: 10px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 14px;
        }
        .alerts-time-card-label {
            color: var(--text2);
        }
        .alerts-time-card-value {
            text-align: right;
            font-weight: 600;
        }
        .alerts-time-card-value span {
            display: block;
            font-size: 12px;
            color: var(--text3);
            font-weight: 400;
        }
        .alerts-time-card.critique { background: rgba(0,0,0,0.06); }
        .alerts-time-card.moderee { background: rgba(255,107,53,0.1); }
        .alerts-time-card.faible { background: rgba(255,146,92,0.12); }

        .alerts-performance {
            margin-top: 16px;
            background: rgba(255,107,53,0.1);
            border-radius: 16px;
            border: 1px solid rgba(255,107,53,0.35);
            padding: 18px 18px 16px;
            font-size: 14px;
        }
        .alerts-performance-title {
            font-weight: 600;
            margin-bottom: 6px;
            color: var(--orange-dark);
        }
        .alerts-performance-main {
            font-size: 28px;
            font-weight: 800;
            color: var(--text);
            margin-bottom: 4px;
        }
        .alerts-performance-sub {
            font-size: 12px;
            color: var(--text2);
        }

        .alerts-type-table-wrap { overflow-x: auto; margin-top: 8px; max-height: 420px; overflow-y: auto; }
        .alerts-type-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .alerts-type-table th { text-align: left; padding: 10px 12px; border-bottom: 2px solid var(--border); color: var(--text2); font-weight: 600; position: sticky; top: 0; background: var(--bg3); }
        .alerts-type-table td { padding: 10px 12px; border-bottom: 1px solid var(--border); vertical-align: top; }
        .alerts-type-table td:last-child { text-align: right; font-weight: 700; white-space: nowrap; }
        .alerts-type-table tr:hover td { background: rgba(255,107,53,0.04); }
        .alerts-type-dot { display: inline-block; width: 10px; height: 10px; border-radius: 3px; margin-right: 8px; vertical-align: middle; }

        .alerts-kpi-strip {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 20px;
        }
        .alerts-kpi-item {
            flex: 1 1 120px;
            min-width: 110px;
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 14px;
            padding: 12px 14px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.04);
        }
        .alerts-kpi-value { font-size: 22px; font-weight: 800; color: var(--text); line-height: 1.15; }
        .alerts-kpi-label { font-size: 11px; color: var(--text2); margin-top: 4px; line-height: 1.35; }
        .alerts-detail-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 20px;
            margin-top: 22px;
        }
        @media (max-width: 960px) {
            .alerts-detail-grid { grid-template-columns: 1fr; }
        }
        .alerts-chart-canvas-wrap { position: relative; height: 260px; margin-top: 8px; }

        /* Blocs risque / sources : anneau + détail */
        .alerts-viz-sub {
            font-size: 12px;
            color: var(--text2);
            margin: 0 0 14px;
            line-height: 1.55;
        }
        .alerts-viz-sub code {
            font-size: 11px;
            padding: 1px 6px;
            border-radius: 6px;
            background: rgba(0, 0, 0, 0.04);
            border: 1px solid rgba(0, 0, 0, 0.06);
        }
        .alerts-viz-shell {
            margin-top: 4px;
            padding: 20px 20px 22px;
            border-radius: 20px;
            border: 1px solid rgba(255, 107, 53, 0.14);
            background:
                linear-gradient(165deg, rgba(255, 255, 255, 0.95) 0%, rgba(255, 107, 53, 0.04) 45%, rgba(0, 0, 0, 0.02) 100%);
            box-shadow:
                0 0 0 1px rgba(255, 255, 255, 0.7) inset,
                0 14px 40px rgba(0, 0, 0, 0.06);
        }
        .alerts-viz-shell--source {
            border-color: rgba(0, 0, 0, 0.08);
            background:
                linear-gradient(165deg, rgba(255, 255, 255, 0.98) 0%, rgba(255, 107, 53, 0.06) 50%, rgba(26, 26, 26, 0.03) 100%);
        }
        .alerts-viz-split {
            display: grid;
            grid-template-columns: minmax(200px, 1fr) minmax(0, 1.2fr);
            gap: 24px;
            align-items: center;
        }
        @media (max-width: 720px) {
            .alerts-viz-split { grid-template-columns: 1fr; gap: 20px; }
        }
        .alerts-doughnut-wrap {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 232px;
            padding: 8px;
        }
        .alerts-doughnut-glow {
            position: absolute;
            width: 200px;
            height: 200px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(255, 107, 53, 0.22) 0%, transparent 70%);
            pointer-events: none;
            filter: blur(2px);
        }
        .alerts-viz-shell--source .alerts-doughnut-glow {
            background: radial-gradient(circle, rgba(255, 107, 53, 0.18) 0%, transparent 68%);
        }
        .alerts-doughnut-inner {
            position: relative;
            z-index: 1;
            width: 220px;
            height: 220px;
            max-width: 100%;
            margin: 0 auto;
        }
        .alerts-doughnut-inner canvas {
            filter: drop-shadow(0 10px 24px rgba(0, 0, 0, 0.08));
        }
        .alerts-breakdown {
            display: flex;
            flex-direction: column;
            gap: 11px;
            min-width: 0;
        }
        .alerts-breakdown-row {
            padding: 14px 16px 13px;
            border-radius: 14px;
            background: rgba(255, 255, 255, 0.75);
            border: 1px solid rgba(0, 0, 0, 0.06);
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.04);
            transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
        }
        .alerts-breakdown-row:hover {
            transform: translateY(-1px);
            box-shadow: 0 8px 22px rgba(0, 0, 0, 0.07);
            border-color: rgba(255, 107, 53, 0.2);
        }
        .alerts-breakdown-row--high { border-left: 4px solid #9a3412; }
        .alerts-breakdown-row--mid { border-left: 4px solid #ea580c; }
        .alerts-breakdown-row--low { border-left: 4px solid #fdba74; }
        .alerts-breakdown-row--neutral { border-left: 4px solid #737373; }
        .alerts-breakdown-row--src { border-left: 4px solid #ff6b35; }
        .alerts-breakdown-row-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            font-size: 13px;
        }
        .alerts-breakdown-left {
            display: flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
        }
        .alerts-breakdown-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            flex-shrink: 0;
            box-shadow: 0 0 0 3px rgba(0, 0, 0, 0.04);
        }
        .alerts-breakdown-row--high .alerts-breakdown-dot { background: linear-gradient(145deg, #9a3412, #ea580c); }
        .alerts-breakdown-row--mid .alerts-breakdown-dot { background: linear-gradient(145deg, #ea580c, #fb923c); }
        .alerts-breakdown-row--low .alerts-breakdown-dot { background: linear-gradient(145deg, #fdba74, #fed7aa); }
        .alerts-breakdown-row--neutral .alerts-breakdown-dot { background: #737373; }
        .alerts-breakdown-row--src .alerts-breakdown-dot { background: linear-gradient(145deg, #1a1a1a, #ff6b35); }
        .alerts-breakdown-label {
            font-weight: 700;
            font-size: 13px;
            color: var(--text);
            letter-spacing: -0.02em;
            min-width: 0;
            word-break: break-word;
        }
        .alerts-breakdown-right {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }
        .alerts-breakdown-count {
            font-size: 12px;
            font-weight: 700;
            color: var(--text2);
            font-variant-numeric: tabular-nums;
            padding: 4px 9px;
            border-radius: 999px;
            background: rgba(0, 0, 0, 0.05);
        }
        .alerts-breakdown-pct {
            font-size: 12px;
            font-weight: 800;
            color: var(--orange-dark);
            font-variant-numeric: tabular-nums;
            min-width: 3.2rem;
            text-align: right;
        }
        .alerts-breakdown-bar {
            height: 10px;
            border-radius: 999px;
            background: rgba(0, 0, 0, 0.06);
            overflow: hidden;
            margin-top: 11px;
            box-shadow: 0 1px 0 rgba(255, 255, 255, 0.8) inset;
        }
        .alerts-breakdown-bar-fill {
            height: 100%;
            border-radius: inherit;
            max-width: 100%;
            transition: width 0.75s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 0 12px rgba(255, 107, 53, 0.25);
        }
        .alerts-breakdown-row--high .alerts-breakdown-bar-fill {
            background: linear-gradient(90deg, #7f1d1d, #ea580c);
        }
        .alerts-breakdown-row--mid .alerts-breakdown-bar-fill {
            background: linear-gradient(90deg, #c2410c, #fb923c);
        }
        .alerts-breakdown-row--low .alerts-breakdown-bar-fill {
            background: linear-gradient(90deg, #fdba74, #fed7aa);
        }
        .alerts-breakdown-row--neutral .alerts-breakdown-bar-fill {
            background: linear-gradient(90deg, #404040, #a3a3a3);
        }
        .alerts-breakdown-row--src .alerts-breakdown-bar-fill {
            background: linear-gradient(90deg, #1a1a1a, #ff6b35);
        }
        .alerts-detail-table-wrap { max-height: 220px; overflow: auto; margin-top: 8px; }

        /* ── Satisfaction citoyen (onglet Analyse) ── */
        .cit-sat-wrap { margin-top: 2px; }
        .cit-sat-hero {
            display: flex;
            gap: 20px;
            align-items: flex-start;
            padding: 24px 26px 26px;
            border-radius: 22px;
            background:
                linear-gradient(145deg, rgba(255,107,53,0.11) 0%, rgba(255,107,53,0.03) 42%, var(--bg3) 100%);
            border: 1px solid rgba(255,107,53,0.22);
            box-shadow: 0 14px 48px rgba(255,107,53,0.08);
            margin-bottom: 22px;
        }
        .cit-sat-hero-icon {
            flex-shrink: 0;
            width: 56px;
            height: 56px;
            border-radius: 18px;
            background: linear-gradient(145deg, #FF6B35 0%, #C2410C 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            box-shadow: 0 10px 28px rgba(255,107,53,0.4);
        }
        .cit-sat-hero-title {
            font-size: 19px;
            font-weight: 800;
            letter-spacing: -0.02em;
            margin: 0 0 8px;
            color: var(--text);
            line-height: 1.25;
        }
        .cit-sat-hero-desc {
            font-size: 13px;
            color: var(--text2);
            margin: 0;
            line-height: 1.55;
            max-width: 720px;
        }
        .cit-sat-kpi-grid {
            display: grid;
            grid-template-columns: minmax(200px, 380px);
            gap: 16px;
            margin-bottom: 20px;
            align-items: stretch;
        }
        .cit-sat-kpi {
            position: relative;
            padding: 20px 18px 18px;
            border-radius: 18px;
            background: var(--bg3);
            border: 1px solid var(--border);
            overflow: hidden;
            transition: transform 0.22s ease, box-shadow 0.22s ease;
        }
        .cit-sat-kpi:hover {
            transform: translateY(-3px);
            box-shadow: 0 16px 40px rgba(0,0,0,0.08);
        }
        .cit-sat-kpi::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            border-radius: 18px 18px 0 0;
            background: linear-gradient(90deg, #FF6B35, #FF925C);
        }
        .cit-sat-kpi-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
            margin-bottom: 12px;
        }
        .cit-sat-kpi-ico {
            width: 32px;
            height: 32px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            background: rgba(255,107,53,0.12);
            color: var(--orange);
        }
        .cit-sat-kpi-value {
            font-size: 30px;
            font-weight: 800;
            letter-spacing: -0.03em;
            line-height: 1;
            color: var(--text);
        }
        .cit-sat-kpi-label {
            font-size: 12px;
            color: var(--text2);
            margin-top: 10px;
            line-height: 1.45;
        }
        .cit-sat-kpi-label code {
            font-size: 10px;
            padding: 1px 5px;
            border-radius: 4px;
            background: rgba(0,0,0,0.05);
        }

        .cit-sat-info {
            display: flex;
            gap: 14px;
            align-items: flex-start;
            padding: 16px 20px;
            border-radius: 16px;
            background: linear-gradient(135deg, rgba(99,102,241,0.07) 0%, rgba(99,102,241,0.02) 100%);
            border: 1px solid rgba(99,102,241,0.18);
            margin-bottom: 22px;
        }
        .cit-sat-info > i {
            flex-shrink: 0;
            font-size: 18px;
            color: #6366f1;
            margin-top: 2px;
            opacity: 0.9;
        }
        .cit-sat-info p {
            margin: 0;
            font-size: 13px;
            color: var(--text2);
            line-height: 1.6;
        }
        .cit-sat-charts {
            display: grid;
            grid-template-columns: 1.4fr 1fr;
            gap: 20px;
            align-items: stretch;
        }
        @media (max-width: 1024px) {
            .cit-sat-charts { grid-template-columns: 1fr; }
        }
        .cit-sat-chart-card {
            background: var(--bg3);
            border-radius: 22px;
            border: 1px solid var(--border);
            padding: 22px 24px 20px;
            box-shadow: 0 12px 36px rgba(0,0,0,0.06);
            display: flex;
            flex-direction: column;
        }
        .cit-sat-chart-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 4px;
        }
        .cit-sat-chart-title {
            font-size: 15px;
            font-weight: 700;
            color: var(--text);
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 0;
        }
        .cit-sat-chart-title span.cit-sat-chart-ic {
            width: 34px;
            height: 34px;
            border-radius: 11px;
            background: rgba(255,107,53,0.12);
            color: var(--orange);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 15px;
        }
        .cit-sat-chart-badge {
            flex-shrink: 0;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.04em;
            padding: 6px 12px;
            border-radius: 999px;
            background: rgba(255,107,53,0.14);
            color: #C2410C;
        }
        .cit-sat-chart-sub {
            font-size: 12px;
            color: var(--text3);
            margin: 8px 0 14px;
            line-height: 1.45;
        }
        .cit-sat-chart-canvas {
            position: relative;
            flex: 1;
            min-height: 268px;
        }
        .cit-sat-empty {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 220px;
            text-align: center;
            padding: 24px 16px;
            color: var(--text2);
            font-size: 14px;
        }
        .cit-sat-empty i {
            font-size: 40px;
            color: var(--text3);
            opacity: 0.45;
            margin-bottom: 12px;
        }
        .cit-sat-feedback-block {
            margin-top: 20px;
        }
        .cit-sat-feedback-block .cit-sat-chart-canvas {
            min-height: 220px;
        }

        .analyse-status-list { display: flex; flex-direction: column; gap: 8px; margin-top: 6px; }
        .analyse-status-item { display: flex; align-items: center; justify-content: space-between; font-size: 13px; padding: 8px 10px; border-radius: 8px; background: var(--surface); }
        .analyse-status-label { color: var(--text2); display: flex; align-items: center; gap: 6px; }
        .analyse-status-value { font-weight: 700; }

        /* Styles pour le nouveau design néon */
        .dur-row {
            display: flex;
            justify-content: space-between;
            font-size: 13px;
            color: var(--text2);
            margin-bottom: 7px;
        }
        .dur-val {
            font-weight: 600;
        }
        .prog-bg {
            height: 7px;
            background: rgba(0,0,0,0.08);
            border-radius: 99px;
            margin-bottom: 16px;
            overflow: hidden;
        }
        .prog-fill {
            height: 100%;
            border-radius: 99px;
            width: 0;
            transition: width 1s cubic-bezier(0.4,0,0.2,1) 0.6s;
        }
        .pb { background: #1A1A1A; }
        .po { background: #FF6B35; }
        .pg { background: #C2410C; }
        .pr { background: #525252; }
        .status-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 13px 18px;
            border-radius: 10px;
            font-size: 14px;
            font-weight: 500;
            color: var(--text2);
            opacity: 0;
            transform: translateY(6px);
        }
        .status-item:nth-child(1) { animation: fadeUp 0.4s ease 0.8s forwards; }
        .status-item:nth-child(2) { animation: fadeUp 0.4s ease 0.92s forwards; }
        .status-item:nth-child(3) { animation: fadeUp 0.4s ease 1.04s forwards; }
        .status-item:nth-child(4) { animation: fadeUp 0.4s ease 1.16s forwards; }
        .snum {
            font-size: 22px;
            font-weight: 700;
        }

        @media (max-width: 1300px) {
            .analyse-main-grid { grid-template-columns: 1fr; }
        }

        /* ACCOUNT INFO */
        .account-info-section { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; padding: 30px; margin-top: 24px; display: none; }
        .account-info-section.show { display: block; animation: fadeIn 0.5s ease-out; }
        .account-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 1px solid var(--border); }
        .account-header h2 { font-size: 24px; font-weight: 700; color: var(--text); display: flex; align-items: center; gap: 12px; }
        .account-header-icon { font-size: 28px; }
        .account-info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 25px; margin-bottom: 30px; }
        .info-card { background: var(--surface); border-radius: 10px; padding: 20px; border-left: 4px solid var(--orange); transition: transform 0.2s, box-shadow 0.2s; }
        .info-card:hover { transform: translateY(-2px); box-shadow: 0 8px 16px rgba(0,0,0,0.2); }
        .info-label { font-size: 13px; color: var(--text3); margin-bottom: 8px; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; }
        .info-value { font-size: 18px; font-weight: 600; color: var(--text); word-break: break-word; }
        .info-value.email { color: var(--orange); }
        .info-value.date { color: var(--text2); font-size: 14px; font-weight: 500; }
        .account-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-top: 30px; }
        .account-stat-card { background: linear-gradient(135deg, var(--orange), #C84B1F); border-radius: 12px; padding: 20px; color: white; text-align: center; }
        .account-stat-card.orange { background: linear-gradient(135deg, var(--orange), #C84B1F); }
        .account-stat-card.green { background: linear-gradient(135deg, var(--orange-dark), #1A1A1A); }
        .account-stat-value { font-size: 32px; font-weight: 700; margin-bottom: 8px; }
        .account-stat-label { font-size: 14px; opacity: 0.9; }
        .account-actions { margin-top: 30px; padding-top: 30px; border-top: 1px solid var(--border); display: flex; gap: 15px; }
        .btn-account { padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.3s; border: none; }
        .btn-account.primary { background: var(--orange); color: #fff; }
        .btn-account.primary:hover { background: var(--orange-light); transform: translateY(-2px); box-shadow: 0 8px 16px rgba(255,107,53,0.4); }
        .btn-account.secondary { background: var(--surface); color: var(--text2); border: 1px solid var(--border); }
        .btn-account.secondary:hover { background: var(--surface2); border-color: var(--border-accent); }
        .btn-account.danger { background: #1A1A1A; color: #fff; }
        .btn-account.danger:hover { background: #000; transform: translateY(-2px); box-shadow: 0 8px 16px rgba(0,0,0,0.2); }

        /* MISC */
        .fade-in { animation: fadeIn 0.6s ease forwards; opacity: 0; }
        @keyframes fadeIn { to { opacity: 1; } }
        .mb-16 { margin-bottom: 16px; }
        .alert { padding: 12px 16px; border-radius: 9px; margin-bottom: 18px; display: flex; align-items: center; gap: 9px; font-size: 13px; }
        .alert-success { background: rgba(255,107,53,0.1); border: 1px solid rgba(255,107,53,0.3); color: var(--orange-dark); }
        .alert-error { background: rgba(0,0,0,0.05); border: 1px solid rgba(0,0,0,0.15); color: var(--text); }

        ::-webkit-scrollbar { width: 5px; height: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 3px; }

        /* PROBLEMES DE VOIRIE SECTION */
        .problemes-section { margin-top: 24px; }
        .problemes-header { display: flex; align-items: center; gap: 12px; margin-bottom: 8px; }
        .problemes-header-icon { width: 40px; height: 40px; border-radius: 10px; background: rgba(255,107,53,0.12); color: var(--orange); display: flex; align-items: center; justify-content: center; font-size: 20px; }
        .problemes-header h3 { font-size: 22px; font-weight: 800; color: var(--text); letter-spacing: -0.5px; }
        .problemes-subtitle { font-size: 13px; color: var(--text2); margin-bottom: 24px; margin-left: 52px; }
        .problemes-stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 28px; }
        .probleme-stat-card { background: var(--bg3); border: 2px solid; border-radius: 14px; padding: 20px; position: relative; overflow: hidden; transition: all 0.3s; }
        .probleme-stat-card.orange { border-color: var(--orange); }
        .probleme-stat-card.blue { border-color: #1A1A1A; }
        .probleme-stat-card.green { border-color: var(--green); }
        .probleme-stat-card.red { border-color: var(--red); }
        .probleme-stat-card:hover { transform: translateY(-3px); box-shadow: 0 16px 32px rgba(0,0,0,0.3); }
        .probleme-stat-label { font-size: 12px; font-weight: 600; color: var(--text2); margin-bottom: 12px; text-transform: uppercase; letter-spacing: 1px; }
        .probleme-stat-value { font-family: 'Bebas Neue', sans-serif; font-size: 48px; letter-spacing: 2px; line-height: 1; margin-bottom: 8px; }
        .probleme-stat-card.orange .probleme-stat-value { color: var(--orange); }
        .probleme-stat-card.blue .probleme-stat-value { color: #1A1A1A; }
        .probleme-stat-card.green .probleme-stat-value { color: var(--green); }
        .probleme-stat-card.red .probleme-stat-value { color: var(--red); }
        .probleme-stat-icon { position: absolute; top: 20px; right: 20px; font-size: 32px; opacity: 0.2; }
        .probleme-stat-card.orange .probleme-stat-icon { color: var(--orange); }
        .probleme-stat-card.blue .probleme-stat-icon { color: #1A1A1A; }
        .probleme-stat-card.green .probleme-stat-icon { color: var(--green); }
        .probleme-stat-card.red .probleme-stat-icon { color: var(--red); }
        .problemes-list-section { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; }
        .problemes-list-header { padding: 20px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; background: rgba(0,0,0,0.03); flex-wrap: wrap; gap: 15px; }
        .problemes-list-title { font-size: 16px; font-weight: 700; color: var(--text); }
        .btn-ai-detection { display: inline-flex; align-items: center; gap: 8px; padding: 10px 18px; border-radius: 8px; background: #1A1A1A; color: #fff; font-size: 13px; font-weight: 700; border: none; cursor: pointer; transition: all 0.2s; box-shadow: 0 4px 14px rgba(0,0,0,0.15); }
        .btn-ai-detection:hover { background: #000; transform: translateY(-1px); }
        .problemes-table { width: 100%; border-collapse: collapse; }
        .problemes-table thead { background: rgba(0,0,0,0.04); }
        .problemes-table th { padding: 15px 20px; text-align: left; font-size: 12px; font-weight: 700; color: var(--text2); text-transform: uppercase; letter-spacing: 1px; border-bottom: 2px solid var(--border); }
        .problemes-table td { padding: 18px 20px; border-bottom: 1px solid var(--border); font-size: 14px; }
        .problemes-table tbody tr { transition: background 0.2s; }
        .problemes-table tbody tr:hover { background: rgba(255,107,53,0.04); }
        .problemes-table tbody tr.priority-1 { background: rgba(0,0,0,0.04); }
        .problemes-table tbody tr.priority-2 { background: rgba(255,107,53,0.08); }
        .problemes-table tbody tr.priority-3 { background: rgba(255,146,92,0.1); }
        .problemes-table tbody tr.priority-4,
        .problemes-table tbody tr.priority-5,
        .problemes-table tbody tr.priority-6 { background: rgba(0,0,0,0.02); }
        .priority-circle { width: 32px; height: 32px; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; background: rgba(255,107,53,0.15); color: var(--text); border: 2px solid rgba(255,107,53,0.55); box-shadow: 0 0 0 3px rgba(255,107,53,0.1); }
        .type-chip { display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 999px; font-size: 12px; font-weight: 600; background: var(--surface); border: 1px solid var(--border); color: var(--text); }
        .type-chip i { font-size: 13px; color: var(--orange); }
        .location-cell { display: flex; align-items: center; gap: 8px; color: var(--text2); font-size: 13px; }
        .location-cell i { color: var(--text3); }
        .btn-gps-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 24px;
            height: 24px;
            border-radius: 999px;
            border: 1px solid var(--border);
            background: var(--surface);
            color: var(--orange);
            text-decoration: none;
            transition: all 0.18s ease;
            flex-shrink: 0;
        }
        .btn-gps-link:hover {
            transform: translateY(-1px);
            border-color: var(--orange);
            box-shadow: 0 0 12px rgba(255, 107, 53, 0.2);
        }
        .btn-gps-link.disabled {
            opacity: 0.4;
            pointer-events: none;
        }
        .risk-score { display: flex; align-items: center; gap: 10px; }
        .risk-score-number { font-weight: 700; font-size: 14px; color: var(--text); min-width: 28px; }
        .risk-bar { flex: 1; height: 6px; border-radius: 999px; background: rgba(0,0,0,0.06); overflow: hidden; }
        .risk-bar-fill { height: 100%; border-radius: inherit; background: linear-gradient(90deg, #1A1A1A, #FF6B35); }
        .gravity-pill { display: inline-flex; align-items: center; padding: 6px 12px; border-radius: 999px; font-size: 12px; font-weight: 700; }
        .gravity-pill.critique { background: rgba(0,0,0,0.08); color: var(--text); border: 1px solid rgba(0,0,0,0.2); }
        .gravity-pill.haute { background: rgba(255,107,53,0.12); color: var(--orange-dark); border: 1px solid rgba(255,107,53,0.4); }
        .gravity-pill.moyenne { background: rgba(255,146,92,0.14); color: #9a3412; border: 1px solid rgba(255,146,92,0.45); }
        .confidence-value { font-size: 14px; font-weight: 600; color: var(--orange-dark); }
        .cout-estime-value { font-size: 14px; font-weight: 700; color: var(--orange-dark); max-width: 140px; display: inline-block; word-break: break-word; }
        .cout-estime-empty { font-size: 13px; color: var(--text3); font-weight: 500; }
        .date-value { font-size: 13px; color: var(--text); }
        .status-dropdown { position: relative; display: inline-block; min-width: 150px; }
        .status-select { padding: 8px 34px 8px 12px; border-radius: 999px; background: #fff; border: 1px solid var(--border); color: var(--text); font-size: 12px; font-weight: 600; cursor: pointer; appearance: none; background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23374151' d='M6 9L1 4h10z'/%3E%3C/svg%3E"); background-repeat: no-repeat; background-position: right 9px center; padding-right: 32px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
        .status-readonly-pill { display: inline-flex; align-items: center; padding: 7px 14px; border-radius: 999px; font-size: 12px; font-weight: 600; border: 1px solid var(--border); background: var(--surface); color: var(--text2); white-space: nowrap; }
        .status-readonly-pill.status-readonly-en_attente { background: rgba(0,0,0,0.06); color: var(--text); border-color: rgba(0,0,0,0.12); }
        .status-readonly-pill.status-readonly-en_cours { background: rgba(255,107,53,0.12); color: var(--orange-dark); border-color: rgba(255,107,53,0.35); }
        .status-readonly-pill.status-readonly-termine { background: rgba(34,197,94,0.12); color: #15803d; border-color: rgba(34,197,94,0.35); }
        .team-value { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border-radius: 999px; background: var(--surface); border: 1px solid var(--border); font-size: 12px; color: var(--text); }
        .team-value::before { content: "\f0c0"; font-family: "Font Awesome 6 Free"; font-weight: 900; font-size: 11px; color: #F97316; }
        .action-cell { display: inline-flex; align-items: center; gap: 10px; padding: 4px 6px; border-radius: 999px; background: linear-gradient(135deg, rgba(255,107,53,0.1), var(--surface)); border: 1px solid var(--border); box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
        .btn-assign { padding: 8px 14px; border-radius: 999px; background: transparent; border: none; color: var(--orange); font-size: 12px; font-weight: 700; cursor: pointer; display: inline-flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.16s; }
        .btn-assign i { font-size: 13px; }
        .btn-assign:hover { background: rgba(255,107,53,0.12); color: var(--orange-dark); transform: translateY(-1px); }
        .priority-dropdown { position: relative; display: inline-block; }
        .priority-select { padding: 6px 30px 6px 12px; border-radius: 999px; background: #fff; border: 1px solid var(--border); color: var(--text); font-size: 11px; font-weight: 700; cursor: pointer; appearance: none; background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23374151' d='M6 9L1 4h10z'/%3E%3C/svg%3E"); background-repeat: no-repeat; background-position: right 9px center; padding-right: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }

        /* ASSIGN MODAL */
        .assign-modal-overlay { position: fixed; inset: 0; z-index: 1000; background: rgba(0,0,0,0.75); backdrop-filter: blur(4px); display: none; align-items: center; justify-content: center; }
        .assign-modal-overlay.show { display: flex; }
        .assign-modal { background: #F9FAFB; color: #111827; border-radius: 18px; width: 90%; max-width: 720px; box-shadow: 0 25px 70px rgba(0,0,0,0.5); overflow: hidden; }
        .assign-modal-header { padding: 22px 28px 8px; display: flex; justify-content: space-between; align-items: flex-start; }
        .assign-modal-title { font-size: 20px; font-weight: 700; color: #111827; }
        .assign-modal-location { font-size: 13px; color: #6B7280; margin-top: 4px; }
        .assign-modal-close { border: none; background: transparent; cursor: pointer; font-size: 18px; color: #9CA3AF; }
        .assign-modal-close:hover { color: #4B5563; }
        .assign-modal-body { padding: 0 28px 22px; }
        .assign-modal-label { display: block; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .08em; color: #6B7280; margin-bottom: 6px; }
        .assign-modal-select-wrap { margin-bottom: 18px; }
        .assign-modal-extra { margin-top: 6px; font-size: 12px; color: #6B7280; }
        .assign-modal-description-box { margin-top: 8px; padding: 14px 16px; background: rgba(255,107,53,0.08); border-radius: 10px; border: 1px solid rgba(255,107,53,0.22); font-size: 13px; color: #1F2937; }
        .assign-modal-description-box .assign-cost-input {
            width: 100%;
            margin-top: 8px;
            padding: 10px 14px;
            border-radius: 10px;
            border: 1px solid rgba(0,0,0,0.12);
            background: #fff;
            font-size: 14px;
            font-weight: 600;
            color: #111827;
            font-family: inherit;
            box-sizing: border-box;
        }
        .assign-modal-description-box .assign-cost-input:focus {
            outline: none;
            border-color: var(--orange);
            box-shadow: 0 0 0 3px rgba(255,107,53,0.15);
        }
        .assign-modal-footer { padding: 16px 28px 22px; display: flex; justify-content: flex-end; gap: 10px; background: #F3F4F6; }
        .assign-btn { padding: 9px 18px; border-radius: 999px; border: none; cursor: pointer; font-size: 13px; font-weight: 600; }
        .assign-btn.cancel { background: #E5E7EB; color: #374151; }
        .assign-btn.cancel:hover { background: #D1D5DB; }
        .assign-btn.primary { background: #111827; color: #F9FAFB; }
        .assign-btn.primary:hover { background: #030712; }

        /* SECTION NAVIGATION */
        .content-section { display: none; }
        .content-section.active { display: block; animation: fadeIn 0.4s ease forwards; }

        /* Profile interface */
        .ap-wrap { max-width: 900px; margin: 0 auto; }
        .ap-header { display: flex; align-items: center; gap: 12px; margin-bottom: 24px; }
        .ap-badge { background: linear-gradient(135deg, var(--orange) 0%, var(--orange-light) 100%); color: #fff; font-size: 10px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase; padding: 4px 10px; border-radius: 20px; }
        .ap-title { font-family: 'Bebas Neue', sans-serif; font-size: 24px; letter-spacing: 1px; }
        .ap-sub { color: var(--text2); font-size: 13px; margin-left: auto; }
        .ap-card { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; margin-bottom: 18px; }
        .ap-head { padding: 18px 20px 14px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; }
        .ap-head h3 { font-size: 15px; font-weight: 700; }
        .ap-edit-btn { background: none; border: 1px solid var(--border); color: var(--orange); font-size: 12px; font-weight: 600; padding: 6px 12px; border-radius: 20px; cursor: pointer; }
        .ap-edit-btn.active { background: rgba(255,107,53,0.12); border-color: var(--orange); }
        .ap-id-top { padding: 18px 20px; display: flex; align-items: center; gap: 16px; }
        .ap-avatar {
            position: relative;
            width: 74px; height: 74px; border-radius: 50%;
            background: linear-gradient(135deg, #0A0A0A, #1A1A1A);
            border: 2px solid var(--orange);
            display: flex; align-items: center; justify-content: center;
            font-size: 24px; font-weight: 700; color: #fff;
            overflow: hidden;
            flex-shrink: 0;
        }
        .ap-avatar-img {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        .ap-avatar.has-image .ap-avatar-img { display: block; }
        .ap-avatar.has-image .ap-avatar-letter { display: none; }
        .ap-avatar-letter { position: relative; z-index: 0; line-height: 1; }
        .ap-role-tag { display: inline-flex; align-items: center; gap: 6px; background: rgba(255,107,53,0.1); border: 1px solid rgba(255,107,53,0.28); color: var(--orange-dark); font-size: 10px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; padding: 4px 10px; border-radius: 20px; margin-bottom: 6px; }
        .ap-role-tag::before { content: ''; width: 6px; height: 6px; border-radius: 50%; background: var(--orange); }
        .ap-name { font-size: 20px; font-weight: 700; text-transform: lowercase; }
        .ap-last { font-size: 12px; color: var(--text2); margin-top: 3px; }
        .ap-stats { display: grid; grid-template-columns: repeat(3, 1fr); border-top: 1px solid var(--border); }
        .ap-stat { padding: 14px 18px; border-right: 1px solid var(--border); }
        .ap-stat:last-child { border-right: none; }
        .ap-stat .v { display: block; font-size: 22px; font-weight: 700; color: var(--text); }
        .ap-stat .l { font-size: 11px; color: var(--text2); text-transform: uppercase; letter-spacing: 1px; }
        .ap-fields { padding: 18px 20px 20px; display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .ap-field { display: flex; flex-direction: column; gap: 6px; }
        .ap-field.ap-span2 { grid-column: span 2; }
        .ap-field label { font-size: 11px; color: var(--text2); text-transform: uppercase; letter-spacing: 1.2px; }
        .ap-val, .ap-input { font-size: 14px; color: var(--text); padding: 10px 12px; background: var(--surface2); border-radius: 8px; border: 1px solid transparent; min-height: 40px; display: flex; align-items: center; }
        .ap-input { width: 100%; outline: none; display: none; background: rgba(255,255,255,0.04); }
        .ap-input:focus { border-color: var(--orange); box-shadow: 0 0 0 2px rgba(255,107,53,0.2); }
        .ap-fields.editing .ap-val { display: none; }
        .ap-fields.editing .ap-input { display: flex; }
        .ap-actions { padding: 0 20px 18px; display: none; justify-content: flex-end; gap: 10px; }
        .ap-fields.editing + .ap-actions { display: flex; }
        .ap-btn { padding: 9px 16px; border-radius: 8px; border: 1px solid var(--border); background: var(--surface2); color: var(--text2); cursor: pointer; font-size: 13px; font-weight: 600; }
        .ap-btn.ap-save { background: linear-gradient(135deg, var(--orange), var(--orange-dark)); color: #fff; border-color: transparent; }

        /* RESPONSIVE */
        @media (max-width: 1300px) { .problemes-stats-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 900px) { .sidebar { display: none; } .content { padding: 16px; } .topbar { padding: 0 16px; } }
        @media (max-width: 640px) { .stats-grid { grid-template-columns: 1fr; } .account-info-grid { grid-template-columns: 1fr; } .account-stats { grid-template-columns: 1fr; } .problemes-stats-grid { grid-template-columns: 1fr; } .problemes-table { font-size: 12px; } .problemes-table th, .problemes-table td { padding: 12px 10px; } }

        /* LEAFLET MAP — blanc (fond carte clair), noir (texte / bords), orange (accents) */
        #map {
            height: min(52vh, 560px);
            min-height: 420px;
            width: 100%;
            /* Fond proche des tuiles OSM en chargement (beige / vert très pâle) */
            background: #E8EDE4;
            border-radius: 12px;
        }
        #map.leaflet-container {
            background: #E8EDE4;
            font-family: 'Outfit', sans-serif;
        }
        .map-frame .leaflet-control-zoom {
            border: 1px solid rgba(0,0,0,0.12) !important;
            border-radius: 10px !important;
            overflow: hidden;
            box-shadow: 0 4px 14px rgba(0,0,0,0.08) !important;
        }
        .map-frame .leaflet-control-zoom a {
            width: 34px !important;
            height: 34px !important;
            line-height: 34px !important;
            background: #FFFFFF !important;
            color: var(--black) !important;
            border: none !important;
            border-bottom: 1px solid rgba(0,0,0,0.08) !important;
            font-weight: 700 !important;
        }
        .map-frame .leaflet-control-zoom a:last-child { border-bottom: none !important; }
        .map-frame .leaflet-control-zoom a:hover {
            background: var(--orange) !important;
            color: #FFFFFF !important;
        }
        .map-frame .leaflet-control-zoom-in { border-radius: 10px 10px 0 0 !important; }
        .map-frame .leaflet-control-zoom-out { border-radius: 0 0 10px 10px !important; }
        .map-frame .leaflet-control-scale-line {
            border: 1px solid rgba(255,107,53,0.35) !important;
            background: #FFFFFF !important;
            color: var(--black) !important;
            border-radius: 8px !important;
            padding: 2px 8px !important;
            font-size: 11px !important;
            font-weight: 600 !important;
        }
        .map-frame .leaflet-popup-content-wrapper {
            border-radius: 10px !important;
            border: 1px solid rgba(0,0,0,0.1) !important;
            background: #FFFFFF !important;
            box-shadow: 0 12px 32px rgba(0,0,0,0.12), 0 0 0 2px rgba(255,107,53,0.2) !important;
        }
        .map-frame .leaflet-popup-tip {
            background: #FFFFFF !important;
            box-shadow: none !important;
        }
        .map-frame .leaflet-popup-content {
            font-family: 'Outfit', sans-serif !important;
            font-size: 13px !important;
            color: var(--black) !important;
            margin: 12px 14px !important;
        }

        /* MarkerCluster : remplace le vert par défaut par orange / noir / blanc */
        .map-frame .marker-cluster-small { background-color: rgba(255, 107, 53, 0.45) !important; }
        .map-frame .marker-cluster-small div {
            background-color: #FF6B35 !important;
            color: #fff !important;
            font-weight: 700 !important;
        }
        .map-frame .marker-cluster-medium { background-color: rgba(194, 65, 12, 0.5) !important; }
        .map-frame .marker-cluster-medium div {
            background-color: #C2410C !important;
            color: #fff !important;
            font-weight: 700 !important;
        }
        .map-frame .marker-cluster-large { background-color: rgba(255, 255, 255, 0.15) !important; }
        .map-frame .marker-cluster-large div {
            background-color: var(--black-soft) !important;
            color: #FFFFFF !important;
            font-weight: 800 !important;
            border: 2px solid var(--orange) !important;
            box-sizing: border-box !important;
        }
        
        /* Custom Leaflet icons */
        .custom-icon {
            background: transparent;
            border: none;
            text-align: center;
            display: flex;
            align-items: center;
            justify-content: center;
        }
    </style>
    <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
    @include('partials.theme-assets')
</head>
<body>
@include('partials.admin.resolve-header-user', ['headerSourceUser' => $user])
@php
    $headerDisplayName = $headerDisplayName ?? 'Administrateur';
    $headerInitials = $headerInitials ?? 'A';
    $headerAvatarUrl = $headerAvatarUrl ?? null;
    $headerRoleLabel = $headerRoleLabel ?? 'Administrateur';
    $apFirstName = $apFirstName ?? '';
    $apLastName = $apLastName ?? '';
@endphp
<div class="bg-canvas"></div>
<div class="grid-overlay"></div>

<div class="app">
    @include('partials.dashboard_sidebar', [
        'problemesStats' => $problemesStats ?? null,
        'sidebarStartExpanded' => true,
    ])

    <div class="main">
        @include('partials.dashboard_topbar', [
            'title' => 'Tableau de Bord',
            'crumbId' => 'tb-crumb',
            'crumbLabel' => 'Dashboard',
            'chatBellUid' => 'dash',
        ])

        <div class="content">
            @if(session('success'))
            <div class="alert alert-success"><i class="fas fa-check-circle"></i><span>{{ session('success') }}</span></div>
            @endif
            @if(session('error'))
            <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i><span>{{ session('error') }}</span></div>
            @endif

            <!-- Dashboard Section -->
            <div id="section-dashboard" class="content-section active">
            <div class="section-header fade-in">
                <h3>Vue d'ensemble</h3>
                <p>Surveillance et gestion en temps réel du réseau routier</p>
            </div>

            <!-- Metrics Cards -->
            <div class="stats-grid">
                <div class="stat-card green">
                    <div class="stat-top">
                        <div class="stat-label">Routes en bon état</div>
                        <div class="stat-icon-wrap"><i class="fas fa-check-circle"></i></div>
                    </div>
                    <div class="stat-value">156</div>
                    <div class="stat-sub">sur 200 routes</div>
                    <div class="stat-bar"><div class="stat-bar-fill" style="background: var(--green); width: 78%;"></div></div>
                </div>

                <div class="stat-card red">
                    <div class="stat-top">
                        <div class="stat-label">Routes fermées</div>
                        <div class="stat-icon-wrap"><i class="fas fa-times-circle"></i></div>
                    </div>
                    <div class="stat-value">4</div>
                    <div class="stat-sub">Diversions actives</div>
                    <div class="stat-bar"><div class="stat-bar-fill" style="background: var(--red); width: 20%;"></div></div>
                </div>

                <div class="stat-card cyan">
                    <div class="stat-top">
                        <div class="stat-label">Zones à risque</div>
                        <div class="stat-icon-wrap"><i class="fas fa-water"></i></div>
                    </div>
                    <div class="stat-value">{{ $riskZonesCount ?? 0 }}</div>
                    <div class="stat-sub">Surveillance active</div>
                    <div class="stat-bar"><div class="stat-bar-fill" style="background: var(--cyan); width: 30%;"></div></div>
                </div>
            </div>

            <!-- Content Grid -->
            <div class="layout-grid">
                <!-- Map Section -->
                <div class="map-section">
                    <header class="map-section-head">
                        <div class="map-section-brand">
                            <div class="card-icon" aria-hidden="true">
                                <i class="fas fa-map-location-dot"></i>
                            </div>
                            <div class="map-section-text">
                                <span class="map-section-kicker">Réseau routier</span>
                                <h2 class="map-section-title">Carte interactive <span>· Tunisie</span></h2>
                            </div>
                        </div>
                        <div class="map-status-legend map-status-legend--head" role="list" aria-label="Légende des statuts">
                            <div class="status-legend-item" role="listitem">
                                <span class="status-legend-dot red" aria-hidden="true"></span>
                                <span>Critique</span>
                            </div>
                            <div class="status-legend-item" role="listitem">
                                <span class="status-legend-dot orange" aria-hidden="true"></span>
                                <span>En cours</span>
                            </div>
                            <div class="status-legend-item" role="listitem">
                                <span class="status-legend-dot green" aria-hidden="true"></span>
                                <span>Normal</span>
                            </div>
                        </div>
                    </header>
                    <div class="map-frame">
                        <div id="map" role="application" aria-label="Carte interactive du réseau routier"></div>
                    </div>

                    <div class="map-widgets-below">
                        <!-- Weather — Open-Meteo (position GPS uniquement) -->
                        <div class="weather-section" id="weather-dashboard-widget">
                            <div class="card-head">
                                <div class="card-title-wrap">
                                    <div class="card-icon"><i class="fas fa-cloud-sun"></i></div>
                                    <span class="card-title">Données météorologiques</span>
                                </div>
                            </div>
                            <div class="weather-item">
                                <span class="weather-label">Température</span>
                                <span class="weather-value" id="wx-temp">—</span>
                            </div>
                            <div class="weather-item">
                                <span class="weather-label">Précipitations</span>
                                <span class="weather-value" id="wx-precip">—</span>
                            </div>
                            <div class="weather-item">
                                <span class="weather-label">Risque inondation</span>
                                <span class="weather-value" id="wx-flood">—</span>
                            </div>
                            <div class="weather-item">
                                <span class="weather-label">Vent</span>
                                <span class="weather-value" id="wx-wind">—</span>
                            </div>
                            <div class="weather-meta">
                                <span id="wx-status">Localisation…</span>
                                <button type="button" class="wx-refresh-btn" id="wx-refresh" title="Actualiser avec votre position">Actualiser</button>
                                <span id="wx-error" style="display:none;"></span>
                            </div>
                        </div>

                        <div class="satellite-section" id="satellite-dashboard-widget">
                            <div class="card-head">
                                <div class="card-title-wrap">
                                    <div class="card-icon"><i class="fas fa-satellite"></i></div>
                                    <span class="card-title">Analyse satellite</span>
                                </div>
                            </div>
                            <div class="satellite-info">
                                <div class="satellite-info-item">
                                    <span>Dernière mise à jour:</span>
                                    <span class="satellite-value" id="sat-last-update">—</span>
                                </div>
                                <div class="satellite-info-item">
                                    <span>Zones surveillées:</span>
                                    <span class="satellite-value" id="sat-zones">—</span>
                                </div>
                                <div class="satellite-info-item">
                                    <span>Anomalies détectées:</span>
                                    <span class="satellite-value orange" id="sat-anomalies">—</span>
                                </div>
                            </div>
                            <div class="satellite-submeta">
                                <span id="sat-radius-hint">Rayon 25 km autour de votre position</span>
                                <span id="sat-cloud-hint">Couverture nuageuse (modèle) —</span>
                            </div>
                            <div class="satellite-meta">
                                <span id="sat-status" style="flex:1;min-width:0;"></span>
                                <button type="button" class="wx-refresh-btn" id="sat-refresh" title="Actualiser l’analyse pour votre position">Actualiser</button>
                                <span id="sat-error" style="display:none;"></span>
                            </div>
                        </div>

                        <div class="risk-zones-section">
                            <div class="card-head">
                                <div class="card-title-wrap">
                                    <div class="card-icon"><i class="fas fa-map-marker-alt"></i></div>
                                    <span class="card-title">Zones à risque</span>
                                </div>
                            </div>
                            @forelse(collect($riskZones ?? [])->slice(1) as $zone)
                                <div class="zone-card {{ $zone['severity_class'] ?? 'orange' }}">
                                    <div>
                                        <div class="zone-name">{{ $zone['name'] ?? 'Zone à risque' }}</div>
                                        <div class="zone-place">
                                            Place:
                                            @if(($zone['gps_lat'] ?? null) !== null && ($zone['gps_lon'] ?? null) !== null)
                                                <a href="https://www.openstreetmap.org/?mlat={{ rawurlencode(sprintf('%.6f', (float) $zone['gps_lat'])) }}&mlon={{ rawurlencode(sprintf('%.6f', (float) $zone['gps_lon'])) }}&zoom=15" target="_blank" rel="noopener noreferrer" title="Ouvrir la position sur la carte (GPS)">
                                                    Lien position GPS
                                                </a>
                                                @if(!empty($zone['place_text']))
                                                    <span class="zone-place-hint"> — {{ $zone['place_text'] }}</span>
                                                @endif
                                            @elseif(!empty($zone['place_text']))
                                                {{ $zone['place_text'] }}
                                            @else
                                                Non précisée
                                            @endif
                                        </div>
                                        <div class="zone-status">{{ $zone['status'] ?? 'Surveillance active' }}</div>
                                        <span class="zone-category">Catégorie: {{ $zone['category'] ?? 'Non spécifiée' }}</span>
                                    </div>
                                </div>
                            @empty
                                <div class="zone-card orange">
                                    <div>
                                        <div class="zone-name">Aucune zone disponible</div>
                                        <div class="zone-status">La collection `zones_risque` est vide ou indisponible.</div>
                                    </div>
                                </div>
                            @endforelse
                        </div>
                    </div>
                </div>
            </div>

            </div>
            <!-- End Dashboard Section -->

            <!-- Problèmes de Voirie Section -->
            <div id="section-problemes" class="content-section problemes-section">
                <div class="problemes-header">
                    <div class="problemes-header-icon">
                        <i class="fas fa-brain"></i>
                    </div>
                    <h3>Problèmes de Voirie - Détection IA</h3>
                </div>
                <p class="problemes-subtitle">Liste générée automatiquement par Intelligence Artificielle</p>

                <!-- Stats Cards -->
                <div class="problemes-stats-grid">
                    <div class="probleme-stat-card orange">
                        <div class="probleme-stat-label">En attente</div>
                        <div id="stat-en-attente" class="probleme-stat-value">{{ $problemesStats['en_attente'] ?? 0 }}</div>
                        <i class="fas fa-clock probleme-stat-icon"></i>
                    </div>
                    <div class="probleme-stat-card blue">
                        <div class="probleme-stat-label">En cours</div>
                        <div id="stat-en-cours" class="probleme-stat-value">{{ $problemesStats['en_cours'] ?? 0 }}</div>
                        <i class="fas fa-chart-line probleme-stat-icon"></i>
                    </div>
                    <div class="probleme-stat-card green">
                        <div class="probleme-stat-label">Terminés</div>
                        <div id="stat-termine" class="probleme-stat-value">{{ $problemesStats['termine'] ?? 0 }}</div>
                        <i class="fas fa-check-circle probleme-stat-icon"></i>
                    </div>
                </div>

                <!-- Problems List -->
                <div class="problemes-list-section">
                    <div class="problemes-list-header">
                        <h4 class="problemes-list-title">Liste des problèmes (triés par priorité)</h4>
                        <button class="btn-ai-detection">
                            <i class="fas fa-brain"></i>
                            Détection automatique IA
                        </button>
                    </div>
                    <div style="overflow-x: auto;">
                        <table class="problemes-table">
                            <thead>
                                <tr>
                                    <th>Priorité</th>
                                    <th>Type</th>
                                    <th>Localisation</th>
                                    <th>Score de risque</th>
                                    <th>Gravité</th>
                                    <th>Confiance IA</th>
                                    <th>Date détection</th>
                                    <th>Statut</th>
                                    <th>Équipe</th>
                                    <th>Coût estimé</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="problems-table-body">
                                @php
                                    $problemesVisibles = collect($problemes ?? [])->reject(function ($probleme) {
                                        $statusValue = strtolower(trim((string) ($probleme['statut'] ?? $probleme['status'] ?? '')));

                                        return str_contains($statusValue, 'term');
                                    })->values();
                                @endphp
                                @forelse($problemesVisibles as $probleme)
                                    @php
                                        $visibleRank = $loop->iteration;
                                        $type = $probleme['type'] ?? 'Problème';
                                        $typeLower = strtolower($type);
                                        $iconClass = str_contains($typeLower, 'eau') || str_contains($typeLower, 'submer')
                                            ? 'fa-water'
                                            : (str_contains($typeLower, 'fissure')
                                                ? 'fa-crack'
                                                : (str_contains($typeLower, 'affaisse')
                                                    ? 'fa-compress-alt'
                                                    : 'fa-road'));

                                        $gravite = strtolower($probleme['gravite'] ?? 'moyenne');
                                        $gravityClass = str_contains($gravite, 'critique')
                                            ? 'critique'
                                            : (str_contains($gravite, 'haute') ? 'haute' : 'moyenne');

                                        $statusValue = strtolower(trim($probleme['statut'] ?? 'en attente'));
                                        $normalizedStatus = str_contains($statusValue, 'cours')
                                            ? 'en_cours'
                                            : (str_contains($statusValue, 'term') ? 'termine' : 'en_attente');
                                        $gpsLat = $probleme['latitude'] ?? null;
                                        $gpsLon = $probleme['longitude'] ?? null;
                                        $gpsUrl = ($gpsLat !== null && $gpsLon !== null)
                                            ? sprintf(
                                                'https://www.openstreetmap.org/?mlat=%s&mlon=%s&zoom=17',
                                                rawurlencode(sprintf('%.6f', (float) $gpsLat)),
                                                rawurlencode(sprintf('%.6f', (float) $gpsLon))
                                            )
                                            : null;
                                        $gpsTitleCoords = ($gpsLat !== null && $gpsLon !== null)
                                            ? sprintf('%.6f, %.6f', (float) $gpsLat, (float) $gpsLon)
                                            : '';
                                    @endphp
                                    <tr class="priority-{{ min($visibleRank, 6) }}" data-problem-id="{{ $probleme['id'] ?? '' }}">
                                        <td><div class="priority-circle">{{ $visibleRank }}</div></td>
                                        <td>
                                            <div class="type-chip">
                                                <i class="fas {{ $iconClass }}"></i>
                                                <span>{{ $type }}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="location-cell">
                                                <i class="fas fa-map-marker-alt"></i>
                                                <span>{{ $probleme['localisation'] ?? 'Localisation inconnue' }}</span>
                                                @if($gpsUrl)
                                                    <a class="btn-gps-link" href="{{ $gpsUrl }}" target="_blank" rel="noopener noreferrer" title="Carte à cette position : {{ $gpsTitleCoords }} (OpenStreetMap)">
                                                        <i class="fas fa-location-crosshairs"></i>
                                                    </a>
                                                @else
                                                    <span class="btn-gps-link disabled" title="Coordonnées GPS indisponibles">
                                                        <i class="fas fa-location-crosshairs"></i>
                                                    </span>
                                                @endif
                                            </div>
                                        </td>
                                        <td>
                                            <div class="risk-score">
                                                <span class="risk-score-number">{{ $probleme['risk_score'] ?? 0 }}</span>
                                                <div class="risk-bar">
                                                    <div class="risk-bar-fill" style="width:{{ $probleme['risk_score'] ?? 0 }}%;"></div>
                                                </div>
                                            </div>
                                        </td>
                                        <td><span class="gravity-pill {{ $gravityClass }}">{{ $probleme['gravite'] ?? 'Moyenne' }}</span></td>
                                        <td><span class="confidence-value">{{ $probleme['confiance'] ?? 0 }}%</span></td>
                                        <td>
                                            <span class="date-value">
                                                {{ $probleme['date_detection'] ?? now()->format('Y-m-d H:i') }}
                                            </span>
                                        </td>
                                        <td>
                                            @if(!empty($canEditProblemStatus))
                                                <div class="status-dropdown">
                                                    <select class="status-select" data-problem-id="{{ $probleme['id'] ?? '' }}" onchange="updateProblemStatus(this)">
                                                        <option value="en_attente" {{ $normalizedStatus === 'en_attente' ? 'selected' : '' }}>En attente</option>
                                                        <option value="en_cours" {{ $normalizedStatus === 'en_cours' ? 'selected' : '' }}>En cours</option>
                                                        <option value="termine" {{ $normalizedStatus === 'termine' ? 'selected' : '' }}>Terminé</option>
                                                    </select>
                                                </div>
                                            @else
                                                @php
                                                    $statusLabel = match ($normalizedStatus) {
                                                        'en_cours' => 'En cours',
                                                        'termine' => 'Terminé',
                                                        default => 'En attente',
                                                    };
                                                @endphp
                                                <span class="status-readonly-pill status-readonly-{{ $normalizedStatus }}" title="Consultation seule — modification réservée à l’administrateur technique">{{ $probleme['statut'] ?? $statusLabel }}</span>
                                            @endif
                                        </td>
                                        <td><span class="team-value">{{ $probleme['equipe'] ?? 'Non assignée' }}</span></td>
                                        <td class="problem-cout-cell">
                                            @php
                                                $rawCout = trim((string) ($probleme['cout_estime'] ?? ''));
                                                $hasCout = $rawCout !== ''
                                                    && strcasecmp($rawCout, 'N/A') !== 0
                                                    && $rawCout !== '—'
                                                    && $rawCout !== '-';
                                            @endphp
                                            @if($hasCout)
                                                <span class="cout-estime-value" title="Coût estimé saisi par l’administrateur">{{ $rawCout }}</span>
                                            @else
                                                <span class="cout-estime-empty">Non saisi</span>
                                            @endif
                                        </td>
                                        <td>
                                            <div class="action-cell">
                                                <button
                                                    class="btn-assign"
                                                    data-problem-id="{{ e((string)($probleme['id'] ?? '')) }}"
                                                    data-location="{{ e((string)($probleme['localisation'] ?? 'Localisation inconnue')) }}"
                                                    data-description="{{ e((string)($probleme['description'] ?? 'Description non disponible')) }}"
                                                    data-cost="{{ e((string)($probleme['cout_estime'] ?? 'N/A')) }}"
                                                    onclick="openAssignModal(this)">
                                                    <i class="fas fa-users"></i>
                                                    <span>Affecter</span>
                                                </button>
                                                <div class="priority-dropdown">
                                                    <select class="priority-select">
                                                        @for ($p = 1; $p <= 6; $p++)
                                                            <option value="P{{ $p }}" {{ ($probleme['priority_code'] ?? 'P6') === ('P' . $p) ? 'selected' : '' }}>P{{ $p }}</option>
                                                        @endfor
                                                    </select>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="11" style="text-align:center; color: var(--text2); padding: 24px;">
                                            Aucun problème en attente ou en cours.
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <!-- End Problèmes de Voirie Section -->

            <!-- Analyse Section -->
            <div id="section-analyse" class="content-section">
                <div class="section-header fade-in analyse-header">
                    <h3>Analyse &amp; pilotage</h3>
                    <p>Statistiques et indicateurs de performance</p>
                </div>

                <!-- Onglets analyse -->
                <div class="analyse-tabs">
                    <div class="analyse-tabs-nav">
                        <button class="analyse-tab-btn active" data-analyse-tab="interventions" onclick="switchAnalyseTab('interventions', this)">Interventions</button>
                        <button class="analyse-tab-btn" data-analyse-tab="alertes" onclick="switchAnalyseTab('alertes', this)">Alertes</button>
                        <button class="analyse-tab-btn" data-analyse-tab="satisfaction_citoyen" onclick="switchAnalyseTab('satisfaction_citoyen', this)">Satisfaction de citoyen</button>
                        <button class="analyse-tab-btn" data-analyse-tab="budget" onclick="switchAnalyseTab('budget', this)">Budget</button>
                    </div>

                    <div class="analyse-tab-panels">
                        <!-- Panel Interventions -->
                        <div class="analyse-tab-panel active" data-analyse-panel="interventions">
                            <style>
                                .analyse-container { padding: 20px; color: var(--text); }
                                .analyse-container .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
                                .analyse-container .kpi-card { background: #fff; padding: 20px; border-radius: 12px; text-align: center; border: 1px solid var(--border); box-shadow: 0 4px 14px rgba(0,0,0,0.05); }
                                .analyse-container .kpi-card h4 { font-size: 14px; color: var(--text2); }
                                .analyse-container .kpi-card p { font-size: 24px; font-weight: bold; margin-top: 10px; color: var(--orange); }
                                .analyse-container .chart-card { margin-top: 20px; background: #fff; padding: 20px; border-radius: 12px; border: 1px solid var(--border); box-shadow: 0 4px 14px rgba(0,0,0,0.05); }
                                .analyse-container .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px; }
                                .analyse-container .card { background: #fff; padding: 20px; border-radius: 12px; border: 1px solid var(--border); }
                                .analyse-container .card ul { list-style: none; padding: 0; }
                                .analyse-container .card li { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid var(--border); }
                                @media (max-width: 900px) { .analyse-container .kpi-grid{grid-template-columns: 1fr 1fr;} .analyse-container .grid-2{grid-template-columns:1fr;} }
                            </style>
                            <div class="analyse-container">
                                <div class="kpi-grid">
                                    <div class="kpi-card">
                                        <h4>Total défauts</h4>
                                        <p>{{ $problemsAnalysis['total'] ?? 0 }}</p>
                                    </div>
                                    <div class="kpi-card">
                                        <h4>Confiance moyenne</h4>
                                        <p>{{ $problemsAnalysis['avgConfidence'] ?? 0 }}%</p>
                                    </div>
                                    <div class="kpi-card">
                                        <h4>Risque moyen</h4>
                                        <p>{{ $problemsAnalysis['avgRisk'] ?? 0 }}</p>
                                    </div>
                                    <div class="kpi-card">
                                        <h4>Zones critiques</h4>
                                        <p>{{ $problemsAnalysis['bySeverity']['Élevée'] ?? ($problemsAnalysis['bySeverity']['Elevee'] ?? 0) }}</p>
                                    </div>
                                </div>
                                <div class="chart-card">
                                    <h3>Évolution mensuelle des défauts</h3>
                                    <canvas id="chartProblemes"></canvas>
                                </div>
                                <div class="grid-2">
                                    <div class="card">
                                        <h3>Types de défauts</h3>
                                        <ul>
                                            @foreach(($problemsAnalysis['byType'] ?? []) as $row)
                                                <li>
                                                    {{ $row->problem_type ?? 'N/A' }}
                                                    <span>{{ $row->c ?? 0 }}</span>
                                                </li>
                                            @endforeach
                                            @if(empty($problemsAnalysis['byType']) || (is_countable($problemsAnalysis['byType']) && count($problemsAnalysis['byType'])===0))
                                                <li>Aucun</li>
                                            @endif
                                        </ul>
                                    </div>
                                    <div class="card">
                                        <h3>Répartition par sévérité</h3>
                                        <ul>
                                            <li>Élevée <span>{{ ($problemsAnalysis['bySeverity']['Élevée'] ?? null) ?? ($problemsAnalysis['bySeverity']['Elevee'] ?? 0) }}</span></li>
                                            <li>Moyenne <span>{{ $problemsAnalysis['bySeverity']['Moyenne'] ?? 0 }}</span></li>
                                            <li>Faible <span>{{ $problemsAnalysis['bySeverity']['Faible'] ?? 0 }}</span></li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
                            <script>
                                const dataAnalyse = @json($problemsAnalysis ?? []);
                                (function(){
                                    const ctx = document.getElementById('chartProblemes');
                                    if (!ctx || !dataAnalyse || !dataAnalyse.labels) return;
                                    new Chart(ctx, {
                                        type: 'line',
                                        data: {
                                            labels: dataAnalyse.labels,
                                            datasets: [{
                                                label: 'Défauts détectés',
                                                data: dataAnalyse.perMonth || [],
                                                borderWidth: 2,
                                                tension: 0.3,
                                                borderColor: '#FF6B35',
                                                backgroundColor: 'rgba(255,107,53,0.2)',
                                                fill: true,
                                                pointRadius: 2
                                            }]
                                        },
                                        options: { responsive: true, scales: { y: { beginAtZero: true } } }
                                    });
                                })();
                            </script>
                        </div>

                        <!-- Panel Alertes : données Mongo alert / alerts -->
                        <div class="analyse-tab-panel" data-analyse-panel="alertes">
                            @php
                                $aa = $alertsAnalysis ?? [];
                                $aaDefs = $aa['definitions'] ?? [];
                                $aaCounts = $aa['counts'] ?? [];
                                $aaChart = $aa['chart'] ?? ['labels' => [], 'data' => [], 'colors' => []];
                                $aaRaw = $aa['raw_by_collection'] ?? ['alert' => 0, 'alerts' => 0];
                                $aaMonthChart = $aa['month_chart'] ?? ['labels' => [], 'data' => []];
                                $aaTimeline = $aa['timeline_stacked'] ?? ['labels' => [], 'datasets' => []];
                                $aaRiskChart = $aa['risk_chart'] ?? ['labels' => [], 'data' => []];
                                $aaRiskSource = $aa['risk_source'] ?? null;
                                $aaZonesRisqueCount = (int) ($aa['zones_risque_count'] ?? 0);
                                $aaSourceChart = $aa['source_chart'] ?? ['labels' => [], 'data' => []];
                                $aaByRawCat = $aa['by_raw_category'] ?? [];
                                $aaColorMap = [
                                    'inondation' => '#1A1A1A',
                                    'routes_impraticables' => '#C2410C',
                                    'tempetes_vents' => '#6366f1',
                                    'zones_ouvertes_nationales' => '#059669',
                                    'pluie' => '#0ea5e9',
                                    'chaleur_extreme' => '#dc2626',
                                    'temperature_elevee' => '#f97316',
                                    'temperature_moderee' => '#fdba74',
                                    'autre' => '#9ca3af',
                                ];
                            @endphp
                            <div class="alerts-kpi-strip">
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ $aa['unique_total'] ?? ($aa['total'] ?? 0) }}</div>
                                    <div class="alerts-kpi-label">Documents uniques (après dédoublonnage)</div>
                                </div>
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ (int) ($aaRaw['alert'] ?? 0) }}</div>
                                    <div class="alerts-kpi-label">Lignes brutes · collection <code>alert</code></div>
                                </div>
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ (int) ($aaRaw['alerts'] ?? 0) }}</div>
                                    <div class="alerts-kpi-label">Lignes brutes · collection <code>alerts</code></div>
                                </div>
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ $aa['with_location'] ?? 0 }}</div>
                                    <div class="alerts-kpi-label">Avec coordonnées GPS / géométrie</div>
                                </div>
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ $aa['recent_7d'] ?? 0 }}</div>
                                    <div class="alerts-kpi-label">Créées / détectées · 7 derniers jours</div>
                                </div>
                                <div class="alerts-kpi-item">
                                    <div class="alerts-kpi-value">{{ $aa['recent_30d'] ?? 0 }}</div>
                                    <div class="alerts-kpi-label">Créées / détectées · 30 derniers jours</div>
                                </div>
                            </div>
                            <p style="font-size:13px;color:var(--text2);margin:0 0 18px;line-height:1.5;">
                                <strong>{{ $aa['total'] ?? 0 }}</strong> alerte(s) classée(s) par type
                                @if(($aa['duplicate_skipped'] ?? 0) > 0)
                                    · <span style="color:var(--text3);">{{ $aa['duplicate_skipped'] }} doublon(s) ignoré(s) entre les deux collections</span>
                                @endif
                            </p>
                            <div class="alerts-grid">
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-chart-pie"></i></span>
                                        Répartition des alertes
                                    </div>
                                    <p style="font-size:13px;color:var(--text2);margin:0 0 12px;">
                                        Répartition par type métier (même document compté une seule fois).
                                    </p>
                                    @if(!empty($aaChart['labels']) && !empty($aaChart['data']))
                                        <div style="max-width:360px;margin:0 auto;">
                                            <canvas id="chartAlertes" height="280"></canvas>
                                        </div>
                                    @else
                                        <p style="font-size:14px;color:var(--text2);padding:24px;text-align:center;">
                                            Aucune alerte en base ou aucun type avec effectif &gt; 0.
                                        </p>
                                    @endif
                                </div>
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-list-ul"></i></span>
                                        Détail par type
                                    </div>
                                    <div class="alerts-type-table-wrap">
                                        <table class="alerts-type-table">
                                            <thead>
                                                <tr>
                                                    <th>Type</th>
                                                    <th>Rôle</th>
                                                    <th>Nb</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                @foreach($aaDefs as $key => $meta)
                                                    @php $n = (int) ($aaCounts[$key] ?? 0); @endphp
                                                    <tr>
                                                        <td>
                                                            <span class="alerts-type-dot" style="background:{{ $aaColorMap[$key] ?? '#9ca3af' }}"></span>
                                                            {{ $meta['label'] ?? $key }}
                                                        </td>
                                                        <td style="color:var(--text2);font-size:12px;line-height:1.45;">{{ $meta['role'] ?? '' }}</td>
                                                        <td>{{ $n }}</td>
                                                    </tr>
                                                @endforeach
                                            </tbody>
                                        </table>
                                    </div>
                                    <div class="alerts-performance" style="margin-top:18px;">
                                        <div class="alerts-performance-title">Temps de résolution (indicatif)</div>
                                        @if(!empty($aa['resolved_count']) && ($aa['resolved_count'] ?? 0) > 0 && ($aa['resolution_avg_days'] ?? null) !== null)
                                            <div class="alerts-performance-main">{{ $aa['resolution_avg_days'] }} j</div>
                                            <div class="alerts-performance-sub">Moyenne sur {{ $aa['resolved_count'] }} alerte(s) avec dates création / résolution renseignées.</div>
                                        @else
                                            <div class="alerts-performance-sub">Pas assez de données (<code>created_at</code> / <code>resolved_at</code> ou équivalents) pour calculer une moyenne.</div>
                                        @endif
                                    </div>
                                </div>
                            </div>

                            <div class="alerts-detail-grid">
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-chart-line"></i></span>
                                        Volume mensuel (6 mois)
                                    </div>
                                    <p style="font-size:12px;color:var(--text2);margin:0 0 8px;">Nombre d’alertes uniques par mois (selon date de création / détection).</p>
                                    <div class="alerts-chart-canvas-wrap">
                                        <canvas id="chartAlertesVolume"></canvas>
                                    </div>
                                </div>
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-layer-group"></i></span>
                                        Types par mois (empilé)
                                    </div>
                                    <p style="font-size:12px;color:var(--text2);margin:0 0 8px;">Répartition des types sur la même fenêtre de 6 mois.</p>
                                    <div class="alerts-chart-canvas-wrap">
                                        <canvas id="chartAlertesStacked"></canvas>
                                    </div>
                                </div>
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-exclamation-triangle"></i></span>
                                        Niveau / risque
                                    </div>
                                    @if($aaRiskSource === 'zones_risque')
                                        <p class="alerts-viz-sub">
                                            <strong>Vue proportionnelle</strong> (anneau + part par niveau) depuis <code>zones_risque</code>
                                            — champs <code>risk_level</code>, <code>risk</code>, <code>niveau_risque</code>, <code>severity</code>, <code>gravite</code>.
                                            <strong>{{ $aaZonesRisqueCount }}</strong> document(s).
                                        </p>
                                    @elseif($aaRiskSource === 'alerts')
                                        <p class="alerts-viz-sub">
                                            Aucune zone dans <code>zones_risque</code> : <strong>vue proportionnelle</strong> à partir des champs risque des alertes.
                                        </p>
                                    @else
                                        <p class="alerts-viz-sub">
                                            Collection <code>zones_risque</code> vide ou indisponible, et aucun champ de risque exploitable sur les alertes.
                                        </p>
                                    @endif
                                    @if(!empty($aaRiskChart['labels']))
                                        @php
                                            $aaRiskSumReal = (int) array_sum($aaRiskChart['data'] ?? []);
                                        @endphp
                                        <div class="alerts-viz-shell">
                                            <div class="alerts-viz-split">
                                                <div class="alerts-doughnut-wrap">
                                                    <div class="alerts-doughnut-glow" aria-hidden="true"></div>
                                                    <div class="alerts-doughnut-inner">
                                                        <canvas id="chartAlertesRisk"></canvas>
                                                    </div>
                                                </div>
                                                <div class="alerts-breakdown" aria-label="Détail par niveau de risque">
                                                    @foreach($aaRiskChart['labels'] as $i => $lab)
                                                        @php
                                                            $rn = (int) ($aaRiskChart['data'][$i] ?? 0);
                                                            $rpct = $aaRiskSumReal > 0 ? round(100 * $rn / $aaRiskSumReal, 1) : 0;
                                                            $ls = strtolower((string) $lab);
                                                            $riskTone = 'neutral';
                                                            if (str_contains($ls, 'élev') || str_contains($ls, 'eleve') || str_contains($ls, 'critique') || str_contains($ls, 'crit')) {
                                                                $riskTone = 'high';
                                                            } elseif (str_contains($ls, 'modér') || str_contains($ls, 'modere') || str_contains($ls, 'moyen')) {
                                                                $riskTone = 'mid';
                                                            } elseif (str_contains($ls, 'faible') || str_contains($ls, 'low') || str_contains($ls, 'mineur')) {
                                                                $riskTone = 'low';
                                                            }
                                                        @endphp
                                                        <div class="alerts-breakdown-row alerts-breakdown-row--{{ $riskTone }}">
                                                            <div class="alerts-breakdown-row-head">
                                                                <div class="alerts-breakdown-left">
                                                                    <span class="alerts-breakdown-dot" aria-hidden="true"></span>
                                                                    <span class="alerts-breakdown-label">{{ $lab }}</span>
                                                                </div>
                                                                <div class="alerts-breakdown-right">
                                                                    <span class="alerts-breakdown-count">{{ $rn }}</span>
                                                                    <span class="alerts-breakdown-pct">{{ $rpct }}%</span>
                                                                </div>
                                                            </div>
                                                            <div class="alerts-breakdown-bar">
                                                                <div class="alerts-breakdown-bar-fill" style="width: {{ $rpct }}%;"></div>
                                                            </div>
                                                        </div>
                                                    @endforeach
                                                </div>
                                            </div>
                                        </div>
                                    @else
                                        <p style="font-size:13px;color:var(--text2);padding:16px 0;">Aucune donnée de risque à afficher.</p>
                                    @endif
                                </div>
                                <div class="alerts-card">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-broadcast-tower"></i></span>
                                        Sources (top 8)
                                    </div>
                                    <p class="alerts-viz-sub">Part de chaque valeur <code>source</code> / <code>origine</code> (anneau + répartition %).</p>
                                    @if(!empty($aaSourceChart['labels']))
                                        @php
                                            $aaSrcSumReal = (int) array_sum($aaSourceChart['data'] ?? []);
                                        @endphp
                                        <div class="alerts-viz-shell alerts-viz-shell--source">
                                            <div class="alerts-viz-split">
                                                <div class="alerts-doughnut-wrap">
                                                    <div class="alerts-doughnut-glow" aria-hidden="true"></div>
                                                    <div class="alerts-doughnut-inner">
                                                        <canvas id="chartAlertesSource"></canvas>
                                                    </div>
                                                </div>
                                                <div class="alerts-breakdown" aria-label="Détail par source">
                                                    @foreach($aaSourceChart['labels'] as $si => $srcLab)
                                                        @php
                                                            $sn = (int) ($aaSourceChart['data'][$si] ?? 0);
                                                            $spct = $aaSrcSumReal > 0 ? round(100 * $sn / $aaSrcSumReal, 1) : 0;
                                                            $srcDisp = \Illuminate\Support\Str::limit((string) $srcLab, 48);
                                                        @endphp
                                                        <div class="alerts-breakdown-row alerts-breakdown-row--src">
                                                            <div class="alerts-breakdown-row-head">
                                                                <div class="alerts-breakdown-left">
                                                                    <span class="alerts-breakdown-dot" aria-hidden="true"></span>
                                                                    <span class="alerts-breakdown-label" title="{{ e($srcLab) }}">{{ $srcDisp }}</span>
                                                                </div>
                                                                <div class="alerts-breakdown-right">
                                                                    <span class="alerts-breakdown-count">{{ $sn }}</span>
                                                                    <span class="alerts-breakdown-pct">{{ $spct }}%</span>
                                                                </div>
                                                            </div>
                                                            <div class="alerts-breakdown-bar">
                                                                <div class="alerts-breakdown-bar-fill" style="width: {{ $spct }}%;"></div>
                                                            </div>
                                                        </div>
                                                    @endforeach
                                                </div>
                                            </div>
                                        </div>
                                    @else
                                        <p style="font-size:13px;color:var(--text2);padding:16px 0;">Aucune source renseignée.</p>
                                    @endif
                                </div>
                            </div>

                            @if(!empty($aaByRawCat))
                                <div class="alerts-card" style="margin-top:22px;">
                                    <div class="alerts-title">
                                        <span class="alerts-title-icon"><i class="fas fa-tags"></i></span>
                                        Catégories brutes (<code>category</code> / <code>categorie</code>)
                                    </div>
                                    <div class="alerts-detail-table-wrap">
                                        <table class="alerts-type-table">
                                            <thead>
                                                <tr>
                                                    <th>Catégorie</th>
                                                    <th>Nb</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                @foreach(array_slice($aaByRawCat, 0, 20, true) as $catLabel => $catN)
                                                    <tr>
                                                        <td>{{ \Illuminate\Support\Str::limit($catLabel, 80) }}</td>
                                                        <td>{{ (int) $catN }}</td>
                                                    </tr>
                                                @endforeach
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            @endif

                            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
                            <script>
                                (function () {
                                    var doughnutPayload = @json($aaChart);
                                    var monthPayload = @json($aaMonthChart);
                                    var timelinePayload = @json($aaTimeline);
                                    var riskPayload = @json($aaRiskChart);
                                    var sourcePayload = @json($aaSourceChart);

                                    var ctxPie = document.getElementById('chartAlertes');
                                    if (ctxPie && doughnutPayload.labels && doughnutPayload.data && doughnutPayload.labels.length > 0) {
                                        new Chart(ctxPie, {
                                            type: 'doughnut',
                                            data: {
                                                labels: doughnutPayload.labels,
                                                datasets: [{
                                                    data: doughnutPayload.data,
                                                    backgroundColor: doughnutPayload.colors || [],
                                                    borderWidth: 2,
                                                    borderColor: '#fff'
                                                }]
                                            },
                                            options: {
                                                responsive: true,
                                                plugins: {
                                                    legend: { position: 'bottom', labels: { boxWidth: 12, font: { size: 11 } } }
                                                }
                                            }
                                        });
                                    }

                                    var ctxVol = document.getElementById('chartAlertesVolume');
                                    if (ctxVol && monthPayload.labels && monthPayload.data) {
                                        new Chart(ctxVol, {
                                            type: 'line',
                                            data: {
                                                labels: monthPayload.labels,
                                                datasets: [{
                                                    label: 'Alertes',
                                                    data: monthPayload.data,
                                                    borderColor: '#FF6B35',
                                                    backgroundColor: 'rgba(255,107,53,0.15)',
                                                    fill: true,
                                                    tension: 0.25,
                                                    borderWidth: 2,
                                                    pointRadius: 3
                                                }]
                                            },
                                            options: {
                                                responsive: true,
                                                maintainAspectRatio: false,
                                                scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
                                            }
                                        });
                                    }

                                    var ctxStack = document.getElementById('chartAlertesStacked');
                                    if (ctxStack && timelinePayload.labels && timelinePayload.datasets && timelinePayload.datasets.length > 0) {
                                        new Chart(ctxStack, {
                                            type: 'bar',
                                            data: {
                                                labels: timelinePayload.labels,
                                                datasets: timelinePayload.datasets.map(function (d) {
                                                    return {
                                                        label: d.label,
                                                        data: d.data,
                                                        backgroundColor: d.backgroundColor || 'rgba(99,102,241,0.7)'
                                                    };
                                                })
                                            },
                                            options: {
                                                responsive: true,
                                                maintainAspectRatio: false,
                                                scales: {
                                                    x: { stacked: true },
                                                    y: { stacked: true, beginAtZero: true, ticks: { precision: 0 } }
                                                },
                                                plugins: {
                                                    legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } }
                                                }
                                            }
                                        });
                                    }

                                    function colorForRiskSlice(label) {
                                        var s = String(label || '').toLowerCase();
                                        if (/élev|eleve|crit|high|danger|grave|severe|haut/.test(s)) return '#9a3412';
                                        if (/modér|modere|moderate|medium|moyen/.test(s)) return '#ea580c';
                                        if (/faible|low|mineur|léger|leger/.test(s)) return '#fdba74';
                                        return '#737373';
                                    }
                                    function sourceSliceColors(n) {
                                        var pal = ['#1A1A1A', '#FF6B35', '#C2410C', '#FF925C', '#ea580c', '#9a3412', '#78716c', '#a3a3a3'];
                                        var out = [];
                                        for (var i = 0; i < n; i++) out.push(pal[i % pal.length]);
                                        return out;
                                    }
                                    function pctTooltipLabel(ctx) {
                                        var ds = ctx.dataset;
                                        var arr = ds.data;
                                        var total = arr.reduce(function (a, b) { return a + b; }, 0);
                                        var v = ctx.parsed;
                                        var pct = total ? ((v / total) * 100).toFixed(1) : '0';
                                        return ' ' + ctx.label + ': ' + v + ' (' + pct + '%)';
                                    }

                                    var ctxRisk = document.getElementById('chartAlertesRisk');
                                    if (ctxRisk && riskPayload.labels && riskPayload.data && riskPayload.labels.length > 0) {
                                        new Chart(ctxRisk, {
                                            type: 'doughnut',
                                            data: {
                                                labels: riskPayload.labels,
                                                datasets: [{
                                                    data: riskPayload.data,
                                                    backgroundColor: riskPayload.labels.map(colorForRiskSlice),
                                                    borderWidth: 2,
                                                    borderColor: '#fff',
                                                    hoverOffset: 6
                                                }]
                                            },
                                            options: {
                                                responsive: true,
                                                maintainAspectRatio: false,
                                                cutout: '62%',
                                                layout: { padding: 4 },
                                                plugins: {
                                                    legend: {
                                                        display: false
                                                    },
                                                    tooltip: {
                                                        callbacks: {
                                                            label: pctTooltipLabel
                                                        }
                                                    }
                                                }
                                            }
                                        });
                                    }

                                    var ctxSrc = document.getElementById('chartAlertesSource');
                                    if (ctxSrc && sourcePayload.labels && sourcePayload.data && sourcePayload.labels.length > 0) {
                                        new Chart(ctxSrc, {
                                            type: 'doughnut',
                                            data: {
                                                labels: sourcePayload.labels,
                                                datasets: [{
                                                    data: sourcePayload.data,
                                                    backgroundColor: sourceSliceColors(sourcePayload.labels.length),
                                                    borderWidth: 2,
                                                    borderColor: '#fff',
                                                    hoverOffset: 6
                                                }]
                                            },
                                            options: {
                                                responsive: true,
                                                maintainAspectRatio: false,
                                                cutout: '62%',
                                                layout: { padding: 4 },
                                                plugins: {
                                                    legend: {
                                                        display: false
                                                    },
                                                    tooltip: {
                                                        callbacks: {
                                                            label: pctTooltipLabel
                                                        }
                                                    }
                                                }
                                            }
                                        });
                                    }
                                })();
                            </script>
                        </div>
                        <div class="analyse-tab-panel" data-analyse-panel="satisfaction_citoyen">
                            @php
                                $ca = $citizenAccountsAnalysis ?? [];
                                $caMonth = $ca['month_chart'] ?? ['labels' => [], 'data' => []];
                                $caDeact = $ca['deactivation_chart'] ?? ['labels' => [], 'data' => [], 'colors' => []];
                                $caFeedbackDist = $ca['feedback_distribution'] ?? ['labels' => [], 'data' => []];
                                $caTotalN = (int) ($ca['total'] ?? 0);
                                $caTotalDeactivated = (int) ($ca['total_deactivated'] ?? 0);
                                $caDeactUndated = (int) ($ca['deactivated_undated'] ?? 0);
                                $caFeedbackTotal = (int) ($ca['feedback_total'] ?? 0);
                            @endphp
                            <div class="cit-sat-wrap">
                                <div class="cit-sat-hero">
                                    <div class="cit-sat-hero-icon" aria-hidden="true"><i class="fas fa-smile-beam"></i></div>
                                    <div>
                                        <h3 class="cit-sat-hero-title">Satisfaction &amp; engagement citoyen</h3>
                                        <p class="cit-sat-hero-desc">
                                            Suivez l’inscription des citoyens et la <strong>satisfaction</strong> mesurée à partir des retours enregistrés dans la collection <code>user_feedback</code>.
                                        </p>
                                    </div>
                                </div>

                                <div class="cit-sat-kpi-grid">
                                    <div class="cit-sat-kpi">
                                        <div class="cit-sat-kpi-top">
                                            <span class="cit-sat-kpi-ico"><i class="fas fa-users"></i></span>
                                        </div>
                                        <div class="cit-sat-kpi-value">{{ $caTotalN }}</div>
                                        <div class="cit-sat-kpi-label">Comptes enregistrés · <code>user_citoyen</code></div>
                                    </div>
                                </div>

                                <div class="cit-sat-info">
                                    <i class="fas fa-info-circle"></i>
                                    <p>
                                        Analyses basées sur la collection MongoDB <strong><code>user_citoyen</code></strong> (ex. champs visibles dans Atlas : <code>fullName</code>, <code>email</code>, <code>createdAt</code>, <code>_id</code>).
                                        Les courbes d’inscription utilisent <strong><code>createdAt</code></strong> en priorité, puis autres champs date, puis l’horodatage du <code>_id</code>.
                                        Les <strong>désactivations</strong> nécessitent des champs dédiés (<code>is_active</code>, <code>deactivated_at</code>, <code>deleted_at</code>, etc.) — absentes dans un schéma minimal.
                                        Les <strong>notes</strong> proviennent de <code>user_feedback</code>.
                                    </p>
                                </div>

                                <div class="cit-sat-charts">
                                    <div class="cit-sat-chart-card">
                                        <div class="cit-sat-chart-head">
                                            <h4 class="cit-sat-chart-title">
                                                <span class="cit-sat-chart-ic"><i class="fas fa-chart-area"></i></span>
                                                Dynamique d’inscription
                                            </h4>
                                            <span class="cit-sat-chart-badge">6 mois</span>
                                        </div>
                                        <p class="cit-sat-chart-sub">Évolution du nombre de nouveaux comptes citoyens par mois.</p>
                                        <div class="cit-sat-chart-canvas">
                                            <canvas id="chartCitoyensInscriptions"></canvas>
                                        </div>
                                    </div>
                                    <div class="cit-sat-chart-card">
                                        <div class="cit-sat-chart-head">
                                            <h4 class="cit-sat-chart-title">
                                                <span class="cit-sat-chart-ic"><i class="fas fa-user-slash"></i></span>
                                                Comptes &amp; désactivations d’app
                                            </h4>
                                            <span class="cit-sat-chart-badge">{{ $caTotalN }} compte(s)</span>
                                        </div>
                                        <p class="cit-sat-chart-sub">
                                            Total <strong>{{ $caTotalN }}</strong> compte(s) citoyen ·
                                            <strong>{{ $caTotalDeactivated }}</strong> désactivé(s) au total
                                            @if($caDeactUndated > 0)
                                                · <span style="color:var(--text3);">{{ $caDeactUndated }} sans date (non ventilés par période)</span>
                                            @endif
                                        </p>
                                        <div class="cit-sat-chart-canvas" id="chartCitoyensDeactivationWrap">
                                            @if($caTotalN > 0)
                                                <canvas id="chartCitoyensDeactivation"></canvas>
                                            @else
                                                <div class="cit-sat-empty" style="min-height:200px;"><i class="fas fa-user-slash"></i><span>Aucun compte dans <code>user_citoyen</code>.</span></div>
                                            @endif
                                        </div>
                                    </div>
                                </div>

                                @if($caFeedbackTotal > 0)
                                    <div class="cit-sat-feedback-block">
                                        <div class="cit-sat-chart-card">
                                            <div class="cit-sat-chart-head">
                                                <h4 class="cit-sat-chart-title">
                                                    <span class="cit-sat-chart-ic"><i class="fas fa-star-half-alt"></i></span>
                                                    Répartition des notes · <code>user_feedback</code>
                                                </h4>
                                                <span class="cit-sat-chart-badge">{{ $caFeedbackTotal }} avis</span>
                                            </div>
                                            <p class="cit-sat-chart-sub">Histogramme des notes ramenées sur une échelle 1 à 5 ★ (agrégation dynamique).</p>
                                            <div class="cit-sat-chart-canvas" id="chartFeedbackDistWrap">
                                                <canvas id="chartFeedbackDistribution"></canvas>
                                            </div>
                                        </div>
                                    </div>
                                @endif
                            </div>
                            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
                            <script>
                                (function () {
                                    var monthPayload = @json($caMonth);
                                    var deactPayload = @json($caDeact);
                                    var feedbackDistPayload = @json($caFeedbackDist);
                                    var gridColor = 'rgba(0,0,0,0.06)';
                                    var tickColor = '#737373';

                                    var ctxLine = document.getElementById('chartCitoyensInscriptions');
                                    if (ctxLine && monthPayload.labels && monthPayload.data) {
                                        new Chart(ctxLine, {
                                            type: 'line',
                                            data: {
                                                labels: monthPayload.labels,
                                                datasets: [{
                                                    label: 'Nouveaux comptes',
                                                    data: monthPayload.data,
                                                    borderColor: '#FF6B35',
                                                    backgroundColor: 'rgba(255,107,53,0.14)',
                                                    fill: true,
                                                    tension: 0.35,
                                                    borderWidth: 2.5,
                                                    pointRadius: 4,
                                                    pointHoverRadius: 6,
                                                    pointBackgroundColor: '#fff',
                                                    pointBorderColor: '#FF6B35',
                                                    pointBorderWidth: 2
                                                }]
                                            },
                                            options: {
                                                responsive: true,
                                                maintainAspectRatio: false,
                                                interaction: { intersect: false, mode: 'index' },
                                                plugins: {
                                                    legend: { display: false },
                                                    tooltip: {
                                                        backgroundColor: 'rgba(26,26,26,0.92)',
                                                        padding: 12,
                                                        cornerRadius: 10,
                                                        titleFont: { size: 13, weight: '600' },
                                                        bodyFont: { size: 13 }
                                                    }
                                                },
                                                scales: {
                                                    x: {
                                                        grid: { color: gridColor, drawBorder: false },
                                                        ticks: { color: tickColor, font: { size: 11 } }
                                                    },
                                                    y: {
                                                        beginAtZero: true,
                                                        ticks: { precision: 0, color: tickColor, font: { size: 11 } },
                                                        grid: { color: gridColor, drawBorder: false }
                                                    }
                                                }
                                            }
                                        });
                                    }

                                    var ctxDeact = document.getElementById('chartCitoyensDeactivation');
                                    if (ctxDeact && deactPayload && deactPayload.labels) {
                                        var deactDatasets = deactPayload.datasets;
                                        if (!deactDatasets && deactPayload.data) {
                                            deactDatasets = [{
                                                label: 'Série',
                                                data: deactPayload.data,
                                                backgroundColor: deactPayload.colors || ['#fb923c', '#ea580c', '#9a3412']
                                            }];
                                        }
                                        if (deactDatasets && deactDatasets.length) {
                                            new Chart(ctxDeact, {
                                                type: 'bar',
                                                data: {
                                                    labels: deactPayload.labels,
                                                    datasets: deactDatasets.map(function (d) {
                                                        return {
                                                            label: d.label || 'Valeur',
                                                            data: d.data,
                                                            backgroundColor: d.backgroundColor,
                                                            borderRadius: 8,
                                                            borderSkipped: false
                                                        };
                                                    })
                                                },
                                                options: {
                                                    responsive: true,
                                                    maintainAspectRatio: false,
                                                    plugins: {
                                                        legend: {
                                                            display: true,
                                                            position: 'bottom',
                                                            labels: {
                                                                boxWidth: 12,
                                                                padding: 14,
                                                                font: { size: 11 },
                                                                color: tickColor,
                                                                usePointStyle: true
                                                            }
                                                        },
                                                        tooltip: {
                                                            backgroundColor: 'rgba(26,26,26,0.92)',
                                                            padding: 12,
                                                            cornerRadius: 10,
                                                            callbacks: {
                                                                label: function (ctx) {
                                                                    var v = ctx.parsed.y !== undefined ? ctx.parsed.y : ctx.parsed;
                                                                    return ' ' + (ctx.dataset.label || '') + ': ' + v;
                                                                }
                                                            }
                                                        }
                                                    },
                                                    scales: {
                                                        x: {
                                                            grid: { display: false },
                                                            ticks: { color: tickColor, font: { size: 10, maxRotation: 45, minRotation: 0 } }
                                                        },
                                                        y: {
                                                            beginAtZero: true,
                                                            ticks: { precision: 0, color: tickColor },
                                                            grid: { color: gridColor, drawBorder: false }
                                                        }
                                                    }
                                                }
                                            });
                                        }
                                    }

                                    var ctxFb = document.getElementById('chartFeedbackDistribution');
                                    var wrapFb = document.getElementById('chartFeedbackDistWrap');
                                    if (wrapFb && feedbackDistPayload && feedbackDistPayload.data) {
                                        var sumFb = feedbackDistPayload.data.reduce(function (a, b) { return a + b; }, 0);
                                        if (sumFb > 0 && ctxFb) {
                                            new Chart(ctxFb, {
                                                type: 'bar',
                                                data: {
                                                    labels: feedbackDistPayload.labels,
                                                    datasets: [{
                                                        label: 'Nombre d’avis',
                                                        data: feedbackDistPayload.data,
                                                        backgroundColor: [
                                                            'rgba(239,68,68,0.75)',
                                                            'rgba(249,115,22,0.75)',
                                                            'rgba(234,179,8,0.8)',
                                                            'rgba(34,197,94,0.75)',
                                                            'rgba(5,150,105,0.85)'
                                                        ],
                                                        borderRadius: 10,
                                                        borderSkipped: false
                                                    }]
                                                },
                                                options: {
                                                    responsive: true,
                                                    maintainAspectRatio: false,
                                                    plugins: {
                                                        legend: { display: false },
                                                        tooltip: {
                                                            backgroundColor: 'rgba(26,26,26,0.92)',
                                                            padding: 12,
                                                            cornerRadius: 10
                                                        }
                                                    },
                                                    scales: {
                                                        x: {
                                                            grid: { display: false },
                                                            ticks: { color: tickColor, font: { size: 11, weight: '600' } }
                                                        },
                                                        y: {
                                                            beginAtZero: true,
                                                            ticks: { precision: 0, color: tickColor },
                                                            grid: { color: gridColor, drawBorder: false }
                                                        }
                                                    }
                                                }
                                            });
                                        } else {
                                            wrapFb.innerHTML = '<div class="cit-sat-empty" style="min-height:160px;"><i class="fas fa-inbox"></i><span>Aucune note numérique sur les avis. Ajoutez un champ <code>rating</code>, <code>note</code> ou <code>score</code> sur chaque document dans <code>user_feedback</code>.</span></div>';
                                        }
                                    }
                                })();
                            </script>
                        </div>
                        <div class="analyse-tab-panel" data-analyse-panel="securite" style="display:none">
                            <style>
    .analyse-tab-panel[data-analyse-panel="securite"] {
        padding: 0;
        background: transparent;
    }

    .securite-wrapper {
        background: #FFFFFF;
        border-radius: 16px;
        border: 1px solid rgba(0,0,0,0.1);
        padding: 24px 28px 28px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.05);
    }

    .securite-chart-title-row {
        display: flex;
        align-items: center;
        gap: 10px;
        margin-bottom: 16px;
    }
    .securite-chart-title-icon { color: #FF6B35; font-size: 18px; }
    .securite-chart-title { font-size: 16px; font-weight: 700; color: #0A0A0A; }

    /* ---- FILTRES ---- */
    .securite-filters {
        display: flex;
        gap: 8px;
        margin-bottom: 20px;
        flex-wrap: wrap;
    }
    .securite-filter-btn {
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 6px 14px;
        border-radius: 999px;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        border: 2px solid transparent;
        background: rgba(0,0,0,0.04);
        color: #525252;
        transition: all 0.18s ease;
        user-select: none;
    }
    .securite-filter-btn .dot {
        width: 10px; height: 10px;
        border-radius: 50%;
        flex-shrink: 0;
    }
    .securite-filter-btn:hover { opacity: 0.85; }
    .securite-filter-btn.active-accidents {
        background: rgba(26,26,26,0.08);
        border-color: #1A1A1A;
        color: #1A1A1A;
    }
    .securite-filter-btn.active-degats {
        background: rgba(255,107,53,0.12);
        border-color: #FF6B35;
        color: #C2410C;
    }
    .securite-filter-btn.active-signalements {
        background: rgba(194,65,12,0.1);
        border-color: #C2410C;
        color: #C2410C;
    }
    .securite-filter-btn.active-all {
        background: rgba(255,107,53,0.1);
        border-color: rgba(255,107,53,0.45);
        color: #0A0A0A;
    }

    /* ---- GRAPHIQUE ---- */
    .securite-bar-chart {
        position: relative;
        width: 100%;
        height: 280px;
        margin-bottom: 16px;
    }

    .securite-grid-lines {
        position: absolute;
        inset: 0 0 32px 36px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        pointer-events: none;
    }
    .securite-grid-line {
        width: 100%;
        height: 1px;
        background: rgba(0,0,0,0.08);
        position: relative;
    }
    .securite-grid-line::before {
        content: attr(data-val);
        position: absolute;
        right: calc(100% + 8px);
        top: 50%;
        transform: translateY(-50%);
        font-size: 11px;
        color: #737373;
        white-space: nowrap;
    }

    .securite-bar-months {
        position: absolute;
        inset: 0 0 32px 36px;
        display: flex;
        align-items: flex-end;
        justify-content: space-around;
        padding: 0 12px;
    }

    .securite-bar-month {
        position: relative;
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: flex-end;
        height: 100%;
        cursor: pointer;
        border-radius: 6px;
        transition: background 0.15s;
    }
    .securite-bar-month:hover { background: rgba(255,107,53,0.06); }
    .securite-bar-month.active-month { 
        background: rgba(255,107,53,0.1);
        position: relative;
    }
    .securite-bar-month.active-month::after {
        content: '';
        position: absolute;
        inset: 0;
        background: rgba(0,0,0,0.04);
        border-radius: 6px;
        pointer-events: none;
        z-index: 0;
    }
    .securite-bar-month.active-month .securite-bar-group {
        position: relative;
        z-index: 1;
    }

    .securite-bar-group {
        display: flex;
        align-items: flex-end;
        gap: 3px;
        height: 100%;
        padding: 0 6px;
        width: 100%;
        justify-content: center;
    }

    /* Barre individuelle */
    .securite-bar-item {
        width: 14px;
        min-height: 2px;
        border-radius: 3px 3px 0 0;
        flex-shrink: 0;
        transition: height 0.4s cubic-bezier(0.34,1.56,0.64,1), opacity 0.2s, width 0.2s;
    }
    .securite-bar-item.accidents    { background: #1A1A1A; }
    .securite-bar-item.degats       { background: #FF6B35; }
    .securite-bar-item.signalements { background: #C2410C; }

    /* Mode single : une seule barre large centrée */
    .securite-bar-group.single-mode .securite-bar-item { width: 28px; }
    .securite-bar-group.single-mode .securite-bar-item.hidden { display: none; }

    .securite-bar-label {
        position: absolute;
        bottom: -24px;
        font-size: 11px;
        color: #525252;
        text-align: center;
        white-space: nowrap;
    }

    /* ---- TOOLTIP ---- */
    .securite-tooltip {
        position: absolute;
        bottom: calc(100% + 8px);
        left: 50%;
        transform: translateX(-50%) translateY(4px);
        background: #FFFFFF;
        border-radius: 10px;
        box-shadow: 0 12px 32px rgba(0,0,0,0.12);
        padding: 12px 16px;
        min-width: 210px;
        font-size: 13px;
        color: #0A0A0A;
        z-index: 30;
        white-space: nowrap;
        pointer-events: none;
        border: 1px solid rgba(0,0,0,0.1);
        opacity: 0;
        transition: opacity 0.18s ease, transform 0.18s ease;
    }
    .securite-bar-month.active-month .securite-tooltip {
        opacity: 1;
        transform: translateX(-50%) translateY(0);
    }
    .securite-tooltip-title {
        font-weight: 700;
        font-size: 14px;
        margin-bottom: 8px;
        color: #0A0A0A;
    }
    .securite-tooltip-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
        margin-top: 5px;
        font-size: 13px;
    }
    .securite-tooltip-row.accidents    { color: #1A1A1A; }
    .securite-tooltip-row.degats       { color: #FF6B35; }
    .securite-tooltip-row.signalements { color: #C2410C; }
    .securite-tooltip-row span:last-child { font-weight: 700; }

    /* ---- LÉGENDE ---- */
    .securite-legend {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 24px;
        font-size: 13px;
        color: #525252;
        margin-top: 8px;
    }
    .securite-legend-item { display: flex; align-items: center; gap: 7px; cursor: pointer; }
    .securite-legend-dot  { width: 12px; height: 12px; border-radius: 3px; }

    /* ---- CARTES INFÉRIEURES ---- */
    .securite-bottom-grid {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 16px;
        margin-top: 24px;
    }
    .securite-stat-card {
        background: #FAFAFA;
        border-radius: 14px;
        border: 1px solid rgba(0,0,0,0.08);
        padding: 18px 20px 20px;
    }
    .securite-stat-title {
        font-size: 14px;
        font-weight: 700;
        color: #0A0A0A;
        margin-bottom: 14px;
    }
    .securite-gravite-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 9px 14px;
        border-radius: 9px;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 8px;
        background: rgba(0,0,0,0.04);
        color: #0A0A0A;
    }
    .securite-gravite-row:last-child { margin-bottom: 0; }
    .securite-gravite-row.critique strong { color: #1A1A1A; font-size: 18px; }
    .securite-gravite-row.modere   strong { color: #FF6B35; font-size: 18px; }
    .securite-gravite-row.mineur   strong { color: #C2410C; font-size: 18px; }

    .securite-response-main { font-size: 40px; font-weight: 800; color: #0A0A0A; line-height: 1; margin-bottom: 4px; }
    .securite-response-sub  { font-size: 13px; color: #737373; margin-bottom: 14px; }
    .securite-response-row  {
        display: flex;
        justify-content: space-between;
        padding: 6px 0;
        border-bottom: 1px solid rgba(0,0,0,0.08);
        font-size: 13px;
        color: #0A0A0A;
    }
    .securite-response-row:last-child { border-bottom: none; }
    .securite-response-row span:first-child { color: #737373; }
    .securite-response-row span:last-child  { font-weight: 600; }

    .securite-zone-pill {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 10px 14px;
        border-radius: 9px;
        font-size: 13px;
        margin-bottom: 8px;
    }
    .securite-zone-pill:last-child { margin-bottom: 0; }
    .securite-zone-pill span:first-child { color: #525252; font-weight: 500; }
    .securite-zone-pill-badge { padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 600; }
    .securite-zone-pill.critique { background: rgba(26,26,26,0.08); }
    .securite-zone-pill.critique .securite-zone-pill-badge { background: rgba(26,26,26,0.12); color: #1A1A1A; }
    .securite-zone-pill.moderee  { background: rgba(255,107,53,0.1); }
    .securite-zone-pill.moderee  .securite-zone-pill-badge { background: rgba(255,107,53,0.18); color: #C2410C; }
    .securite-zone-pill.mineure  { background: rgba(194,65,12,0.08); }
    .securite-zone-pill.mineure  .securite-zone-pill-badge { background: rgba(194,65,12,0.15); color: #C2410C; }

    @media (max-width: 900px) {
        .securite-bottom-grid { grid-template-columns: 1fr; }
        .securite-filters { gap: 6px; }
    }
</style>

<div class="securite-wrapper">

    <!-- Titre -->
    <div class="securite-chart-title-row">
        <i class="fas fa-triangle-exclamation securite-chart-title-icon"></i>
        <span class="securite-chart-title">Suivi incidents / sécurité routière - 7 derniers mois</span>
    </div>

    <!-- Filtres -->
    <div class="securite-filters">
        <div class="securite-filter-btn active-all" data-filter="all" onclick="securiteSetFilter('all')">
            <span class="dot" style="background:#FF6B35;"></span> Tout afficher
        </div>
        <div class="securite-filter-btn" data-filter="accidents" onclick="securiteSetFilter('accidents')">
            <span class="dot" style="background:#1A1A1A;"></span> Accidents
        </div>
        <div class="securite-filter-btn" data-filter="degats" onclick="securiteSetFilter('degats')">
            <span class="dot" style="background:#FF6B35;"></span> Dégâts matériels
        </div>
        <div class="securite-filter-btn" data-filter="signalements" onclick="securiteSetFilter('signalements')">
            <span class="dot" style="background:#C2410C;"></span> Signalements citoyens
        </div>
    </div>

    <!-- Graphique -->
    <div class="securite-bar-chart">

        <div class="securite-grid-lines">
            <div class="securite-grid-line" data-val="16"></div>
            <div class="securite-grid-line" data-val="12"></div>
            <div class="securite-grid-line" data-val="8"></div>
            <div class="securite-grid-line" data-val="4"></div>
            <div class="securite-grid-line" data-val="0"></div>
        </div>

        <div class="securite-bar-months">

            <!-- Août -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(8/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(3/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(8/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Août</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Août</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>8</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>3</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>8</span></div>
                </div>
            </div>

            <!-- Sept -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(6/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(2/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(6/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Sept</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Sept</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>6</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>2</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>6</span></div>
                </div>
            </div>

            <!-- Oct -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(9/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(4/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(15/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Oct</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Oct</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>9</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>4</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>15</span></div>
                </div>
            </div>

            <!-- Nov -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(7/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(3/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(4/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Nov</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Nov</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>7</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>3</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>4</span></div>
                </div>
            </div>

            <!-- Déc -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(4/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(2/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(4/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Déc</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Déc</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>4</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>2</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>4</span></div>
                </div>
            </div>

            <!-- Jan -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(2/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(1/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(10/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Jan</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Jan</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>2</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>1</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>10</span></div>
                </div>
            </div>

            <!-- Fév -->
            <div class="securite-bar-month" onclick="securiteToggleMonth(this)">
                <div class="securite-bar-group">
                    <div class="securite-bar-item accidents"    style="height:calc(6/16*100%)"></div>
                    <div class="securite-bar-item degats"       style="height:calc(5/16*100%)"></div>
                    <div class="securite-bar-item signalements" style="height:calc(15/16*100%)"></div>
                </div>
                <div class="securite-bar-label">Fév</div>
                <div class="securite-tooltip">
                    <div class="securite-tooltip-title">Fév</div>
                    <div class="securite-tooltip-row accidents"><span>Accidents</span><span>6</span></div>
                    <div class="securite-tooltip-row degats"><span>Dégâts matériels</span><span>5</span></div>
                    <div class="securite-tooltip-row signalements"><span>Signalements</span><span>15</span></div>
                </div>
            </div>

        </div>
    </div>

    <!-- Légende -->
    <div class="securite-legend">
        <div class="securite-legend-item" onclick="securiteSetFilter('accidents')">
            <span class="securite-legend-dot" style="background:#1A1A1A;"></span>
            <span>Accidents</span>
        </div>
        <div class="securite-legend-item" onclick="securiteSetFilter('degats')">
            <span class="securite-legend-dot" style="background:#FF6B35;"></span>
            <span>Dégâts matériels</span>
        </div>
        <div class="securite-legend-item" onclick="securiteSetFilter('signalements')">
            <span class="securite-legend-dot" style="background:#C2410C;"></span>
            <span>Signalements citoyens</span>
        </div>
    </div>

    <!-- 3 cartes inférieures -->
    <div class="securite-bottom-grid">

        <div class="securite-stat-card">
            <div class="securite-stat-title">Incidents par gravité</div>
            <div class="securite-gravite-row critique"><span>Critiques</span><strong>8</strong></div>
            <div class="securite-gravite-row modere"><span>Modérés</span><strong>24</strong></div>
            <div class="securite-gravite-row mineur"><span>Mineurs</span><strong>45</strong></div>
        </div>

        <div class="securite-stat-card">
            <div class="securite-stat-title">Temps de réponse moyen</div>
            <div class="securite-response-main">18min</div>
            <div class="securite-response-sub">Toutes catégories</div>
            <div>
                <div class="securite-response-row"><span>Critiques</span><span>8 min</span></div>
                <div class="securite-response-row"><span>Modérés</span><span>15 min</span></div>
                <div class="securite-response-row"><span>Mineurs</span><span>25 min</span></div>
            </div>
        </div>

        <div class="securite-stat-card">
            <div class="securite-stat-title">Zones à risque</div>
            <div class="securite-zone-pill critique">
                <span>Centre-ville</span>
                <span class="securite-zone-pill-badge">32 incidents</span>
            </div>
            <div class="securite-zone-pill moderee">
                <span>Zone industrielle</span>
                <span class="securite-zone-pill-badge">18 incidents</span>
            </div>
            <div class="securite-zone-pill mineure">
                <span>Périphérie Nord</span>
                <span class="securite-zone-pill-badge">12 incidents</span>
            </div>
        </div>

    </div>
</div>

<script>
(function() {
    let currentFilter = 'all';
    let activeMonth = null;

    window.securiteSetFilter = function(filter) {
        currentFilter = filter;

        // Mise à jour des boutons
        document.querySelectorAll('.securite-filter-btn').forEach(btn => {
            btn.className = 'securite-filter-btn';
            if (btn.dataset.filter === filter) {
                btn.classList.add('active-' + filter);
            }
        });

        // Mise à jour des barres
        document.querySelectorAll('.securite-bar-month').forEach(month => {
            const group = month.querySelector('.securite-bar-group');

            if (filter === 'all') {
                group.classList.remove('single-mode');
                group.querySelectorAll('.securite-bar-item').forEach(bar => {
                    bar.classList.remove('hidden');
                });
            } else {
                group.classList.add('single-mode');
                group.querySelectorAll('.securite-bar-item').forEach(bar => {
                    if (bar.classList.contains(filter)) {
                        bar.classList.remove('hidden');
                    } else {
                        bar.classList.add('hidden');
                    }
                });
            }

            // Mise à jour tooltip : afficher seulement la ligne filtrée
            month.querySelectorAll('.securite-tooltip-row').forEach(row => {
                if (filter === 'all') {
                    row.style.display = 'flex';
                } else {
                    row.style.display = row.classList.contains(filter) ? 'flex' : 'none';
                }
            });
        });
    };

    window.securiteToggleMonth = function(el) {
        if (activeMonth && activeMonth !== el) {
            activeMonth.classList.remove('active-month');
        }
        if (el.classList.contains('active-month')) {
            el.classList.remove('active-month');
            activeMonth = null;
        } else {
            el.classList.add('active-month');
            activeMonth = el;
        }
    };
})();
</script>
                        </div>
                        <div class="analyse-tab-panel" data-analyse-panel="budget">
                            @include('partials.budget_dashboard', [
                                'budgetDashboard' => $budgetDashboard ?? config('trig_budget'),
                                'problemes' => $problemes ?? [],
                            ])
                        </div>
                    </div>
                </div>
            </div>
            <!-- End Analyse Section -->

            <!-- Équipes d'intervention -->
            <div id="section-equipes" class="content-section">
                @include('partials.equipes_dashboard_table')
            </div>

            <!-- Budget (menu latéral) -->
            <div id="section-budget" class="content-section">
                @include('partials.budget_dashboard', [
                    'budgetDashboard' => $budgetDashboard ?? config('trig_budget'),
                    'problemes' => $problemes ?? [],
                ])
            </div>

            <!-- Profile Section -->
            <div id="section-profile" class="content-section">
                <div class="ap-wrap">
                    <div class="ap-header">
                        <div class="ap-badge">Admin</div>
                        <div class="ap-title">Profil Administrateur</div>
                        <div class="ap-sub">Gestion du compte</div>
                    </div>

                    <div class="ap-card" id="apIdentityCard">
                        <div class="ap-head">
                            <h3>Informations du compte</h3>
                            <button class="ap-edit-btn" id="apIdentityToggle" onclick="apToggleEdit('identity')">Modifier</button>
                        </div>
                        <div class="ap-id-top">
                            <div class="ap-avatar{{ $headerAvatarUrl ? ' has-image' : '' }}" id="apAvatar">
                                @if($headerAvatarUrl)
                                    <img class="ap-avatar-img" id="apAvatarImg" src="{{ $headerAvatarUrl }}" alt="">
                                @endif
                                <span class="ap-avatar-letter" id="apAvatarLetter">{{ $headerInitials }}</span>
                            </div>
                            <div>
                                <div class="ap-role-tag">{{ $headerRoleLabel }}</div>
                                <div class="ap-name" id="apDisplayName">{{ $headerDisplayName }}</div>
                                <div class="ap-last">Derniere connexion : Aujourd'hui</div>
                            </div>
                        </div>
                        <div class="ap-stats">
                            <div class="ap-stat"><span class="v">247</span><span class="l">Actions</span></div>
                            <div class="ap-stat"><span class="v">3 ans</span><span class="l">Anciennete</span></div>
                            <div class="ap-stat"><span class="v">Actif</span><span class="l">Statut</span></div>
                        </div>
                        <div class="ap-fields" id="apIdentityFields">
                            <div class="ap-field"><label>Prenom</label><div class="ap-val">{{ $apFirstName }}</div><input class="ap-input" type="text" value="{{ $apFirstName }}"></div>
                            <div class="ap-field"><label>Nom</label><div class="ap-val">{{ $apLastName }}</div><input class="ap-input" type="text" value="{{ $apLastName }}"></div>
                            <div class="ap-field"><label>Email</label><div class="ap-val">{{ $user->email ?? 'Non defini' }}</div><input class="ap-input" type="email" value="{{ $user->email ?? '' }}"></div>
                            <div class="ap-field"><label>Telephone</label><div class="ap-val">{{ $user->phone ?? '+216 -- --- ---' }}</div><input class="ap-input" type="text" value="{{ $user->phone ?? '' }}"></div>
                            <div class="ap-field ap-span2"><label>Bio</label><div class="ap-val">Administrateur systeme principal.</div><textarea class="ap-input">Administrateur systeme principal.</textarea></div>
                        </div>
                        <div class="ap-actions">
                            <button class="ap-btn" onclick="apCancelEdit('identity')">Annuler</button>
                            <button class="ap-btn ap-save" onclick="apSaveEdit('identity')">Enregistrer</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Account Info Section -->
            <div id="account-info" class="account-info-section">
                <div class="account-header">
                    <h2>
                        <span class="account-header-icon"><i class="fas fa-user"></i></span>
                        Informations du Compte
                    </h2>
                </div>

                <div class="account-info-grid">
                    <div class="info-card">
                        <div class="info-label">Nom complet</div>
                        <div class="info-value">{{ $headerDisplayName }}</div>
                    </div>

                    <div class="info-card">
                        <div class="info-label">Adresse email</div>
                        <div class="info-value email">{{ $user->email ?? 'Non défini' }}</div>
                    </div>

                    <div class="info-card">
                        <div class="info-label">ID Utilisateur</div>
                        <div class="info-value">#{{ $user->id ?? 'N/A' }}</div>
                    </div>

                    <div class="info-card">
                        <div class="info-label">Email vérifié</div>
                        <div class="info-value">
                            @if($user->email_verified_at ?? false)
                                <span style="color: var(--green);">✓ Vérifié</span>
                            @else
                                <span style="color: var(--orange);">⚠ Non vérifié</span>
                            @endif
                        </div>
                    </div>

                    <div class="info-card">
                        <div class="info-label">Date de création</div>
                        <div class="info-value date">
                            {{ $user->created_at ? $user->created_at->format('d/m/Y à H:i') : 'Non disponible' }}
                        </div>
                    </div>

                    <div class="info-card">
                        <div class="info-label">Dernière mise à jour</div>
                        <div class="info-value date">
                            {{ $user->updated_at ? $user->updated_at->format('d/m/Y à H:i') : 'Non disponible' }}
                        </div>
                    </div>
                </div>

                <div class="account-stats">
                    <div class="account-stat-card">
                        <div class="account-stat-value">{{ $user->created_at ? $user->created_at->diffForHumans() : 'N/A' }}</div>
                        <div class="account-stat-label">Compte créé</div>
                    </div>
                    <div class="account-stat-card orange">
                        <div class="account-stat-value">{{ $user->email_verified_at ? 'Oui' : 'Non' }}</div>
                        <div class="account-stat-label">Email vérifié</div>
                    </div>
                    <div class="account-stat-card green">
                        <div class="account-stat-value">Actif</div>
                        <div class="account-stat-label">Statut du compte</div>
                    </div>
                </div>

                <div class="account-actions">
                    <button class="btn-account primary" onclick="editAccount()">
                        <i class="fas fa-edit"></i> Modifier le profil
                    </button>
                    <button class="btn-account secondary" onclick="changePassword()">
                        <i class="fas fa-key"></i> Changer le mot de passe
                    </button>
                    <form method="POST" action="{{ route('logout') }}" style="display: inline;">
                        @csrf
                        <button type="submit" class="btn-account danger">
                            <i class="fas fa-sign-out-alt"></i> Déconnexion
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Assign Team Modal -->
    <div id="assign-modal" class="assign-modal-overlay" onclick="if(event.target === this) closeAssignModal()">
        <div class="assign-modal">
            <div class="assign-modal-header">
                <div>
                    <div class="assign-modal-title">Affecter une équipe</div>
                    <div id="assign-location" class="assign-modal-location"></div>
                </div>
                <button type="button" class="assign-modal-close" onclick="closeAssignModal()">&times;</button>
            </div>
            <div class="assign-modal-body">
                <div class="assign-modal-select-wrap">
                    <label class="assign-modal-label">Équipe d'intervention</label>
                    <select id="assign-team-select" class="status-select" style="width: 100%;">
                        <option value="">Sélectionner une équipe</option>
                        <option value="equipe_1">Equipe 1</option>
                        <option value="equipe_2">Equipe 2</option>
                        <option value="equipe_3">Equipe 3</option>
                        <option value="equipe_5">Equipe 5</option>
                    </select>
                    <div class="assign-modal-extra">Choisissez l'équipe la plus adaptée à ce type d'incident.</div>
                </div>
                <div class="assign-modal-description-box">
                    <p><strong>Description :</strong> <span id="assign-description"></span></p>
                    <p style="margin-top: 10px;">
                        <strong>Coût estimé (à saisir par l'admin) :</strong>
                        <input
                            id="assign-cost-input"
                            type="text"
                            class="assign-cost-input"
                            inputmode="decimal"
                            autocomplete="off"
                            placeholder="Ex: 35 000 DNT"
                            required
                        >
                    </p>
                </div>
            </div>
            <div class="assign-modal-footer">
                <button type="button" class="assign-btn cancel" onclick="closeAssignModal()">Annuler</button>
                <button type="button" class="assign-btn primary" onclick="confirmAssign()">Affecter</button>
            </div>
        </div>
    </div>
</div>

<script>
    function showSection(sectionId, navItem) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.remove('active');
        });
        
        // Remove active class from all nav items
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        // Show selected section
        const section = document.getElementById('section-' + sectionId);
        if (section) {
            section.classList.add('active');
        }
        
        // Add active class to clicked nav item
        if (navItem) {
            navItem.classList.add('active');
        }
        
        // Update page title and breadcrumb
        const titles = {
            'dashboard': { title: 'Tableau de Bord', breadcrumb: 'Trig-Essalama / <span>Dashboard</span>' },
            'problemes': { title: 'Problèmes de Voirie', breadcrumb: 'Trig-Essalama / <span>Problèmes de Voirie</span>' },
            'analyse': { title: 'Analyse', breadcrumb: 'Trig-Essalama / <span>Analyse</span>' },
            'equipes': { title: 'Équipes d\'intervention', breadcrumb: 'Trig-Essalama / <span>Équipes</span>' }
        };
        
        if (titles[sectionId]) {
            const titleEl = document.querySelector('.page-title h2');
            const breadcrumbEl = document.querySelector('.page-breadcrumb');
            if (titleEl) titleEl.textContent = titles[sectionId].title;
            if (breadcrumbEl) breadcrumbEl.innerHTML = titles[sectionId].breadcrumb;
        }
        
    }

    function showAccountInfo() {
        const accountSection = document.getElementById('account-info');
        if (accountSection) {
            accountSection.classList.toggle('show');
            if (accountSection.classList.contains('show')) {
                accountSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        }
    }

    function editAccount() {
        alert('Fonctionnalité de modification du profil à venir...');
    }

    function changePassword() {
        alert('Fonctionnalité de changement de mot de passe à venir...');
    }

    let currentAssignTeamSpan = null;
    let currentAssignButton = null;
    let currentAssignProblemId = '';

    function openAssignModal(button) {
        const overlay = document.getElementById('assign-modal');
        if (!overlay) return;

        const locEl = document.getElementById('assign-location');
        const descEl = document.getElementById('assign-description');
        const costInput = document.getElementById('assign-cost-input');
        const teamSelect = document.getElementById('assign-team-select');
        const location = button?.dataset?.location || '';
        const description = button?.dataset?.description || '';
        const cost = button?.dataset?.cost || '';

        // cibler la cellule Équipe de la ligne cliquée
        currentAssignTeamSpan = null;
        currentAssignButton = button || null;
        currentAssignProblemId = button?.dataset?.problemId || '';
        if (button) {
            const row = button.closest('tr');
            if (row) {
                currentAssignTeamSpan = row.querySelector('.team-value');
            }
        }

        if (locEl) locEl.textContent = location || '';
        if (descEl) descEl.textContent = description || '';
        if (costInput) {
            const raw = (cost || '').trim();
            const useless = /^(n\/?a|—|-)$/i.test(raw);
            costInput.value = (!useless && raw) ? raw : '';
        }
        if (teamSelect) teamSelect.value = '';

        overlay.classList.add('show');
        document.body.style.overflow = 'hidden';
    }

    function closeAssignModal() {
        const overlay = document.getElementById('assign-modal');
        if (!overlay) return;
        overlay.classList.remove('show');
        document.body.style.overflow = '';
    }

    function escapeHtmlBudgetCell(text) {
        if (text == null) return '';
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function formatBudgetAmountFr(n) {
        var v = Math.round(Number(n) || 0);
        return v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }

    function refreshBudgetEntreeKpi(summary) {
        if (!summary || typeof summary !== 'object') return;
        var initial = summary.income_initial != null ? Number(summary.income_initial) : null;
        var spent = summary.total_spent != null ? Number(summary.total_spent) : null;
        var remaining = summary.income_remaining != null ? Number(summary.income_remaining) : null;
        if (remaining == null && initial != null && spent != null) {
            remaining = Math.max(0, initial - spent);
        }
        document.querySelectorAll('[data-budget-kpi-root]').forEach(function (root) {
            var remainingEl = root.querySelector('[data-budget-income-remaining]');
            var initialEl = root.querySelector('[data-budget-income-initial]');
            var spentEl = root.querySelector('[data-budget-income-spent]');
            var spentLine = root.querySelector('[data-budget-income-spent-line]');
            if (remainingEl && remaining != null) {
                remainingEl.textContent = formatBudgetAmountFr(remaining);
            }
            if (initialEl && initial != null) {
                initialEl.textContent = formatBudgetAmountFr(initial);
            }
            if (spentEl && spent != null) {
                spentEl.textContent = spent > 0 ? ('−' + formatBudgetAmountFr(spent)) : '0';
                if (spentLine) spentLine.style.display = spent > 0 ? '' : 'none';
            }
            if (initial != null) root.setAttribute('data-income-initial', String(initial));
            if (remaining != null) root.setAttribute('data-income-remaining', String(remaining));
            if (spent != null) root.setAttribute('data-total-spent', String(spent));
        });
    }

    async function confirmAssign() {
        const teamSelect = document.getElementById('assign-team-select');
        const costInput = document.getElementById('assign-cost-input');
        const assignBtn = document.querySelector('#assign-modal .assign-btn.primary');

        if (!teamSelect || !costInput) return;

        const selectedValue = teamSelect.value || '';
        const selectedText = teamSelect.options[teamSelect.selectedIndex]?.text || '';
        const newCost = (costInput.value || '').trim();

        if (!selectedValue || !selectedText) {
            alert("Veuillez sélectionner une équipe avant de confirmer.");
            return;
        }

        if (!newCost) {
            alert("Veuillez saisir le coût estimé avant d'affecter l'équipe.");
            return;
        }

        if (!currentAssignProblemId) {
            alert("Identifiant du problème manquant. Rafraîchissez la page puis réessayez.");
            return;
        }

        if (assignBtn) {
            assignBtn.disabled = true;
            assignBtn.textContent = 'Affectation...';
        }

        try {
            const res = await fetch(`/problems/${encodeURIComponent(currentAssignProblemId)}/assign-team`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({
                    team_key: selectedValue,
                    team_label: selectedText,
                    cost: newCost
                })
            });

            const payload = await res.json().catch(() => ({}));
            if (!res.ok || payload?.success !== true) {
                throw new Error(payload?.message || "Impossible d'affecter l'équipe pour le moment.");
            }

            if (currentAssignTeamSpan) {
                currentAssignTeamSpan.textContent = selectedText;
            }
            if (currentAssignButton) {
                currentAssignButton.dataset.cost = newCost;
            }
            const assignRow = currentAssignButton ? currentAssignButton.closest('tr') : null;
            document.querySelectorAll('tr[data-problem-id="' + currentAssignProblemId + '"] td.problem-cout-cell').forEach(function (coutCell) {
                if (newCost) {
                    coutCell.innerHTML = '<span class="cout-estime-value" title="Coût estimé saisi par l\'administrateur">'
                        + escapeHtmlBudgetCell(newCost) + '</span>';
                }
            });
            if (payload.budget_summary) {
                refreshBudgetEntreeKpi(payload.budget_summary);
            }
            closeAssignModal();
        } catch (e) {
            alert(e?.message || "Erreur lors de l'affectation.");
        } finally {
            if (assignBtn) {
                assignBtn.disabled = false;
                assignBtn.textContent = 'Affecter';
            }
        }
    }

    function switchAnalyseTab(tabId, btn) {
        // Boutons
        document.querySelectorAll('.analyse-tab-btn').forEach(b => b.classList.remove('active'));
        if (btn) {
            btn.classList.add('active');
        }

        // Panels
        document.querySelectorAll('.analyse-tab-panel').forEach(panel => {
            if (panel.getAttribute('data-analyse-panel') === tabId) {
                panel.classList.add('active');
            } else {
                panel.classList.remove('active');
            }
        });
    }

    function handleStatusChange(event) {
        // Désactivé: la persistance se fait via updateProblemStatus()
    }

    // ── Progress bars ──
    function initProgressBars() {
        setTimeout(() => {
            document.querySelectorAll('.prog-fill').forEach(el => {
                if (el.dataset.w) el.style.width = el.dataset.w + '%';
            });
        }, 600);
    }

    // ── Counters ──
    function animateCount(el, target, delay) {
        setTimeout(() => {
            let t0 = null;
            const dur = 900;
            const step = ts => {
                if (!t0) t0 = ts;
                const p = Math.min((ts - t0) / dur, 1);
                el.textContent = Math.round((1 - Math.pow(1 - p, 3)) * target);
                if (p < 1) requestAnimationFrame(step);
            };
            requestAnimationFrame(step);
        }, delay);
    }

    function initCounters() {
        document.querySelectorAll('.snum[data-count]').forEach((el, i) => {
            animateCount(el, +el.dataset.count, 900 + i * 130);
        });
    }

    // Mise à jour des cartes « En attente / En cours / Terminés » depuis l’API
    async function refreshDashboardProblemStats() {
        const els = {
            en_attente: document.getElementById('stat-en-attente'),
            en_cours: document.getElementById('stat-en-cours'),
            termine: document.getElementById('stat-termine'),
        };
        try {
            const res = await fetch('/api/problems/stats', { headers: { 'Accept': 'application/json' }});
            const json = await res.json();
            if (!res.ok || !json.success) throw new Error(json.message || 'fetch failed');
            const d = json.data || {};
            Object.entries(els).forEach(([key, el]) => {
                if (!el || typeof d[key] !== 'number') return;
                el.textContent = d[key];
            });
        } catch (e) {
            console.warn('Stats refresh error:', e.message);
        }
    }

    // Auto-refresh des KPI depuis /api/problems/stats
    function startStatsAutoRefresh() {
        refreshDashboardProblemStats();
        setInterval(refreshDashboardProblemStats, 10000); // toutes les 10s
    }

    function toggleProfileMenu(event) {
        event.stopPropagation();
        var menu = document.getElementById('tb-profile-menu');
        if (!menu) return;
        menu.classList.toggle('show');
    }

    function closeProfileMenu() {
        var menu = document.getElementById('tb-profile-menu');
        if (menu) menu.classList.remove('show');
    }

    function apToggleEdit(section) {
        var fields = document.getElementById('apIdentityFields');
        var btn = document.getElementById('apIdentityToggle');
        if (!fields || !btn || section !== 'identity') return;
        fields.classList.toggle('editing');
        btn.classList.toggle('active', fields.classList.contains('editing'));
        btn.textContent = fields.classList.contains('editing') ? 'Fermer' : 'Modifier';
    }

    function apCancelEdit(section) {
        var fields = document.getElementById('apIdentityFields');
        var btn = document.getElementById('apIdentityToggle');
        if (!fields || !btn || section !== 'identity') return;
        fields.classList.remove('editing');
        btn.classList.remove('active');
        btn.textContent = 'Modifier';
    }

    function apSaveEdit(section) {
        if (section !== 'identity') return;
        var fields = document.getElementById('apIdentityFields');
        if (!fields) return;
        var values = fields.querySelectorAll('.ap-val');
        var inputs = fields.querySelectorAll('.ap-input');
        inputs.forEach(function(input, idx) {
            if (values[idx]) values[idx].textContent = input.value;
        });
        var first = inputs[0] ? inputs[0].value.trim() : '';
        var last = inputs[1] ? inputs[1].value.trim() : '';
        var full = (first + ' ' + last).trim() || 'Administrateur';
        var display = document.getElementById('apDisplayName');
        var avatar = document.getElementById('apAvatar');
        var letter = document.getElementById('apAvatarLetter');
        if (display) display.textContent = full;
        if (avatar && !avatar.classList.contains('has-image') && letter) {
            letter.textContent = ((first[0] || 'U') + (last[0] || '')).toUpperCase();
        }
        apCancelEdit('identity');
    }

    // ── Extend existing showSection to sync both navs ──
    var _originalShowSection = window.showSection;
    window.showSection = function(sectionId, navItem) {
        if (_originalShowSection) _originalShowSection(sectionId, navItem);

        // sync sidebar
        document.querySelectorAll('.sb-item').forEach(i => i.classList.remove('active'));
        if (navItem) navItem.classList.add('active');

        // update topbar title
        var titles = {
            'dashboard': { title: 'Tableau de Bord',       crumb: 'Dashboard' },
            'problemes': { title: 'Problèmes de Voirie',   crumb: 'Problèmes de Voirie' },
            'analyse':   { title: 'Analyse',               crumb: 'Analyse' },
            'equipes':   { title: 'Équipes d\'intervention', crumb: 'Équipes' },
            'budget':    { title: 'Budget',                crumb: 'Budget' },
            'profile':   { title: 'Profil Administrateur', crumb: 'Profil' }
        };
        if (titles[sectionId]) {
            var t = document.getElementById('tb-title');
            var c = document.getElementById('tb-crumb');
            if (t) t.textContent = titles[sectionId].title;
            if (c) c.textContent = titles[sectionId].crumb;
        }

        if (window.history && window.history.replaceState) {
            try {
                var url = new URL(window.location.href);
                if (sectionId === 'dashboard') {
                    url.searchParams.delete('section');
                } else {
                    url.searchParams.set('section', sectionId);
                }
                window.history.replaceState({}, '', url.pathname + url.search + url.hash);
            } catch (e) { /* ignore */ }
        }
    };

    window.addEventListener('load', function() {
        if (window.location.hash === '#account-info') {
            showAccountInfo();
        }
        var params = new URLSearchParams(window.location.search);
        var requestedSection = params.get('section') || 'dashboard';
        var allowedSections = ['dashboard', 'problemes', 'analyse', 'equipes', 'budget'];
        if (allowedSections.indexOf(requestedSection) === -1) {
            requestedSection = 'dashboard';
        }
        var requestedNav = document.querySelector('.sb-item[onclick*="' + requestedSection + '"]')
            || document.querySelector('.nav-item.active');
        showSection(requestedSection, requestedNav);
        var requestedTab = params.get('tab');
        if (requestedSection === 'analyse' && requestedTab && typeof switchAnalyseTab === 'function') {
            var tabBtn = document.querySelector('[data-analyse-tab="' + requestedTab + '"]');
            if (tabBtn) {
                switchAnalyseTab(requestedTab, tabBtn);
            }
        }

        // Les changements de statut sont gérés par updateProblemStatus()

        // Initialize animations
        initProgressBars();
        initCounters();

        // Démarrer l'auto-refresh des KPI
        startStatsAutoRefresh();

        document.addEventListener('click', function(event) {
            var wrap = document.querySelector('.tb-profile-wrap');
            if (!wrap) return;
            if (!wrap.contains(event.target)) {
                closeProfileMenu();
            }
        });

        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') {
                closeProfileMenu();
            }
        });
    });
</script>
<script>
(function () {
    var FALLBACK = { lat: 36.8065, lon: 10.1815, label: 'Tunis (position par défaut)' };

    function $(id) { return document.getElementById(id); }

    function setLoading(isLoading) {
        var btn = $('wx-refresh');
        if (btn) btn.disabled = !!isLoading;
        if (isLoading) {
            ['wx-temp', 'wx-precip', 'wx-flood', 'wx-wind'].forEach(function (id) {
                var el = $(id);
                if (el) { el.textContent = '…'; el.className = 'weather-value'; }
            });
        }
    }

    function applyValueClasses(precipEl, floodEl, level) {
        precipEl.className = 'weather-value';
        floodEl.className = 'weather-value';
        if (level === 'high') {
            precipEl.classList.add('high');
            floodEl.classList.add('high');
        } else if (level === 'medium') {
            precipEl.classList.add('medium');
            floodEl.classList.add('medium');
        }
    }

    function setSatLoading(isLoading) {
        var btn = $('sat-refresh');
        if (btn) btn.disabled = !!isLoading;
        if (isLoading) {
            ['sat-last-update', 'sat-zones', 'sat-anomalies'].forEach(function (id) {
                var el = $(id);
                if (el) el.textContent = '…';
            });
            var rh = $('sat-radius-hint');
            var ch = $('sat-cloud-hint');
            if (rh) rh.textContent = '…';
            if (ch) ch.textContent = '…';
        }
    }

    async function loadSatellite(lat, lon) {
        var errEl = $('sat-error');
        var statusEl = $('sat-status');
        if (!$('sat-last-update')) return;

        setSatLoading(true);
        if (errEl) { errEl.style.display = 'none'; errEl.textContent = ''; }
        if (statusEl) statusEl.textContent = 'Analyse en cours…';

        try {
            var url = '/satellite/dashboard-summary/' + encodeURIComponent(lat) + '/' + encodeURIComponent(lon);
            var res = await fetch(url, { headers: { 'Accept': 'application/json' } });
            var data = await res.json().catch(function () { return {}; });
            if (!res.ok) {
                throw new Error(data.error || ('Erreur ' + res.status));
            }

            var lu = $('sat-last-update');
            var z = $('sat-zones');
            var a = $('sat-anomalies');
            if (lu) lu.textContent = data.last_update_relative || '—';
            if (z) z.textContent = data.monitored_zones_count != null ? String(data.monitored_zones_count) : '—';
            if (a) {
                a.textContent = data.anomalies_count != null ? String(data.anomalies_count) : '—';
                a.className = 'satellite-value orange';
            }
            var radHint = $('sat-radius-hint');
            var cloudHint = $('sat-cloud-hint');
            if (radHint) {
                radHint.textContent = data.radius_km != null
                    ? 'Rayon ' + data.radius_km + ' km autour de votre position'
                    : '—';
            }
            if (cloudHint) {
                cloudHint.textContent = data.cloud_cover_pct != null
                    ? 'Couverture nuageuse (modèle) ' + data.cloud_cover_pct + '%'
                    : 'Couverture nuageuse (modèle) —';
            }
            if (statusEl) statusEl.textContent = '';
        } catch (e) {
            if (errEl) {
                errEl.style.display = 'block';
                errEl.textContent = e.message || 'Impossible de charger l’analyse satellite.';
            }
        } finally {
            setSatLoading(false);
        }
    }

    async function loadWeather(lat, lon, sourceLabel) {
        var statusEl = $('wx-status');
        var errEl = $('wx-error');
        var precipEl = $('wx-precip');
        var floodEl = $('wx-flood');
        if (!precipEl || !floodEl) return;

        setLoading(true);
        if (errEl) { errEl.style.display = 'none'; errEl.textContent = ''; }
        if (statusEl) statusEl.textContent = sourceLabel || ('Mise à jour… ' + lat.toFixed(3) + ', ' + lon.toFixed(3));

        try {
            var url = '/weather/dashboard-summary/' + encodeURIComponent(lat) + '/' + encodeURIComponent(lon);
            var res = await fetch(url, { headers: { 'Accept': 'application/json' } });
            var data = await res.json().catch(function () { return {}; });
            if (!res.ok) {
                throw new Error(data.error || ('Erreur ' + res.status));
            }

            var t = $('wx-temp');
            var w = $('wx-wind');
            if (t) t.textContent = data.temperature_c != null ? data.temperature_c + ' °C' : '—';
            if (w) w.textContent = data.wind_kmh != null ? data.wind_kmh + ' km/h' : '—';
            precipEl.textContent = data.precipitation_mm_h != null ? data.precipitation_mm_h + ' mm/h' : '—';
            floodEl.textContent = data.flood_risk_label || '—';
            applyValueClasses(precipEl, floodEl, data.flood_risk_level || 'low');

            if (statusEl) {
                statusEl.textContent = '';
                var mlat = data.latitude != null ? Number(data.latitude) : lat;
                var mlon = data.longitude != null ? Number(data.longitude) : lon;
                var mapUrl = 'https://www.openstreetmap.org/?mlat=' + encodeURIComponent(mlat) + '&mlon=' + encodeURIComponent(mlon) + '&zoom=12';
                var a = document.createElement('a');
                a.href = mapUrl;
                a.className = 'wx-status-link';
                a.target = '_blank';
                a.rel = 'noopener noreferrer';
                a.title = 'Ouvrir la position sur la carte (OpenStreetMap)';
                a.textContent = 'Position GPS (carte)';
                statusEl.appendChild(a);
                statusEl.appendChild(document.createTextNode(' · '));
                var c = document.createElement('span');
                c.className = 'wx-status-coords';
                c.textContent = mlat.toFixed(4) + '°, ' + mlon.toFixed(4) + '°';
                statusEl.appendChild(c);
                var timeStr = data.observed_at_fr || '';
                if (!timeStr && data.observed_at) {
                    try {
                        var d = new Date(String(data.observed_at).replace(' ', 'T'));
                        if (!isNaN(d.getTime())) {
                            timeStr = d.toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' });
                        }
                    } catch (e2) { /* ignore */ }
                }
                if (timeStr) {
                    statusEl.appendChild(document.createTextNode(' · '));
                    var t = document.createElement('span');
                    t.className = 'wx-status-time';
                    t.textContent = 'Observation : ' + timeStr;
                    statusEl.appendChild(t);
                }
            }
        } catch (e) {
            if (errEl) {
                errEl.style.display = 'block';
                errEl.textContent = e.message || 'Impossible de charger la météo.';
            }
            ['wx-temp', 'wx-precip', 'wx-flood', 'wx-wind'].forEach(function (id) {
                var el = $(id);
                if (el) { el.textContent = '—'; el.className = 'weather-value'; }
            });
        } finally {
            setLoading(false);
        }
    }

    /** Météo uniquement à la position GPS réelle (pas de coordonnées par défaut). */
    function runWithGpsPosition(lat, lon) {
        window.__dashboardGeo = { lat: lat, lon: lon, label: 'Votre position (GPS)', fromGps: true };
        loadWeather(lat, lon, 'Votre position (GPS)');
        loadSatellite(lat, lon);
    }

    function showWeatherWithoutGps(message) {
        window.__dashboardGeo = null;
        var statusEl = $('wx-status');
        var errEl = $('wx-error');
        var precipEl = $('wx-precip');
        var floodEl = $('wx-flood');
        var w = $('wx-wind');
        var tempEl = $('wx-temp');
        if (errEl) { errEl.style.display = 'none'; errEl.textContent = ''; }
        if (tempEl) { tempEl.textContent = '—'; tempEl.className = 'weather-value'; }
        if (precipEl) { precipEl.textContent = '—'; precipEl.className = 'weather-value'; }
        if (floodEl) { floodEl.textContent = '—'; floodEl.className = 'weather-value'; }
        if (w) { w.textContent = '—'; }
        if (statusEl) {
            statusEl.textContent = '';
            var span = document.createElement('span');
            span.className = 'wx-status-need-gps';
            span.textContent = message || 'Autorisez la géolocalisation pour afficher la météo à votre position.';
            statusEl.appendChild(span);
        }
        // Satellite : on garde un repli carte (Tunis) pour ne pas laisser le bloc vide
        loadSatellite(FALLBACK.lat, FALLBACK.lon);
    }

    function refreshFromGeolocation() {
        var statusEl = $('wx-status');
        if (statusEl) statusEl.textContent = 'Recherche de votre position…';

        if (!navigator.geolocation) {
            showWeatherWithoutGps('Géolocalisation non disponible dans ce navigateur. Utilisez « Actualiser » après avoir autorisé la position.');
            return;
        }

        navigator.geolocation.getCurrentPosition(
            function (pos) {
                var lat = pos.coords.latitude;
                var lon = pos.coords.longitude;
                runWithGpsPosition(lat, lon);
            },
            function () {
                showWeatherWithoutGps('Position GPS refusée ou indisponible. Autorisez la localisation pour ce site, puis cliquez sur « Actualiser ».');
            },
            { enableHighAccuracy: true, maximumAge: 0, timeout: 25000 }
        );
    }

    function init() {
        var box = $('weather-dashboard-widget');
        var satBox = $('satellite-dashboard-widget');
        if (!box && !satBox) return;
        var btn = $('wx-refresh');
        if (btn) btn.addEventListener('click', function () { refreshFromGeolocation(); });
        var satBtn = $('sat-refresh');
        if (satBtn) satBtn.addEventListener('click', function () {
            if (window.__dashboardGeo && typeof window.__dashboardGeo.lat === 'number') {
                loadSatellite(window.__dashboardGeo.lat, window.__dashboardGeo.lon);
            } else {
                refreshFromGeolocation();
            }
        });
        refreshFromGeolocation();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
</script>
<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.css">
<link rel="stylesheet" href="https://unpkg.com/leaflet.markercluster@1.5.3/dist/MarkerCluster.Default.css">
<script src="https://unpkg.com/leaflet.markercluster@1.5.3/dist/leaflet.markercluster.js"></script>
<script>
    async function updateProblemStatus(selectEl) {
        const id = selectEl?.dataset?.problemId || selectEl?.closest('tr')?.dataset?.problemId;
        const status = selectEl?.value;
        if (!id || !status) return;

        const previous = selectEl.dataset.previousStatus || '';
        const token = '{{ csrf_token() }}';
        try {
            const res = await fetch(`/problems/${encodeURIComponent(id)}/status`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({ status })
            });
            const data = await res.json().catch(function () { return {}; });
            if (!res.ok || !data.success) {
                throw new Error(data.message || 'Erreur lors de la mise à jour du statut');
            }
            selectEl.dataset.previousStatus = status;
            selectEl.style.boxShadow = '0 0 0 2px rgba(34,197,94,0.6)';
            setTimeout(function () { selectEl.style.boxShadow = ''; }, 800);
            if (typeof refreshDashboardProblemStats === 'function') {
                await refreshDashboardProblemStats();
            }
            if (status === 'termine') {
                const row = selectEl.closest('tr');
                const tbody = document.getElementById('problems-table-body');
                if (row) {
                    row.style.transition = 'opacity 0.2s ease, transform 0.2s ease';
                    row.style.opacity = '0';
                    row.style.transform = 'translateX(12px)';
                    setTimeout(function () {
                        row.remove();
                        renumberVisibleProblems();
                        if (tbody && !tbody.querySelector('tr[data-problem-id]')) {
                            tbody.innerHTML = '<tr><td colspan="10" style="text-align:center; color: var(--text2); padding: 24px;">Aucun problème en attente ou en cours.</td></tr>';
                        }
                    }, 220);
                }
            }
        } catch (err) {
            alert('Échec de la mise à jour du statut: ' + err.message);
            if (previous) {
                selectEl.value = previous;
            } else {
                window.location.reload();
            }
        }
    }

    function renumberVisibleProblems() {
        document.querySelectorAll('#problems-table-body tr[data-problem-id]').forEach(function (row, index) {
            var rank = index + 1;
            row.className = row.className.replace(/\bpriority-\d+\b/g, '').trim();
            row.classList.add('priority-' + Math.min(rank, 6));
            var circle = row.querySelector('.priority-circle');
            if (circle) {
                circle.textContent = String(rank);
            }
        });
    }

    (function initStatusSelectPrevious() {
        document.querySelectorAll('select.status-select').forEach(function (sel) {
            if (!sel.dataset.previousStatus) {
                sel.dataset.previousStatus = sel.value;
            }
        });
    })();
    // Initialize Leaflet map - Limited to Tunisia only
    var map = L.map('map', {
        center: [36.8, 10.1],
        zoom: 7,
        maxBounds: [
            [30.2, 7.5],   // Southwest corner (Sud-Ouest)
            [37.5, 11.6]   // Northeast corner (Nord-Est)
        ],
        maxBoundsViscosity: 1.0,  // Empêche complètement le déplacement hors des limites
        zoomControl: false,
        attributionControl: false
    });
    L.control.zoom({ position: 'bottomright' }).addTo(map);
    L.control.scale({ position: 'bottomleft', imperial: false }).addTo(map);
    
    // Tuiles OpenStreetMap — attribution masquée sur la carte (voir conditions d’usage OSM pour mentions légales ailleurs sur le site)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        minZoom: 6,
        maxZoom: 19
    }).addTo(map);
    
    // Stockage des marqueurs pour gestion dynamique
    var markers = [];
    var circles = [];
    var polylines = [];
    var clusterGroup = L.markerClusterGroup({
        showCoverageOnHover: false,
        spiderfyOnMaxZoom: true,
        maxClusterRadius: 50
    });
    map.addLayer(clusterGroup);
    
    // Custom icons for different types
    var mapIcons = {
        'alerte_active': L.divIcon({
            className: 'custom-icon',
            html: '<div style="width: 0; height: 0; border-left: 14px solid transparent; border-right: 14px solid transparent; border-bottom: 24px solid #FF6B35; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.25));"></div>',
            iconSize: [28, 24],
            iconAnchor: [14, 24]
        }),
        'chantier_en_cours': L.divIcon({
            className: 'custom-icon',
            html: '<div style="width: 28px; height: 22px; background: repeating-linear-gradient(45deg, #6B7280 0px, #6B7280 5px, #9CA3AF 5px, #9CA3AF 10px); border: 2px solid #4B5563; border-radius: 2px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);"></div>',
            iconSize: [28, 22],
            iconAnchor: [14, 11]
        }),
        'zone_inondable': L.divIcon({
            className: 'custom-icon',
            html: '<svg width="28" height="28" viewBox="0 0 28 28" xmlns="http://www.w3.org/2000/svg"><path d="M14 4C9.03 4 5 8.03 5 13c0 6 9 15 9 15s9-9 9-15c0-4.97-4.03-9-9-9zm0 11c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3z" fill="#1A1A1A" opacity="0.85"/><path d="M6 20c0-1.5 2-2.5 2-2.5s2 1 2 2.5-2 2.5-2 2.5-2-1-2-2.5z" fill="#1A1A1A"/><path d="M3 22 Q7 20 11 22 T19 22" stroke="#FF6B35" stroke-width="2" fill="none" stroke-linecap="round"/></svg>',
            iconSize: [28, 28],
            iconAnchor: [14, 14]
        }),
        'route_degradee': L.divIcon({
            className: 'custom-icon',
            html: '<div style="width: 0; height: 0; border-left: 12px solid transparent; border-right: 12px solid transparent; border-bottom: 20px solid #FF6B35; position: relative;"><span style="position: absolute; top: 4px; left: -6px; font-size: 14px; font-weight: bold; color: #1A1A1A;">!</span></div>',
            iconSize: [24, 20],
            iconAnchor: [12, 20]
        }),
        'circulation': L.divIcon({
            className: 'custom-icon',
            html: '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z" fill="#C2410C"/></svg>',
            iconSize: [24, 24],
            iconAnchor: [12, 12]
        })
    };
    
    // Fonction pour ajouter un marqueur dynamiquement
    function addMarker(type, lat, lng, popupText, id) {
        if (!mapIcons[type]) {
            console.error('Type d\'icône non trouvé:', type);
            return null;
        }
        
        var marker = L.marker([lat, lng], { icon: mapIcons[type] });
        clusterGroup.addLayer(marker);
        if (popupText) {
            marker.bindPopup(popupText);
        }
        
        var markerData = {
            id: id || Date.now(),
            type: type,
            marker: marker,
            lat: lat,
            lng: lng,
            popup: popupText
        };
        
        markers.push(markerData);
        return markerData;
    }

    // Problèmes / interventions (Mongo) — même source que la liste « triés par priorité »
    (function loadProblemesMarkersOnMap() {
        var items = @json($allDashboardMarkers ?? $mapMarkers ?? []);
        if (!Array.isArray(items) || items.length === 0) {
            return;
        }
        items.forEach(function (item) {
            var t = item.type || 'circulation';
            if (!mapIcons[t]) {
                t = 'circulation';
            }
            addMarker(t, item.lat, item.lng, item.popup || '', item.id);
        });
    })();
    
    // Fonction pour supprimer un marqueur
    function removeMarker(id) {
        var index = markers.findIndex(m => m.id === id);
        if (index !== -1) {
            map.removeLayer(markers[index].marker);
            markers.splice(index, 1);
            return true;
        }
        return false;
    }
    
    // Fonction pour ajouter un cercle dynamiquement
    function addCircle(lat, lng, radius, color, popupText, id) {
        var circle = L.circle([lat, lng], {
            color: color || 'red',
            radius: radius || 200
        }).addTo(map);
        
        if (popupText) {
            circle.bindPopup(popupText);
        }
        
        var circleData = {
            id: id || Date.now(),
            circle: circle,
            lat: lat,
            lng: lng,
            radius: radius,
            color: color,
            popup: popupText
        };
        
        circles.push(circleData);
        return circleData;
    }
    
    // Fonction pour supprimer un cercle
    function removeCircle(id) {
        var index = circles.findIndex(c => c.id === id);
        if (index !== -1) {
            map.removeLayer(circles[index].circle);
            circles.splice(index, 1);
            return true;
        }
        return false;
    }
    
    // Fonction pour ajouter une polyligne dynamiquement
    function addPolyline(coordinates, color, popupText, id) {
        var polyline = L.polyline(coordinates, {
            color: color || 'orange'
        }).addTo(map);
        
        if (popupText) {
            polyline.bindPopup(popupText);
        }
        
        var polylineData = {
            id: id || Date.now(),
            polyline: polyline,
            coordinates: coordinates,
            color: color,
            popup: popupText
        };
        
        polylines.push(polylineData);
        return polylineData;
    }
    
    // Fonction pour supprimer une polyligne
    function removePolyline(id) {
        var index = polylines.findIndex(p => p.id === id);
        if (index !== -1) {
            map.removeLayer(polylines[index].polyline);
            polylines.splice(index, 1);
            return true;
        }
        return false;
    }
    
    // Fonction pour charger les données depuis le backend
    function loadMapData(data) {
        // Supprimer tous les éléments existants
        clearMap();
        
        // Charger les marqueurs
        if (data.markers && Array.isArray(data.markers)) {
            data.markers.forEach(function(item) {
                addMarker(item.type, item.lat, item.lng, item.popup, item.id);
            });
        }
        
        // Charger les cercles
        if (data.circles && Array.isArray(data.circles)) {
            data.circles.forEach(function(item) {
                addCircle(item.lat, item.lng, item.radius, item.color, item.popup, item.id);
            });
        }
        
        // Charger les polylignes
        if (data.polylines && Array.isArray(data.polylines)) {
            data.polylines.forEach(function(item) {
                addPolyline(item.coordinates, item.color, item.popup, item.id);
            });
        }
    }
    
    // Fonction pour vider la carte
    function clearMap() {
        markers.forEach(function(m) { map.removeLayer(m.marker); });
        circles.forEach(function(c) { map.removeLayer(c.circle); });
        polylines.forEach(function(p) { map.removeLayer(p.polyline); });
        markers = [];
        circles = [];
        polylines = [];
    }
    
    fetch('/api/zones')
        .then(function(res) { return res.json(); })
        .then(function(data) {
            var points = [];

            data.forEach(function(z) {
                if (!Array.isArray(z.coordinates) || z.coordinates.length < 2) {
                    return;
                }

                var lat = Number(z.coordinates[1]);
                var lon = Number(z.coordinates[0]);
                if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
                    return;
                }

                var color = 'green';
                if (z.risk === 'high') color = 'red';
                if (z.risk === 'medium') color = 'orange';

                var circle = L.circle([lat, lon], {
                    color: color,
                    radius: 150
                }).addTo(map);

                var riskLabel = z.risk ? String(z.risk) : 'unknown';
                circle.bindPopup(
                    '<strong>Zone de risque</strong><br>' +
                    'Niveau: ' + riskLabel + '<br>' +
                    'Lat: ' + lat.toFixed(6) + ', Lon: ' + lon.toFixed(6)
                );

                points.push([lat, lon]);
            });

            if (points.length > 0) {
                map.fitBounds(points, { padding: [30, 30], maxZoom: 13 });
            }
        })
        .catch(function(error) {
            console.error('Erreur de chargement des zones:', error);
        });

    // Légende : blanc, texte noir, accent orange
    (function addLegend() {
        var legend = L.control({ position: 'topright' });
        legend.onAdd = function() {
            var div = L.DomUtil.create('div');
            div.style.background = '#FFFFFF';
            div.style.backdropFilter = 'blur(12px)';
            div.style.WebkitBackdropFilter = 'blur(12px)';
            div.style.border = '1px solid rgba(0,0,0,0.1)';
            div.style.boxShadow = '0 0 0 2px rgba(255,107,53,0.25), 0 8px 24px rgba(0,0,0,0.1)';
            div.style.borderRadius = '14px';
            div.style.padding = '12px 14px';
            div.style.color = '#0A0A0A';
            div.style.fontSize = '12px';
            div.style.fontWeight = '500';
            div.style.minWidth = '168px';
            div.innerHTML = '<div style="font-weight:800;color:#0A0A0A;margin-bottom:8px;font-size:11px;letter-spacing:0.06em;text-transform:uppercase;">Légende</div>'
              + '<div style="display:flex;align-items:center;gap:10px;margin:6px 0;"><span style="width:10px;height:10px;background:#FF6B35;display:inline-block;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,0.12);"></span> Alerte active</div>'
              + '<div style="display:flex;align-items:center;gap:10px;margin:6px 0;"><span style="width:10px;height:10px;background:#1A1A1A;display:inline-block;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,0.12);"></span> Zone inondable</div>'
              + '<div style="display:flex;align-items:center;gap:10px;margin:6px 0;"><span style="width:10px;height:10px;background:#6B7280;display:inline-block;border-radius:3px;box-shadow:0 1px 3px rgba(0,0,0,0.12);"></span> Chantier en cours</div>';
            return div;
        };
        legend.addTo(map);
    })();
    // Bouton « Ma position » : GPS réel (haute précision), pas la position IP/Wi‑Fi par défaut
    var userLocationLayerGroup = null;
    function clearUserLocationOverlay() {
        if (userLocationLayerGroup && map.hasLayer(userLocationLayerGroup)) {
            map.removeLayer(userLocationLayerGroup);
        }
        userLocationLayerGroup = null;
    }
    (function addGeolocate() {
        var btn = L.control({ position: 'bottomright' });
        btn.onAdd = function() {
            var div = L.DomUtil.create('div');
            div.innerHTML = '<button type="button" id="btnGeo" title="Ma position (GPS du navigateur — haute précision)" aria-label="Ma position GPS" style="width:42px;height:42px;border:1px solid rgba(255,107,53,0.45);background:linear-gradient(180deg,#1A1A1A 0%,#2d2d2d 100%);color:#FF925C;border-radius:50%;cursor:pointer;display:flex;align-items:center;justify-content:center;box-shadow:0 8px 24px rgba(0,0,0,0.15),inset 0 1px 0 rgba(255,255,255,0.12);padding:0;font-family:inherit;">'
                + '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><circle cx="12" cy="12" r="3" fill="currentColor"/><circle cx="12" cy="12" r="8" stroke="currentColor" stroke-width="1.5" fill="none"/><path stroke="currentColor" stroke-width="1.5" stroke-linecap="round" d="M12 2v3M12 19v3M2 12h3M19 12h3"/></svg>'
                + '</button>';
            return div;
        };
        btn.addTo(map);
        setTimeout(function(){
            var el = document.getElementById('btnGeo');
            if (el) {
                el.addEventListener('click', function(){
                    if (!navigator.geolocation) {
                        alert('Géolocalisation non supportée par ce navigateur.');
                        return;
                    }
                    el.disabled = true;
                    clearUserLocationOverlay();
                    navigator.geolocation.getCurrentPosition(function(pos){
                        el.disabled = false;
                        var lat = pos.coords.latitude;
                        var lon = pos.coords.longitude;
                        var acc = typeof pos.coords.accuracy === 'number' && isFinite(pos.coords.accuracy) ? pos.coords.accuracy : null;

                        userLocationLayerGroup = L.layerGroup().addTo(map);

                        if (acc !== null && acc > 0) {
                            L.circle([lat, lon], {
                                radius: acc,
                                color: '#FF6B35',
                                weight: 1,
                                fillColor: '#FF6B35',
                                fillOpacity: 0.12
                            }).addTo(userLocationLayerGroup);
                        }

                        var dot = L.circleMarker([lat, lon], {
                            radius: 7,
                            color: '#1A1A1A',
                            weight: 2,
                            fillColor: '#FF6B35',
                            fillOpacity: 1
                        }).addTo(userLocationLayerGroup);

                        var popupLines = [
                            '<strong>Votre position</strong> (navigateur / GPS)',
                            'lat: ' + lat.toFixed(6) + ', lon: ' + lon.toFixed(6)
                        ];
                        if (acc !== null && acc > 0) {
                            popupLines.push('Précision estimée : ±' + Math.round(acc) + ' m');
                            if (acc > 2000) {
                                popupLines.push('<small style="color:#b45309;">Position très approximative — attendez le GPS, sortez à l’air libre ou vérifiez les autorisations du site.</small>');
                            }
                        }
                        dot.bindPopup(popupLines.join('<br>'));

                        if (acc !== null && acc > 0) {
                            map.fitBounds(L.circle([lat, lon], { radius: acc }).getBounds(), { maxZoom: 16, padding: [24, 24] });
                        } else {
                            map.setView([lat, lon], 16);
                        }
                        dot.openPopup();
                    }, function(err){
                        el.disabled = false;
                        var msg = 'Impossible de récupérer votre position.';
                        if (err && err.code === 1) {
                            msg = 'Accès refusé : autorisez la localisation pour ce site (icône à gauche de la barre d’adresse), puis réessayez.';
                        } else if (err && err.code === 2) {
                            msg = 'Position indisponible (GPS ou réseau). Réessayez dehors ou plus tard.';
                        } else if (err && err.code === 3) {
                            msg = 'Délai dépassé : le GPS met parfois 20–30 s au premier fix. Réessayez à l’extérieur.';
                        }
                        alert(msg);
                    }, {
                        enableHighAccuracy: true,
                        maximumAge: 0,
                        timeout: 30000
                    });
                });
            }
        }, 100);
    })();
    
    // ============================================
    // SYSTÈME DE GESTION DYNAMIQUE DE LA CARTE
    // ============================================
    // Utilisation :
    // 
    // Ajouter un marqueur :
    //   mapManager.addMarker('alerte_active', 36.81, 10.17, 'Texte du popup', id);
    // 
    // Supprimer un marqueur :
    //   mapManager.removeMarker(id);
    // 
    // Ajouter un cercle :
    //   mapManager.addCircle(36.80, 10.18, 200, 'red', 'Zone dangereuse', id);
    // 
    // Ajouter une polyligne :
    //   mapManager.addPolyline([[36.80, 10.18], [36.81, 10.19]], 'orange', 'Route fermée', id);
    // 
    // Charger des données depuis le backend :
    //   mapManager.loadMapData({
    //     markers: [...],
    //     circles: [...],
    //     polylines: [...]
    //   });
    // 
    // Types disponibles : 'alerte_active', 'chantier_en_cours', 'zone_inondable', 'route_degradee', 'circulation'
    // ============================================
    
    // ============================================
    // INTÉGRATION MÉTÉO AVEC LA CARTE
    // ============================================
    
    // Stockage des zones météo
    var weatherZones = [];
    
    // Fonction pour récupérer les risques météo et afficher sur la carte
    function checkWeatherRisk(lat, lng, markerId) {
        fetch(`/weather-risk/${lat}/${lng}`)
            .then(response => response.json())
            .then(data => {
                var rain = data.precipitation || 0;
                var riskLevel = data.risk_level || 'normal';
                var message = data.message || 'Conditions normales';
                
                // Mettre à jour le popup du marqueur avec l'info météo
                var marker = markers.find(m => m.id === markerId);
                if (marker) {
                    var currentPopup = marker.popup || '';
                    marker.marker.setPopupContent(currentPopup + '<br><small style="color: #666;">🌧️ ' + message + ' (' + rain.toFixed(1) + 'mm)</small>');
                }
                
                // Afficher visuellement selon le niveau de risque
                if (riskLevel === 'inondation') {
                    // Zone bleue pour pluie forte / risque inondation
                    var floodZone = L.circle([lat, lng], {
                        color: '#1A1A1A',
                        fillColor: '#1A1A1A',
                        fillOpacity: 0.22,
                        radius: 500
                    }).addTo(map);
                    floodZone.bindPopup('⚠️ Risque inondation - ' + rain.toFixed(1) + 'mm de pluie');
                    weatherZones.push({ id: 'weather_' + markerId, layer: floodZone });
                    
                    // Marquer la route comme fermée si risque d'inondation
                    var closedRoute = L.polyline([
                        [lat - 0.01, lng - 0.01],
                        [lat, lng],
                        [lat + 0.01, lng + 0.01]
                    ], {
                        color: '#FF6B35',
                        weight: 5,
                        opacity: 0.85
                    }).addTo(map);
                    closedRoute.bindPopup('🚧 Route fermée - Risque inondation');
                    weatherZones.push({ id: 'route_' + markerId, layer: closedRoute });
                    
                } else if (riskLevel === 'route_mouillee') {
                    // Zone bleue claire pour route mouillée
                    var wetZone = L.circle([lat, lng], {
                        color: '#FF925C',
                        fillColor: '#FF925C',
                        fillOpacity: 0.22,
                        radius: 300
                    }).addTo(map);
                    wetZone.bindPopup('⚠️ Route mouillée - ' + rain.toFixed(1) + 'mm de pluie');
                    weatherZones.push({ id: 'weather_' + markerId, layer: wetZone });
                }
            })
            .catch(error => {
                console.error('Erreur lors de la récupération des données météo:', error);
            });
    }
    
    // Fonction pour vérifier la météo pour tous les marqueurs
    function checkWeatherForAllMarkers() {
        markers.forEach(function(marker) {
            // Attendre un peu entre chaque requête pour éviter de surcharger l'API
            setTimeout(function() {
                checkWeatherRisk(marker.lat, marker.lng, marker.id);
            }, markers.indexOf(marker) * 200);
        });
    }
    
    // Fonction pour vérifier la météo pour un marqueur spécifique
    function checkWeatherForMarker(markerId) {
        var marker = markers.find(m => m.id === markerId);
        if (marker) {
            checkWeatherRisk(marker.lat, marker.lng, markerId);
        }
    }
    
    // Fonction pour supprimer toutes les zones météo
    function clearWeatherZones() {
        weatherZones.forEach(function(zone) {
            map.removeLayer(zone.layer);
        });
        weatherZones = [];
    }
    
    // Vérifier la météo automatiquement après le chargement de la carte
    setTimeout(function() {
        // Vérifier la météo pour quelques marqueurs importants (pour éviter trop de requêtes)
        var importantMarkers = markers.slice(0, 10); // Premiers 10 marqueurs
        importantMarkers.forEach(function(marker, index) {
            setTimeout(function() {
                checkWeatherRisk(marker.lat, marker.lng, marker.id);
            }, index * 300);
        });
    }, 2000);
    
    // Exposer les fonctions globalement pour utilisation externe
    window.mapManager = {
        addMarker: addMarker,
        removeMarker: removeMarker,
        addCircle: addCircle,
        removeCircle: removeCircle,
        addPolyline: addPolyline,
        removePolyline: removePolyline,
        loadMapData: loadMapData,
        clearMap: clearMap,
        getMarkers: function() { return markers; },
        getCircles: function() { return circles; },
        getPolylines: function() { return polylines; },
        // Fonctions météo
        checkWeatherRisk: checkWeatherRisk,
        checkWeatherForAllMarkers: checkWeatherForAllMarkers,
        checkWeatherForMarker: checkWeatherForMarker,
        clearWeatherZones: clearWeatherZones
    };
</script>
@include('partials.equipes_chat')

@include('partials.theme-toggle')
</body>
</html>