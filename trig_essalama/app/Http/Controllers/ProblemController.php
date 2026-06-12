<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use App\Models\Budget;
use App\Support\BudgetSummary;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;
use MongoDB\BSON\ObjectId;

class ProblemController extends Controller
{
    private function toArray(mixed $doc): array
    {
        return json_decode(json_encode($doc), true) ?? [];
    }

    private function pick(array $row, array $keys, mixed $default = null): mixed
    {
        foreach ($keys as $key) {
            $value = data_get($row, $key);
            if ($value !== null && $value !== '') {
                return $value;
            }
        }

        return $default;
    }

    private function normalizeConfidencePercent(mixed $value): int
    {
        if (! is_numeric($value)) {
            return 0;
        }
        $num = (float) $value;
        if ($num <= 1) {
            $num *= 100;
        }

        return max(0, min(100, (int) round($num)));
    }

    private function normalizeDateText(mixed $value): string
    {
        if ($value === null || $value === '') {
            return '';
        }
        try {
            if ($value instanceof \MongoDB\BSON\UTCDateTime) {
                return \Carbon\Carbon::instance($value->toDateTime())->format('Y-m-d H:i');
            }
            if ($value instanceof \DateTimeInterface) {
                return \Carbon\Carbon::instance($value)->format('Y-m-d H:i');
            }

            return \Carbon\Carbon::parse((string) $value)->format('Y-m-d H:i');
        } catch (\Throwable $e) {
            return (string) $value;
        }
    }

    private function hydrateIntervenantWithProblem(array $item): array
    {
        $problemId = trim((string) ($item['problem_id'] ?? ''));
        $objectId = $this->tryObjectId($problemId);
        if (! $objectId) {
            return $item;
        }

        $problemDoc = DB::connection('mongodb')->table('problemes_de_voirie')
            ->where('_id', '=', $objectId)
            ->first();
        if (! $problemDoc) {
            return $item;
        }

        $problem = $this->toArray($problemDoc);
        $risk = (int) $this->pick($problem, ['risk_score', 'score_risque', 'score'], 0);
        $severity = (string) $this->pick($problem, ['gravite', 'severity'], 'Moyenne');
        $confidence = $this->normalizeConfidencePercent(
            $this->pick($problem, ['confiance', 'confidence', 'confiance_ia', 'confidence_ia'], 0)
        );
        $detectedAt = $this->normalizeDateText(
            $this->pick($problem, ['date_detection', 'detected_at', 'created_at'], '')
        );

        $item['type'] = (string) ($item['type'] ?: $this->pick($problem, ['type', 'type_probleme', 'problem_type'], 'Intervention'));
        $item['title'] = (string) ($item['title'] ?: $item['type']);
        $item['address'] = (string) ($item['address'] ?: $this->pick($problem, ['localisation', 'location.address', 'address'], 'Localisation inconnue'));
        $item['team'] = (string) ($item['team'] ?: $this->pick($problem, ['equipe', 'assigned_team', 'team'], ''));
        $item['risk_score'] = (int) ($item['risk_score'] ?: $risk);
        $item['severity'] = (string) ($item['severity'] ?: $severity);
        $item['confidence'] = (int) ($item['confidence'] ?: $confidence);
        $item['detected_at'] = (string) ($item['detected_at'] ?: $detectedAt);
        $item['priority'] = (string) ($item['priority'] ?: $this->pick($problem, ['priority_code', 'priorite'], ''));
        $item['estimated_cost'] = (string) ($item['estimated_cost'] ?: $this->pick($problem, ['cout_estime', 'estimated_cost', 'cost'], ''));

        return $item;
    }

    private function normalizeTeamKey(string $value): string
    {
        $v = trim(Str::lower($value));
        if ($v === '') {
            return '';
        }
        $v = str_replace(['é', 'è', 'ê', 'ë'], 'e', $v);
        $v = preg_replace('/\s+/', '_', $v) ?? $v;
        $v = preg_replace('/[^a-z0-9_]/', '', $v) ?? $v;

        // "equipe 2" => "equipe_2"
        if (preg_match('/^equipe_?\d+$/', $v) === 1) {
            return preg_replace('/^equipe_?(\d+)$/', 'equipe_$1', $v) ?? $v;
        }

        return $v;
    }

