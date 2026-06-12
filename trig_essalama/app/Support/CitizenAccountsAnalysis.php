<?php

namespace App\Support;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Statistiques sur les comptes citoyens (MongoDB `user_citoyen`) et les avis (`user_feedback`) pour l’onglet Analyse.
 */
class CitizenAccountsAnalysis
{
    /**
     * Date de création du compte (champs usuels + repli sur l’horodatage du ObjectId Mongo).
     *
     * @param  array<string, mixed>  $row
     */
    public static function parseCreatedAt(array $row): ?Carbon
    {
        foreach (['createdAt', 'created_at', 'registered_at', 'date_creation', 'date_inscription', 'created'] as $key) {
            $d = self::parseMongoDate(data_get($row, $key));
            if ($d !== null) {
                return $d;
            }
        }

        return self::createdAtFromObjectId($row);
    }

    /**
     * @param  array<string, mixed>  $row
     */
    public static function createdAtFromObjectId(array $row): ?Carbon
    {
        $_id = data_get($row, '_id');
        if ($_id instanceof \MongoDB\BSON\ObjectId) {
            try {
                return Carbon::createFromTimestampUTC($_id->getTimestamp());
            } catch (\Throwable $e) {
                return null;
            }
        }

        return null;
    }

    /**
     * Domaine à partir du champ email (pour répartition type Atlas).
     */
    public static function emailDomain(?string $email): string
    {
        $email = strtolower(trim((string) $email));
        if ($email === '' || ! str_contains($email, '@')) {
            return 'non renseigné';
        }
        $parts = explode('@', $email, 2);

        return isset($parts[1]) && $parts[1] !== '' ? $parts[1] : 'invalide';
    }

