@php
    $equipesList = $equipes ?? collect();
    $intervenantsList = $intervenants ?? collect();
    $totalRows = $equipesList->count() + $intervenantsList->count();
    $withPhone = $intervenantsList->filter(fn ($iv) => ! empty($iv['phone'] ?? null) && ($iv['phone'] ?? '—') !== '—')->count();
    $withEmail = $intervenantsList->filter(fn ($iv) => ! empty($iv['email'] ?? null) && ($iv['email'] ?? '—') !== '—')->count();

    $eqInitials = static function (?string $nom, ?string $prenom, ?string $fallback = null): string {
        $n = trim(($nom ?? '') !== '—' ? ($nom ?? '') : '');
        $p = trim(($prenom ?? '') !== '—' ? ($prenom ?? '') : '');
        $letters = strtoupper(mb_substr($n, 0, 1).mb_substr($p, 0, 1));
        if ($letters !== '') {
            return $letters;
        }
        $fb = trim((string) ($fallback ?? ''));
        if ($fb !== '' && $fb !== '—') {
            return strtoupper(mb_substr($fb, 0, 2));
        }

        return '?';
    };

    $eqIsGpsZone = static function (?string $zone): bool {
        $zone = trim((string) ($zone ?? ''));

        return $zone !== '' && $zone !== '—' && preg_match('/lat:\s*[-\d.]+,\s*lon:\s*[-\d.]+/i', $zone);
    };

    $eqParseGps = static function (?string $zone): ?array {
        if (! preg_match('/lat:\s*([-\d.]+),\s*lon:\s*([-\d.]+)/i', (string) $zone, $m)) {
            return null;
        }

        return ['lat' => $m[1], 'lon' => $m[2]];
    };
@endphp

