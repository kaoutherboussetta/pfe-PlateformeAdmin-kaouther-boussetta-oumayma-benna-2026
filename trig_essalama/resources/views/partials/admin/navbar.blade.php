@php
    $hasProfileRoute = \Illuminate\Support\Facades\Route::has('profile');
    $profileHref = $hasProfileRoute ? route('profile') : '#';
@endphp
@include('partials.admin.resolve-header-user', ['headerSourceUser' => $user ?? null])
<header class="topbar topbar--dashboard">
    <div class="tb-page-info">
        <div class="tb-page-title">{{ $title ?? 'Administration' }}</div>
        <div class="tb-breadcrumb">{!! $breadcrumb ?? 'Trig-Essalama / <span>Dashboard</span>' !!}</div>
    </div>

    <div class="tb-right">
        <div class="tb-profile-wrap">
            <div class="tb-profile" id="tb-profile-trigger" role="button" tabindex="0" onclick="toggleTechProfileMenu(event)" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();toggleTechProfileMenu(event);}">
                <div class="profile-av{{ $headerAvatarUrl ? ' has-image' : '' }}">
                    @if($headerAvatarUrl)
                        <img class="profile-av-img" src="{{ $headerAvatarUrl }}" alt="">
                    @endif
                    <span class="profile-av-letter">{{ $headerInitials }}</span>
                </div>
                <div>
                    <div class="profile-name">{{ $headerDisplayName }}</div>
                    <div class="profile-role">{{ $headerRoleLabel }}</div>
                </div>
                <svg class="profile-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                    <polyline points="6 9 12 15 18 9"/>
                </svg>
            </div>

            <div class="tb-profile-menu" id="tb-profile-menu">
                <div class="tb-profile-head">
                    <div class="profile-av{{ $headerAvatarUrl ? ' has-image' : '' }}">
                        @if($headerAvatarUrl)
                            <img class="profile-av-img" src="{{ $headerAvatarUrl }}" alt="">
                        @endif
                        <span class="profile-av-letter">{{ $headerInitials }}</span>
                    </div>
                    <div>
                        <div class="profile-name">{{ $headerDisplayName }}</div>
                        <div class="profile-role">{{ $headerRoleLabel }}</div>
                    </div>
                </div>

                @if($hasProfileRoute)
                <a href="{{ $profileHref }}" class="tb-profile-item" onclick="closeTechProfileMenu()">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    Profil
                </a>
                @else
                <a href="#" class="tb-profile-item" onclick="closeTechProfileMenu(); if (typeof openProfileModal === 'function') openProfileModal(); return false;">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    Profil
                </a>
                @endif

                <form method="POST" action="{{ route('logout') }}" style="margin:0;">
                    @csrf
                    <button type="submit" class="tb-profile-item logout">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                            <polyline points="16 17 21 12 16 7"/>
                            <line x1="21" y1="12" x2="9" y2="12"/>
                        </svg>
                        Déconnexion
                    </button>
                </form>
            </div>
        </div>
    </div>
</header>

