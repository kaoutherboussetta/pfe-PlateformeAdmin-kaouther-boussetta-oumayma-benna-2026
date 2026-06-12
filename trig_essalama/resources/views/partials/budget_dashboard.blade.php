@php
    $bd = $budgetDashboard ?? config('trig_budget');
    $summary = is_array($bd['budget_summary'] ?? null) ? $bd['budget_summary'] : [];
    $incomeInitial = (int) ($summary['income_initial'] ?? $bd['monthly_income_dnt'] ?? (int) (config('trig_budget.monthly_income_dnt') ?? 100_000_000));
    $totalCoutsEstimes = (int) ($summary['total_spent'] ?? $bd['total_couts_estimes'] ?? 0);
    $incomeRemaining = (int) ($summary['income_remaining'] ?? $bd['monthly_income_remaining'] ?? max(0, $incomeInitial - $totalCoutsEstimes));
    $cur = $bd['currency'] ?? ($summary['currency'] ?? 'DNT');
    $chantiers = $bd['chantiers'] ?? [];
    $problemesBudget = collect($problemes ?? [])->reject(function ($probleme) {
        $statusValue = strtolower(trim((string) ($probleme['statut'] ?? $probleme['status'] ?? '')));

        return str_contains($statusValue, 'term');
    })->values();
    $meta = is_array($bd['meta'] ?? null) ? $bd['meta'] : [];
    $pageTitle = (string) ($meta['page_title'] ?? 'Budget — TRIG ESSALAMA');
    $pageSubtitle = (string) ($meta['page_subtitle'] ?? '');
    $listTitle = (string) ($meta['list_title'] ?? 'Budget des admins chantier');
    $listButton = (string) ($meta['list_button'] ?? 'Actualiser la vue');
    $kpiLabels = is_array($bd['kpi_labels'] ?? null) ? $bd['kpi_labels'] : [];
    $lblEntree = (string) ($kpiLabels['entree'] ?? 'Entrée mensuelle');

    $totalAlloue = collect($chantiers)->sum(fn ($row) => (int) data_get($row, 'budget_admin_dnt', 0));
    $pctEngage = $incomeInitial > 0
        ? (int) round(min(100, ($totalAlloue / $incomeInitial) * 100))
        : 0;
@endphp

@once
<style>
    .analyse-tab-panel[data-analyse-panel="budget"] .budget-page-wrap {
        margin-top: 0;
        width: 100%;
        max-width: 100%;
    }
    /* Aligné sur la section Problèmes : carte KPI pleine largeur */
    .budget-page-wrap.problemes-section {
        margin-top: 0;
        width: 100%;
        max-width: 100%;
        box-sizing: border-box;
    }
    .budget-page-wrap .problemes-stats-grid {
        display: grid;
        grid-template-columns: 1fr;
        width: 100%;
        max-width: none;
        gap: 16px;
        margin-bottom: 28px;
    }
    .budget-page-wrap .problemes-stats-grid .probleme-stat-card {
        width: 100%;
        box-sizing: border-box;
        padding: 28px 32px;
        min-height: 140px;
    }
    .budget-page-wrap .probleme-stat-value--money {
        font-family: 'Bebas Neue', 'Outfit', sans-serif;
        font-size: clamp(36px, 6vw, 72px);
        letter-spacing: 1px;
        line-height: 1.05;
        word-break: break-word;
    }
    .budget-page-wrap .probleme-stat-label {
        font-size: 12px;
    }
    .budget-page-wrap .probleme-stat-currency {
        display: block;
        font-family: 'Outfit', sans-serif;
        font-size: 13px;
        font-weight: 600;
        letter-spacing: 0.08em;
        color: var(--text2);
        margin-top: 6px;
    }
    .budget-page-wrap .budget-engage-card {
        width: 100%;
        box-sizing: border-box;
        padding: 18px 20px;
        border-bottom: 1px solid var(--border);
    }
    .budget-page-wrap .budget-engage-label {
        font-size: 12px;
        font-weight: 700;
        color: var(--text2);
        text-transform: uppercase;
        letter-spacing: 0.06em;
        margin-bottom: 10px;
    }
    .budget-page-wrap .budget-pill-statut {
        display: inline-flex;
        align-items: center;
        padding: 6px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 700;
    }
    .budget-page-wrap .budget-pill-statut--ok {
        background: rgba(16, 185, 129, 0.15);
        color: #065f46;
    }
    .budget-page-wrap .budget-pill-statut--wait {
        background: rgba(251, 191, 36, 0.22);
        color: #92400e;
    }
    .budget-page-wrap .budget-pill-paye {
        display: inline-flex;
        padding: 6px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 700;
    }
    .budget-page-wrap .budget-pill-paye--oui {
        background: rgba(16, 185, 129, 0.15);
        color: #065f46;
    }
    .budget-page-wrap .budget-pill-paye--non {
        background: rgba(239, 68, 68, 0.12);
        color: #991b1b;
    }
    .budget-page-wrap .alert-budget {
        margin: 0 0 20px;
        width: 100%;
        box-sizing: border-box;
        background: #fff7ed;
        border: 1px solid #fdba74;
        color: #9a3412;
        padding: 14px 16px;
        border-radius: 12px;
        font-weight: 600;
        font-size: 14px;
    }
    .budget-page-wrap .budget-income-meta {
        margin-top: 12px;
        font-size: clamp(12px, 1.2vw, 14px);
        font-weight: 600;
        color: var(--text3);
        line-height: 1.5;
        max-width: 100%;
    }
    .budget-page-wrap .problemes-list-section {
        width: 100%;
        max-width: 100%;
    }
    .budget-page-wrap .budget-income-meta strong {
        color: var(--text2);
        font-weight: 700;
    }