<div class="eq-section fade-in">
    <div class="section-header eq-section-header">
        <h3>Gestion des équipes d'intervention</h3>
        <p>Coordination des équipes terrain et messagerie instantanée avec les intervenants MongoDB.</p>
    </div>

    <div class="eq-kpi-strip">
        <div class="eq-kpi-card">
            <div class="eq-kpi-icon eq-kpi-icon--orange"><i class="fas fa-people-group"></i></div>
            <div>
                <div class="eq-kpi-value">{{ $totalRows }}</div>
                <p class="eq-kpi-label">Membres & équipes listés</p>
            </div>
        </div>
        <div class="eq-kpi-card">
            <div class="eq-kpi-icon eq-kpi-icon--dark"><i class="fas fa-phone-volume"></i></div>
            <div>
                <div class="eq-kpi-value">{{ $withPhone }}</div>
                <p class="eq-kpi-label">Avec téléphone renseigné</p>
            </div>
        </div>
        <div class="eq-kpi-card">
            <div class="eq-kpi-icon eq-kpi-icon--warm"><i class="fas fa-envelope-open-text"></i></div>
            <div>
                <div class="eq-kpi-value">{{ $withEmail }}</div>
                <p class="eq-kpi-label">Avec email de contact</p>
            </div>
        </div>
    </div>

    <div class="eq-card">
        <div class="eq-card-head">
            <div class="eq-card-head-left">
                <div class="eq-card-icon"><i class="fas fa-users-gear"></i></div>
                <div>
                    <h4 class="eq-card-title">Équipes & intervenants</h4>
                    <p class="eq-card-sub">Données synchronisées depuis MongoDB · module équipes + collection <code>intervenants</code></p>
                </div>
            </div>
            <div class="eq-card-tools">
                <div class="eq-search-wrap">
                    <i class="fas fa-search eq-search-icon" aria-hidden="true"></i>
                    <input type="search" class="eq-search-input" id="eq-table-search" placeholder="Rechercher nom, équipe, zone…" autocomplete="off">
                </div>
                <span class="eq-count-badge">{{ $totalRows }} entrée{{ $totalRows > 1 ? 's' : '' }}</span>
            </div>
        </div>

        <div class="eq-table-wrap">
            <table class="eq-table" id="eq-intervenants-table">
                <thead>
                    <tr>
                        <th class="eq-th-person">Intervenant</th>
                        <th>Équipe</th>
                        <th>Contact</th>
                        <th>Zone</th>
                        <th class="eq-th-action">Message</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($equipesList as $eq)
                        @php
                            $eid = (string) $eq->getKey();
                            $teamName = (string) ($eq->nom ?? 'Équipe');
                            $zoneRaw = (string) ($eq->zone ?: '—');
                            $isGps = $eqIsGpsZone($zoneRaw);
                            $gps = $isGps ? $eqParseGps($zoneRaw) : null;
                        @endphp
                        <tr class="eq-row eq-row--team" data-eq-search="{{ strtolower($teamName.' '.$zoneRaw) }}">
                            <td>
                                <div class="eq-person">
                                    <div class="eq-avatar eq-avatar--team" aria-hidden="true">{{ $eqInitials(null, null, $teamName) }}</div>
                                    <div class="eq-person-meta">
                                        <span class="eq-person-name">{{ $teamName }}</span>
                                        <span class="eq-person-sub"><span class="eq-tag eq-tag--module">Équipe module</span></span>
                                    </div>
                                </div>
                            </td>
                            <td><span class="eq-team-badge"><i class="fas fa-hard-hat"></i> {{ $teamName }}</span></td>
                            <td><span class="eq-empty-cell">—</span></td>
                            <td>
                                @if($isGps && $gps)
                                    <a href="https://www.google.com/maps?q={{ $gps['lat'] }},{{ $gps['lon'] }}" target="_blank" rel="noopener" class="eq-zone-gps" title="{{ $zoneRaw }}">
                                        <i class="fas fa-location-dot"></i>
                                        <span>{{ $gps['lat'] }}, {{ $gps['lon'] }}</span>
                                    </a>
                                @elseif($zoneRaw !== '—')
                                    <span class="eq-zone-chip"><i class="fas fa-map-pin"></i> {{ $zoneRaw }}</span>
                                @else
                                    <span class="eq-empty-cell">Non renseignée</span>
                                @endif
                            </td>
                            <td class="eq-td-action">
                                <button type="button" class="eq-msg-btn eq-chat-open" data-type="module" data-id="{{ $eid }}" data-collection="" data-label="{{ $teamName }}" title="Écrire à cette équipe">
                                    <i class="fas fa-comment-dots" aria-hidden="true"></i>
                                    <span>Message</span>
                                </button>
                            </td>
                        </tr>
                    @endforeach

                    @foreach($intervenantsList as $iv)
                        @php
                            $ivChatId = (string) ($iv['chat_recipient_id'] ?? $iv['id'] ?? '');
                            $ivChatCol = (string) ($iv['chat_collection'] ?? $iv['collection'] ?? 'intervenants');
                            if (! in_array($ivChatCol, ['intervenants', 'intervenant'], true)) {
                                $ivChatCol = 'intervenants';
                            }
                            $nom = (string) ($iv['nom'] ?? '—');
                            $prenom = (string) ($iv['prenom'] ?? '—');
                            $equipe = (string) ($iv['equipe'] ?? '—');
                            $phone = (string) ($iv['phone'] ?? '—');
                            $email = (string) ($iv['email'] ?? '—');
                            $zoneRaw = (string) ($iv['zone'] ?? '—');
                            $isGps = $eqIsGpsZone($zoneRaw);
                            $gps = $isGps ? $eqParseGps($zoneRaw) : null;
                            $ivLabel = trim($prenom.' '.$nom);
                            if ($ivLabel === '' || $ivLabel === '— —') {
                                $ivLabel = $equipe !== '—' ? $equipe : 'Intervenant';
                            }
                            $displayName = trim(($prenom !== '—' ? $prenom : '').' '.($nom !== '—' ? $nom : ''));
                            if ($displayName === '') {
                                $displayName = $equipe !== '—' ? $equipe : 'Intervenant';
                            }
                        @endphp
                        <tr class="eq-row eq-row--intervenant intervenant-from-mongo-row" data-eq-search="{{ strtolower($displayName.' '.$equipe.' '.$phone.' '.$email.' '.$zoneRaw) }}">
                            <td>
                                <div class="eq-person">
                                    <div class="eq-avatar" aria-hidden="true">{{ $eqInitials($nom, $prenom, $displayName) }}</div>
                                    <div class="eq-person-meta">
                                        <span class="eq-person-name">{{ $displayName }}</span>
                                        @if($nom !== '—' || $prenom !== '—')
                                            <span class="eq-person-sub">{{ $prenom !== '—' ? $prenom : '' }}{{ ($prenom !== '—' && $nom !== '—') ? ' · ' : '' }}{{ $nom !== '—' ? $nom : '' }}</span>
                                        @endif
                                    </div>
                                </div>
                            </td>
                            <td>
                                @if($equipe !== '—')
                                    <span class="eq-team-badge"><i class="fas fa-users"></i> {{ $equipe }}</span>
                                @else
                                    <span class="eq-empty-cell">Non assignée</span>
                                @endif
                            </td>
                            <td>
                                <div class="eq-contact-stack">
                                    @if($phone !== '—')
                                        <a href="tel:{{ preg_replace('/\s+/', '', $phone) }}" class="eq-contact-line eq-contact-line--phone">
                                            <i class="fas fa-phone"></i> {{ $phone }}
                                        </a>
                                    @endif
                                    @if($email !== '—')
                                        <a href="mailto:{{ $email }}" class="eq-contact-line eq-contact-line--email" title="{{ $email }}">
                                            <i class="fas fa-envelope"></i> {{ \Illuminate\Support\Str::limit($email, 28) }}
                                        </a>
                                    @endif
                                    @if($phone === '—' && $email === '—')
                                        <span class="eq-empty-cell">—</span>
                                    @endif
                                </div>
                            </td>
                            <td>
                                @if($isGps && $gps)
                                    <a href="https://www.google.com/maps?q={{ $gps['lat'] }},{{ $gps['lon'] }}" target="_blank" rel="noopener" class="eq-zone-gps" title="{{ $zoneRaw }}">
                                        <i class="fas fa-location-dot"></i>
                                        <span>{{ $gps['lat'] }}, {{ $gps['lon'] }}</span>
                                    </a>
                                @elseif($zoneRaw !== '—')
                                    <span class="eq-zone-chip"><i class="fas fa-map-pin"></i> {{ \Illuminate\Support\Str::limit($zoneRaw, 48) }}</span>
                                @else
                                    <span class="eq-empty-cell">Non renseignée</span>
                                @endif
                            </td>
                            <td class="eq-td-action">
                                <button type="button" class="eq-msg-btn eq-chat-open" data-type="intervenant" data-id="{{ $ivChatId }}" data-collection="{{ $ivChatCol }}" data-label="{{ $ivLabel }}" title="Discuter avec cet intervenant">
                                    <i class="fas fa-comment-dots" aria-hidden="true"></i>
                                    <span>Message</span>
                                </button>
                            </td>
                        </tr>
                    @endforeach

                    @if($totalRows === 0)
                        <tr class="eq-row eq-row--empty">
                            <td colspan="5">
                                <div class="eq-empty-state">
                                    <i class="fas fa-users-slash"></i>
                                    <p>Aucune donnée disponible</p>
                                    <span>Pas d'équipe en base module et aucun document dans les collections <code>intervenants</code> / <code>intervenant</code>.</span>
                                </div>
                            </td>
                        </tr>
                    @endif
                </tbody>
            </table>
            <div class="eq-no-results" id="eq-no-results" hidden>
                <i class="fas fa-magnifying-glass"></i>
                <p>Aucun résultat pour cette recherche</p>
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    var input = document.getElementById('eq-table-search');
    var table = document.getElementById('eq-intervenants-table');
    var empty = document.getElementById('eq-no-results');
    if (!input || !table) return;

    input.addEventListener('input', function () {
        var q = (input.value || '').trim().toLowerCase();
        var rows = table.querySelectorAll('tbody tr.eq-row:not(.eq-row--empty)');
        var visible = 0;

        rows.forEach(function (row) {
            var hay = row.getAttribute('data-eq-search') || row.textContent.toLowerCase();
            var show = !q || hay.indexOf(q) !== -1;
            row.style.display = show ? '' : 'none';
            if (show) visible++;
        });

        if (empty) {
            empty.hidden = !q || visible > 0 || rows.length === 0;
        }
    });
})();
</script>
