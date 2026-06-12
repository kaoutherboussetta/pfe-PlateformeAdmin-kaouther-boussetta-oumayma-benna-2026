        *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

        :root {
            --orange: #FF6B35;
            --orange-light: #FF8C5A;
            --orange-dark: #C2410C;
            --orange-glow: rgba(255, 107, 53, 0.22);
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

        /* MAIN */
        .main { flex: 1; display: flex; flex-direction: column; min-width: 0; overflow: hidden; }
        .page-title { display: flex; align-items: center; }
        .page-title h2 { font-size: 17px; font-weight: 700; color: var(--text); }
        .page-breadcrumb { font-size: 12px; color: var(--text2); margin-left: 12px; }
        .page-breadcrumb span { color: var(--orange); }
        .topbar-actions { display: flex; align-items: center; gap: 10px; }
        .topbar-btn { width: 38px; height: 38px; border-radius: 9px; background: var(--surface); border: 1px solid var(--border); color: var(--text2); display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; font-size: 14px; position: relative; text-decoration: none; }
        .topbar-btn:hover { background: var(--surface2); color: var(--text); border-color: var(--border-accent); }
        .notif-dot { position: absolute; top: 7px; right: 7px; width: 7px; height: 7px; border-radius: 50%; background: var(--orange); border: 2px solid var(--bg2); animation: blink 2s ease-in-out infinite; }
        @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.4} }
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
        .stat-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 14px; }
        .stat-label { font-size: 10px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: var(--text3); }
        .stat-icon-wrap { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
        .stat-card.orange .stat-icon-wrap { background: rgba(255,107,53,0.15); color: var(--orange); }
        .stat-card.yellow .stat-icon-wrap { background: rgba(255,146,92,0.18); color: var(--yellow); }
        .stat-card.cyan .stat-icon-wrap { background: rgba(26,26,26,0.08); color: var(--cyan); }
        .stat-value { font-family: 'Bebas Neue', sans-serif; font-size: 40px; letter-spacing: 2px; line-height: 1; }
        .stat-card.orange .stat-value { color: var(--orange); }
        .stat-card.yellow .stat-value { color: var(--yellow); }
        .stat-card.cyan .stat-value { color: var(--cyan); }
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

        /* LAYOUT */
        .layout-grid { display: grid; grid-template-columns: 1fr 290px; gap: 18px; align-items: start; }

        /* CARD */
        .card { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; overflow: hidden; transition: border-color 0.2s; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
        .card:hover { border-color: rgba(255,107,53,0.25); }
        .card-head { padding: 15px 20px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; background: rgba(0,0,0,0.03); gap: 10px; flex-wrap: wrap; }
        .card-title-wrap { display: flex; align-items: center; gap: 9px; }
        .card-icon { width: 30px; height: 30px; border-radius: 8px; background: rgba(255,107,53,0.12); color: var(--orange); display: flex; align-items: center; justify-content: center; font-size: 12px; }
        .card-title { font-size: 14px; font-weight: 700; color: var(--text); }

        .btn-create { display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; border-radius: 8px; background: var(--orange); color: #fff; font-size: 12px; font-weight: 700; border: none; cursor: pointer; transition: all 0.2s; box-shadow: 0 0 14px rgba(255,107,53,0.3); white-space: nowrap; }
        .btn-create:hover { background: var(--orange-light); transform: translateY(-1px); }

        /* TABLE */
        .table-wrap { overflow-x: auto; }
        .table-wrap::-webkit-scrollbar { height: 4px; }
        .table-wrap::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.12); border-radius: 2px; }
        .table-wrap--citizens-scroll {
            max-height: min(52vh, 440px);
            overflow-y: auto;
            overflow-x: auto;
        }
        .table-wrap--citizens-scroll thead th {
            position: sticky;
            top: 0;
            z-index: 2;
            background: var(--bg3);
            box-shadow: 0 1px 0 var(--border);
        }
        .table-wrap--citizens-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
        .table-wrap--citizens-scroll::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 4px; }
        table { width: 100%; border-collapse: separate; border-spacing: 0; }
        thead tr { background: rgba(0,0,0,0.04); }
        th { padding: 10px 14px; font-size: 10px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: var(--text3); text-align: left; white-space: nowrap; border-bottom: 1px solid var(--border); }
        td { padding: 12px 14px; font-size: 12.5px; color: var(--text2); border-bottom: 1px solid rgba(0,0,0,0.06); vertical-align: middle; }
        tbody tr { transition: background 0.15s; }
        tbody tr:hover { background: rgba(255,107,53,0.04); }
        tbody tr:last-child td { border-bottom: none; }
        .admin-row-clickable:hover { background: rgba(255,107,53,0.08) !important; }
        .td-name { font-weight: 600; color: var(--text); }
        .td-email { font-family: monospace; font-size: 11.5px; color: var(--text3); }
        .td-clip { max-width: 130px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; display: block; }

        .badge { display: inline-flex; align-items: center; gap: 5px; padding: 4px 9px; border-radius: 20px; font-size: 10px; font-weight: 700; letter-spacing: 0.5px; text-transform: uppercase; white-space: nowrap; }
        .badge::before { content:'●'; font-size: 7px; }
        .badge-orange { background: rgba(255,107,53,0.12); color: var(--orange-dark); border: 1px solid rgba(255,107,53,0.35); }
        .badge-yellow { background: rgba(255,146,92,0.12); color: var(--orange-dark); border: 1px solid rgba(255,146,92,0.35); }
        .badge-green { background: rgba(234,88,12,0.12); color: var(--orange-dark); border: 1px solid rgba(234,88,12,0.35); }

        .actions { display: flex; gap: 5px; align-items: center; flex-wrap: nowrap; }
        .btn-act { width: 27px; height: 27px; border-radius: 7px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; font-size: 11px; cursor: pointer; transition: all 0.2s; border: 1px solid var(--border); background: var(--bg3); color: var(--text2); }
        .btn-act:hover { color: var(--text); border-color: rgba(0,0,0,0.15); background: var(--surface2); }
        .btn-act.danger { border-color: rgba(0,0,0,0.2); color: var(--black-soft); }
        .btn-act.danger:hover { background: rgba(0,0,0,0.06); border-color: rgba(0,0,0,0.3); }
        .btn-sm-text { padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: 600; cursor: pointer; transition: all 0.2s; border: 1px solid var(--border); background: var(--bg3); color: var(--text); white-space: nowrap; }
        .btn-sm-text:hover { border-color: rgba(0,0,0,0.15); background: var(--surface2); }

        /* SEARCH */
        .search-container { position: relative; width: 240px; }
        .search-input { width: 100%; padding: 8px 32px 8px 32px; border-radius: 8px; background: var(--bg2); border: 1px solid var(--border); color: var(--text); font-size: 12px; transition: all 0.2s; }
        .search-input:focus { outline: none; border-color: var(--orange); box-shadow: 0 0 0 3px rgba(255,107,53,0.1); }
        .search-input::placeholder { color: var(--text3); }
        .search-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--text3); font-size: 11px; pointer-events: none; }
        .search-clear { position: absolute; right: 8px; top: 50%; transform: translateY(-50%); background: transparent; border: none; color: var(--text3); cursor: pointer; padding: 3px; display: none; transition: color 0.2s; }
        .search-clear:hover { color: var(--text); }
        .client-count { font-size: 11px; color: var(--text2); font-weight: 600; white-space: nowrap; }

        /* RIGHT PANEL */
        .right-col { display: flex; flex-direction: column; gap: 16px; }
        .card-body { padding: 18px 20px; }
        .info-row { display: flex; justify-content: space-between; align-items: center; padding: 11px 14px; border-radius: 9px; background: var(--surface); border: 1px solid var(--border); transition: all 0.2s; margin-bottom: 8px; }
        .info-row:last-of-type { margin-bottom: 0; }
        .info-row:hover { border-color: rgba(255,107,53,0.3); background: rgba(255,107,53,0.04); }
        .info-row-label { font-size: 11.5px; color: var(--text2); font-weight: 500; display: flex; align-items: center; gap: 7px; }
        .info-row-label i { color: var(--orange); width: 13px; }
        .info-row-val { font-size: 12px; font-weight: 700; color: var(--text); white-space: nowrap; }
        .storage-bar { height: 5px; border-radius: 3px; background: rgba(0,0,0,0.06); overflow: hidden; margin-top: 12px; }
        .storage-fill { height: 100%; border-radius: 3px; background: linear-gradient(90deg, var(--orange), var(--yellow)); }
        .storage-info { display: flex; justify-content: space-between; margin-top: 6px; font-size: 10.5px; color: var(--text3); }
        .btn-full { width: 100%; padding: 11px 14px; border-radius: 9px; border: none; background: linear-gradient(135deg, var(--orange), #C84B1F); color: #fff; font-size: 12px; font-weight: 700; cursor: pointer; margin-top: 14px; display: flex; align-items: center; justify-content: center; gap: 7px; transition: all 0.2s; box-shadow: 0 0 16px rgba(255,107,53,0.25); }
        .btn-full:hover { transform: translateY(-2px); box-shadow: 0 0 28px rgba(255,107,53,0.45); }

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

        /* MODAL */
        .modal-overlay { position: fixed; inset: 0; z-index: 1000; background: rgba(0,0,0,0.45); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; opacity: 0; pointer-events: none; transition: opacity 0.25s ease; }
        .modal-overlay.active { opacity: 1; pointer-events: all; }
        .modal { background: var(--bg3); border: 1px solid var(--border); border-radius: 14px; width: 90%; max-width: 500px; max-height: 90vh; overflow-y: auto; transform: scale(0.92); transition: transform 0.3s; box-shadow: 0 20px 60px rgba(0,0,0,0.12); }
        #profileModal .modal { max-width: 1200px; }
        .modal-overlay.active .modal { transform: scale(1); }
        .modal-header { padding: 20px 24px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; background: rgba(0,0,0,0.03); }
        .modal-title { font-size: 16px; font-weight: 700; color: var(--text); }
        .modal-close { width: 30px; height: 30px; border-radius: 7px; background: var(--surface); border: 1px solid var(--border); color: var(--text2); display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; font-size: 12px; }
        .modal-close:hover { background: var(--surface2); color: var(--text); border-color: var(--border-accent); }
        .modal-body { padding: 22px 24px; }
        .form-group { margin-bottom: 17px; }
        .form-label { display: block; font-size: 11px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase; color: var(--text3); margin-bottom: 6px; }
        .form-input { width: 100%; padding: 11px 13px; border-radius: 9px; background: var(--surface); border: 1px solid var(--border); color: var(--text); font-size: 13px; transition: all 0.2s; }
        .form-input:focus { outline: none; border-color: var(--orange); box-shadow: 0 0 0 3px rgba(255,107,53,0.1); }
        .form-input::placeholder { color: var(--text3); }
        .form-actions { display: flex; gap: 10px; margin-top: 20px; justify-content: flex-end; }
        .btn-modal { padding: 10px 18px; border-radius: 8px; font-size: 13px; font-weight: 700; cursor: pointer; transition: all 0.2s; border: none; }
        .btn-modal-cancel { background: var(--surface); border: 1px solid var(--border); color: var(--text2); }
        .btn-modal-cancel:hover { background: var(--surface2); color: var(--text); }
        .btn-modal-submit { background: var(--orange); color: #fff; box-shadow: 0 0 16px rgba(255,107,53,0.3); }
        .btn-modal-submit:hover { background: var(--orange-light); }
        .form-error { color: var(--orange-dark); font-size: 11px; margin-top: 5px; display: flex; align-items: center; gap: 5px; }

        /* ===============================
           PROFILE MODAL - VERSION PREMIUM
        ================================ */

        .profile-layout {
            display: grid;
            grid-template-columns: 320px 1fr;
            gap: 24px;
            padding: 30px;
        }

        /* ================= CARD ================= */
        .profile-card {
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 22px;
            padding: 25px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }

        /* ================= AVATAR ================= */
        .profile-avatar {
            width: 100px;
            height: 100px;
            border-radius: 25px;
            background: linear-gradient(135deg, #FF6B35, #FFD38C);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 30px;
            margin: auto;
            color: #fff;
            font-weight: 700;
        }

        /* ================= TEXT ================= */
        .profile-name {
            text-align: center;
            font-weight: bold;
            margin-top: 10px;
            color: var(--text);
            font-size: 18px;
        }

        .profile-email {
            text-align: center;
            font-size: 12px;
            color: var(--text2);
            margin-top: 4px;
        }

        /* ================= ROLE ================= */
        .profile-role {
            text-align: center;
            margin-top: 8px;
            font-size: 12px;
            color: var(--text2);
        }

        /* ================= META ================= */
        .profile-meta {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 20px;
        }

        .profile-meta-item {
            background: var(--surface);
            border: 1px solid var(--border);
            padding: 10px;
            border-radius: 10px;
        }

        .profile-meta-label {
            font-size: 10px;
            color: var(--text3);
            margin-bottom: 4px;
        }

        .profile-meta-value {
            font-size: 13px;
            font-weight: 600;
            color: var(--text);
        }

        /* ================= BUTTONS ================= */
        .profile-actions {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-top: 20px;
        }

        .btn-profile {
            width: 100%;
            padding: 10px;
            border-radius: 10px;
            border: none;
            margin-top: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 600;
            transition: all 0.2s;
        }

        .btn-profile.primary {
            background: var(--orange);
            color: #fff;
        }

        .btn-profile.primary:hover {
            background: var(--orange-light);
            transform: translateY(-1px);
        }

        .btn-profile.secondary {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
        }

        .btn-profile.secondary:hover {
            background: var(--surface2);
            border-color: var(--border-accent);
        }

        /* ================= SECTION ================= */
        .profile-section {
            margin-bottom: 30px;
        }

        .profile-section-title {
            margin-bottom: 10px;
            font-weight: bold;
            font-size: 16px;
            color: var(--text);
        }

        /* ================= FIELDS ================= */
        .profile-field-label {
            font-size: 11px;
            color: var(--text3);
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .profile-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }

        .profile-field-value {
            background: var(--surface);
            border: 1px solid var(--border);
            padding: 10px;
            border-radius: 10px;
            color: var(--text);
            font-size: 13px;
        }

        /* ================= ACTIVITY ================= */
        .activity-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .activity-item {
            background: var(--surface);
            border: 1px solid var(--border);
            padding: 10px;
            margin-bottom: 8px;
            border-radius: 10px;
            color: var(--text);
            font-size: 13px;
        }

        /* ================= RESPONSIVE ================= */
        @media (max-width: 1300px) { .layout-grid { grid-template-columns: 1fr; } }
        @media (max-width: 900px) {
            .sidebar { display: none; }
            .content { padding: 16px; }
            .topbar { padding: 0 16px; }
            .profile-layout { 
                grid-template-columns: 1fr;
                padding: 20px;
            }
            .profile-card { order: -1; }
        }
        @media (max-width: 640px) {
            .stats-grid { grid-template-columns: 1fr; }
            .search-container { width: 100%; }
            .profile-grid { grid-template-columns: 1fr; }
        }

        a.nav-item { text-decoration: none; color: inherit; -webkit-tap-highlight-color: transparent; }
        a.nav-item:visited { color: inherit; }
        .nav-item--link { cursor: pointer; }
        .nav-item--link span { pointer-events: none; }
