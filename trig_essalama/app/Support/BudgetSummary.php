<?php

namespace App\Support;

use App\Models\Budget;
use App\Models\BudgetMonthlyIncome;

/**
 * Synthèse budget mensuel : entrée initiale, coûts estimés (problèmes), reste.
 */
class BudgetSummary
{
    public static function forMonth(?string $yearMonth = null): array
    {
        $month = $yearMonth ?? now()->format('Y-m');
        if (! is_string($month) || ! preg_match('/^\d{4}-\d{2}$/', $month)) {
            $month = now()->format('Y-m');
        }

        $defaultAmount = (int) (config('trig_budget.monthly_income_dnt') ?? 100_000_000);
        if ($defaultAmount < 1) {
            $defaultAmount = 100_000_000;
        }

        $currency = (string) (config('trig_budget.currency') ?? 'DNT');
        $initial = $defaultAmount;

        try {
            $incomeRow = BudgetMonthlyIncome::firstOrDefaultForMonth($month);
            $initial = (int) $incomeRow->income_amount;
            if ($incomeRow->currency) {
                $currency = (string) $incomeRow->currency;
            }
        } catch (\Throwable $e) {
            // garde config par défaut
        }

        $spent = self::totalEstimatedCostsForMonth($month);
        $remaining = max(0, $initial - $spent);

        return [
            'year_month' => $month,
            'income_initial' => $initial,
            'total_spent' => $spent,
            'income_remaining' => $remaining,
            'currency' => $currency,
        ];
    }

    /**
     * Somme des coûts estimés enregistrés pour le mois (date de mise à jour).
     */
    public static function totalEstimatedCostsForMonth(string $yearMonth): int
    {
        if (! preg_match('/^(\d{4})-(\d{2})$/', $yearMonth, $m)) {
            return 0;
        }

        $year = (int) $m[1];
        $monthNum = (int) $m[2];

        try {
            $sum = Budget::query()
                ->whereYear('updated_at', $year)
                ->whereMonth('updated_at', $monthNum)
                ->sum('cout_estime_numeric');

            return (int) round((float) $sum);
        } catch (\Throwable $e) {
            return 0;
        }
    }
}