</style>
@endonce

<div
    class="budget-page-wrap problemes-section"
    data-budget-kpi-root
    data-income-initial="{{ $incomeInitial }}"
    data-income-remaining="{{ $incomeRemaining }}"
    data-total-spent="{{ $totalCoutsEstimes }}"
>

    <div class="problemes-header">
        <h3>{{ $pageTitle }}</h3>
    </div>
    @if($pageSubtitle !== '')
        <p class="problemes-subtitle">{{ $pageSubtitle }}</p>
    @else
        <p class="problemes-subtitle">Données chargées depuis la configuration (<code>config/trig_budget.php</code>).</p>
    @endif

    <div class="problemes-stats-grid">
        <div class="probleme-stat-card orange">
            <div class="probleme-stat-label">{{ $lblEntree }}</div>
            <div class="probleme-stat-value probleme-stat-value--money">
                <span data-budget-income-remaining>{{ number_format($incomeRemaining, 0, ',', ' ') }}</span>
            </div>
            <span class="probleme-stat-currency">{{ $cur }}</span>
            <p class="budget-income-meta">
                Entrée du mois : <strong data-budget-income-initial>{{ number_format($incomeInitial, 0, ',', ' ') }}</strong> {{ $cur }}
                <span data-budget-income-spent-line @if($totalCoutsEstimes <= 0) style="display:none;" @endif>
                    — Coûts estimés (problèmes) : <strong data-budget-income-spent>−{{ number_format($totalCoutsEstimes, 0, ',', ' ') }}</strong> {{ $cur }}
                </span>
            </p>
        </div>
    </div>

    <div class="problemes-list-section" style="margin-bottom: 20px;">
        <div class="budget-engage-card">
            <div class="budget-engage-label">Taux engagé (budgets admins / entrée) : {{ $pctEngage }} %</div>
            <div class="risk-bar" style="max-width: 100%; height: 10px;">
                <div class="risk-bar-fill" style="width: {{ $pctEngage }}%;"></div>
            </div>
        </div>
    </div>

    @if($totalAlloue > $incomeRemaining)
        <div class="alert-budget" data-budget-alert-over>
            Attention : la somme des budgets chantier dépasse le solde restant de l’entrée mensuelle.
        </div>
    @endif

    <div class="problemes-list-section">
        <div class="problemes-list-header">
            <h4 class="problemes-list-title">{{ $listTitle }}</h4>
            <button type="button" class="btn-ai-detection" onclick="window.location.reload()">
                <i class="fas fa-arrows-rotate"></i>
                {{ $listButton }}
            </button>
        </div>
        <div style="overflow-x: auto;">
            <table class="problemes-table budget-problems-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Type</th>
                        <th>Localisation</th>
                        <th>Coût estimé</th>
                    </tr>
                </thead>
                <tbody id="budget-problems-table-body">
                    @forelse($problemesBudget as $probleme)
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
                            $rawCout = trim((string) ($probleme['cout_estime'] ?? ''));
                            $hasCout = $rawCout !== ''
                                && strcasecmp($rawCout, 'N/A') !== 0
                                && $rawCout !== '—'
                                && $rawCout !== '-';
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
                                        <a class="btn-gps-link" href="{{ $gpsUrl }}" target="_blank" rel="noopener noreferrer" title="Carte : {{ $gpsTitleCoords }}">
                                            <i class="fas fa-location-crosshairs"></i>
                                        </a>
                                    @else
                                        <span class="btn-gps-link disabled" title="Coordonnées GPS indisponibles">
                                            <i class="fas fa-location-crosshairs"></i>
                                        </span>
                                    @endif
                                </div>
                            </td>
                            <td class="problem-cout-cell">
                                @if($hasCout)
                                    <span class="cout-estime-value" title="Coût estimé saisi par l’administrateur">{{ $rawCout }}</span>
                                @else
                                    <span class="cout-estime-empty">Non saisi</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" style="text-align: center; color: var(--text2); padding: 28px;">
                                Aucun problème en attente ou en cours.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

</div>
