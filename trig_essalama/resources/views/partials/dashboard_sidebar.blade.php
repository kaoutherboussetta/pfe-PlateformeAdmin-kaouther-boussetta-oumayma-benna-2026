@php
    $sidebarMinimal = (bool) ($sidebarMinimal ?? false) || request()->routeIs('interface_admin_tech');
    $problemesStats = is_array($problemesStats ?? null)
        ? $problemesStats
        : ($sidebarMinimal
            ? ['en_attente' => 0, 'en_cours' => 0, 'termine' => 0, 'critiques' => 0]
            : \App\Support\ProblemesSidebarStats::counts());
    $problemesEnAttente = (int) ($problemesStats['en_attente'] ?? 0);
    $onDashboard = request()->routeIs('dashboard');
    $dashboardSection = (string) request()->query('section', '');
    $sidebarStartExpanded = (bool) ($sidebarStartExpanded ?? true);
    $sidebarHomeUrl = $sidebarHomeUrl ?? ($sidebarMinimal ? route('interface_admin_tech') : route('dashboard'));
    $isDashboardActive = $sidebarMinimal
        ? request()->routeIs('interface_admin_tech')
        : ($onDashboard && ($dashboardSection === '' || $dashboardSection === 'dashboard'));
    $isProblemesActive = ! $sidebarMinimal && $onDashboard && $dashboardSection === 'problemes';
    $isAnalyseActive = ! $sidebarMinimal && $onDashboard && $dashboardSection === 'analyse';
    $isEquipesActive = ! $sidebarMinimal && (($onDashboard && $dashboardSection === 'equipes') || request()->routeIs('interface_admin_tech.equipes'));
@endphp
<aside class="sidebar{{ $sidebarStartExpanded ? ' expanded' : '' }}" id="sidebar">
    <div class="sb-logo">
        <div class="logo-mark">TE</div>
        <div class="logo-text">
            <div class="logo-title">Trig-Essalama</div>
            <div class="logo-sub">Administration</div>
        </div>
    </div>

    <div class="sb-toggle" onclick="toggleSidebar()" role="button" tabindex="0" aria-label="Réduire le menu" title="Réduire le menu">
        <svg id="toggle-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="{{ $sidebarStartExpanded ? '2.5' : '2' }}" stroke-linecap="round" aria-hidden="true">
            @if($sidebarStartExpanded)
                <polyline points="15 18 9 12 15 6"/>
            @else
                <line x1="3" y1="12" x2="21" y2="12"/>
                <line x1="3" y1="6" x2="21" y2="6"/>
                <line x1="3" y1="18" x2="21" y2="18"/>
            @endif
        </svg>
    </div>

    <div class="sb-section">
        <div class="sb-section-label">Principal</div>

        @if($sidebarMinimal)
            <a href="{{ $sidebarHomeUrl }}"
               class="sb-item sb-item--page-link{{ $isDashboardActive ? ' active' : '' }}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <rect x="3" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="14" width="7" height="7" rx="1"/>
                    <rect x="3" y="14" width="7" height="7" rx="1"/>
                </svg>
                <span class="sb-item-label">Tableau de Bord</span>
            </a>
        @elseif($onDashboard)
            <a href="#" class="sb-item{{ $isDashboardActive ? ' active' : '' }}"
               onclick="showSection('dashboard', this); return false;">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <rect x="3" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="14" width="7" height="7" rx="1"/>
                    <rect x="3" y="14" width="7" height="7" rx="1"/>
                </svg>
                <span class="sb-item-label">Tableau de Bord</span>
            </a>

            <a href="#" class="sb-item{{ $isProblemesActive ? ' active' : '' }}"
               onclick="showSection('problemes', this); return false;">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                    <line x1="12" y1="9" x2="12" y2="13"/>
                    <line x1="12" y1="17" x2="12.01" y2="17"/>
                </svg>
                <span class="sb-item-label">Problèmes de Voirie</span>
                <span class="sb-badge" id="sb-badge-problemes">{{ $problemesEnAttente }}</span>
            </a>

            <a href="#" class="sb-item{{ $isAnalyseActive ? ' active' : '' }}"
               onclick="showSection('analyse', this); return false;">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <line x1="18" y1="20" x2="18" y2="10"/>
                    <line x1="12" y1="20" x2="12" y2="4"/>
                    <line x1="6" y1="20" x2="6" y2="14"/>
                </svg>
                <span class="sb-item-label">Analyse</span>
            </a>

            <a href="#" class="sb-item{{ $isEquipesActive ? ' active' : '' }}"
               onclick="showSection('equipes', this); return false;"
               title="Gestion des équipes d'intervention">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                <span class="sb-item-label">Équipes d'intervention</span>
            </a>
        @else
            <a href="{{ route('dashboard') }}"
               class="sb-item sb-item--page-link{{ $isDashboardActive ? ' active' : '' }}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <rect x="3" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="3" width="7" height="7" rx="1"/>
                    <rect x="14" y="14" width="7" height="7" rx="1"/>
                    <rect x="3" y="14" width="7" height="7" rx="1"/>
                </svg>
                <span class="sb-item-label">Tableau de Bord</span>
            </a>

            <a href="{{ url('/dashboard?section=problemes') }}"
               class="sb-item sb-item--page-link{{ $isProblemesActive ? ' active' : '' }}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                    <line x1="12" y1="9" x2="12" y2="13"/>
                    <line x1="12" y1="17" x2="12.01" y2="17"/>
                </svg>
                <span class="sb-item-label">Problèmes de Voirie</span>
                <span class="sb-badge" id="sb-badge-problemes">{{ $problemesEnAttente }}</span>
            </a>

            <a href="{{ url('/dashboard?section=analyse') }}"
               class="sb-item sb-item--page-link{{ $isAnalyseActive ? ' active' : '' }}">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <line x1="18" y1="20" x2="18" y2="10"/>
                    <line x1="12" y1="20" x2="12" y2="4"/>
                    <line x1="6" y1="20" x2="6" y2="14"/>
                </svg>
                <span class="sb-item-label">Analyse</span>
            </a>

            <a href="{{ url('/dashboard?section=equipes') }}"
               class="sb-item sb-item--page-link{{ $isEquipesActive ? ' active' : '' }}"
               title="Gestion des équipes d'intervention">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                <span class="sb-item-label">Équipes d'intervention</span>
            </a>
        @endif
    </div>

    <div class="sb-spacer"></div>
</aside>
@once
<script>
    if (typeof window.sidebarOpen === 'undefined') {
        window.sidebarOpen = {{ $sidebarStartExpanded ? 'true' : 'false' }};
    }
    if (typeof window.toggleSidebar !== 'function') {
        window.toggleSidebar = function () {
            window.sidebarOpen = !window.sidebarOpen;
            var sidebar = document.getElementById('sidebar');
            if (sidebar) {
                sidebar.classList.toggle('expanded', window.sidebarOpen);
            }
            var icon = document.getElementById('toggle-icon');
            if (!icon) return;
            if (window.sidebarOpen) {
                icon.innerHTML = '<polyline points="15 18 9 12 15 6"/>';
                icon.setAttribute('stroke-width', '2.5');
            } else {
                icon.innerHTML = '<line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/>';
                icon.setAttribute('stroke-width', '2');
            }
        };
    }
</script>
@endonce
