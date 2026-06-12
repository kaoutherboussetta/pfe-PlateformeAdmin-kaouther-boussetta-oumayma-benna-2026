<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Entrée mensuelle de trésorerie (montant saisi par l’admin, par mois YYYY-MM).
 */
class BudgetMonthlyIncome extends Model
{
    protected $connection = 'budget';

    protected $table = 'budget_monthly_incomes';

    protected $fillable = [
        'year_month',
        'income_amount',
        'currency',
        'saved_by',
    ];

    /**
     * Retourne la ligne du mois ; si absente, crée une entrée avec
     * monthly_income_dnt du fichier config (ex. 100 000 000 DNT).
     */
    public static function firstOrDefaultForMonth(string $yearMonth): self
    {
        $defaultAmount = (int) (config('trig_budget.monthly_income_dnt') ?? 100_000_000);
        if ($defaultAmount < 1) {
            $defaultAmount = 100_000_000;
        }

        return static::query()->firstOrCreate(
            ['year_month' => $yearMonth],
            [
                'income_amount' => $defaultAmount,
                'currency' => (string) (config('trig_budget.currency') ?? 'DNT'),
                'saved_by' => 'auto',
            ]
        );
    }

    protected function casts(): array
    {
        return [
            'income_amount' => 'integer',
        ];
    }
}