    /**
     * Extrait un montant numérique depuis la saisie libre (ex. "35 000 DNT", "12.500,50").
     */
    private function parseCostToDecimal(string $cost): ?float
    {
        $t = trim($cost);
        if ($t === '') {
            return null;
        }
        $t = preg_replace('/[^\d,\.\-]/u', '', str_replace(["\xc2\xa0", ' ', "\u{00a0}"], '', $t)) ?? '';
        $t = str_replace(',', '.', $t);
        if ($t === '' || $t === '.' || $t === '-' || ! is_numeric($t)) {
            return null;
        }

        return round((float) $t, 2);
    }

    private function tryObjectId(string $id): ?ObjectId
    {
        try {
            return new ObjectId($id);
        } catch (\Throwable $e) {
            return null;
        }
    }

    /**
     * Vérifie que l’utilisateur peut modifier le statut (même logique que le tableau de bord).
     */
    private function userCanUpdateProblemStatus(Request $request): bool
    {
        if ($request->session()->get('autoritaire_authenticated') === true) {
            return true;
        }

        if ($request->session()->get('authenticated_admin_technical') === true) {
            return true;
        }

        if (! Auth::guard('admin')->check()) {
            return false;
        }

        $sessionType = $request->session()->get('admin_type');
        $role = optional(Auth::guard('admin')->user())->role ?? null;

        return $sessionType === 'technical' || $role === 'technical';
    }

