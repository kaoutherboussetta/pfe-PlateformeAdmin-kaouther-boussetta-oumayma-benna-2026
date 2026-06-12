@php
    $topbarTitle = $title ?? 'Tableau de Bord';
    $topbarTitleId = $titleId ?? 'tb-title';
    $topbarCrumbHtml = $breadcrumb ?? 'Trig-Essalama / <span>Dashboard</span>';
    $topbarCrumbId = $crumbId ?? null;
    $topbarChatUid = $chatBellUid ?? 'dash';
    $topbarShowBell = (bool) ($showNotificationBell ?? true);
    $topbarProfileRoute = \Illuminate\Support\Facades\Route::has('profil_admin_Autoritaire')
        ? route('profil_admin_Autoritaire')
        : (\Illuminate\Support\Facades\Route::has('profile') ? route('profile') : '#');
@endphp
<header class="topbar">
    <div class="tb-page-info">
        <div class="tb-page-title" @if($topbarTitleId) id="{{ $topbarTitleId }}" @endif>{{ $topbarTitle }}</div>
        <div class="tb-breadcrumb">
            @if($topbarCrumbId)
                Trig-Essalama / <span id="{{ $topbarCrumbId }}">{{ $crumbLabel ?? 'Dashboard' }}</span>
            @else
                {!! $topbarCrumbHtml !!}
            @endif
        </div>
    </div>

    <div class="tb-right">
        @if($topbarShowBell)
            @include('partials.admin.chat_intervenant_bell', ['chatBellUid' => $topbarChatUid])
        @endif
        <div class="tb-profile-wrap">
            <div class="tb-profile" id="tb-profile-trigger" onclick="toggleProfileMenu(event)" role="button" tabindex="0">
                <div class="profile-av{{ ($headerAvatarUrl ?? null) ? ' has-image' : '' }}">
                    @if($headerAvatarUrl ?? null)
                        <img class="profile-av-img" src="{{ $headerAvatarUrl }}" alt="">
                    @endif
                    <span class="profile-av-letter">{{ $headerInitials ?? 'A' }}</span>
                </div>
                <div>
                    <div class="profile-name">{{ $headerDisplayName ?? 'Administrateur' }}</div>
                    <div class="profile-role">{{ $headerRoleLabel ?? 'Administrateur' }}</div>
                </div>
                <svg class="profile-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                    <polyline points="6 9 12 15 18 9"/>
                </svg>
            </div>

            <div class="tb-profile-menu" id="tb-profile-menu">
                <div class="tb-profile-head">
                    <div class="profile-av{{ ($headerAvatarUrl ?? null) ? ' has-image' : '' }}">
                        @if($headerAvatarUrl ?? null)
                            <img class="profile-av-img" src="{{ $headerAvatarUrl }}" alt="">
                        @endif
                        <span class="profile-av-letter">{{ $headerInitials ?? 'A' }}</span>
                    </div>
                    <div>
                        <div class="profile-name">{{ $headerDisplayName ?? 'Administrateur' }}</div>
                        <div class="profile-role">{{ $headerRoleLabel ?? 'Administrateur' }}</div>
                    </div>
                </div>

                <a href="{{ $topbarProfileRoute }}" class="tb-profile-item" onclick="closeProfileMenu()">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    Profil
                </a>

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
@once
<script>
    if (typeof window.toggleProfileMenu !== 'function') {
        window.toggleProfileMenu = function (event) {
            if (event) event.stopPropagation();
            var menu = document.getElementById('tb-profile-menu');
            if (menu) menu.classList.toggle('show');
        };
    }
    if (typeof window.closeProfileMenu !== 'function') {
        window.closeProfileMenu = function () {
            var menu = document.getElementById('tb-profile-menu');
            if (menu) menu.classList.remove('show');
        };
    }
    document.addEventListener('click', function (event) {
        var wrap = document.querySelector('.tb-profile-wrap');
        if (!wrap || !wrap.contains(event.target)) {
            if (typeof window.closeProfileMenu === 'function') window.closeProfileMenu();
        }
    });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape' && typeof window.closeProfileMenu === 'function') {
            window.closeProfileMenu();
        }
    });
</script>
@endonce
