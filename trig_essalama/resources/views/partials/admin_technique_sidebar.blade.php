@include('partials.dashboard_sidebar', [
    'problemesStats' => ['en_attente' => 0, 'en_cours' => 0, 'termine' => 0, 'critiques' => 0],
    'sidebarStartExpanded' => $sidebarStartExpanded ?? true,
    'sidebarMinimal' => true,
    'sidebarHomeUrl' => route('interface_admin_tech'),
])