<style>
    .topbar.topbar--dashboard {
        height: 60px;
        background: rgba(255,255,255,0.97);
        border-bottom: 1px solid var(--border);
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0 20px;
        gap: 16px;
        position: sticky;
        top: 0;
        z-index: 50;
        flex-shrink: 0;
        overflow: visible;
    }

    .tb-page-info {
        min-width: 0;
        flex: 1;
        padding-right: 12px;
        flex-shrink: 1;
    }
    .tb-page-title { font-size: 14px; font-weight: 700; color: var(--text); line-height: 1.2; }
    .tb-breadcrumb { font-size: 11px; color: var(--text3); margin-top: 2px; }
    .tb-breadcrumb span { color: var(--orange); }

    .tb-right { display: flex; align-items: center; gap: 6px; flex-shrink: 0; overflow: visible; position: relative; z-index: 60; }

    .tb-icon {
        width: 34px; height: 34px; border-radius: 8px;
        background: transparent; border: 1px solid transparent;
        display: flex; align-items: center; justify-content: center;
        color: var(--text2);
        transition: background 0.15s, color 0.15s, border-color 0.15s;
        position: relative; flex-shrink: 0;
    }
    .tb-icon:hover { background: var(--surface2); color: var(--text); border-color: var(--border); }
    .tb-icon svg { width: 15px; height: 15px; }
    .tb-icon .dot {
        position: absolute; top: 6px; right: 6px;
        width: 6px; height: 6px; border-radius: 50%;
        background: var(--orange); border: 1.5px solid var(--bg2);
        animation: tbBlink 2s infinite;
    }
    @keyframes tbBlink { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }

    .tb-profile {
        display: flex; align-items: center; gap: 8px;
        padding: 4px 8px 4px 4px;
        border-radius: 10px;
        border: 1px solid transparent;
        cursor: pointer;
        transition: background 0.15s, border-color 0.15s;
    }
    .tb-profile:hover { background: var(--surface2); border-color: var(--border); }
    .topbar--dashboard .profile-av {
        position: relative;
        width: 30px; height: 30px; border-radius: 8px;
        background: var(--orange);
        display: flex; align-items: center; justify-content: center;
        font-size: 12px; font-weight: 700; color: #fff;
        overflow: hidden;
        flex-shrink: 0;
    }
    .topbar--dashboard .profile-av-img {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: none;
    }
    .topbar--dashboard .profile-av.has-image .profile-av-img { display: block; }
    .topbar--dashboard .profile-av.has-image .profile-av-letter { display: none; }
    .topbar--dashboard .profile-av-letter { position: relative; z-index: 0; line-height: 1; }
    .topbar--dashboard .tb-profile .profile-name,
    .topbar--dashboard .tb-profile-head .profile-name {
        font-size: 12px; font-weight: 600; color: var(--text);
        text-transform: lowercase;
        text-align: left;
    }
    .topbar--dashboard .tb-profile .profile-role,
    .topbar--dashboard .tb-profile-head .profile-role {
        font-size: 10px; color: var(--text2); margin-top: 1px;
        text-align: left;
    }
    .profile-chevron { width: 12px; height: 12px; color: var(--text3); flex-shrink: 0; }
    .tb-profile-wrap { position: relative; }
    .tb-profile-menu {
        position: absolute;
        right: 0;
        top: calc(100% + 8px);
        min-width: 240px;
        background: #fff;
        border: 1px solid var(--border);
        border-radius: 12px;
        box-shadow: 0 18px 40px rgba(0,0,0,0.12);
        overflow: hidden;
        display: none;
        z-index: 200;
    }
    .tb-profile-menu.show { display: block; }
    .tb-profile-head {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 14px;
        border-bottom: 1px solid var(--border);
    }
    .tb-profile-head .profile-av { width: 34px; height: 34px; font-size: 13px; }
    .tb-profile-item {
        width: 100%;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 14px;
        color: var(--text2);
        background: transparent;
        border: none;
        text-decoration: none;
        font-size: 14px;
        text-align: left;
        cursor: pointer;
        border-bottom: 1px solid var(--border);
        box-sizing: border-box;
    }
    .tb-profile-item:last-child { border-bottom: none; }
    .tb-profile-item:hover { background: var(--surface); color: var(--text); }
    .tb-profile-item.logout { color: var(--text); }
    .tb-profile-item.logout:hover { background: rgba(255,107,53,0.1); color: var(--orange-dark); }
    .tb-profile-item svg { width: 16px; height: 16px; flex-shrink: 0; }

    @media (max-width: 900px) {
        .topbar.topbar--dashboard { padding: 0 16px; }
        .tb-profile .profile-name,
        .tb-profile .profile-role,
        .tb-profile .profile-chevron { display: none; }
        .tb-profile { padding: 4px; }
    }
</style>

<script>
    function toggleTechProfileMenu(event) {
        if (event) event.stopPropagation();
        var menu = document.getElementById('tb-profile-menu');
        if (!menu) return;
        menu.classList.toggle('show');
    }
    function closeTechProfileMenu() {
        var menu = document.getElementById('tb-profile-menu');
        if (menu) menu.classList.remove('show');
    }
    document.addEventListener('click', function (event) {
        var wrap = document.querySelector('.topbar--dashboard .tb-profile-wrap');
        if (!wrap || !wrap.contains(event.target)) closeTechProfileMenu();
    });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            closeTechProfileMenu();
        }
    });
</script>