    /**
     * @param  mixed  $raw
     */
    public static function parseMongoDate($raw): ?Carbon
    {
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
     * @param  array<string, mixed>  $row
     */
    public static function parseDeactivationDate(array $row): ?Carbon
    {
        foreach (['deactivated_at', 'app_disabled_at', 'deleted_at', 'disabled_at', 'account_disabled_at', 'app_deactivated_at'] as $key) {
            $d = self::parseMongoDate(data_get($row, $key));
            if ($d !== null) {
                return $d;
            }
        }

        return null;
    }

    /**
     * Compte citoyen considéré comme désactivé / app coupée (champs usuels MongoDB).
     *
     * @param  array<string, mixed>  $row
     */
    public static function isCitizenDeactivated(array $row): bool
    {
        if (self::parseMongoDate(data_get($row, 'deleted_at')) !== null) {
            return true;
        }
        if (self::parseMongoDate(data_get($row, 'deactivated_at')) !== null) {
            return true;
        }

        foreach (['is_active', 'active', 'app_enabled', 'account_active'] as $key) {
            $v = data_get($row, $key);
            if ($v === null) {
                continue;
            }
            if ($v === false || $v === 0 || $v === '0' || $v === 'false') {
                return true;
            }
        }

        $st = strtolower(trim((string) (data_get($row, 'status') ?? data_get($row, 'account_status') ?? data_get($row, 'etat_compte') ?? '')));
        if (in_array($st, ['inactive', 'disabled', 'deactivated', 'deleted', 'suspended', 'desactive', 'desactivé', 'désactivé', 'inactif'], true)) {
            return true;
        }

        return false;
    }

    /**
     * Extrait une note numérique depuis un document `user_feedback`.
     *
     * @param  array<string, mixed>  $row
     */
    public static function extractFeedbackScore(array $row): ?float
    {
        foreach (['rating', 'note', 'score', 'satisfaction', 'stars', 'note_moyenne', 'valeur', 'value', 'niveau', 'avis_note'] as $key) {
            $v = data_get($row, $key);
            if ($v !== null && $v !== '' && is_numeric($v)) {
                return (float) $v;
            }
        }

        return null;
    }

    /**
     * Clé stable pour regrouper les avis par personne (citoyen / utilisateur).
     *
     * @param  array<string, mixed>  $row
     */
    public static function feedbackPersonKey(array $row): string
    {
        foreach (['user_id', 'citizen_id', 'userId', 'citoyen_id', 'author_id', 'created_by'] as $key) {
            $v = data_get($row, $key);
            if ($v !== null && $v !== '') {
                if (is_object($v) && method_exists($v, '__toString')) {
                    $v = (string) $v;
                }
                if (! is_array($v)) {
                    return 'id:'.(string) $v;
                }
            }
        }

        $author = data_get($row, 'author');
        if (is_array($author)) {
            $ae = $author['email'] ?? $author['id'] ?? $author['_id'] ?? null;
            if ($ae !== null && $ae !== '') {
                return 'author:'.(string) $ae;
            }
        } elseif ($author !== null && $author !== '' && ! is_array($author)) {
            return 'author:'.(string) $author;
        }

        $email = data_get($row, 'email') ?? data_get($row, 'user.email') ?? data_get($row, 'citizen_email');
        if ($email !== null && $email !== '') {
            return 'email:'.strtolower(trim((string) $email));
        }

        // Sans auteur : chaque document = une contribution distincte
        $oid = data_get($row, '_id');
        if ($oid !== null && $oid !== '') {
            return 'doc:'.(string) $oid;
        }

        return 'hash:'.substr(sha1(json_encode($row)), 0, 20);
    }

    /**
     * Regroupe une note sur une échelle 1–5 pour la répartition (histogramme).
     */
    public static function scoreToFiveStarBucket(float $s): ?int
    {
        if ($s < 0 || ! is_finite($s)) {
            return null;
        }
        // Échelle 0–10 → 1–5
        if ($s > 5 && $s <= 10) {
            return max(1, min(5, (int) round($s / 2)));
        }

        return max(1, min(5, (int) round($s)));
    }

    /**
     * Agrège les avis depuis la collection Mongo `user_feedback`.
     *
     * @return array{
     *   total_docs: int,
     *   satisfaction_avg: float|null,
     *   satisfaction_samples: int,
     *   satisfaction_available: bool,
     *   distribution_chart: array{labels: array<int, string>, data: array<int, int>}
     * }
     */
    public static function aggregateUserFeedbackFromMongo(): array
    {
        $scores = [];
        $totalDocs = 0;
        $dist = [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0];
        $distinctPeople = [];

        try {
            try {
                $feedbackDocs = DB::connection('mongodb')->table('user_feedback')->orderBy('_id', 'desc')->limit(3000)->get();
            } catch (\Throwable $e) {
                $feedbackDocs = DB::connection('mongodb')->table('user_feedback')->limit(3000)->get();
            }
            foreach ($feedbackDocs as $doc) {
                $row = is_array($doc) ? $doc : (array) $doc;
                $totalDocs++;

                $pkey = self::feedbackPersonKey($row);
                $distinctPeople[$pkey] = true;

                $s = self::extractFeedbackScore($row);
                if ($s !== null) {
                    $scores[] = $s;
                    $bucket = self::scoreToFiveStarBucket($s);
                    if ($bucket !== null) {
                        $dist[$bucket]++;
                    }
                }
            }
        } catch (\Throwable $e) {
            Log::warning('Analyse citoyens : collection user_feedback indisponible', [
                'error' => $e->getMessage(),
            ]);
        }

        $n = count($scores);
        $avg = null;
        if ($n > 0) {
            $avg = round(array_sum($scores) / $n, 2);
        }

        $labels = ['1 ★', '2 ★', '3 ★', '4 ★', '5 ★'];
        $data = array_map(fn (int $i) => $dist[$i] ?? 0, [1, 2, 3, 4, 5]);

        return [
            'total_docs' => $totalDocs,
            'feedback_distinct_people' => count($distinctPeople),
            'satisfaction_avg' => $avg,
            'satisfaction_samples' => $n,
            'satisfaction_available' => $n > 0,
            'distribution_chart' => [
                'labels' => $labels,
                'data' => $data,
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function aggregateFromMongo(): array
    {
        $total = 0;
        $verifiedCount = 0;
        $pendingCount = 0;

        $deactivatedTotal = 0;
        $deactivatedUndated = 0;
        $deactWeek = 0;
        $deactMonth = 0;
        $deactYear = 0;

        $inscWeek = 0;
        $inscMonth = 0;
        $inscYear = 0;

        $domainCounts = [];
        $schemaTracksDeactivation = false;

        $now = Carbon::now();
        $t7 = $now->copy()->subDays(7)->startOfDay();
        $t30 = $now->copy()->subDays(30)->startOfDay();
        $t365 = $now->copy()->subDays(365)->startOfDay();

        $byMonth = [];
        foreach (range(5, 0) as $i) {
            $ym = $now->copy()->subMonths($i)->format('Y-m');
            $byMonth[$ym] = 0;
        }

        try {
            try {
                $citizenDocs = DB::connection('mongodb')->table('user_citoyen')->orderBy('_id', 'desc')->limit(8000)->get();
            } catch (\Throwable $e) {
                $citizenDocs = DB::connection('mongodb')->table('user_citoyen')->limit(8000)->get();
            }
            foreach ($citizenDocs as $doc) {
                $row = is_array($doc) ? $doc : (array) $doc;
                $total++;

                $dom = self::emailDomain((string) (data_get($row, 'email') ?? ''));
                $domainCounts[$dom] = ($domainCounts[$dom] ?? 0) + 1;

                if (isset($row['is_active']) || isset($row['app_enabled'])
                    || data_get($row, 'deactivated_at') || data_get($row, 'deleted_at')
                    || data_get($row, 'disabled_at')) {
                    $schemaTracksDeactivation = true;
                }

                $ev = data_get($row, 'email_verified_at');
                $isVerified = $ev !== null && $ev !== '';
                if ($isVerified) {
                    $verifiedCount++;
                } else {
                    $pendingCount++;
                }

                $dt = self::parseCreatedAt($row);
                if ($dt) {
                    if ($dt->greaterThanOrEqualTo($t7)) {
                        $inscWeek++;
                    }
                    if ($dt->greaterThanOrEqualTo($t30)) {
                        $inscMonth++;
                    }
                    if ($dt->greaterThanOrEqualTo($t365)) {
                        $inscYear++;
                    }
                    $ym = $dt->format('Y-m');
                    if (array_key_exists($ym, $byMonth)) {
                        $byMonth[$ym]++;
                    }
                }

                if (self::isCitizenDeactivated($row)) {
                    $deactivatedTotal++;
                    $dd = self::parseDeactivationDate($row);
                    if ($dd !== null) {
                        if ($dd->greaterThanOrEqualTo($t7)) {
                            $deactWeek++;
                        }
                        if ($dd->greaterThanOrEqualTo($t30)) {
                            $deactMonth++;
                        }
                        if ($dd->greaterThanOrEqualTo($t365)) {
                            $deactYear++;
                        }
                    } else {
                        $deactivatedUndated++;
                    }
                }
            }
        } catch (\Throwable $e) {
            Log::warning('Analyse citoyens : collection user_citoyen indisponible', [
                'error' => $e->getMessage(),
            ]);
        }

        $monthLabels = [];
        $monthData = [];
        foreach (range(5, 0) as $i) {
            $d = $now->copy()->subMonths($i);
            $monthLabels[] = $d->locale('fr_FR')->isoFormat('MMM YY');
            $ym = $d->format('Y-m');
            $monthData[] = $byMonth[$ym] ?? 0;
        }

        $verifiedPercent = $total > 0 ? round(100 * $verifiedCount / $total, 1) : null;

        arsort($domainCounts);
        $domainTop = array_slice($domainCounts, 0, 10, true);
        $emailDomainChart = [
            'labels' => array_keys($domainTop),
            'data' => array_values($domainTop),
            'colors' => ['#FF6B35', '#f97316', '#fb923c', '#fdba74', '#ea580c', '#c2410c', '#9a3412', '#7c2d12', '#431407', '#1A1A1A'],
        ];

        $deactivationChart = [
            'labels' => ['Semaine (7 j)', 'Mois (30 j)', 'Année (365 j)'],
            'datasets' => [
                [
                    'label' => 'Nouvelles inscriptions',
                    'data' => [$inscWeek, $inscMonth, $inscYear],
                    'backgroundColor' => ['rgba(255,107,53,0.88)', 'rgba(249,115,22,0.85)', 'rgba(251,146,60,0.82)'],
                ],
                [
                    'label' => 'Désactivations (date renseignée)',
                    'data' => [$deactWeek, $deactMonth, $deactYear],
                    'backgroundColor' => ['rgba(154,52,18,0.9)', 'rgba(124,45,18,0.88)', 'rgba(67,20,7,0.85)'],
                ],
            ],
        ];

        $feedback = self::aggregateUserFeedbackFromMongo();

        return [
            'total' => $total,
            'verified_count' => $verifiedCount,
            'pending_count' => $pendingCount,
            'verified_percent' => $verifiedPercent,
            'month_chart' => [
                'labels' => $monthLabels,
                'data' => $monthData,
            ],
            'deactivation_chart' => $deactivationChart,
            'total_deactivated' => $deactivatedTotal,
            'deactivated_undated' => $deactivatedUndated,
            'schema_tracks_deactivation' => $schemaTracksDeactivation,
            'email_domain_chart' => $emailDomainChart,
            'satisfaction_avg' => $feedback['satisfaction_avg'],
            'satisfaction_samples' => $feedback['satisfaction_samples'],
            'satisfaction_available' => $feedback['satisfaction_available'],
            'feedback_total' => $feedback['total_docs'],
            'feedback_distinct_people' => $feedback['feedback_distinct_people'],
            'feedback_distribution' => $feedback['distribution_chart'],
        ];
    }
}
