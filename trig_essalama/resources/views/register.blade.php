<!DOCTYPE html>
<html lang="fr" class="trig-app trig-auth">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Créer un compte - Trig-Essalama</title>
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=Bebas+Neue&display=swap" rel="stylesheet">
    <style>
        :root {
            --neon: #ffd700;
            --neon2: #ff6b35;
            --dark: #060810;
            --card: #0c0f1a;
            --surface: rgba(255,255,255,0.04);
            --border: rgba(255,215,0,0.12);
            --text: #e8f0ff;
            --muted: rgba(232,240,255,0.4);
            --success: #ffd700;
            --danger: #ff6b35;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Space Grotesk', sans-serif;
            background: var(--dark);
            min-height: 100vh;
            display: flex;
            overflow: hidden;
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
            position: absolute; inset: 0;
            width: 100%; height: 100%; object-fit: cover;
        }

        .left-panel-overlay {
            position: absolute; inset: 0;
            background: linear-gradient(135deg, rgba(6,8,16,0.65) 0%, rgba(255,215,0,0.03) 50%, rgba(255,107,53,0.05) 100%);
        }

        .left-scan-lines {
            position: absolute; inset: 0;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(255,215,0,0.03) 2px, rgba(255,215,0,0.03) 4px);
            pointer-events: none;
            animation: scanMove 8s linear infinite;
        }
        @keyframes scanMove { 0%{background-position:0 0;} 100%{background-position:0 100px;} }

        .left-content {
            position: relative; z-index: 2;
            padding: 40px 40px 40px 50px;
            text-align: left;
        }

        .brand-tag {
            display: inline-flex; align-items: center; gap: 8px;
            background: rgba(0,0,0,0.4); border: 1px solid rgba(255,215,0,0.3);
            padding: 8px 16px; border-radius: 30px; margin-bottom: 32px;
            backdrop-filter: blur(10px);
        }
        .brand-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--neon2); box-shadow: 0 0 12px var(--neon2); animation: pulse 2s ease infinite; }
        @keyframes pulse { 0%,100%{opacity:1;} 50%{opacity:0.5;} }
        .brand-tag span { font-size: 12px; letter-spacing: 2.5px; text-transform: uppercase; color: #fff; font-weight: 600; }

        .left-title {
            font-family: 'Bebas Neue', sans-serif;
            font-size: clamp(48px, 6vw, 84px);
            line-height: 1.1;
            color: #fff;
            margin-bottom: 24px;
            letter-spacing: 2px;
            font-weight: 700;
        }
        .left-title .glitch {
            color: #fff;
            text-shadow: 0 0 20px rgba(255,255,255,0.3);
            display: block;
        }
        .left-title .accent { 
            color: var(--neon); 
            text-shadow: 0 0 30px rgba(255,215,0,0.6), 0 0 60px rgba(255,215,0,0.3); 
            display: block; 
            font-weight: 700;
        }
        .left-title .accent2 { 
            color: var(--neon2); 
            text-shadow: 0 0 30px rgba(255,107,53,0.6), 0 0 60px rgba(255,107,53,0.3); 
            display: block; 
            font-weight: 700;
        }

        .left-desc { 
            font-size: 15px; 
            color: rgba(255,255,255,0.9); 
            line-height: 1.8; 
            max-width: 380px; 
            margin-bottom: 40px;
            font-weight: 400;
            text-shadow: 0 2px 10px rgba(0,0,0,0.3);
        }

        .feature-list { display: flex; flex-direction: column; gap: 16px; }
        .feature-item { display: flex; align-items: center; gap: 14px; }
        .feature-line {
            width: 32px; height: 2px;
            background: linear-gradient(90deg, var(--neon) 0%, rgba(255,215,0,0.6) 50%, transparent 100%);
            box-shadow: 0 0 8px rgba(255,215,0,0.4);
            flex-shrink: 0;
        }
        .feature-item span { 
            font-size: 13px; 
            color: rgba(255,255,255,0.85); 
            letter-spacing: 0.2px;
            font-weight: 400;
            text-shadow: 0 1px 5px rgba(0,0,0,0.2);
        }

        /* Glitch text effect */
        .glitch {
            position: relative;
        }
        .glitch::before, .glitch::after {
            content: attr(data-text);
            position: absolute; top: 0; left: 0;
            font-family: 'Bebas Neue', sans-serif;
            font-size: inherit; line-height: inherit;
            color: inherit;
        }
        .glitch::before {
            color: var(--neon2);
            animation: glitch1 4s infinite linear;
            clip-path: polygon(0 0, 100% 0, 100% 35%, 0 35%);
            opacity: 0;
        }
        .glitch::after {
            color: var(--neon);
            animation: glitch2 4s infinite linear;
            clip-path: polygon(0 65%, 100% 65%, 100% 100%, 0 100%);
            opacity: 0;
        }
        @keyframes glitch1 { 0%,94%,100%{transform:translate(0);opacity:0;} 95%{transform:translate(-3px,1px);opacity:0.7;} 97%{transform:translate(3px,-1px);opacity:0.7;} 99%{transform:translate(-2px,2px);opacity:0.7;} }
        @keyframes glitch2 { 0%,94%,100%{transform:translate(0);opacity:0;} 95%{transform:translate(3px,-2px);opacity:0.7;} 97%{transform:translate(-3px,1px);opacity:0.7;} 99%{transform:translate(2px,-2px);opacity:0.7;} }

        /* Corner decorations */
        .corner { position: absolute; width: 30px; height: 30px; }
        .corner-tl { top: 20px; left: 20px; border-top: 2px solid var(--neon); border-left: 2px solid var(--neon); }
        .corner-br { bottom: 20px; right: 20px; border-bottom: 2px solid var(--neon2); border-right: 2px solid var(--neon2); }

        /* ===== DIVIDER ===== */
        .divider {
            width: 1px;
            background: linear-gradient(180deg, transparent 0%, var(--neon) 30%, rgba(255,215,0,0.3) 70%, transparent 100%);
            position: relative; flex-shrink: 0;
        }
        .divider-glow { position: absolute; left: -20px; top: 50%; transform: translateY(-50%); width: 40px; height: 200px; background: radial-gradient(ellipse, rgba(255,215,0,0.1) 0%, transparent 70%); }

        /* ===== RIGHT PANEL ===== */
        .right-panel {
            width: 380px; flex-shrink: 0;
            background: var(--card);
            display: flex; flex-direction: column; justify-content: center;
            padding: 24px 28px;
            position: relative; overflow-y: auto;
        }

        .right-panel::before {
            content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
            background: linear-gradient(90deg, var(--neon2), var(--neon));
        }

        /* HEX pattern background */
        .right-panel::after {
            content: ''; position: absolute; inset: 0; pointer-events: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='60' height='52' viewBox='0 0 60 52'%3E%3Cpath d='M0 26 L15 0 L45 0 L60 26 L45 52 L15 52Z' fill='none' stroke='rgba(255,215,0,0.04)' stroke-width='1'/%3E%3C/svg%3E");
            background-size: 60px 52px;
        }

        .back-btn {
            position: absolute; top: 16px; left: 16px;
            width: 30px; height: 30px; border-radius: 6px;
            background: var(--surface); border: 1px solid var(--border);
            color: var(--muted); cursor: pointer; font-size: 14px;
            display: flex; align-items: center; justify-content: center;
            text-decoration: none; transition: all 0.3s; z-index: 10;
        }
        .back-btn:hover { background: rgba(255,215,0,0.08); border-color: rgba(255,215,0,0.4); color: var(--neon); transform: translateX(-2px); }

        /* Header */
        .form-header { margin-bottom: 20px; margin-top: 8px; position: relative; z-index: 1; }
        .form-header .step-label {
            font-size: 9px; letter-spacing: 2.5px; text-transform: uppercase;
            color: var(--neon); margin-bottom: 5px; display: flex; align-items: center; gap: 6px;
        }
        .step-label::before { content: ''; display: block; width: 18px; height: 1px; background: var(--neon); }
        .form-header h2 {
            font-family: 'Bebas Neue', sans-serif;
            font-size: 32px; letter-spacing: 1px; color: var(--text); line-height: 1;
        }
        .form-header p { font-size: 11px; color: var(--muted); margin-top: 4px; }

        /* Logo small */
        .logo-sm {
            width: 48px; height: 48px; position: absolute; top: 16px; right: 16px;
            background: rgba(255,215,0,0.05); border: 1px solid rgba(255,215,0,0.15);
            border-radius: 10px; display: flex; align-items: center; justify-content: center;
            padding: 6px;
        }
        .logo-sm img { width: 100%; height: 100%; object-fit: contain; border-radius: 8px; }

        /* Alert */
        .alert { border-radius: 6px; padding: 8px 10px; margin-bottom: 14px; font-size: 11px; position: relative; z-index: 1; }
        .alert-error { background: rgba(255,107,53,0.1); border: 1px solid rgba(255,107,53,0.3); color: #ff8c69; }
        .alert-success { background: rgba(255,215,0,0.08); border: 1px solid rgba(255,215,0,0.3); color: var(--neon); }

        /* Form */
        form { position: relative; z-index: 1; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
        .form-group { margin-bottom: 12px; }
        .form-group label {
            display: flex; align-items: center; gap: 5px;
            font-size: 9px; font-weight: 600; color: var(--muted);
            text-transform: uppercase; letter-spacing: 1.2px; margin-bottom: 6px;
        }
        .label-num {
            width: 14px; height: 14px; border-radius: 3px;
            background: rgba(255,215,0,0.1); border: 1px solid rgba(255,215,0,0.2);
            color: var(--neon); font-size: 8px; font-weight: 700;
            display: flex; align-items: center; justify-content: center;
        }

        .input-field {
            width: 100%; padding: 9px 36px 9px 12px;
            background: rgba(232,240,255,0.03);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 6px; color: var(--text);
            font-family: 'Space Grotesk', sans-serif; font-size: 12px;
            transition: all 0.25s; position: relative;
        }
        .input-field::placeholder { color: rgba(232,240,255,0.2); }
        .input-field:focus {
            outline: none;
            border-color: rgba(255,215,0,0.45);
            background: rgba(255,215,0,0.04);
            box-shadow: 0 0 0 3px rgba(255,215,0,0.06), inset 0 0 20px rgba(255,215,0,0.02);
        }
        .input-field.valid { border-color: rgba(255,215,0,0.35); }
        .input-field.invalid { border-color: rgba(255,107,53,0.45); }

        .input-wrap { position: relative; }
        .input-icon { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); font-size: 13px; pointer-events: none; opacity: 0.4; }
        .toggle-btn {
            position: absolute; right: 8px; top: 50%; transform: translateY(-50%);
            background: none; border: none; color: var(--muted); cursor: pointer;
            font-size: 13px; padding: 3px; display: flex; align-items: center; z-index: 2;
            transition: color 0.3s;
        }
        .toggle-btn:hover { color: var(--neon); }

        /* Strength */
        .strength-track { display: flex; gap: 3px; margin-top: 6px; }
        .strength-seg {
            flex: 1; height: 2.5px; border-radius: 2.5px;
            background: rgba(255,255,255,0.08); transition: all 0.4s;
        }

        .pw-pills { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 6px; }
        .pill {
            font-size: 9px; padding: 2px 7px; border-radius: 18px;
            background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08);
            color: rgba(232,240,255,0.35); transition: all 0.3s;
        }
        .pill.ok { background: rgba(255,215,0,0.08); border-color: rgba(255,215,0,0.3); color: var(--neon); }
        .pill.no { background: rgba(255,107,53,0.08); border-color: rgba(255,107,53,0.25); color: var(--neon2); }

        .match-line { font-size: 10px; margin-top: 4px; font-weight: 500; }

        .hint-text { font-size: 10px; color: rgba(232,240,255,0.3); margin-top: 4px; display: flex; align-items: center; gap: 4px; }

        /* Checkbox */
        .check-row { display: flex; align-items: flex-start; gap: 8px; margin-bottom: 14px; }
        .check-row input[type=checkbox] { width: 14px; height: 14px; flex-shrink: 0; margin-top: 1px; accent-color: var(--neon); cursor: pointer; }
        .check-row label { font-size: 10px; color: var(--muted); cursor: pointer; line-height: 1.4; }
        .check-row a { color: var(--neon); text-decoration: none; }
        .check-row a:hover { text-decoration: underline; }

        /* Submit */
        .btn-submit {
            width: 100%; padding: 11px;
            background: transparent;
            border: 1px solid var(--neon);
            border-radius: 6px; color: var(--neon);
            font-family: 'Bebas Neue', sans-serif;
            font-size: 16px; letter-spacing: 2.5px;
            cursor: pointer; position: relative; overflow: hidden;
            transition: all 0.3s; margin-bottom: 14px;
        }
        .btn-submit::before {
            content: ''; position: absolute; inset: 0;
            background: linear-gradient(135deg, rgba(255,215,0,0.15) 0%, rgba(255,215,0,0.05) 100%);
            transform: translateX(-101%); transition: transform 0.4s cubic-bezier(0.4,0,0.2,1);
        }
        .btn-submit::after {
            content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            box-shadow: inset 0 0 30px rgba(255,215,0,0.1);
            opacity: 0; transition: opacity 0.3s;
        }
        .btn-submit:hover::before { transform: translateX(0); }
        .btn-submit:hover::after { opacity: 1; }
        .btn-submit:hover { box-shadow: 0 0 25px rgba(255,215,0,0.25), 0 0 60px rgba(255,215,0,0.1); text-shadow: 0 0 15px rgba(255,215,0,0.8); }
        .btn-submit span { position: relative; z-index: 1; }

        .login-link { text-align: center; font-size: 11px; color: var(--muted); position: relative; z-index: 1; }
        .login-link a { color: var(--neon2); font-weight: 600; text-decoration: none; }
        .login-link a:hover { text-decoration: underline; }

        /* Scan line animation on card */
        .scan-anim {
            position: absolute; left: 0; right: 0; height: 2px; z-index: 5; pointer-events: none;
            background: linear-gradient(90deg, transparent, rgba(255,215,0,0.6), transparent);
            animation: scanY 6s ease-in-out infinite;
        }
        @keyframes scanY { 0%{top:-10px;opacity:0;} 5%{opacity:1;} 95%{opacity:0.5;} 100%{top:100%;opacity:0;} }

        /* Stagger */
        .form-group { animation: fadeUp 0.5s ease both; }
        .form-row .form-group:nth-child(1) { animation-delay: 0.1s; }
        .form-row .form-group:nth-child(2) { animation-delay: 0.15s; }
        form > .form-group:nth-child(2) { animation-delay: 0.2s; }
        form > .form-group:nth-child(3) { animation-delay: 0.25s; }
        form > .form-group:nth-child(4) { animation-delay: 0.3s; }
        form > .form-group:nth-child(5) { animation-delay: 0.35s; }
        @keyframes fadeUp { from{opacity:0;transform:translateY(16px);} to{opacity:1;transform:translateY(0);} }

        .form-header { animation: fadeUp 0.5s ease both 0.05s; }
        .check-row { animation: fadeUp 0.5s ease both 0.4s; }
        .btn-submit { animation: fadeUp 0.5s ease both 0.45s; }

        /* Mobile */
        @media (max-width: 768px) {
            body { flex-direction: column; overflow-y: auto; }
            .left-panel { min-height: 240px; flex-shrink: 0; }
            .left-title { font-size: 48px; }
            .divider { display: none; }
            .right-panel { width: 100%; flex-shrink: 0; padding: 22px 20px; }
        }
        @media (max-width: 480px) {
            .form-row { grid-template-columns: 1fr; }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>

    <!-- ===== LEFT PANEL ===== -->
    <div class="left-panel">
        <video autoplay muted loop playsinline>
        <source src="{{ asset('image/intro.mp4') }}" type="video/mp4">
    </video>
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
                <span class="glitch" data-text="REJOIGNEZ">REJOIGNEZ</span>
                <span class="accent">LA</span>
                <span class="accent2">PLATEFORME</span>
            </h1>

            <p class="left-desc">
                Accédez à un système sécurisé et performant. Créez votre compte et rejoignez notre réseau protégé.
            </p>

            <div class="feature-list">
                <div class="feature-item">
                    <div class="feature-line"></div>
                    <span>Authentification à double facteur</span>
                </div>
                <div class="feature-item">
                    <div class="feature-line"></div>
                    <span>Chiffrement de bout en bout</span>
                </div>
                <div class="feature-item">
                    <div class="feature-line"></div>
                    <span>Accès sécurisé par code unique</span>
                </div>
            </div>
        </div>
    </div>

    <!-- DIVIDER -->
    <div class="divider"><div class="divider-glow"></div></div>

    <!-- ===== RIGHT PANEL ===== -->
    <div class="right-panel">
        <div class="scan-anim"></div>

        <a href="{{ route('login') }}" class="back-btn">←</a>

        <div class="logo-sm">
            <img src="{{ asset('image/logo.png') }}" alt="Logo">
        </div>

        <div class="form-header">
            <div class="step-label">Nouvelle session</div>
            <h2>Créer un compte</h2>
            <p>Remplissez le formulaire pour commencer</p>
        </div>

        {{-- Message d'erreur général (code de sécurité invalide, MongoDB, etc.) --}}
        @if(session('error'))
            <div class="alert alert-error">{{ session('error') }}</div>
        @endif

        {{-- Toutes les erreurs de validation Laravel --}}
        @if($errors->any())
            <div class="alert alert-error">
                @foreach($errors->all() as $error)
                    <div>{{ $error }}</div>
                @endforeach
            </div>
        @endif
        @if(session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif

        <form method="POST" action="{{ route('register.post') }}">
            @csrf

            <!-- Prénom + Nom -->
            <div class="form-row form-group">
                <div class="form-group">
                    <label><span class="label-num">1</span>Prénom</label>
                    <div class="input-wrap">
                        <input class="input-field" type="text" name="first_name" value="{{ old('first_name') }}" placeholder="Prénom" required>
                        <span class="input-icon">👤</span>
                    </div>
                </div>
                <div class="form-group">
                    <label><span class="label-num">2</span>Nom</label>
                    <div class="input-wrap">
                        <input class="input-field" type="text" name="last_name" value="{{ old('last_name') }}" placeholder="Nom" required>
                        <span class="input-icon">👤</span>
                    </div>
                </div>
            </div>

            <!-- Email -->
            <div class="form-group">
                <label><span class="label-num">3</span>Email</label>
                <div class="input-wrap">
                    <input class="input-field" type="email" name="email" value="{{ old('email') }}" placeholder="exemple@email.com" required>
                    <span class="input-icon">✉️</span>
                </div>
            </div>

            <!-- Mot de passe -->
            <div class="form-group">
                <label><span class="label-num">4</span>Mot de passe</label>
                <div class="input-wrap">
                    <input class="input-field" type="password" id="password" name="password" placeholder="Mot de passe sécurisé" required>
                    <button type="button" class="toggle-btn" onclick="togglePw('password',this)">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
                <div class="strength-track">
                    <div class="strength-seg" id="s1"></div>
                    <div class="strength-seg" id="s2"></div>
                    <div class="strength-seg" id="s3"></div>
                    <div class="strength-seg" id="s4"></div>
                    <div class="strength-seg" id="s5"></div>
                    </div>
                <div class="pw-pills">
                    <span class="pill" id="c-len">8+ car.</span>
                    <span class="pill" id="c-up">A-Z</span>
                    <span class="pill" id="c-low">a-z</span>
                    <span class="pill" id="c-num">0-9</span>
                    <span class="pill" id="c-spe">!@#</span>
                </div>
                </div>

            <!-- Confirmation -->
            <div class="form-group">
                <label><span class="label-num">5</span>Confirmer</label>
                <div class="input-wrap">
                    <input class="input-field" type="password" id="password_confirmation" name="password_confirmation" placeholder="Répéter le mot de passe" required>
                    <button type="button" class="toggle-btn" onclick="togglePw('password_confirmation',this)">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
                <div class="match-line" id="match-line"></div>
            </div>

            <!-- Code de sécurité -->
            <div class="form-group">
                <label><span class="label-num">6</span>Code de sécurité</label>
                <div class="input-wrap">
                    <input class="input-field" type="password" id="security_code" name="security_code" value="{{ old('security_code') }}" placeholder="••••••••" maxlength="8" required style="text-transform:uppercase;letter-spacing:6px;font-weight:700;font-size:15px;">
                    <button type="button" class="toggle-btn" onclick="togglePw('security_code',this)">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                    </button>
                </div>
                <div class="hint-text">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                    Code administrateur à 8 caractères
                </div>
            </div>

            <!-- CGU -->
            <div class="check-row">
                <input type="checkbox" id="terms" name="terms" required>
                <label for="terms">J'accepte les <a href="#">conditions d'utilisation</a> et la <a href="#">politique de confidentialité</a></label>
            </div>

            <button type="submit" class="btn-submit"><span>S'inscrire →</span></button>
        </form>

        <div class="login-link">
            Déjà un compte ? <a href="{{ route('login') }}">Se connecter</a>
        </div>
    </div>

    <script>
        function togglePw(id, btn) {
            const input = document.getElementById(id);
            const isText = input.type === 'text';
            input.type = isText ? 'password' : 'text';
            btn.style.color = isText ? '' : 'var(--neon)';
        }

        const pw = document.getElementById('password');
        const conf = document.getElementById('password_confirmation');
        const segs = [document.getElementById('s1'),document.getElementById('s2'),document.getElementById('s3'),document.getElementById('s4'),document.getElementById('s5')];
        const colors = ['#ff6b35','#ff8c00','#ffa502','#ffd700','#ffed4e'];

        pw.addEventListener('input', function() {
            const v = this.value;
            const checks = {
                len: v.length >= 8,
                up: /[A-Z]/.test(v),
                low: /[a-z]/.test(v),
                num: /[0-9]/.test(v),
                spe: /[!@#$%&*?]/.test(v)
            };
            setPill('c-len', checks.len);
            setPill('c-up', checks.up);
            setPill('c-low', checks.low);
            setPill('c-num', checks.num);
            setPill('c-spe', checks.spe);

            const score = Object.values(checks).filter(Boolean).length;
            segs.forEach((s, i) => {
                s.style.background = i < score ? colors[score - 1] : 'rgba(255,255,255,0.08)';
                s.style.boxShadow = i < score ? `0 0 8px ${colors[score-1]}60` : 'none';
            });
            if (conf.value) checkMatch();
        });

        conf.addEventListener('input', checkMatch);

        function checkMatch() {
            const line = document.getElementById('match-line');
            const ok = conf.value === pw.value && conf.value;
            if (ok) {
                line.textContent = '✓ Les mots de passe correspondent';
                line.style.color = 'var(--neon)';
                conf.classList.add('valid'); conf.classList.remove('invalid');
            } else if (conf.value) {
                line.textContent = '✗ Les mots de passe ne correspondent pas';
                line.style.color = 'var(--neon2)';
                conf.classList.add('invalid'); conf.classList.remove('valid');
            } else {
                line.textContent = ''; conf.classList.remove('valid','invalid');
            }
        }

        function setPill(id, valid) {
            const el = document.getElementById(id);
            el.className = 'pill ' + (valid ? 'ok' : 'no');
        }

        document.getElementById('security_code').addEventListener('input', function() {
            this.value = this.value.toUpperCase();
        });
    </script>
@include('partials.theme-toggle')
</body>
</html>