    public function updateStatus(Request $request, string $id): JsonResponse
    {
        if (! $this->userCanUpdateProblemStatus($request)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’avez pas les droits pour modifier le statut d’un problème.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'status' => ['required', 'string', Rule::in(['en_attente', 'en_cours', 'termine'])],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Statut invalide.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $status = $request->string('status')->toString();
        $normalized = match ($status) {
            'en_cours' => 'En cours',
            'termine' => 'Terminé',
            default => 'En attente',
        };

        $objectId = $this->tryObjectId($id);
        if (! $objectId) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant du problème invalide.',
            ], 422);
        }

        $modified = (int) DB::connection('mongodb')->table('problemes_de_voirie')
            ->where('_id', '=', $objectId)
            ->update([
                'status' => $normalized,
                'statut' => $normalized,
                'updated_at' => now()->toIso8601String(),
            ]);

        if ($modified === 0) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun problème trouvé avec cet identifiant.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour.',
            'status' => $normalized,
        ]);
    }

    public function assignTeam(Request $request, string $id): JsonResponse
    {
        if (! $this->userCanUpdateProblemStatus($request)) {
            return response()->json([
                'success' => false,
                'message' => 'Vous n’avez pas les droits pour affecter une équipe.',
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'team_key' => ['required', 'string', 'max:120'],
            'team_label' => ['required', 'string', 'max:160'],
            'cost' => ['required', 'string', 'max:80'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Données d’affectation invalides.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $objectId = $this->tryObjectId($id);
        if (! $objectId) {
            return response()->json([
                'success' => false,
                'message' => 'Identifiant du problème invalide.',
            ], 422);
        }

        $teamKey = trim($request->string('team_key')->toString());
        $teamLabel = trim($request->string('team_label')->toString());
        $cost = trim($request->string('cost')->toString());
        $now = now()->toIso8601String();

        $assignedBy = $request->session()->get('admin_email')
            ?? $request->session()->get('admin_name')
            ?? optional(Auth::guard('admin')->user())->email;

        $problem = DB::connection('mongodb')->table('problemes_de_voirie')
            ->where('_id', '=', $objectId)
            ->first();

        if (! $problem) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun problème trouvé avec cet identifiant.',
            ], 404);
        }

        $problemRow = $this->toArray($problem);
        $lat = data_get($problemRow, 'location.lat')
            ?? data_get($problemRow, 'lat')
            ?? data_get($problemRow, 'latitude');
        $lng = data_get($problemRow, 'location.lon')
            ?? data_get($problemRow, 'location.lng')
            ?? data_get($problemRow, 'lon')
            ?? data_get($problemRow, 'lng')
            ?? data_get($problemRow, 'longitude');

        $status = 'En cours';
        $commonUpdate = [
            'equipe' => $teamLabel,
            'assigned_team' => $teamKey,
            'team' => $teamLabel,
            'cout_estime' => $cost,
            'status' => $status,
            'statut' => $status,
            'updated_at' => $now,
        ];

        $updated = (int) DB::connection('mongodb')->table('problemes_de_voirie')
            ->where('_id', '=', $objectId)
            ->update($commonUpdate);

        if ($updated === 0) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune mise à jour effectuée.',
            ], 500);
        }

        $problemId = (string) $objectId;
        $costNumeric = $this->parseCostToDecimal($cost);

        try {
            Budget::query()->updateOrCreate(
                ['problem_id' => $problemId],
                [
                    'team_key' => $teamKey,
                    'team_label' => $teamLabel,
                    'cout_estime' => $cost,
                    'cout_estime_numeric' => $costNumeric,
                    'assigned_by' => ($assignedBy !== null && $assignedBy !== '')
                        ? mb_substr((string) $assignedBy, 0, 190)
                        : null,
                ]
            );
        } catch (\Throwable $e) {
            Log::warning('Enregistrement coût estimé (table budget SQL) échoué', [
                'problem_id' => $problemId,
                'error' => $e->getMessage(),
            ]);
        }

        $risk = (int) $this->pick($problemRow, ['risk_score', 'score_risque', 'score'], 0);
        $severity = (string) $this->pick($problemRow, ['gravite', 'severity'], 'Moyenne');
        $confidence = $this->normalizeConfidencePercent(
            $this->pick($problemRow, ['confiance', 'confidence', 'confiance_ia', 'confidence_ia'], 0)
        );
        $detectedAt = $this->normalizeDateText(
            $this->pick($problemRow, ['date_detection', 'detected_at', 'created_at'], '')
        );
        $priority = (string) $this->pick($problemRow, ['priority_code', 'priorite'], '');
        $type = (string) $this->pick($problemRow, ['type', 'type_probleme', 'problem_type'], 'Intervention voirie');
        $description = (string) $this->pick($problemRow, ['description', 'details', 'notes'], 'Intervention assignée par l’administrateur');
        $address = (string) $this->pick($problemRow, ['localisation', 'location.address', 'address', 'adresse'], 'Localisation inconnue');

        $intervenantDoc = [
            'problem_id' => $problemId,
            'problem_object_id' => $problemId,
            'equipe' => $teamLabel,
            'team_key' => $teamKey,
            'team' => $teamLabel,
            'titre' => $type,
            'type' => $type,
            'description' => $description,
            'adresse' => $address,
            'cout_estime' => $cost,
            'risk_score' => $risk,
            'gravite' => $severity,
            'confiance' => $confidence,
            'date_detection' => $detectedAt,
            'priorite' => $priority,
            'statut' => $status,
            'status' => $status,
            'source' => 'dashboard_admin',
            'updated_at' => $now,
        ];

        if (is_numeric($lat) && is_numeric($lng)) {
            $intervenantDoc['lat'] = (float) $lat;
            $intervenantDoc['lng'] = (float) $lng;
            $intervenantDoc['latitude'] = (float) $lat;
            $intervenantDoc['longitude'] = (float) $lng;
            $intervenantDoc['location'] = [
                'lat' => (float) $lat,
                'lng' => (float) $lng,
            ];
        }

        try {
            $existing = DB::connection('mongodb')->table('intervenants')
                ->where('problem_id', '=', $problemId)
                ->first();

            if ($existing) {
                DB::connection('mongodb')->table('intervenants')
                    ->where('problem_id', '=', $problemId)
                    ->update($intervenantDoc);
            } else {
                $intervenantDoc['created_at'] = $now;
                DB::connection('mongodb')->table('intervenants')->insert($intervenantDoc);
            }
        } catch (\Throwable $e) {
            Log::warning('Affectation équipe: synchronisation intervenants échouée', [
                'problem_id' => $problemId,
                'error' => $e->getMessage(),
            ]);
        }

        $budgetSummary = null;
        try {
            $budgetSummary = BudgetSummary::forMonth(now()->format('Y-m'));
        } catch (\Throwable $e) {
            Log::debug('Synthèse budget après affectation ignorée', ['error' => $e->getMessage()]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Équipe affectée et synchronisée avec l’interface intervenant.',
            'data' => [
                'team' => $teamLabel,
                'cost' => $cost,
                'status' => $status,
            ],
            'budget_summary' => $budgetSummary,
        ]);
    }

    public function intervenantAssignments(Request $request): JsonResponse
    {
        $teamKey = trim((string) $request->query('team_key', ''));
        $teamLabel = trim((string) $request->query('team_label', ''));
        $limit = max(1, min((int) $request->query('limit', 100), 300));
        $teamKeyNormalized = $this->normalizeTeamKey($teamKey !== '' ? $teamKey : $teamLabel);

        try {
            // Source principale = problemes_de_voirie (source de vérité des affectations).
            $problemQuery = DB::connection('mongodb')->table('problemes_de_voirie')->orderBy('_id', 'desc');
            if ($teamKeyNormalized !== '') {
                $problemQuery->where(function ($q) use ($teamKeyNormalized, $teamLabel) {
                    if ($teamLabel !== '') {
                        $q->where('equipe', 'regex', '/^'.preg_quote($teamLabel, '/').'$/i');
                    }
                    if (preg_match('/^equipe_(\d+)$/', $teamKeyNormalized, $m) === 1) {
                        $human = 'equipe '.$m[1];
                        $q->orWhere('equipe', 'regex', '/^'.preg_quote($human, '/').'$/i');
                    }
                    $q->orWhere('assigned_team', '=', $teamKeyNormalized)
                        ->orWhere('team', '=', $teamKeyNormalized);
                });
            }

            $items = collect($problemQuery->limit($limit)->get())
                ->map(function ($doc) {
                    $row = $this->toArray($doc);
                    $docId = data_get($row, '_id');
                    if ($docId instanceof \MongoDB\BSON\ObjectId) {
                        $docId = (string) $docId;
                    } elseif (is_array($docId) && isset($docId['$oid'])) {
                        $docId = (string) $docId['$oid'];
                    } else {
                        $docId = (string) ($docId ?? '');
                    }

                    $risk = (int) $this->pick($row, ['risk_score', 'score_risque', 'score'], 0);
                    $severity = (string) $this->pick($row, ['gravite', 'severity'], 'Moyenne');
                    $confidence = $this->normalizeConfidencePercent(
                        $this->pick($row, ['confiance', 'confidence', 'confiance_ia', 'confidence_ia'], 0)
                    );
                    $detectedAt = $this->normalizeDateText(
                        $this->pick($row, ['date_detection', 'detected_at', 'created_at'], '')
                    );
                    $lat = $this->pick($row, ['location.lat', 'lat', 'latitude'], null);
                    $lng = $this->pick($row, ['location.lon', 'location.lng', 'lon', 'lng', 'longitude'], null);

                    return [
                        'id' => $docId,
                        'problem_id' => $docId,
                        'team_key' => (string) $this->pick($row, ['assigned_team', 'team'], ''),
                        'team' => (string) $this->pick($row, ['equipe', 'assigned_team', 'team'], ''),
                        'title' => (string) $this->pick($row, ['type', 'type_probleme', 'problem_type'], 'Intervention voirie'),
                        'type' => (string) $this->pick($row, ['type', 'type_probleme', 'problem_type'], ''),
                        'description' => (string) $this->pick($row, ['description', 'details', 'notes'], ''),
                        'address' => (string) $this->pick($row, ['localisation', 'location.address', 'address', 'adresse'], 'Localisation inconnue'),
                        'status' => (string) $this->pick($row, ['status', 'statut'], 'En attente'),
                        'estimated_cost' => (string) $this->pick($row, ['cout_estime', 'estimated_cost', 'cost'], ''),
                        'risk_score' => $risk,
                        'severity' => $severity,
                        'confidence' => $confidence,
                        'detected_at' => $detectedAt,
                        'priority' => (string) $this->pick($row, ['priority_code', 'priorite'], ''),
                        'lat' => is_numeric($lat) ? (float) $lat : null,
                        'lng' => is_numeric($lng) ? (float) $lng : null,
                        'updated_at' => (string) $this->pick($row, ['updated_at'], ''),
                    ];
                })
                ->filter(fn (array $item): bool => trim((string) ($item['team'] ?? '')) !== '')
                ->values();

            return response()->json([
                'success' => true,
                'count' => $items->count(),
                'items' => $items,
            ]);
        } catch (\Throwable $e) {
            Log::warning('Lecture affectations intervenant échouée', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Impossible de charger les affectations.',
            ], 500);
        }
    }
}
