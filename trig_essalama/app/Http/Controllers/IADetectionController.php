<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class IADetectionController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $expectedToken = (string) env('IA_API_TOKEN', '');
        $providedToken = (string) $request->bearerToken();

        if ($expectedToken === '' || !hash_equals($expectedToken, $providedToken)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized request.',
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'problem_type' => 'required|string|max:100',
            'risk_score' => 'required|numeric|min:0|max:100',
            'severity' => 'required|string|max:50',
            'confidence' => 'required|numeric|min:0|max:1',
            'location' => 'nullable|array',
            'location.address' => 'nullable|string|max:255',
            'location.lat' => 'nullable|numeric|between:-90,90',
            'location.lon' => 'nullable|numeric|between:-180,180',
            'location.lng' => 'nullable|numeric|between:-180,180',
            'location.accuracy' => 'nullable|numeric|min:0',
            'total_defects' => 'nullable|integer|min:0',
            'ai_model' => 'nullable|string|max:150',
            'date_detection' => 'nullable|date',
            'status' => 'nullable|string|max:50',
            'source' => 'nullable|string|max:100',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $payload = $validator->validated();
        $lon = $payload['location']['lon'] ?? $payload['location']['lng'] ?? null;

        $document = [
            'problem_type' => $payload['problem_type'],
            'risk_score' => (float) $payload['risk_score'],
            'severity' => $payload['severity'],
            'confidence' => (float) $payload['confidence'],
            'location' => [
                'address' => $payload['location']['address'] ?? null,
                'lat' => isset($payload['location']['lat']) ? (float) $payload['location']['lat'] : null,
                'lon' => isset($lon) ? (float) $lon : null,
                'accuracy' => isset($payload['location']['accuracy']) ? (float) $payload['location']['accuracy'] : null,
            ],
            'total_defects' => isset($payload['total_defects']) ? (int) $payload['total_defects'] : null,
            'ai_model' => $payload['ai_model'] ?? null,
            'date_detection' => isset($payload['date_detection']) ? Carbon::parse($payload['date_detection'])->toIso8601String() : now()->toIso8601String(),
            'status' => $payload['status'] ?? 'En attente',
            'source' => $payload['source'] ?? 'trig_essalama_ia',
            'description' => $payload['description'] ?? null,
            'created_at' => now()->toIso8601String(),
            'updated_at' => now()->toIso8601String(),
        ];

        $inserted = DB::connection('mongodb')
            ->table('problemes_de_voirie')
            ->insertGetId($document);

        return response()->json([
            'success' => true,
            'message' => 'Detection stored successfully.',
            'id' => (string) $inserted,
        ], 201);
    }

    public function storeBulk(Request $request): JsonResponse
    {
        $expectedToken = (string) env('IA_API_TOKEN', '');
        $providedToken = (string) $request->bearerToken();

        if ($expectedToken === '' || !hash_equals($expectedToken, $providedToken)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized request.',
            ], 401);
        }

        $items = $request->input('items');
        if (!is_array($items) || empty($items)) {
            return response()->json([
                'success' => false,
                'message' => 'Payload invalide: envoyez un tableau "items" non vide.',
            ], 422);
        }

        $insertDocs = [];
        foreach ($items as $i => $data) {
            $validator = Validator::make((array) $data, [
                'problem_type' => 'required|string|max:100',
                'risk_score' => 'required|numeric|min:0|max:100',
                'severity' => 'required|string|max:50',
                'confidence' => 'required|numeric|min:0|max:1',
                'location' => 'nullable|array',
                'location.address' => 'nullable|string|max:255',
                'location.lat' => 'nullable|numeric|between:-90,90',
                'location.lon' => 'nullable|numeric|between:-180,180',
                'location.lng' => 'nullable|numeric|between:-180,180',
                'location.accuracy' => 'nullable|numeric|min:0',
                'total_defects' => 'nullable|integer|min:0',
                'ai_model' => 'nullable|string|max:150',
                'date_detection' => 'nullable|date',
                'status' => 'nullable|string|max:50',
                'source' => 'nullable|string|max:100',
                'description' => 'nullable|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => "Validation failed at index $i.",
                    'errors' => $validator->errors(),
                ], 422);
            }

            $payload = $validator->validated();
            $lon = $payload['location']['lon'] ?? $payload['location']['lng'] ?? null;

            $insertDocs[] = [
                'problem_type' => $payload['problem_type'],
                'risk_score' => (float) $payload['risk_score'],
                'severity' => $payload['severity'],
                'confidence' => (float) $payload['confidence'],
                'location' => [
                    'address' => $payload['location']['address'] ?? null,
                    'lat' => isset($payload['location']['lat']) ? (float) $payload['location']['lat'] : null,
                    'lon' => isset($lon) ? (float) $lon : null,
                    'accuracy' => isset($payload['location']['accuracy']) ? (float) $payload['location']['accuracy'] : null,
                ],
                'total_defects' => isset($payload['total_defects']) ? (int) $payload['total_defects'] : null,
                'ai_model' => $payload['ai_model'] ?? null,
                'date_detection' => isset($payload['date_detection']) ? Carbon::parse($payload['date_detection'])->toIso8601String() : now()->toIso8601String(),
                'status' => $payload['status'] ?? 'En attente',
                'source' => $payload['source'] ?? 'trig_essalama_ia',
                'description' => $payload['description'] ?? null,
                'created_at' => now()->toIso8601String(),
                'updated_at' => now()->toIso8601String(),
            ];
        }

        if (!empty($insertDocs)) {
            DB::connection('mongodb')->table('problemes_de_voirie')->insert($insertDocs);
        }

        return response()->json([
            'success' => true,
            'message' => 'Bulk detections stored successfully.',
            'inserted' => count($insertDocs),
        ], 201);
    }
}
