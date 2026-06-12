<?php

namespace App\Support;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Classification des alertes (collections Mongo `alert` / `alerts`) pour l’onglet Analyse.
 */
class AlertsAnalysis
{
    /**
     * @return array<string, array{label: string, role: string}>
     */
    public static function typeDefinitions(): array
    {
        return [
            'inondation' => [
                'label' => 'Inondation',
                'role' => 'Risque lié à l’eau (inondation, oued, débordement, etc.)',
            ],
            'routes_impraticables' => [
                'label' => 'Routes impraticables',
                'role' => 'Routes impraticables, fermeture, etc.',
            ],
            'tempetes_vents' => [
                'label' => 'Tempêtes / vents forts',
                'role' => 'Tempête, vents forts, rafales',
            ],
            'zones_ouvertes_nationales' => [
                'label' => 'Zones ouvertes (routes nationales)',
                'role' => 'Zones ouvertes / routes nationales',
            ],
            'pluie' => [
                'label' => 'Pluie',
                'role' => 'Pluie, météo forte/moyenne, chaussée glissante (zone_glissante), etc.',
            ],
            'chaleur_extreme' => [
                'label' => 'Chaleur extrême',
                'role' => 'Canicule / chaleur (mots-clés dans le contenu)',
            ],
            'temperature_elevee' => [
                'label' => 'Température élevée',
                'role' => 'Alerte température horaire ≥ 34 °C',
            ],
            'temperature_moderee' => [
                'label' => 'Température modérée',
                'role' => 'Alerte température horaire (< 34 °C)',
            ],
            'autre' => [
                'label' => 'Autres',
                'role' => 'Non classé selon les règles ci-dessus',
            ],
        ];
    }

    /**
     * @param  array<string, mixed>  $row
     */
    public static function classify(array $row): string
    {
        $blob = strtolower(implode(' ', array_filter([
            (string) data_get($row, 'type'),
            (string) data_get($row, 'categorie'),
            (string) data_get($row, 'category'),
            (string) data_get($row, 'type_alerte'),
            (string) data_get($row, 'titre'),
            (string) data_get($row, 'libelle'),
            (string) data_get($row, 'nom'),
            (string) data_get($row, 'description'),
            (string) data_get($row, 'message'),
            (string) data_get($row, 'details'),
            (string) data_get($row, 'variable'),
            (string) data_get($row, 'code'),
            (string) data_get($row, 'kind'),
            (string) data_get($row, 'tags'),
            (string) data_get($row, 'source'),
            (string) data_get($row, 'title'),
        ])));

        $tempRaw = data_get($row, 'temperature')
            ?? data_get($row, 'temp_c')
            ?? data_get($row, 'temp')
            ?? data_get($row, 'value');

        $isHourlyTempContext = str_contains($blob, 'hourly_temperature')
            || str_contains($blob, 'hourly temp')
            || str_contains($blob, 'temperature_2m')
            || (str_contains($blob, 'température') && preg_match('/\b(34|35|36|37|38|39|40)\b/', $blob));

        if ($isHourlyTempContext || (is_numeric($tempRaw) && (str_contains($blob, 'température') || str_contains($blob, 'temperature')))) {
            if (is_numeric($tempRaw)) {
                $t = (float) $tempRaw;

                return $t >= 34.0 ? 'temperature_elevee' : 'temperature_moderee';
            }
            if (preg_match('/(\d{1,2}(?:\.\d+)?)\s*°?\s*c/i', $blob, $m)) {
                $t = (float) $m[1];

                return $t >= 34.0 ? 'temperature_elevee' : 'temperature_moderee';
            }
        }

        if (preg_match('/inond|oued|débord|debord|flood|submer|crue|crues|ruissel|barrage.*eau/', $blob)) {
            return 'inondation';
        }

        if (preg_match('/impratic|fermeture|fermé|ferme\b|route ferm|déviation|deviation|circulation coup|coupée|coupée|barrage routier/', $blob)) {
            return 'routes_impraticables';
        }

        if (preg_match('/tempête|tempete|vent fort|rafale|rafales|storm|cyclone|ouragan/', $blob)) {
            return 'tempetes_vents';
        }

        if (preg_match('/route nationale|routes nationales|\brn\b|zone ouverte|autoroute nationale|rocade nationale/', $blob)) {
            return 'zones_ouvertes_nationales';
        }

        if (preg_match('/canicule|chaleur extrême|chaleur extreme|heat wave|vague de chaleur/', $blob)) {
            return 'chaleur_extreme';
        }

        if (preg_match('/pluie|pluvieux|zone_glissante|glissant|chaussée|chaussee|météo forte|meteo forte|forte pluie|bruine|orage|précipitation/', $blob)) {
            return 'pluie';
        }

        if (preg_match('/température.*élev|temperature.*elev|alerte.*chaud/', $blob)) {
            return 'temperature_elevee';
        }

        if (preg_match('/température|temperature|thermique|°c/', $blob)) {
            return 'temperature_moderee';
        }

        return 'autre';
    }

