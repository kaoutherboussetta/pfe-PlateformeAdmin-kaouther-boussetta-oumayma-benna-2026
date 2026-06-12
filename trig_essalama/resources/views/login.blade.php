<!DOCTYPE html>
<html lang="fr" class="trig-app trig-auth">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connexion - Trig-Essalama</title>
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --neon: #f4d03f;
            --neon2: #ff6b35;
            --dark: #060810;
            --card: #0a0e18;
            --surface: rgba(255, 255, 255, 0.045);
            --border: rgba(255, 215, 0, 0.14);
            --text: #f0f4ff;
            --muted: rgba(232, 240, 255, 0.48);
            --success: #f4d03f;
            --danger: #ff6b35;
            --radius: 14px;
            --radius-sm: 10px;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
            background: var(--dark);
            min-height: 100vh;
            display: flex;
            overflow-x: hidden;
            overflow-y: auto;
        }

        /* ===== LEFT PANEL ===== */
        .left-panel {
            flex: 1;
            position: relative;
            display: flex;
            align-items: center;
            justify-content: center;
            overflow: hidden;
            min-width: 0;
        }

        .left-panel video {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            object-fit: cover;
            transform: scale(1.02);
        }

        .left-aurora {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 1;
            background:
                radial-gradient(ellipse 80% 50% at 20% 40%, rgba(255, 107, 53, 0.22) 0%, transparent 55%),
                radial-gradient(ellipse 60% 40% at 80% 60%, rgba(244, 208, 63, 0.12) 0%, transparent 50%),
                radial-gradient(circle at 50% 100%, rgba(6, 8, 16, 0.9) 0%, transparent 45%);
        }

        .left-panel-overlay {
            position: absolute;
            inset: 0;
            z-index: 1;
            background: linear-gradient(115deg,
                rgba(6, 8, 16, 0.82) 0%,
                rgba(6, 8, 16, 0.55) 45%,
                rgba(10, 14, 24, 0.75) 100%);
        }

        .left-scan-lines {
            position: absolute;
            inset: 0;
            z-index: 1;
            opacity: 0.35;
            background: repeating-linear-gradient(
                0deg,
                transparent,
                transparent 3px,
                rgba(255, 215, 0, 0.02) 3px,
                rgba(255, 215, 0, 0.02) 6px
            );
            pointer-events: none;
            animation: scanMove 12s linear infinite;
        }
        @keyframes scanMove {
            0% { background-position: 0 0; }
            100% { background-position: 0 120px; }
        }

        .left-content {
            position: relative;
            z-index: 2;
            padding: clamp(32px, 5vw, 56px);
            text-align: left;
            max-width: 520px;
        }

        .brand-tag {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 10px 18px;
            border-radius: 100px;
            margin-bottom: 28px;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
        }
        .brand-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--neon), var(--neon2));
            box-shadow: 0 0 16px rgba(255, 107, 53, 0.65);
            animation: pulse 2.4s ease infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.75; transform: scale(0.92); }
        }
        .brand-tag span {
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.22em;
            text-transform: uppercase;
            color: rgba(255, 255, 255, 0.92);
        }

        .left-title { margin-bottom: 20px; }
        .title-kicker {
            display: block;
            font-size: 13px;
            font-weight: 600;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: rgba(255, 255, 255, 0.55);
            margin-bottom: 10px;
        }
        .title-main {
            display: block;
            font-family: 'Bebas Neue', sans-serif;
            font-size: clamp(3.25rem, 9vw, 5.75rem);
            line-height: 0.95;
            letter-spacing: 0.04em;
            background: linear-gradient(125deg, #ffffff 0%, var(--neon) 42%, var(--neon2) 100%);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
            filter: drop-shadow(0 12px 40px rgba(255, 107, 53, 0.25));
        }
        .title-accent {
            display: block;
            margin-top: 14px;
            font-size: 1.05rem;
            font-weight: 500;
            color: rgba(255, 255, 255, 0.78);
            line-height: 1.55;
            max-width: 28ch;
        }

        .left-desc {
            font-size: 15px;
            color: rgba(255, 255, 255, 0.72);
            line-height: 1.75;
            max-width: 400px;
            margin-bottom: 36px;
        }

        .feature-list {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }
        .feature-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 12px 16px;
            border-radius: var(--radius-sm);
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.06);
            backdrop-filter: blur(8px);
            transition: border-color 0.2s, background 0.2s;
        }
        .feature-item:hover {
            border-color: rgba(255, 215, 0, 0.15);
            background: rgba(255, 255, 255, 0.06);
        }
        .feature-icon {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            background: linear-gradient(145deg, rgba(255, 215, 0, 0.15), rgba(255, 107, 53, 0.1));
            border: 1px solid rgba(255, 215, 0, 0.2);
            flex-shrink: 0;
        }
        .feature-item span {
            font-size: 13px;
            font-weight: 500;
            color: rgba(255, 255, 255, 0.88);
        }

        .corner {
            position: absolute;
            width: 56px;
            height: 56px;
            z-index: 2;
            pointer-events: none;
        }
        .corner-tl {
            top: 24px;
            left: 24px;
            border-top: 2px solid rgba(244, 208, 63, 0.45);
            border-left: 2px solid rgba(244, 208, 63, 0.45);
            border-radius: 4px 0 0 0;
        }
        .corner-br {
            bottom: 24px;
            right: 24px;
            border-bottom: 2px solid rgba(255, 107, 53, 0.45);
            border-right: 2px solid rgba(255, 107, 53, 0.45);
            border-radius: 0 0 4px 0;
        }

        /* ===== DIVIDER ===== */
        .divider {
            width: 1px;
            flex-shrink: 0;
            position: relative;
            background: linear-gradient(
                180deg,
                transparent 0%,
                rgba(244, 208, 63, 0.35) 35%,
                rgba(255, 107, 53, 0.25) 65%,
                transparent 100%
            );
        }
        .divider-glow {
            position: absolute;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            width: 48px;
            height: 240px;
            background: radial-gradient(ellipse, rgba(244, 208, 63, 0.12) 0%, transparent 70%);
        }

        /* ===== RIGHT PANEL ===== */
        .right-panel {
            width: min(440px, 100%);
            flex-shrink: 0;
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 40px 40px 48px;
            overflow-y: auto;
            background:
                linear-gradient(165deg, rgba(14, 18, 30, 0.97) 0%, rgba(8, 10, 18, 0.99) 100%);
            border-left: 1px solid rgba(255, 255, 255, 0.06);
            box-shadow: -24px 0 80px rgba(0, 0, 0, 0.35);
        }

        .right-panel::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, var(--neon2), var(--neon), rgba(255, 255, 255, 0.35));
            opacity: 0.95;
        }

        .right-panel::after {
            content: '';
            position: absolute;
            inset: 0;
            pointer-events: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='56' height='48' viewBox='0 0 56 48'%3E%3Cpath d='M0 24 L14 0 L42 0 L56 24 L42 48 L14 48Z' fill='none' stroke='rgba(255,215,0,0.035)' stroke-width='1'/%3E%3C/svg%3E");
            background-size: 56px 48px;
        }

        .right-inner {
            position: relative;
            z-index: 2;
            width: 100%;
            max-width: 340px;
            margin: 0 auto;
        }

        .back-btn {
            position: absolute;
            top: 20px;
            left: 20px;
            z-index: 15;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 8px 14px 8px 12px;
            border-radius: 100px;
            font-size: 12px;
            font-weight: 600;
            color: var(--muted);
            text-decoration: none;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.08);
            transition: color 0.2s, border-color 0.2s, background 0.2s, transform 0.2s;
        }
        .back-btn:hover {
            color: var(--neon);
            border-color: rgba(244, 208, 63, 0.35);
            background: rgba(244, 208, 63, 0.08);
            transform: translateX(-2px);
        }

        .logo-sm {
            width: 88px;
            height: 88px;
            margin: 8px auto 22px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 22px;
            background: linear-gradient(145deg, rgba(255, 255, 255, 0.08), rgba(255, 255, 255, 0.02));
            border: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow:
                0 20px 48px rgba(0, 0, 0, 0.35),
                inset 0 1px 0 rgba(255, 255, 255, 0.1);
        }
        .logo-sm img {
            width: 70%;
            height: 70%;
            object-fit: contain;
            filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.3));
        }

        .form-header {
            text-align: center;
            margin-bottom: 26px;
        }
        .form-header .step-label {
            justify-content: center;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            color: var(--neon2);
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .form-header .step-label::before,
        .form-header .step-label::after {
            content: '';
            width: 24px;
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(255, 107, 53, 0.6));
        }
        .form-header .step-label::after {
            background: linear-gradient(90deg, rgba(255, 107, 53, 0.6), transparent);
        }
        .form-header h2 {
            font-family: 'Bebas Neue', sans-serif;
            font-size: 2.25rem;
            letter-spacing: 0.06em;
            color: var(--text);
            line-height: 1;
        }
        .form-header p {
            font-size: 13px;
            color: var(--muted);
            margin-top: 8px;
            font-weight: 500;
        }

        .alert {
            border-radius: var(--radius-sm);
            padding: 12px 14px;
            margin-bottom: 16px;
            font-size: 12px;
            font-weight: 500;
            line-height: 1.45;
        }
        .alert-error {
            background: rgba(255, 107, 53, 0.1);
            border: 1px solid rgba(255, 107, 53, 0.28);
            color: #ffb4a1;
        }
        .alert-success {
            background: rgba(244, 208, 63, 0.1);
            border: 1px solid rgba(244, 208, 63, 0.28);
            color: var(--neon);
        }

        form { position: relative; z-index: 1; }
        .form-group { margin-bottom: 16px; }
        .form-group label {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 10px;
            font-weight: 700;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.14em;
            margin-bottom: 8px;
        }
        .label-num {
            width: 20px;
            height: 20px;
            border-radius: 6px;
            background: rgba(244, 208, 63, 0.12);
            border: 1px solid rgba(244, 208, 63, 0.22);
            color: var(--neon);
            font-size: 10px;
            font-weight: 800;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .input-field {
            width: 100%;
            padding: 13px 40px 13px 14px;
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: var(--radius-sm);
            color: var(--text);
            font-family: inherit;
            font-size: 14px;
            font-weight: 500;
            transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
        }
        .input-field::placeholder {
            color: rgba(232, 240, 255, 0.28);
            font-weight: 400;
        }
        .input-field:focus {
            outline: none;
            border-color: rgba(244, 208, 63, 0.45);
            background: rgba(244, 208, 63, 0.05);
            box-shadow: 0 0 0 4px rgba(244, 208, 63, 0.08);
        }
        .input-field.valid { border-color: rgba(244, 208, 63, 0.35); }
        .input-field.invalid { border-color: rgba(255, 107, 53, 0.5); }

        select.input-field {
            cursor: pointer;
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 12 12'%3E%3Cpath fill='%23f4d03f' d='M6 9L1 4h10z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 14px center;
            padding-right: 40px;
        }
        select.input-field option {
            background: #0e121f;
            color: var(--text);
        }

        .input-wrap { position: relative; }
        .input-icon {
            position: absolute;
            right: 14px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 15px;
            pointer-events: none;
            opacity: 0.45;
        }
        .toggle-btn {
            position: absolute;
            right: 10px;
            top: 50%;
            transform: translateY(-50%);
            background: rgba(255, 255, 255, 0.06);
            border: none;
            color: var(--muted);
            cursor: pointer;
            padding: 6px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            z-index: 2;
            transition: color 0.2s, background 0.2s;
        }
        .toggle-btn:hover {
            color: var(--neon);
            background: rgba(244, 208, 63, 0.1);
        }

        .check-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            margin-bottom: 18px;
            flex-wrap: wrap;
        }
        .check-row input[type=checkbox] {
            width: 16px;
            height: 16px;
            flex-shrink: 0;
            accent-color: var(--neon);
            cursor: pointer;
        }
        .check-row label { font-size: 12px; color: var(--muted); cursor: pointer; }
        .check-row a {
            font-size: 12px;
            font-weight: 600;
            color: var(--neon2);
            text-decoration: none;
        }
        .check-row a:hover { text-decoration: underline; }
        .remember-me { display: flex; align-items: center; gap: 8px; }

        .btn-submit {
            width: 100%;
            padding: 15px 20px;
            border: none;
            border-radius: var(--radius-sm);
            font-family: 'Bebas Neue', sans-serif;
            font-size: 1.15rem;
            letter-spacing: 0.18em;
            cursor: pointer;
            position: relative;
            overflow: hidden;
            margin-bottom: 18px;
            color: #0a0c12;
            background: linear-gradient(135deg, var(--neon) 0%, #f39c12 48%, var(--neon2) 100%);
            background-size: 200% 200%;
            box-shadow:
                0 12px 40px rgba(255, 107, 53, 0.28),
                0 4px 0 rgba(0, 0, 0, 0.15);
            transition: transform 0.2s, box-shadow 0.25s, filter 0.2s;
        }
        .btn-submit:hover {
            transform: translateY(-2px);
            filter: brightness(1.05);
            box-shadow:
                0 18px 48px rgba(255, 107, 53, 0.38),
                0 4px 0 rgba(0, 0, 0, 0.12);
        }
        .btn-submit:active {
            transform: translateY(0);
        }
        .btn-submit span { position: relative; z-index: 1; }

        .register-link {
            text-align: center;
            font-size: 13px;
            color: var(--muted);
        }
        .register-link a {
            color: var(--neon);
            font-weight: 700;
            text-decoration: none;
        }
        .register-link a:hover { text-decoration: underline; }

        .scan-anim {
            position: absolute;
            left: 0;
            right: 0;
            height: 2px;
            z-index: 5;
            pointer-events: none;
            background: linear-gradient(90deg, transparent, rgba(244, 208, 63, 0.5), transparent);
            animation: scanY 7s ease-in-out infinite;
        }
        @keyframes scanY {
            0% { top: -8px; opacity: 0; }
            8% { opacity: 1; }
            92% { opacity: 0.4; }
            100% { top: 100%; opacity: 0; }
        }

        .form-group { animation: fadeUp 0.55s ease both; }
        form > .form-group:nth-child(1) { animation-delay: 0.06s; }
        form > .form-group:nth-child(2) { animation-delay: 0.1s; }
        form > .form-group:nth-child(3) { animation-delay: 0.14s; }
        form > .form-group:nth-child(4) { animation-delay: 0.18s; }
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(14px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .form-header { animation: fadeUp 0.5s ease both; }
        .logo-sm { animation: fadeUp 0.5s ease 0.04s both; }
        .check-row { animation: fadeUp 0.55s ease 0.22s both; }
        .btn-submit { animation: fadeUp 0.55s ease 0.26s both; }
        .register-link { animation: fadeUp 0.55s ease 0.3s both; }

        @media (max-width: 768px) {
            body { flex-direction: column; }
            .left-panel { min-height: 280px; flex-shrink: 0; }
            .left-content { padding: 28px 24px; }
            .title-main { font-size: clamp(2.5rem, 14vw, 3.5rem); }
            .divider { display: none; }
            .right-panel {
                width: 100%;
                border-left: none;
                border-top: 1px solid rgba(255, 255, 255, 0.06);
                padding: 36px 24px 40px;
                box-shadow: 0 -20px 60px rgba(0, 0, 0, 0.3);
            }
            .back-btn { top: 16px; left: 16px; }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>

    <div class="left-panel">
        <video autoplay muted loop playsinline>
            <source src="{{ asset('image/intro.mp4') }}" type="video/mp4">
        </video>
        <div class="left-aurora"></div>
        <div class="left-panel-overlay"></div>
        <div class="left-scan-lines"></div>

        <div class="corner corner-tl"></div>
        <div class="corner corner-br"></div>

        <div class="left-content">
            <div class="brand-tag">
                <div class="brand-dot"></div>
                <span>Trig-Essalama</span>
            </div>

            <h1 class="left-title">
                <span class="title-kicker">Plateforme nationale</span>
                <span class="title-main">TRIG-ESSALAMA</span>
                <span class="title-accent">Votre espace sécurisé pour la voirie et la sécurité des citoyens.</span>
            </h1>

            <p class="left-desc">
                Une connexion chiffrée, des accès contrôlés et un suivi transparent des signalements.
            </p>

            <div class="feature-list">
                <div class="feature-item">
                    <div class="feature-icon">🔐</div>
                    <span>Authentification renforcée et sessions protégées</span>
                </div>
                <div class="feature-item">
                    <div class="feature-icon">🛣️</div>
                    <span>Signalement et suivi des problèmes de voirie</span>
                </div>
                <div class="feature-item">
                    <div class="feature-icon">⚡</div>
                    <span>Interface pensée pour les équipes et les administrateurs</span>
                </div>
            </div>
        </div>
    </div>

    <div class="divider"><div class="divider-glow"></div></div>

    <div class="right-panel">
        <div class="scan-anim"></div>

        <a href="{{ route('register') }}" class="back-btn">← Inscription</a>

        <div class="right-inner">
            <div class="logo-sm">
                <img src="{{ asset('image/logo.png') }}" alt="Logo Trig-Essalama">
            </div>

            <div class="form-header">
                <div class="step-label">Accès sécurisé</div>
                <h2>Connexion</h2>
                <p>Identifiez-vous pour accéder à la plateforme</p>
            </div>

            @if(session('error'))
                <div class="alert alert-error">{{ session('error') }}</div>
            @endif
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif

            <form id="loginForm" method="POST" action="{{ route('login.post') }}">
                @csrf

                <div class="form-group">
                    <label><span class="label-num">1</span>Type de compte</label>
                    <div class="input-wrap">
                        <select class="input-field" id="account_type" name="account_type" onchange="toggleSecurityCode()" required>
                            <option value="">Sélectionner un type</option>
                            <option value="technical" {{ old('account_type') == 'technical' ? 'selected' : '' }}>Administrateur Technique</option>
                            <option value="autoritaire" {{ old('account_type') == 'autoritaire' ? 'selected' : '' }}>Administrateur Autoritaire</option>
                        </select>
                        <span class="input-icon">👤</span>
                    </div>
                </div>

                <div class="form-group">
                    <label><span class="label-num">2</span>Email</label>
                    <div class="input-wrap">
                        <input class="input-field" type="email" id="email" name="email" value="{{ old('email') }}" placeholder="vous@exemple.tn" required autocomplete="email">
                        <span class="input-icon">✉️</span>
                    </div>
                </div>

                <div class="form-group">
                    <label><span class="label-num">3</span>Mot de passe</label>
                    <div class="input-wrap">
                        <input class="input-field" type="password" id="password" name="password" placeholder="••••••••" required autocomplete="current-password">
                        <button type="button" class="toggle-btn" onclick="togglePw('password',this)" aria-label="Afficher le mot de passe">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                </div>

                <div class="form-group" id="security_code_group" style="display: none;">
                    <label><span class="label-num">4</span>Code de sécurité</label>
                    <div class="input-wrap">
                        <input class="input-field" type="password" id="security_code" name="security_code" value="{{ old('security_code') }}" placeholder="••••••••" maxlength="8" style="text-transform:uppercase;letter-spacing:5px;font-weight:700;font-size:15px;">
                        <button type="button" class="toggle-btn" onclick="togglePw('security_code',this)" aria-label="Afficher le code">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                    <small style="color: var(--muted); font-size: 11px; margin-top: 6px; display: block;">Code à 8 caractères — accès administrateur</small>
                </div>

                <div class="check-row">
                    <div class="remember-me">
                        <input type="checkbox" id="remember" name="remember">
                        <label for="remember">Se souvenir de moi</label>
                    </div>
                    <a href="{{ route('forgot-password') }}">Mot de passe oublié ?</a>
                </div>

                <button type="submit" class="btn-submit"><span>SE CONNECTER →</span></button>
            </form>

            <div class="register-link">
                Pas encore de compte ? <a href="{{ route('register') }}">Créer un compte</a>
            </div>
        </div>
    </div>

    <script>
        function togglePw(id, btn) {
            const input = document.getElementById(id);
            const isText = input.type === 'text';
            input.type = isText ? 'password' : 'text';
            btn.style.color = isText ? '' : 'var(--neon)';
        }

        function toggleSecurityCode() {
            const accountType = document.getElementById('account_type').value;
            const securityCodeGroup = document.getElementById('security_code_group');
            const securityCodeInput = document.getElementById('security_code');

            if (accountType === 'technical' || accountType === 'autoritaire') {
                securityCodeGroup.style.display = 'block';
                securityCodeInput.required = true;
            } else {
                securityCodeGroup.style.display = 'none';
                securityCodeInput.required = false;
                securityCodeInput.value = '';
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            toggleSecurityCode();
            const securityCodeInput = document.getElementById('security_code');
            if (securityCodeInput) {
                securityCodeInput.addEventListener('input', function() {
                    this.value = this.value.toUpperCase();
                });
            }
        });

        document.getElementById('loginForm').addEventListener('submit', function(e) {
            const accountType = document.getElementById('account_type').value;
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const securityCode = document.getElementById('security_code').value;

            if (!accountType) {
                e.preventDefault();
                showError('Veuillez sélectionner un type de compte.');
                return false;
            }

            if (!email || !password) {
                e.preventDefault();
                showError('Veuillez remplir tous les champs.');
                return false;
            }

            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                e.preventDefault();
                showError('Veuillez entrer une adresse email valide.');
                return false;
            }

            if (password.length < 6) {
                e.preventDefault();
                showError('Le mot de passe doit contenir au moins 6 caractères.');
                return false;
            }

            if (!securityCode) {
                e.preventDefault();
                showError('Le code de sécurité est requis.');
                return false;
            }

            if (securityCode.length !== 8) {
                e.preventDefault();
                showError('Le code de sécurité doit contenir exactement 8 caractères.');
                return false;
            }
        });

        function showError(message) {
            let alert = document.querySelector('.alert-error');
            if (!alert) {
                alert = document.createElement('div');
                alert.className = 'alert alert-error';
                const form = document.getElementById('loginForm');
                form.parentNode.insertBefore(alert, form);
            }
            alert.textContent = message;
        }

        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('registered') === 'true') {
            const alert = document.createElement('div');
            alert.className = 'alert alert-success';
            alert.textContent = 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.';
            const form = document.getElementById('loginForm');
            form.parentNode.insertBefore(alert, form);
        }
    </script>
@include('partials.theme-toggle')
</body>
</html>
