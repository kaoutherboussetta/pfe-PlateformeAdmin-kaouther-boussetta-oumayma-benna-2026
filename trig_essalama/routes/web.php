<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\WeatherController;
use App\Http\Controllers\SatelliteController;
use App\Http\Controllers\ProblemController;
use App\Http\Controllers\BudgetMonthlyIncomeController;
use App\Http\Controllers\EquipeInterventionController;
use App\Models\AdminAutoritaire;
use App\Models\Admin;
use App\Models\BudgetMonthlyIncome;
use App\Models\Budget;
use App\Support\AlertsAnalysis;
use App\Support\BudgetSummary;
use App\Support\CitizenAccountsAnalysis;

/*
|--------------------------------------------------------------------------
| Routes publiques
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return view('login');
});

Route::get('/login', [AuthController::class, 'login'])->name('login');
Route::post('/login', [AuthController::class, 'loginPost'])->name('login.post');

Route::get('/register', [AuthController::class, 'register'])->name('register');
Route::post('/register', [AuthController::class, 'registerPost'])->name('register.post');

Route::get('/forgot-password', function () {
    return view('forgot-password');
})->name('forgot-password');
Route::post('/forgot-password', [AuthController::class, 'forgotPasswordPost'])->name('forgot-password.post');

Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

/*
|--------------------------------------------------------------------------
| Dashboard
|--------------------------------------------------------------------------
|
| Cette route vérifie le guard et la session pour déterminer le type
| d'utilisateur (Admin Autoritaire, Admin Technique ou Utilisateur classique)
| et affiche la vue dashboard. Si aucun utilisateur n'est connecté,
| il redirige vers login.
|
*/
Route::get('/dashboard', function () {
    $user = null;
    $problemes = collect();
    $mapMarkers = [];
    $riskZones = collect();
    $riskZonesCount = 0;
    $problemesStats = [
        'en_attente' => 0,
        'en_cours' => 0,
        'termine' => 0,
        'critiques' => 0,
    ];

    // Admin autoritaire (authentifié via session)
    if (session('autoritaire_authenticated')) {
        // Essayer de récupérer l'utilisateur depuis la base de données si on a un admin_id
        $adminId = session('admin_id');
        if ($adminId) {
            $user = AdminAutoritaire::find($adminId);
            if (! $user && is_string($adminId) && preg_match('/^[a-f\d]{24}$/i', (string) $adminId)) {
                try {
                    $user = AdminAutoritaire::find(new \MongoDB\BSON\ObjectId((string) $adminId));
                } catch (\Throwable $e) {
                    // identifiant invalide
                }
            }
        }
        if (! $user) {
            $email = strtolower(trim((string) (session('admin_email') ?? '')));
            if ($email !== '') {
                $user = AdminAutoritaire::where('email', $email)->first()
                    ?? AdminAutoritaire::where('email', 'regex', '/^'.preg_quote($email, '/').'$/i')->first();
            }
        }

        // Si pas trouvé en DB, créer un objet session (fallback pour config)
        if (!$user) {
            $user = new \App\Models\AdminAutoritaireSession([
                'id' => 'autoritaire_1',
                'email' => session('admin_email'),
                'name' => session('admin_name', 'Administrateur Autoritaire'),
                'first_name' => config('admin_autoritaire.first_name', 'Admin'),
                'last_name' => config('admin_autoritaire.last_name', 'Autoritaire'),
                'role' => 'autoritaire',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
    // Admin technique authentifié via User (collection users_admin_tech)
    elseif (session('authenticated_admin_technical') && session('admin_type') === 'technical') {
        $adminId = session('admin_id');
        if ($adminId) {
            $user = \App\Models\User::find($adminId);
        }
    }
    // Admin technique (collection admins)
    elseif (Auth::guard('admin')->check()) {
        $admin = Auth::guard('admin')->user();
        $adminType = session('admin_type');
        // Vérifier si c'est un admin technique (via session ou via rôle du modèle)
        if ($adminType === 'technical' || (isset($admin->role) && $admin->role === 'technical')) {
            $user = $admin;
        }
    }
    // Utilisateur classique
    elseif (Auth::check()) {
        $user = Auth::user();
    }

    if (!$user) {
        return redirect()->route('login');
    }

    /** Exclure de la carte les alertes / problèmes liés à la température (ex. variable Open-Meteo hourly_temperature). */
    $excludeTemperatureRelatedMapMarker = static function (array $row): bool {
        $structParts = [
            (string) data_get($row, 'type'),
            (string) data_get($row, 'type_probleme'),
            (string) data_get($row, 'problem_type'),
            (string) data_get($row, 'categorie'),
            (string) data_get($row, 'category'),
            (string) data_get($row, 'type_carte'),
            (string) data_get($row, 'map_legend_type'),
            (string) data_get($row, 'icone_carte'),
            (string) data_get($row, 'titre'),
            (string) data_get($row, 'libelle'),
            (string) data_get($row, 'nom'),
            (string) data_get($row, 'kind'),
            (string) data_get($row, 'code'),
            (string) data_get($row, 'variable'),
            (string) data_get($row, 'metric'),
            (string) data_get($row, 'parameter'),
            (string) data_get($row, 'source'),
            (string) data_get($row, 'alert_type'),
            (string) data_get($row, 'weather_variable'),
        ];
        $haystack = strtolower(implode(' ', array_filter($structParts)));

        $hourlyTempSnippets = ['hourly_temperature', 'hourly temperature', 'hourly-temperature', 'hourlytemp'];
        foreach ($hourlyTempSnippets as $tok) {
            if ($haystack !== '' && str_contains($haystack, $tok)) {
                return true;
            }
        }

        $desc = strtolower(implode("\n", array_filter([
            (string) data_get($row, 'description'),
            (string) data_get($row, 'message'),
            (string) data_get($row, 'details'),
        ])));
        foreach (array_merge($hourlyTempSnippets, ['temperature_2m']) as $tok) {
            if ($desc !== '' && str_contains($desc, $tok)) {
                return true;
            }
        }

        if ($haystack === '') {
            return false;
        }

        return str_contains($haystack, 'température')
            || str_contains($haystack, 'temperature')
            || str_contains($haystack, 'thermique')
            || str_contains($haystack, 'canicule')
            || str_contains($haystack, 'vague de chaleur')
            || str_contains($haystack, 'chaleur extrême')
            || str_contains($haystack, 'froid intense');
    };

    try {
        // Ne jamais charger toute la collection (risque timeout 60s). Fenêtre récente pour le dashboard.
        $problemesTable = DB::connection('mongodb')->table('problemes_de_voirie');
        try {
            $rawProblemes = $problemesTable->orderBy('_id', 'desc')->limit(3000)->get();
        } catch (\Throwable $e) {
            $rawProblemes = $problemesTable->limit(3000)->get();
        }

        $problemes = collect($rawProblemes)->map(function ($item) {
            $row = is_array($item) ? $item : (array) $item;

            $pick = static function (array $keys, $default = null) use ($row) {
                foreach ($keys as $key) {
                    $value = data_get($row, $key);
                    if ($value !== null && $value !== '') {
                        return $value;
                    }
                }

                return $default;
            };

            $riskScore = (int) $pick(['score_risque', 'risk_score', 'score', 'riskScore'], 0);
            $confidenceRaw = $pick(['confiance_ia', 'confidence_ia', 'confidence', 'ai_confidence'], 0);
            $priority = (int) $pick(['priorite', 'priority', 'priority_level'], 0);
            $severity = (string) $pick(['gravite', 'severity'], 'Moyenne');
            $status = (string) $pick(['statut', 'status'], 'En attente');
            $problemTypeRaw = strtolower(trim((string) $pick(['type', 'type_probleme', 'problem_type', 'categorie'], 'Problème')));

            $displayType = match ($problemTypeRaw) {
                'crack', 'fissure' => 'Fissure',
                'pothole', 'nid-de-poule', 'nid de poule' => 'Nid-de-poule',
                'subsidence', 'affaissement' => 'Affaissement',
                'flood', 'flooding', 'zone submergee', 'zone submergée' => 'Zone submergée',
                default => ucfirst($problemTypeRaw ?: 'Problème'),
            };

            $confidenceNumeric = is_numeric($confidenceRaw) ? (float) $confidenceRaw : 0.0;
            $confidencePct = $confidenceNumeric <= 1
                ? (int) round($confidenceNumeric * 100)
                : (int) round($confidenceNumeric);
            $confidencePct = max(0, min($confidencePct, 100));

            $lat = $pick(['location.lat', 'lat', 'latitude'], null);
            $lon = $pick(['location.lon', 'location.lng', 'lon', 'lng', 'longitude'], null);

            if (!is_numeric($lat) || !is_numeric($lon)) {
                $coords = data_get($row, 'location.coordinates');
                if (is_array($coords) && count($coords) >= 2
                    && is_numeric($coords[0]) && is_numeric($coords[1])) {
                    // GeoJSON : [longitude, latitude]
                    $lon = $coords[0];
                    $lat = $coords[1];
                }
            }

            $latitude = is_numeric($lat) ? (float) $lat : null;
            $longitude = is_numeric($lon) ? (float) $lon : null;

            $accuracyRaw = $pick(['location.accuracy', 'gps_accuracy', 'accuracy', 'location.horizontalAccuracy'], null);
            $accuracyM = is_numeric($accuracyRaw) ? (float) $accuracyRaw : null;

            $textAddress = $pick(['localisation', 'location.address', 'address', 'adresse'], null);
            if (is_array($textAddress) || is_object($textAddress)) {
                $textAddress = json_encode($textAddress, JSON_UNESCAPED_UNICODE);
            }
            $textAddress = trim((string) ($textAddress ?? ''));

            // Même source que le lien GPS : coordonnées exactes du document (pas l’adresse texte seule)
            if ($latitude !== null && $longitude !== null) {
                $rawAddress = sprintf('lat: %.6f, lon: %.6f', $latitude, $longitude);
                if ($accuracyM !== null && $accuracyM > 0) {
                    $rawAddress .= sprintf(', précision: %sm', (int) round($accuracyM));
                }
            } elseif ($textAddress !== '') {
                $rawAddress = $textAddress;
            } else {
                $rawAddress = 'Localisation inconnue';
            }

            if ($priority <= 0) {
                $priority = max(1, min(6, (int) ceil((101 - max(0, min($riskScore, 100))) / 17)));
            }

            $rawDate = $pick(['date_detection', 'detected_at', 'created_at', 'date'], now());
            if ($rawDate instanceof \MongoDB\BSON\UTCDateTime) {
                $detectedAt = \Carbon\Carbon::instance($rawDate->toDateTime());
            } elseif ($rawDate instanceof \DateTimeInterface) {
                $detectedAt = \Carbon\Carbon::instance($rawDate);
            } else {
                try {
                    $detectedAt = \Carbon\Carbon::parse((string) $rawDate);
                } catch (\Throwable $e) {
                    $detectedAt = now();
                }
            }

            $docId = $pick(['_id', 'id'], null);
            if ($docId instanceof \MongoDB\BSON\ObjectId) {
                $docId = (string) $docId;
            } elseif (is_object($docId) && method_exists($docId, '__toString')) {
                $docId = (string) $docId;
            } else {
                $docId = (string) $docId;
            }

            return [
                'id' => $docId,
                'type' => $displayType,
                'localisation' => $rawAddress,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'risk_score' => max(0, min($riskScore, 100)),
                'gravite' => $severity,
                'confiance' => $confidencePct,
                'date_detection' => $detectedAt->format('Y-m-d H:i'),
                'statut' => $status,
                'equipe' => (string) $pick(['equipe', 'assigned_team', 'team'], 'Non assignée'),
                'description' => (string) $pick(
                    ['description', 'details', 'notes'],
                    sprintf(
                        '%s détecté par %s (défauts: %s).',
                        $displayType,
                        (string) $pick(['ai_model', 'model'], 'IA'),
                        (string) $pick(['total_defects', 'defects_count'], 'N/A')
                    )
                ),
                'cout_estime' => (string) $pick(['cout_estime', 'estimated_cost', 'cost'], 'N/A'),
                'priorite' => $priority,
            ];
        })->sortBy([
            ['priorite', 'asc'],
            ['risk_score', 'desc'],
        ])->values()->map(function (array $problem, int $index) {
            $problem['priority_rank'] = $index + 1;
            $problem['priority_code'] = 'P' . max(1, min(6, $problem['priorite']));

            return $problem;
        })->values();

        try {
            $problemIds = $problemes->pluck('id')->filter()->unique()->values()->all();
            if ($problemIds !== []) {
                $budgetByProblemId = Budget::query()
                    ->whereIn('problem_id', $problemIds)
                    ->get()
                    ->keyBy('problem_id');
                $problemes = $problemes->map(function (array $p) use ($budgetByProblemId) {
                    $pid = (string) ($p['id'] ?? '');
                    $cur = trim((string) ($p['cout_estime'] ?? ''));
                    $missing = $cur === '' || strcasecmp($cur, 'N/A') === 0 || $cur === '—' || $cur === '-';
                    if ($pid !== '' && $missing && $budgetByProblemId->has($pid)) {
                        $p['cout_estime'] = (string) $budgetByProblemId->get($pid)->cout_estime;
                    }

                    return $p;
                });
            }
        } catch (\Throwable $e) {
            Log::debug('Dashboard: fusion coûts (table budget SQL) ignorée', ['error' => $e->getMessage()]);
        }

        $statusNormalizer = static function (?string $status): string {
            $value = strtolower(trim((string) $status));

            return match ($value) {
                'en cours', 'en_cours', 'encours', 'in progress' => 'en_cours',
                'termine', 'terminé', 'completed', 'done' => 'termine',
                default => 'en_attente',
            };
        };

        $problemesStats = [
            'en_attente' => $problemes->filter(fn ($p) => $statusNormalizer($p['statut']) === 'en_attente')->count(),
            'en_cours' => $problemes->filter(fn ($p) => $statusNormalizer($p['statut']) === 'en_cours')->count(),
            'termine' => $problemes->filter(fn ($p) => $statusNormalizer($p['statut']) === 'termine')->count(),
            'critiques' => $problemes->filter(function ($p) {
                $gravite = strtolower(trim((string) ($p['gravite'] ?? '')));

                return $gravite === 'critique' || (int) ($p['risk_score'] ?? 0) >= 85;
            })->count(),
        ];

        $mapMarkers = $problemes
            ->filter(fn ($p) => isset($p['latitude'], $p['longitude']) && is_numeric($p['latitude']) && is_numeric($p['longitude']))
            ->filter(fn (array $p) => ! $excludeTemperatureRelatedMapMarker($p))
            ->values()
            ->map(function (array $p, int $index) {
                $typeLower = strtolower((string) ($p['type'] ?? ''));
                $statusLower = strtolower((string) ($p['statut'] ?? ''));
                $riskScore = (int) ($p['risk_score'] ?? 0);

                $mapType = 'circulation';
                if (str_contains($typeLower, 'submer') || str_contains($typeLower, 'inond')) {
                    $mapType = 'zone_inondable';
                } elseif (str_contains($statusLower, 'cours')) {
                    $mapType = 'chantier_en_cours';
                } elseif ($riskScore >= 80) {
                    $mapType = 'alerte_active';
                } elseif (
                    str_contains($typeLower, 'fissure')
                    || str_contains($typeLower, 'nid')
                    || str_contains($typeLower, 'affaisse')
                    || str_contains($typeLower, 'détérioration')
                ) {
                    $mapType = 'route_degradee';
                }

                $statutLabel = trim((string) ($p['statut'] ?? 'En attente'));
                $interventionBadge = str_contains($statusLower, 'cours')
                    ? '<br><span style="color:#C2410C;font-weight:700;">Intervention en cours</span>'
                    : '';

                $docId = (string) ($p['id'] ?? ('idx_' . $index));

                return [
                    'id' => $docId,
                    'type' => $mapType,
                    'lat' => (float) $p['latitude'],
                    'lng' => (float) $p['longitude'],
                    'popup' => sprintf(
                        '<strong>%s</strong><br>%s<br>Score: %d · Gravité: %s · Statut: %s%s',
                        e($p['type'] ?? 'Problème'),
                        e($p['localisation'] ?? 'Localisation inconnue'),
                        $riskScore,
                        e($p['gravite'] ?? 'Moyenne'),
                        e($statutLabel),
                        $interventionBadge
                    ),
                ];
            })
            ->all();
    } catch (\Throwable $e) {
        \Illuminate\Support\Facades\Log::warning('Impossible de charger problemes_de_voirie', [
            'error' => $e->getMessage(),
        ]);
    }

    // ---------- Analyse pour le panneau "Analyse" ----------
    $problemsAnalysis = [
        'total' => 0,
        'avgRisk' => 0,
        'avgConfidence' => 0,
        'bySeverity' => [],
        'byType' => [],
        'labels' => [],
        'perMonth' => [],
    ];
    $analyseKpis = [
        'total' => 0,
        'avgResolutionDays' => 0.0,
        'completionRatePct' => 0,
        'budgetUsedPct' => 0,
        'budgetUsedLabel' => null,
    ];
    try {
        $items = collect($rawProblemes ?? []);

        // total
        $problemsAnalysis['total'] = $items->count();
        $analyseKpis['total'] = $problemsAnalysis['total'];

        // moyennes
        $avgRisk = $items->avg(function ($row) {
            $arr = (array) $row;
            return (float) ($arr['risk_score'] ?? $arr['score_risque'] ?? 0);
        });
        $avgConf = $items->avg(function ($row) {
            $arr = (array) $row;
            $v = $arr['confidence'] ?? $arr['confiance_ia'] ?? $arr['confidence_ia'] ?? 0;
            $f = is_numeric($v) ? (float) $v : 0.0;
            if ($f <= 1) $f *= 100;
            return $f;
        });
        $problemsAnalysis['avgRisk'] = round((float) ($avgRisk ?? 0), 2);
        $problemsAnalysis['avgConfidence'] = round((float) ($avgConf ?? 0), 0);

        // bySeverity
        $sevCounts = [];
        foreach ($items as $row) {
            $arr = (array) $row;
            $sev = (string) ($arr['severity'] ?? $arr['gravite'] ?? 'Moyenne');
            $sevCounts[$sev] = ($sevCounts[$sev] ?? 0) + 1;
        }
        $problemsAnalysis['bySeverity'] = $sevCounts;

        // byType (top 6)
        $typeCounts = [];
        foreach ($items as $row) {
            $arr = (array) $row;
            $type = strtolower(trim((string)($arr['problem_type'] ?? $arr['type'] ?? $arr['categorie'] ?? 'inconnu')));
            $typeCounts[$type] = ($typeCounts[$type] ?? 0) + 1;
        }
        arsort($typeCounts);
        $top = array_slice($typeCounts, 0, 6, true);
        $byTypeArr = [];
        foreach ($top as $k => $v) {
            $o = new \stdClass();
            $o->problem_type = $k;
            $o->c = $v;
            $byTypeArr[] = $o;
        }
        $problemsAnalysis['byType'] = $byTypeArr;

        // monthly (7 derniers mois) sur date_detection/detected_at/created_at
        $months = collect(range(6,0))->map(fn($i)=>now()->subMonths($i));
        $ymKeys = $months->map(fn($d)=>$d->format('Y-m'));
        $labels = $months->map(fn($d)=>$d->locale('fr_FR')->isoFormat('MMM'))->values()->all();
        $bucket = array_fill_keys($ymKeys->all(), 0);
        foreach ($items as $row) {
            $arr = (array) $row;
            $rawDate = $arr['date_detection'] ?? $arr['detected_at'] ?? $arr['created_at'] ?? null;
            try {
                if ($rawDate instanceof \MongoDB\BSON\UTCDateTime) {
                    $dt = \Carbon\Carbon::instance($rawDate->toDateTime());
                } elseif ($rawDate instanceof \DateTimeInterface) {
                    $dt = \Carbon\Carbon::instance($rawDate);
                } else {
                    $dt = \Carbon\Carbon::parse((string) $rawDate);
                }
                $ym = $dt->format('Y-m');
                if (array_key_exists($ym, $bucket)) $bucket[$ym] += 1;
            } catch (\Throwable $e) {
                // ignore
            }
        }
        $problemsAnalysis['labels'] = $labels;
        $problemsAnalysis['perMonth'] = array_values($bucket);

        // ---- KPIs supplémentaires ----
        // Taux de réalisation
        $completed = $items->filter(function ($row) {
            $arr = (array) $row;
            $status = strtolower(trim((string) ($arr['status'] ?? $arr['statut'] ?? '')));
            return str_contains($status, 'term') || str_contains($status, 'done') || str_contains($status, 'résolu') || str_contains($status, 'resolu');
        })->count();
        $total = max(1, $items->count());
        $analyseKpis['completionRatePct'] = (int) round(($completed / $total) * 100);

        // Durée moyenne de résolution (jours) pour les éléments avec date de résolution
        $durationsHours = [];
        foreach ($items as $row) {
            $arr = (array) $row;
            $start = $arr['date_detection'] ?? $arr['detected_at'] ?? $arr['created_at'] ?? null;
            $end = $arr['resolved_at'] ?? $arr['date_resolution'] ?? $arr['closed_at'] ?? $arr['resolution_date'] ?? null;
            if (!$start || !$end) continue;
            try {
                $s = $start instanceof \MongoDB\BSON\UTCDateTime ? \Carbon\Carbon::instance($start->toDateTime()) : \Carbon\Carbon::parse((string) $start);
                $e = $end instanceof \MongoDB\BSON\UTCDateTime ? \Carbon\Carbon::instance($end->toDateTime()) : \Carbon\Carbon::parse((string) $end);
                if ($e->greaterThan($s)) {
                    $durationsHours[] = $e->diffInHours($s);
                }
            } catch (\Throwable $e) {
                // ignore invalid rows
            }
        }
        if (!empty($durationsHours)) {
            $analyseKpis['avgResolutionDays'] = round(array_sum($durationsHours) / count($durationsHours) / 24, 1);
        }

        // Budget utilisé (optionnel) basé sur coût estimé
        $sumCost = 0.0;
        foreach ($items as $row) {
            $arr = (array) $row;
            $raw = $arr['cout_estime'] ?? $arr['estimated_cost'] ?? $arr['cost'] ?? null;
            if ($raw === null) continue;
            // extraire nombre (autoriser "35 000 €", "2.4M", "1,200,000")
            $str = trim((string) $raw);
            if ($str === '') continue;
            $num = 0.0;
            if (preg_match('/([0-9]+(?:[\\s,\\.][0-9]{3})*|[0-9]*\\.?[0-9]+)\\s*([kKmM]?)\\b/u', str_replace(['€', 'TND', 'DT'], '', $str), $m)) {
                $base = (float) str_replace([',', ' '], ['', ''], $m[1]);
                $suffix = strtolower($m[2] ?? '');
                $mult = $suffix === 'm' ? 1_000_000 : ($suffix === 'k' ? 1_000 : 1);
                $num = $base * $mult;
            }
            if ($num > 0) $sumCost += $num;
        }
        $totalBudget = (float) (config('app.total_budget', 3_500_000));
        if ($totalBudget > 0) {
            $analyseKpis['budgetUsedPct'] = (int) round(min(100, ($sumCost / $totalBudget) * 100));
            $analyseKpis['budgetUsedLabel'] = sprintf('%s / %s',
                number_format($sumCost, 1, ',', ' '),
                number_format($totalBudget, 1, ',', ' ')
            );
        }
    } catch (\Throwable $e) {
        // silencieux
    }

    /*
    | Marqueurs carte : collections Mongo `alert` (alerte active / zone inondable)
    | et `intervenant` (chantier en cours), avec les types d’icônes déjà gérés par le dashboard.
    */
    $alertsLayerMarkers = [];
    $intervenantsLayerMarkers = [];

    $extractLatLngForMap = static function (array $row): ?array {
        $lat = data_get($row, 'lat')
            ?? data_get($row, 'latitude')
            ?? data_get($row, 'location.lat');
        $lon = data_get($row, 'lon')
            ?? data_get($row, 'lng')
            ?? data_get($row, 'longitude')
            ?? data_get($row, 'location.lon')
            ?? data_get($row, 'location.lng');

        $coords = data_get($row, 'location.coordinates');
        if (is_array($coords) && count($coords) >= 2
            && is_numeric($coords[0]) && is_numeric($coords[1])) {
            $lon = $coords[0];
            $lat = $coords[1];
        }

        if (! is_numeric($lat) || ! is_numeric($lon)) {
            return null;
        }

        return [(float) $lat, (float) $lon];
    };

    $mongoDocIdString = static function (array $row): string {
        $id = $row['_id'] ?? $row['id'] ?? null;
        if ($id instanceof \MongoDB\BSON\ObjectId) {
            return (string) $id;
        }

        return (string) ($id ?? uniqid('map_', true));
    };

    $mapAlertRowToLegendType = static function (array $row): string {
        $explicit = strtolower(trim((string) (
            data_get($row, 'type_carte')
            ?? data_get($row, 'icone_carte')
            ?? data_get($row, 'map_legend_type')
            ?? ''
        )));
        foreach (['zone_inondable', 'zone-inondable', 'inondable'] as $token) {
            if ($explicit === $token || str_contains($explicit, $token)) {
                return 'zone_inondable';
            }
        }
        foreach (['alerte_active', 'alerte-active', 'critique', 'danger'] as $token) {
            if ($explicit === $token || str_contains($explicit, $token)) {
                return 'alerte_active';
            }
        }

        $haystack = strtolower(trim(implode(' ', array_filter([
            (string) data_get($row, 'type'),
            (string) data_get($row, 'categorie'),
            (string) data_get($row, 'category'),
            (string) data_get($row, 'niveau'),
            (string) data_get($row, 'libelle'),
            (string) data_get($row, 'titre'),
            (string) data_get($row, 'statut'),
        ]))));

        if ($haystack !== '' && (
            str_contains($haystack, 'inond')
            || str_contains($haystack, 'flood')
            || str_contains($haystack, 'submer')
            || str_contains($haystack, 'zone inond')
        )) {
            return 'zone_inondable';
        }

        return 'alerte_active';
    };

    foreach (['alert', 'alerts'] as $alertCollection) {
        try {
            foreach (DB::connection('mongodb')->table($alertCollection)->limit(800)->get() as $doc) {
                $row = is_array($doc) ? $doc : (array) $doc;
                if ($excludeTemperatureRelatedMapMarker($row)) {
                    continue;
                }
                $coords = $extractLatLngForMap($row);
                if ($coords === null) {
                    continue;
                }
                [$lat, $lng] = $coords;
                $legendType = $mapAlertRowToLegendType($row);
                $title = (string) (data_get($row, 'titre')
                    ?: data_get($row, 'libelle')
                    ?: data_get($row, 'nom')
                    ?: 'Alerte');
                $desc = (string) (data_get($row, 'description')
                    ?: data_get($row, 'message')
                    ?: data_get($row, 'details')
                    ?: '—');
                $alertsLayerMarkers[] = [
                    'id' => 'alert_' . $alertCollection . '_' . $mongoDocIdString($row),
                    'type' => $legendType,
                    'lat' => $lat,
                    'lng' => $lng,
                    'popup' => '<strong>'.e($title).'</strong><br>'.e($desc)
                        .'<br><small style="color:#737373;">Source : '.$alertCollection.' · '
                        .($legendType === 'zone_inondable' ? 'Zone inondable' : 'Alerte active')
                        .'</small>',
                ];
            }
        } catch (\Throwable $e) {
            Log::warning('Carte : collection alert indisponible ou vide', [
                'collection' => $alertCollection,
                'error' => $e->getMessage(),
            ]);
        }
    }

    foreach (['intervenant', 'intervenants'] as $interCollection) {
        try {
            foreach (DB::connection('mongodb')->table($interCollection)->limit(800)->get() as $doc) {
                $row = is_array($doc) ? $doc : (array) $doc;
                $coords = $extractLatLngForMap($row);
                if ($coords === null) {
                    continue;
                }
                [$lat, $lng] = $coords;
                $title = (string) (data_get($row, 'titre')
                    ?: data_get($row, 'libelle')
                    ?: data_get($row, 'nom')
                    ?: data_get($row, 'equipe')
                    ?: 'Intervention');
                $desc = (string) (data_get($row, 'description')
                    ?: data_get($row, 'commentaire')
                    ?: data_get($row, 'adresse')
                    ?: '—');
                $intervenantsLayerMarkers[] = [
                    'id' => 'intervenant_' . $interCollection . '_' . $mongoDocIdString($row),
                    'type' => 'chantier_en_cours',
                    'lat' => $lat,
                    'lng' => $lng,
                    'popup' => '<strong>'.e($title).'</strong><br>'.e($desc)
                        .'<br><small style="color:#737373;">Source : '.$interCollection.' · Chantier en cours</small>',
                ];
            }
        } catch (\Throwable $e) {
            Log::warning('Carte : collection intervenant indisponible ou vide', [
                'collection' => $interCollection,
                'error' => $e->getMessage(),
            ]);
        }
    }

    $allDashboardMarkers = array_values(array_merge(
        $mapMarkers,
        $alertsLayerMarkers,
        $intervenantsLayerMarkers
    ));

    try {
        $rawRiskZones = DB::connection('mongodb')->table('zones_risque')->limit(500)->get();
        $riskZones = collect($rawRiskZones)
            ->map(function ($item) {
                $row = is_array($item) ? $item : (array) $item;

                $pick = static function (array $keys, $default = null) use ($row) {
                    foreach ($keys as $key) {
                        $value = data_get($row, $key);
                        if ($value !== null && $value !== '') {
                            return $value;
                        }
                    }

                    return $default;
                };

                $name = trim((string) $pick(
                    ['nom', 'name', 'zone_name', 'titre', 'libelle'],
                    'Zone à risque'
                ));
                $placeText = trim((string) $pick(
                    ['localisation', 'location.address', 'adresse', 'zone', 'quartier', 'region', 'ville', 'place'],
                    ''
                ));
                $category = trim((string) $pick(
                    ['categorie', 'category', 'type', 'type_risque', 'risk_type'],
                    ''
                ));
                $status = trim((string) $pick(
                    ['status_label', 'description', 'message', 'details', 'statut', 'status'],
                    ''
                ));
                $riskRaw = strtolower(trim((string) $pick(
                    ['risk_level', 'risk', 'niveau_risque', 'severity', 'gravite'],
                    ''
                )));

                $severityClass = (
                    str_contains($riskRaw, 'high')
                    || str_contains($riskRaw, 'élev')
                    || str_contains($riskRaw, 'crit')
                    || str_contains($riskRaw, 'danger')
                ) ? 'red' : 'orange';

                if ($status === '') {
                    $status = $severityClass === 'red'
                        ? 'Risque inondation élevé'
                        : 'Surveillance renforcée';
                }

                $lat = $pick(['lat', 'latitude', 'location.lat'], null);
                $lon = $pick(['lon', 'lng', 'longitude', 'location.lon', 'location.lng'], null);

                $coords = data_get($row, 'coordinates');
                if ((! is_numeric($lat) || ! is_numeric($lon)) && is_array($coords)
                    && count($coords) >= 2 && is_numeric($coords[0]) && is_numeric($coords[1])) {
                    // GeoJSON standard: [lon, lat]
                    $lon = $coords[0];
                    $lat = $coords[1];
                }

                $nestedCoords = data_get($row, 'location.coordinates');
                if ((! is_numeric($lat) || ! is_numeric($lon)) && is_array($nestedCoords)
                    && count($nestedCoords) >= 2 && is_numeric($nestedCoords[0]) && is_numeric($nestedCoords[1])) {
                    $lon = $nestedCoords[0];
                    $lat = $nestedCoords[1];
                }

                $geomCoords = data_get($row, 'geometry.coordinates');
                if ((! is_numeric($lat) || ! is_numeric($lon)) && is_array($geomCoords)
                    && count($geomCoords) >= 2 && is_numeric($geomCoords[0]) && is_numeric($geomCoords[1])) {
                    $lon = $geomCoords[0];
                    $lat = $geomCoords[1];
                }

                $gpsLat = (is_numeric($lat) && is_numeric($lon)) ? (float) $lat : null;
                $gpsLon = (is_numeric($lat) && is_numeric($lon)) ? (float) $lon : null;

                if ($category === '') {
                    $category = 'Non spécifiée';
                }

                return [
                    'name' => $name,
                    'place_text' => $placeText,
                    'gps_lat' => $gpsLat,
                    'gps_lon' => $gpsLon,
                    'category' => ucfirst($category),
                    'status' => $status,
                    'severity_class' => $severityClass,
                ];
            })
            ->filter(fn (array $zone) => $zone['name'] !== '')
            ->values();

        $riskZonesCount = $riskZones->count();
        $riskZones = $riskZones->take(6);
    } catch (\Throwable $e) {
        Log::warning('Dashboard : collection zones_risque indisponible ou vide', [
            'collection' => 'zones_risque',
            'error' => $e->getMessage(),
        ]);
    }

    $alertsAnalysis = AlertsAnalysis::aggregateFromMongo();
    $citizenAccountsAnalysis = CitizenAccountsAnalysis::aggregateFromMongo();

    // Gestion du statut dans la liste des problèmes : admin autoritaire ou admin technique connecté au tableau de bord
    $canEditProblemStatus = session('autoritaire_authenticated') === true
        || session('authenticated_admin_technical') === true
        || (
            Auth::guard('admin')->check()
            && (
                session('admin_type') === 'technical'
                || (optional(Auth::guard('admin')->user())->role ?? null) === 'technical'
            )
        );

    return view('admin.dashboard', [
        'user' => $user,
        'problemes' => $problemes,
        'problemesStats' => $problemesStats,
        'mapMarkers' => $mapMarkers,
        'allDashboardMarkers' => $allDashboardMarkers,
        'problemsAnalysis' => $problemsAnalysis,
        'analyseKpis' => $analyseKpis,
        'canEditProblemStatus' => $canEditProblemStatus,
        'riskZones' => $riskZones,
        'riskZonesCount' => $riskZonesCount,
        'alertsAnalysis' => $alertsAnalysis,
        'citizenAccountsAnalysis' => $citizenAccountsAnalysis,
        'budgetDashboard' => (static function (): array {
            $cfg = config('trig_budget', []);
            if (! is_array($cfg)) {
                $cfg = [];
            }
            $month = request()->query('budget_month', now()->format('Y-m'));
            if (! is_string($month) || ! preg_match('/^\d{4}-\d{2}$/', $month)) {
                $month = now()->format('Y-m');
            }
            $cfg['selected_budget_month'] = $month;
            try {
                $summary = BudgetSummary::forMonth($month);
                $cfg['budget_summary'] = $summary;
                $cfg['monthly_income_dnt'] = (int) ($summary['income_initial'] ?? config('trig_budget.monthly_income_dnt', 100_000_000));
                $cfg['monthly_income_remaining'] = (int) ($summary['income_remaining'] ?? $cfg['monthly_income_dnt']);
                $cfg['total_couts_estimes'] = (int) ($summary['total_spent'] ?? 0);
                if (! empty($summary['currency'])) {
                    $cfg['currency'] = (string) $summary['currency'];
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::debug('Budget mensuel: lecture SQL ignorée', ['error' => $e->getMessage()]);
            }

            return $cfg;
        })(),
        ...app(EquipeInterventionController::class)->embedViewData(request(), $user),
    ]);
})->middleware('autoritaire.auth')->name('dashboard');


/*
|--------------------------------------------------------------------------
| Routes protégées par authentification
|--------------------------------------------------------------------------
*/
Route::middleware(['autoritaire.auth'])->group(function () {

    // Interface Admin Technique
    Route::get('/interface_admin_tech', [AdminController::class, 'interfaceAdminTech'])->name('interface_admin_tech');

    Route::get('/interface_admin_tech/equipes', [EquipeInterventionController::class, 'index'])->name('interface_admin_tech.equipes');
    Route::post('/interface_admin_tech/equipes', [EquipeInterventionController::class, 'store'])->name('interface_admin_tech.equipes.store');
    Route::put('/interface_admin_tech/equipes/{id}', [EquipeInterventionController::class, 'update'])->name('interface_admin_tech.equipes.update');
    Route::delete('/interface_admin_tech/equipes/{id}', [EquipeInterventionController::class, 'destroy'])->name('interface_admin_tech.equipes.destroy');
    Route::post('/interface_admin_tech/equipes/{id}/assign', [EquipeInterventionController::class, 'assign'])->name('interface_admin_tech.equipes.assign');
    Route::get('/interface_admin_tech/equipes/chat/messages', [EquipeInterventionController::class, 'chatMessages'])->name('interface_admin_tech.equipes.chat.messages');
    Route::put('/interface_admin_tech/equipes/chat/messages/{id}', [EquipeInterventionController::class, 'chatMessageUpdate'])->name('interface_admin_tech.equipes.chat.messages.update');
    Route::delete('/interface_admin_tech/equipes/chat/messages/{id}', [EquipeInterventionController::class, 'chatMessageDestroy'])->name('interface_admin_tech.equipes.chat.messages.destroy');
    Route::post('/interface_admin_tech/equipes/chat/send', [EquipeInterventionController::class, 'chatSend'])->name('interface_admin_tech.equipes.chat.send');
    Route::post('/interface_admin_tech/equipes/chat/voice', [EquipeInterventionController::class, 'chatVoiceUpload'])->name('interface_admin_tech.equipes.chat.voice.upload');
    Route::get('/interface_admin_tech/equipes/chat/voice/{id}', [EquipeInterventionController::class, 'chatVoiceStream'])->name('interface_admin_tech.equipes.chat.voice.stream');
    Route::post('/interface_admin_tech/equipes/chat/image', [EquipeInterventionController::class, 'chatImageUpload'])->name('interface_admin_tech.equipes.chat.image.upload');
    Route::get('/interface_admin_tech/equipes/chat/image/{id}', [EquipeInterventionController::class, 'chatImageStream'])->name('interface_admin_tech.equipes.chat.image.stream');
    Route::get('/api/chat-intervenant/notifications', [EquipeInterventionController::class, 'chatIntervenantNotifications'])->name('api.chat_intervenant.notifications');
    Route::get('/api/chat-intervenant/recipient-counts', [EquipeInterventionController::class, 'chatIntervenantRecipientCounts'])->name('api.chat_intervenant.recipient_counts');

    // Page de profil
    Route::get('/profile', [AdminController::class, 'profile'])->name('profile');
    Route::get('/profil_admin_Autoritaire', [AdminController::class, 'profilAdminAutoritaire'])->name('profil_admin_Autoritaire');

    // API et actions admin technique
    Route::get('/api/stats/status', [AdminController::class, 'getStatusStats'])->name('api.stats.status');
    Route::post('/interface_admin_tech/backup', [AdminController::class, 'forceBackup'])->name('admin.force_backup');
    Route::post('/admin/autoritaire/store', [AdminController::class, 'storeAutoritaire'])->name('admin.autoritaire.store');

    // Gestion Admin Autoritaire
    Route::prefix('admin/autoritaire')->group(function () {
        Route::post('{id}/toggle', [AdminController::class, 'toggleAdminStatus'])->name('admin.autoritaire.toggle');
        Route::delete('{id}', [AdminController::class, 'deleteAdmin'])->name('admin.autoritaire.delete');
        Route::post('{id}/reset-password', [AdminController::class, 'resetAdminPassword'])->name('admin.autoritaire.reset-password');
    });

    // Gestion Utilisateur
    Route::post('/user/update-profile', [AdminController::class, 'updateProfile'])->name('user.update-profile');
    Route::post('/user/update-profile-photo', [AdminController::class, 'updateProfilePhoto'])->name('user.update-profile-photo');
    Route::post('/user/change-password', [AdminController::class, 'changeUserPassword'])->name('user.change-password');

    // Gestion Comptes Citoyens
    Route::prefix('citizen')->group(function () {
        Route::post('{id}/toggle', [AdminController::class, 'toggleCitizenStatus'])->name('citizen.toggle');
        Route::delete('{id}', [AdminController::class, 'deleteCitizen'])->name('citizen.delete');
        Route::post('{id}/reset-password', [AdminController::class, 'resetCitizenPassword'])->name('citizen.reset-password');
    });

    // Suppression intervenant (MongoDB : collections `intervenants` / `intervenant`)
    Route::delete('intervenant/{collection}/{id}', [AdminController::class, 'deleteIntervenant'])
        ->name('intervenant.delete')
        ->where('collection', 'intervenants|intervenant')
        ->where('id', '[^/]+');

    // Vues statiques protégées
    Route::get('/alertes', function () {
        return view('alertes');
    })->name('alertes');

    Route::get('/interventions', function () {
        return view('interventions');
    })->name('interventions');

    // Mettre à jour le statut d'un problème (depuis le tableau, persistant)
    Route::post('/problems/{id}/status', [ProblemController::class, 'updateStatus'])->name('problems.update-status');
    Route::post('/problems/{id}/assign-team', [ProblemController::class, 'assignTeam'])->name('problems.assign-team');
    Route::get('/api/budget/monthly-income', [BudgetMonthlyIncomeController::class, 'show'])->name('api.budget.monthly-income.show');
    Route::post('/api/budget/monthly-income', [BudgetMonthlyIncomeController::class, 'store'])->name('api.budget.monthly-income.store');

    // API simple: statistiques temps réel des problèmes
    Route::get('/api/problems/stats', function () {
        try {
            try {
                $raw = DB::connection('mongodb')->table('problemes_de_voirie')->orderBy('_id', 'desc')->limit(5000)->get();
            } catch (\Throwable $e) {
                $raw = DB::connection('mongodb')->table('problemes_de_voirie')->limit(5000)->get();
            }
            $items = collect($raw)->map(function ($item) {
                $row = is_array($item) ? $item : (array) $item;
                $status = strtolower(trim((string) ($row['status'] ?? $row['statut'] ?? 'en attente')));
                $risk = (int) (($row['risk_score'] ?? $row['score_risque'] ?? 0));
                $severity = strtolower(trim((string) ($row['severity'] ?? $row['gravite'] ?? '')));
                $norm = match (true) {
                    str_contains($status, 'cours') => 'en_cours',
                    str_contains($status, 'term') => 'termine',
                    default => 'en_attente',
                };
                return [
                    'status' => $norm,
                    'risk' => $risk,
                    'severity' => $severity,
                ];
            });

            $enAttente = $items->where('status', 'en_attente')->count();
            $enCours = $items->where('status', 'en_cours')->count();
            $termine = $items->where('status', 'termine')->count();
            $critiques = $items->filter(fn ($i) => $i['risk'] >= 85 || str_contains($i['severity'], 'critique'))->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'en_attente' => $enAttente,
                    'en_cours' => $enCours,
                    'termine' => $termine,
                    'critiques' => $critiques,
                ],
                'refreshed_at' => now()->toIso8601String(),
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    })->name('api.problems.stats');
});

/*
|--------------------------------------------------------------------------
| API Météo
|--------------------------------------------------------------------------
*/

Route::get('/weather/{lat}/{lon}', [WeatherController::class, 'getWeather'])->name('weather.get');
Route::get('/weather-alert/{lat}/{lon}', [WeatherController::class, 'getWeatherAlert'])->name('weather.alert');
Route::get('/weather-risk/{lat}/{lon}', [WeatherController::class, 'weatherRisk'])->name('weather.risk');
Route::get('/weather/dashboard-summary/{lat}/{lon}', [WeatherController::class, 'dashboardSummary'])->name('weather.dashboard.summary');
Route::get('/satellite/dashboard-summary/{lat}/{lon}', [SatelliteController::class, 'dashboardSummary'])->name('satellite.dashboard.summary');