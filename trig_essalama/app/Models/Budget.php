<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Ligne de coût estimé liée à un problème Mongo (problem_id = ObjectId hex).
 *
 * @property int $id
 * @property string $problem_id
 * @property string|null $team_key
 * @property string|null $team_label
 * @property string $cout_estime
 * @property string|null $assigned_by
 */
class Budget extends Model
{
    protected $connection = 'budget';

    protected $table = 'budget';

    protected $fillable = [
        'problem_id',
        'team_key',
        'team_label',
        'cout_estime',
        'cout_estime_numeric',
        'assigned_by',
    ];

    protected function casts(): array
    {
        return [
            'cout_estime_numeric' => 'decimal:2',
        ];
    }
}