    /**
     * @param  array<string, mixed>  $row
     */
    public static function hasCoordinates(array $row): bool
    {
        $lat = data_get($row, 'lat')
            ?? data_get($row, 'latitude')
            ?? data_get($row, 'location.lat');
        $lon = data_get($row, 'lon')
            ?? data_get($row, 'lng')
            ?? data_get($row, 'longitude')
            ?? data_get($row, 'location.lon')
            ?? data_get($row, 'location.lng');

        $coords = data_get($row, 'location.coordinates');
        if ((! is_numeric($lat) || ! is_numeric($lon)) && is_array($coords) && count($coords) >= 2
            && is_numeric($coords[0]) && is_numeric($coords[1])) {
            return true;
        }

        $geom = data_get($row, 'geometry.coordinates');
        if ((! is_numeric($lat) || ! is_numeric($lon)) && is_array($geom) && count($geom) >= 2
            && is_numeric($geom[0]) && is_numeric($geom[1])) {
            return true;
        }

        return is_numeric($lat) && is_numeric($lon);
    }

    /**
     * @param  array<string, mixed>  $row
     */
    public static function parseAlertDate(array $row): ?Carbon
    {
        $raw = data_get($row, 'created_at')
            ?? data_get($row, 'date_creation')
            ?? data_get($row, 'detected_at')
            ?? data_get($row, 'createdAt')
            ?? data_get($row, 'date');

        if ($raw === null || $raw === '') {
            return null;
        }

        try {
            if ($raw instanceof \MongoDB\BSON\UTCDateTime) {
                return Carbon::instance($raw->toDateTime());
            }
            if ($raw instanceof \DateTimeInterface) {
                return Carbon::instance($raw);
            }

            return Carbon::parse((string) $raw);
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Normalise un libellé de risque à partir d'une chaîne brute (alertes ou zones).
     */
    /**
     * Libellé affiché pour le champ source / origine (clés techniques → français).
     */
    public static function normalizeSourceLabel(string $raw): string
    {
        $raw = trim($raw);
        if ($raw === '') {
            return '';
        }

        $key = strtolower(str_replace(['-', ' '], '_', $raw));

        return match ($key) {
            'hourly_temperature' => 'Température horaire',
            'hourlytemp' => 'Température horaire',
            'temperature_2m', 'temperature_2_m' => 'Température à 2 m',
            'temperature_2m_max' => 'Température max. à 2 m',
            'temperature_2m_min' => 'Température min. à 2 m',
            default => $raw,
        };
    }

    public static function normalizeRiskLabel(string $riskRaw): string
    {
        $riskRaw = strtolower(trim($riskRaw));
        if ($riskRaw === '') {
            return 'Non renseigné';
        }

        return match (true) {
            str_contains($riskRaw, 'high') || str_contains($riskRaw, 'élev') || str_contains($riskRaw, 'crit')
            || str_contains($riskRaw, 'danger') => 'Élevé',
            str_contains($riskRaw, 'medium') || str_contains($riskRaw, 'mod') => 'Modéré',
            str_contains($riskRaw, 'low') || str_contains($riskRaw, 'faible') => 'Faible',
            default => ucfirst($riskRaw),
        };
    }

    /**
     * Agrège les niveaux de risque depuis la collection Mongo `zones_risque`
     * (champs alignés sur la carte « zones à risque » : risk_level, risk, niveau_risque, severity, gravite).
     *
     * @return array{by_risk: array<string, int>, risk_chart: array{labels: array<int, string>, data: array<int, int>}, total: int}
     */
    public static function aggregateZonesRisqueRisk(): array
    {
        $byRisk = [];
        $total = 0;

        try {
            foreach (DB::connection('mongodb')->table('zones_risque')->limit(500)->get() as $doc) {
                $row = is_array($doc) ? $doc : (array) $doc;
                $total++;

                $riskRaw = '';
                foreach (['risk_level', 'risk', 'niveau_risque', 'severity', 'gravite'] as $key) {
                    $v = data_get($row, $key);
                    if ($v !== null && $v !== '') {
                        $riskRaw = strtolower(trim((string) $v));
                        break;
                    }
                }

                $label = $riskRaw === '' ? 'Non renseigné' : self::normalizeRiskLabel($riskRaw);
                $byRisk[$label] = ($byRisk[$label] ?? 0) + 1;
            }
        } catch (\Throwable $e) {
            Log::warning('Analyse alertes : collection zones_risque indisponible', [
                'error' => $e->getMessage(),
            ]);
        }

        arsort($byRisk);

        $riskChart = ['labels' => [], 'data' => []];
        foreach ($byRisk as $label => $n) {
            $riskChart['labels'][] = $label;
            $riskChart['data'][] = $n;
        }

        return [
            'by_risk' => $byRisk,
            'risk_chart' => $riskChart,
            'total' => $total,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function aggregateFromMongo(): array
    {
        $definitions = self::typeDefinitions();
        $counts = array_fill_keys(array_keys($definitions), 0);

        $rawByCollection = ['alert' => 0, 'alerts' => 0];
        $seenIds = [];
        $resolutionHours = [];
        $withLocation = 0;
        $withoutLocation = 0;
        $recent7 = 0;
        $recent30 = 0;
        $byRisk = [];
        $bySource = [];
        $byRawCategory = [];
        $byMonth = [];
        $byTypeForTimeline = [];
        $now = Carbon::now();

        foreach (range(5, 0) as $i) {
            $ym = $now->copy()->subMonths($i)->format('Y-m');
            $byMonth[$ym] = 0;
            $byTypeForTimeline[$ym] = array_fill_keys(array_keys($definitions), 0);
        }

        foreach (['alert', 'alerts'] as $collection) {
            try {
                try {
                    $alertDocs = DB::connection('mongodb')->table($collection)->orderBy('_id', 'desc')->limit(4000)->get();
                } catch (\Throwable $e) {
                    $alertDocs = DB::connection('mongodb')->table($collection)->limit(4000)->get();
                }
                foreach ($alertDocs as $doc) {
                    $row = is_array($doc) ? $doc : (array) $doc;
                    $rawByCollection[$collection] = ($rawByCollection[$collection] ?? 0) + 1;

                    $idKey = isset($row['_id'])
                        ? 'oid_'.(string) $row['_id']
                        : (isset($row['id']) ? 'id_'.(string) $row['id'] : null);

                    if ($idKey === null) {
                        $idKey = 'hash_'.substr(sha1(json_encode($row)), 0, 16);
                    }

                    if (isset($seenIds[$idKey])) {
                        continue;
                    }
                    $seenIds[$idKey] = true;

                    $classKey = self::classify($row);
                    if (! array_key_exists($classKey, $counts)) {
                        $classKey = 'autre';
                    }
                    $counts[$classKey]++;

                    if (self::hasCoordinates($row)) {
                        $withLocation++;
                    } else {
                        $withoutLocation++;
                    }

                    $dt = self::parseAlertDate($row);
                    if ($dt) {
                        if ($dt->greaterThanOrEqualTo($now->copy()->subDays(7))) {
                            $recent7++;
                        }
                        if ($dt->greaterThanOrEqualTo($now->copy()->subDays(30))) {
                            $recent30++;
                        }
                        $ym = $dt->format('Y-m');
                        if (array_key_exists($ym, $byMonth)) {
                            $byMonth[$ym]++;
                            $byTypeForTimeline[$ym][$classKey] = ($byTypeForTimeline[$ym][$classKey] ?? 0) + 1;
                        }
                    }

                    $riskRaw = strtolower(trim((string) (data_get($row, 'risk')
                        ?? data_get($row, 'niveau_risque')
                        ?? data_get($row, 'severity')
                        ?? data_get($row, 'gravite')
                        ?? '')));
                    if ($riskRaw !== '') {
                        $riskLabel = self::normalizeRiskLabel($riskRaw);
                        if ($riskLabel !== 'Non renseigné') {
                            $byRisk[$riskLabel] = ($byRisk[$riskLabel] ?? 0) + 1;
                        }
                    }

                    $src = trim((string) (data_get($row, 'source') ?? data_get($row, 'origine') ?? ''));
                    if ($src !== '') {
                        $srcLabel = self::normalizeSourceLabel($src);
                        $bySource[$srcLabel] = ($bySource[$srcLabel] ?? 0) + 1;
                    }

                    $catRaw = trim((string) (data_get($row, 'category') ?? data_get($row, 'categorie') ?? ''));
                    if ($catRaw !== '') {
                        $byRawCategory[$catRaw] = ($byRawCategory[$catRaw] ?? 0) + 1;
                    }

                    $start = data_get($row, 'created_at') ?? data_get($row, 'date_creation') ?? data_get($row, 'detected_at');
                    $end = data_get($row, 'resolved_at') ?? data_get($row, 'date_resolution') ?? data_get($row, 'closed_at');
                    try {
                        if ($start && $end) {
                            $s = $start instanceof \MongoDB\BSON\UTCDateTime
                                ? Carbon::instance($start->toDateTime())
                                : Carbon::parse((string) $start);
                            $e = $end instanceof \MongoDB\BSON\UTCDateTime
                                ? Carbon::instance($end->toDateTime())
                                : Carbon::parse((string) $end);
                            if ($e->greaterThan($s)) {
                                $resolutionHours[] = $s->diffInHours($e);
                            }
                        }
                    } catch (\Throwable $e) {
                        // ignore
                    }
                }
            } catch (\Throwable $e) {
                Log::warning('Analyse alertes : collection indisponible', [
                    'collection' => $collection,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        $uniqueTotal = count($seenIds);
        $totalClassified = array_sum($counts);

        $avgDays = null;
        $resolvedCount = count($resolutionHours);
        if ($resolvedCount > 0) {
            $avgDays = round(array_sum($resolutionHours) / $resolvedCount / 24, 1);
        }

        $colorMap = [
            'inondation' => '#1A1A1A',
            'routes_impraticables' => '#C2410C',
            'tempetes_vents' => '#6366f1',
            'zones_ouvertes_nationales' => '#059669',
            'pluie' => '#0ea5e9',
            'chaleur_extreme' => '#dc2626',
            'temperature_elevee' => '#f97316',
            'temperature_moderee' => '#fdba74',
            'autre' => '#9ca3af',
        ];

        $chart = ['labels' => [], 'data' => [], 'colors' => []];
        foreach ($definitions as $key => $meta) {
            $c = $counts[$key] ?? 0;
            if ($c > 0) {
                $chart['labels'][] = $meta['label'];
                $chart['data'][] = $c;
                $chart['colors'][] = $colorMap[$key] ?? '#9ca3af';
            }
        }

        arsort($bySource);
        arsort($byRawCategory);
        arsort($byRisk);

        $monthLabels = [];
        $monthData = [];
        foreach (range(5, 0) as $i) {
            $d = $now->copy()->subMonths($i);
            $monthLabels[] = $d->locale('fr_FR')->isoFormat('MMM YY');
            $ym = $d->format('Y-m');
            $monthData[] = $byMonth[$ym] ?? 0;
        }

        $timelineStacked = [
            'labels' => array_map(function ($i) use ($now) {
                return $now->copy()->subMonths(5 - $i)->locale('fr_FR')->isoFormat('MMM YY');
            }, range(0, 5)),
            'datasets' => [],
        ];

        $stackKeys = array_keys(array_filter($counts, fn ($n) => $n > 0));
        if ($stackKeys === []) {
            $stackKeys = ['autre'];
        }

        foreach ($stackKeys as $sk) {
            $timelineStacked['datasets'][] = [
                'label' => $definitions[$sk]['label'] ?? $sk,
                'key' => $sk,
                'data' => array_map(function ($i) use ($byTypeForTimeline, $sk, $now) {
                    $ym = $now->copy()->subMonths(5 - $i)->format('Y-m');

                    return $byTypeForTimeline[$ym][$sk] ?? 0;
                }, range(0, 5)),
                'backgroundColor' => ($colorMap[$sk] ?? '#9ca3af').'CC',
            ];
        }

        $sourceChart = ['labels' => [], 'data' => []];
        foreach (array_slice($bySource, 0, 8, true) as $label => $n) {
            $sourceChart['labels'][] = $label;
            $sourceChart['data'][] = $n;
        }

        $zonesRiskData = self::aggregateZonesRisqueRisk();
        $riskSource = null;
        if ($zonesRiskData['total'] > 0) {
            $byRisk = $zonesRiskData['by_risk'];
            $riskChart = $zonesRiskData['risk_chart'];
            $riskSource = 'zones_risque';
        } else {
            $riskChart = ['labels' => [], 'data' => []];
            foreach ($byRisk as $label => $n) {
                $riskChart['labels'][] = $label;
                $riskChart['data'][] = $n;
            }
            $riskSource = count($byRisk) > 0 ? 'alerts' : null;
        }

        return [
            'total' => $totalClassified,
            'unique_total' => $uniqueTotal,
            'raw_by_collection' => $rawByCollection,
            'duplicate_skipped' => max(0, ($rawByCollection['alert'] ?? 0) + ($rawByCollection['alerts'] ?? 0) - $uniqueTotal),
            'counts' => $counts,
            'definitions' => $definitions,
            'resolution_avg_days' => $avgDays,
            'resolved_count' => $resolvedCount,
            'chart' => $chart,
            'with_location' => $withLocation,
            'without_location' => $withoutLocation,
            'recent_7d' => $recent7,
            'recent_30d' => $recent30,
            'by_risk' => $byRisk,
            'by_source' => $bySource,
            'by_raw_category' => $byRawCategory,
            'by_month' => $byMonth,
            'month_chart' => [
                'labels' => $monthLabels,
                'data' => $monthData,
            ],
            'timeline_stacked' => $timelineStacked,
            'source_chart' => $sourceChart,
            'risk_chart' => $riskChart,
            'risk_source' => $riskSource,
            'zones_risque_count' => $zonesRiskData['total'],
        ];
    }
}
