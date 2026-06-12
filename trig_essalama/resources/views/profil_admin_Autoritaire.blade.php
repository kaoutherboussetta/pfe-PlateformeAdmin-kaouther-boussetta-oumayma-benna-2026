<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Profil Administrateur Autoritaire</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
<style>
    :root {
        --bg: #f4f4f5;
        --card: #ffffff;
        --text: #0a0a0a;
        --text2: #525252;
        --line: rgba(0, 0, 0, 0.1);
        --primary: #ff6b35;
        --primary-dark: #c2410c;
        --primary-soft: rgba(255, 107, 53, 0.1);
        --success: #ea580c;
        --shadow: 0 14px 36px rgba(0, 0, 0, 0.08);
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
        font-family: 'Outfit', sans-serif;
        background:
            linear-gradient(155deg, rgba(255, 107, 53, 0.28) 0%, rgba(194, 65, 12, 0.2) 32%, rgba(244, 244, 245, 0.97) 32%);
        color: var(--text);
        min-height: 100vh;
        padding: 34px 22px;
        position: relative;
        overflow-x: hidden;
    }
    body::before,
    body::after {
        content: '';
        position: fixed;
        border-radius: 50%;
        pointer-events: none;
        z-index: 0;
        filter: blur(2px);
    }
    body::before {
        width: 360px;
        height: 360px;
        top: -120px;
        right: -80px;
        background: radial-gradient(circle, rgba(255, 107, 53, 0.22) 0%, transparent 65%);
        animation: floatGlow 8s ease-in-out infinite;
    }
    body::after {
        width: 280px;
        height: 280px;
        bottom: -100px;
        left: -70px;
        background: radial-gradient(circle, rgba(194, 65, 12, 0.18) 0%, transparent 68%);
        animation: floatGlow 10s ease-in-out infinite reverse;
    }
    @keyframes floatGlow {
        0%, 100% { transform: translateY(0) scale(1); }
        50% { transform: translateY(12px) scale(1.05); }
    }

    .page {
        max-width: 1120px;
        margin: 0 auto;
        position: relative;
        z-index: 1;
    }

    .page-head {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        margin-bottom: 14px;
    }

    .page-title {
        font-size: 20px;
        font-weight: 800;
        color: #1a1a1a;
        letter-spacing: 0.01em;
        text-shadow: 0 1px 0 rgba(255,255,255,0.6);
    }
    .head-btn {
        text-decoration: none;
        font-size: 13px;
        font-weight: 600;
        color: #fff;
        background: linear-gradient(135deg, var(--primary), var(--primary-dark));
        border: 1px solid rgba(194, 65, 12, 0.45);
        border-radius: 999px;
        padding: 9px 14px;
        backdrop-filter: blur(2px);
        box-shadow: 0 10px 22px rgba(255, 107, 53, 0.24);
    }
    .head-btn:hover { filter: brightness(1.06); }

    .layout {
        display: grid;
        grid-template-columns: 270px minmax(0, 1fr);
        gap: 18px;
        align-items: start;
    }

    .profile-side,
    .profile-main {
        background: var(--card);
        border: 1px solid var(--line);
        border-radius: 16px;
        box-shadow: var(--shadow);
        transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.2s ease;
    }
    .profile-side:hover,
    .profile-main:hover {
        border-color: rgba(255, 107, 53, 0.26);
        box-shadow: 0 18px 44px rgba(0,0,0,0.1);
    }

    .profile-side {
        padding: 22px 18px;
        background: linear-gradient(180deg, rgba(255, 107, 53, 0.05) 0%, #fff 40%);
    }

    .avatar {
        position: relative;
        width: 112px;
        height: 112px;
        border-radius: 50%;
        background: linear-gradient(145deg, rgba(255, 107, 53, 0.16), rgba(194, 65, 12, 0.08));
        color: var(--primary-dark);
        border: 4px solid rgba(255, 107, 53, 0.18);
        box-shadow: 0 8px 22px rgba(194, 65, 12, 0.24);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 30px;
        font-weight: 800;
        margin: 0 auto 12px;
        transition: transform 0.25s ease;
        overflow: hidden;
        flex-shrink: 0;
    }
    .profile-side:hover .avatar { transform: translateY(-2px) scale(1.03); }
    .avatar-img {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;
        object-position: center center;
        display: none;
        pointer-events: none;
    }
    .avatar.has-image .avatar-img {
        display: block;
    }
    .avatar-initials {
        position: relative;
        z-index: 0;
        line-height: 1;
    }
    .avatar.has-image .avatar-initials {
        display: none;
    }

    .side-name { text-align: center; font-weight: 800; font-size: 17px; }
    .side-role { text-align: center; color: var(--text2); font-size: 12px; margin-top: 4px; }

    .side-metrics {
        margin-top: 16px;
        border-top: 1px dashed var(--line);
        border-bottom: 1px dashed var(--line);
        padding: 12px 0;
        display: grid;
        gap: 8px;
    }

    .metric-row {
        display: flex;
        justify-content: space-between;
        font-size: 13px;
        padding: 7px 8px;
        border-radius: 8px;
        background: rgba(255, 255, 255, 0.7);
        border: 1px solid rgba(0, 0, 0, 0.04);
    }
    .metric-label { color: var(--text2); }
    .metric-value { font-weight: 700; color: var(--primary-dark); }
    .metric-value.success { color: var(--success); }

    .side-actions { margin-top: 16px; display: grid; gap: 10px; }
    .btn {
        width: 100%;
        border: none;
        border-radius: 10px;
        padding: 11px 12px;
        font-size: 13px;
        font-weight: 700;
        cursor: pointer;
        transition: transform 0.2s ease, filter 0.2s ease;
    }
    .btn:hover { transform: translateY(-1px); }
    .btn-primary {
        background: linear-gradient(135deg, var(--primary), var(--primary-dark));
        color: #fff;
        box-shadow: 0 10px 20px rgba(255, 107, 53, 0.25);
    }
    .btn-primary:hover { filter: brightness(1.08); }
    .btn-soft {
        background: var(--primary-soft);
        color: var(--primary-dark);
        border: 1px solid rgba(255, 107, 53, 0.35);
    }
    .upload-hint {
        font-size: 11px;
        color: var(--text2);
        line-height: 1.5;
        margin-top: 2px;
    }
    .upload-box {
        border: 1px dashed rgba(255, 107, 53, 0.35);
        background: rgba(255, 107, 53, 0.06);
        border-radius: 10px;
        padding: 10px;
        margin-top: 8px;
    }
    .upload-box input[type="file"] {
        width: 100%;
        font: inherit;
        font-size: 12px;
        color: var(--text2);
    }

    .profile-main { overflow: hidden; }
    .tabs {
        display: flex;
        align-items: center;
        gap: 0;
        border-bottom: 1px solid var(--line);
        background: rgba(255, 107, 53, 0.04);
        overflow-x: auto;
    }
    .tab {
        padding: 14px 18px;
        font-size: 13px;
        color: var(--text2);
        font-weight: 600;
        border-bottom: 2px solid transparent;
        white-space: nowrap;
    }
    .tab.active {
        color: var(--primary-dark);
        border-bottom-color: var(--primary);
        background: #fff;
    }

    .profile-topline {
        padding: 16px 22px 0;
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }
    .profile-chip {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        font-size: 12px;
        font-weight: 700;
        border-radius: 999px;
        padding: 7px 12px;
        border: 1px solid rgba(255, 107, 53, 0.26);
        background: rgba(255, 107, 53, 0.08);
        color: var(--primary-dark);
    }
    .profile-chip.dot::before {
        content: '';
        width: 7px;
        height: 7px;
        border-radius: 50%;
        background: var(--primary);
    }
    .form-wrap { padding: 16px 22px 24px; }
    .form-grid {
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 16px 18px;
    }
    .group label {
        display: block;
        font-size: 12px;
        font-weight: 700;
        color: var(--text2);
        margin-bottom: 6px;
        text-transform: uppercase;
        letter-spacing: 0.03em;
    }
    .group input,
    .group select,
    .group textarea {
        width: 100%;
        border: 1px solid rgba(0, 0, 0, 0.14);
        border-radius: 10px;
        padding: 12px 12px;
        font: inherit;
        color: var(--text);
        background: #fff;
        transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
    }
    .group input:focus,
    .group select:focus,
    .group textarea:focus {
        outline: none;
        border-color: rgba(255, 107, 53, 0.55);
        box-shadow: 0 0 0 3px rgba(255, 107, 53, 0.12);
        transform: translateY(-1px);
    }
    .group textarea { min-height: 84px; resize: vertical; }
    .group.full { grid-column: 1 / -1; }
    .readonly-field {
        width: 100%;
        border: 1px solid rgba(0, 0, 0, 0.12);
        border-radius: 10px;
        padding: 12px;
        font-size: 14px;
        color: var(--text2);
        background: #f9fafb;
    }

    .save-row {
        margin-top: 18px;
        display: flex;
        justify-content: flex-start;
    }
    .save-btn {
        border: none;
        border-radius: 10px;
        background: linear-gradient(135deg, var(--primary), var(--primary-dark));
        color: #fff;
        font-size: 13px;
        font-weight: 700;
        padding: 10px 18px;
        cursor: pointer;
        box-shadow: 0 10px 20px rgba(255, 107, 53, 0.24);
        transition: transform 0.2s ease, filter 0.2s ease, box-shadow 0.2s ease;
    }
    .save-btn:hover {
        filter: brightness(1.08);
        transform: translateY(-1px);
        box-shadow: 0 14px 28px rgba(255, 107, 53, 0.3);
    }

    @media (max-width: 960px) {
        .layout { grid-template-columns: 1fr; }
        .form-grid { grid-template-columns: 1fr; }
    }

    .profile-flash {
        margin-bottom: 14px;
        padding: 12px 14px;
        border-radius: 10px;
        font-size: 13px;
        font-weight: 600;
    }
    .profile-flash.success {
        background: rgba(34, 197, 94, 0.12);
        border: 1px solid rgba(34, 197, 94, 0.35);
        color: #166534;
    }
    .profile-flash.error {
        background: rgba(239, 68, 68, 0.1);
        border: 1px solid rgba(239, 68, 68, 0.35);
        color: #991b1b;
    }
</style>
</head>
<body>
@php
    $fullName = trim((string) ($user->name ?? ($user->first_name ?? '').' '.($user->last_name ?? '')));
    $fullName = $fullName !== '' ? $fullName : 'Administrateur Autoritaire';
    $nameParts = preg_split('/\s+/', $fullName) ?: [];
    $firstName = (string) ($user->first_name ?? ($nameParts[0] ?? ''));
    $lastName = (string) ($user->last_name ?? (count($nameParts) > 1 ? implode(' ', array_slice($nameParts, 1)) : ''));
    $initials = strtoupper(substr($firstName ?: $fullName, 0, 1).substr($lastName, 0, 1));
    $initials = trim($initials) !== '' ? $initials : 'AA';
@endphp

<div class="page">
    <div class="page-head">
        <div class="page-title">Profil Administrateur Autoritaire</div>
        <a class="head-btn" href="{{ route('dashboard') }}">Retour Dashboard</a>
    </div>

    @if (session('success'))
        <div class="profile-flash success" role="status">{{ session('success') }}</div>
    @endif
    @if (session('error'))
        <div class="profile-flash error" role="alert">{{ session('error') }}</div>
    @endif
    @if ($errors->has('avatar_file'))
        <div class="profile-flash error" role="alert">{{ $errors->first('avatar_file') }}</div>
    @endif

    <div class="layout">
        <aside class="profile-side">
            <div
                id="profileAvatar"
                class="avatar{{ !empty($user->avatar_url) ? ' has-image' : '' }}"
                aria-label="Photo de profil"
            >
                <img
                    id="profileAvatarImg"
                    class="avatar-img"
                    alt=""
                    decoding="async"
                    src="{{ !empty($user->avatar_url) ? $user->avatar_url : 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7' }}"
                >
                <span id="profileAvatarInitials" class="avatar-initials">{{ $initials }}</span>
            </div>
            <div class="side-name">{{ $fullName }}</div>
            <div class="side-role">Administrateur Autoritaire</div>

            <div class="side-metrics">
                <div class="metric-row">
                    <span class="metric-label">Email vérifié</span>
                    <span class="metric-value success">{{ !empty($user->email_verified_at) ? 'Oui' : 'Non' }}</span>
                </div>
                <div class="metric-row">
                    <span class="metric-label">Statut</span>
                    <span class="metric-value success">Actif</span>
                </div>
            </div>

            <div class="side-actions">
                <form method="POST" action="{{ route('user.update-profile-photo') }}" enctype="multipart/form-data">
                    @csrf
                    <label class="btn btn-primary" for="avatar_file" style="display:block;text-align:center;">Changer la photo</label>
                    <div class="upload-box">
                        <input id="avatar_file" name="avatar_file" type="file" accept=".jpg,.jpeg,.png,.webp,.gif" required>
                    </div>
                    <button class="btn btn-soft" type="submit" style="margin-top:10px;">Enregistrer la photo</button>
                    <p class="upload-hint">Seule la photo est modifiable ici. Les informations du compte restent en lecture seule.</p>
                </form>
            </div>
        </aside>

        <section class="profile-main">
            <div class="tabs">
                <div class="tab active">Profil</div>
            </div>

            <div class="profile-topline">
                <span class="profile-chip dot">Compte actif</span>
                <span class="profile-chip">Niveau: Administrateur Autoritaire</span>
                <span class="profile-chip">Mise a jour securisee</span>
            </div>

            <div class="form-wrap">
                <div class="form-grid">
                    <div class="group">
                        <label>Prénom</label>
                        <div class="readonly-field">{{ $firstName !== '' ? $firstName : 'Non renseigné' }}</div>
                    </div>
                    <div class="group">
                        <label>Nom</label>
                        <div class="readonly-field">{{ $lastName !== '' ? $lastName : 'Non renseigné' }}</div>
                    </div>
                    <div class="group">
                        <label>Email</label>
                        <div class="readonly-field">{{ $user->email ?? 'Non renseigné' }}</div>
                    </div>
                    <div class="group">
                        <label>Téléphone</label>
                        <div class="readonly-field">{{ $user->phone ?? 'Non renseigné' }}</div>
                    </div>
                    <div class="group">
                        <label>Ville / Région</label>
                        <div class="readonly-field">{{ $user->city ?? $user->region ?? 'Non renseigné' }}</div>
                    </div>
                    <div class="group">
                        <label>Pays</label>
                        <div class="readonly-field">{{ $user->country ?? 'Tunisie' }}</div>
                    </div>
                </div>
            </div>
        </section>
    </div>
</div>
<script>
(function () {
    var input = document.getElementById('avatar_file');
    var avatar = document.getElementById('profileAvatar');
    var img = document.getElementById('profileAvatarImg');
    if (!input || !avatar || !img) return;
    var previewUrl = null;
    input.addEventListener('change', function () {
        var file = this.files && this.files[0];
        if (previewUrl) {
            URL.revokeObjectURL(previewUrl);
            previewUrl = null;
        }
        if (!file || !file.type || file.type.indexOf('image/') !== 0) return;
        previewUrl = URL.createObjectURL(file);
        img.src = previewUrl;
        avatar.classList.add('has-image');
    });
})();
</script>
</body>
</html>