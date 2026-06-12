<?php

namespace App\Http\Controllers;

use App\Models\BudgetMonthlyIncome;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class BudgetMonthlyIncomeController extends Controller
{
    private function canEdit(Request $request): bool
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

    private function savedBy(Request $request): ?string
    {
        $v = $request->session()->get('admin_email')
            ?? $request->session()->get('admin_name')
            ?? optional(Auth::guard('admin')->user())->email;

        if ($v === null || $v === '') {
            return null;
        }

        return mb_substr((string) $v, 0, 190);
    }

    public function show(Request $request): JsonResponse
    {
        if (! $this->canEdit($request)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        $month = $request->query('month', now()->format('Y-m'));
        if (! is_string($month) || ! preg_match('/^\d{4}-\d{2}$/', $month)) {
            return response()->json(['success' => false, 'message' => 'Mois invalide.'], 422);
        }

        try {
            $row = BudgetMonthlyIncome::firstOrDefaultForMonth($month);

            return response()->json([
                'success' => true,
                'data' => [
                    'year_month' => $month,
                    'income_amount' => (int) $row->income_amount,
                    'currency' => (string) $row->currency,
                    'exists' => true,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de lire l’entrée mensuelle (base budget).',
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        if (! $this->canEdit($request)) {
            return response()->json(['success' => false, 'message' => 'Accès refusé.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'year_month' => ['required', 'string', 'regex:/^\d{4}-\d{2}$/'],
            'income_amount' => ['required', 'integer', 'min:1', 'max:999999999999'],
            'currency' => ['nullable', 'string', 'max:8'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Données invalides.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $month = $request->string('year_month')->toString();
        $amount = (int) $request->input('income_amount');
        $currency = $request->filled('currency')
            ? mb_substr($request->string('currency')->toString(), 0, 8)
            : (string) (config('trig_budget.currency') ?? 'DNT');

        try {
            BudgetMonthlyIncome::query()->updateOrCreate(
                ['year_month' => $month],
                [
                    'income_amount' => $amount,
                    'currency' => $currency,
                    'saved_by' => $this->savedBy($request),
                ]
            );

            return response()->json([
                'success' => true,
                'message' => 'Entrée mensuelle enregistrée.',
                'data' => [
                    'year_month' => $month,
                    'income_amount' => $amount,
                    'currency' => $currency,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Enregistrement impossible (base budget).',
            ], 500);
        }
    }
}
