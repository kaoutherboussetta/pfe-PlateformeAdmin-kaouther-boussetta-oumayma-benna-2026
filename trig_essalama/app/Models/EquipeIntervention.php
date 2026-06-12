<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class EquipeIntervention extends Model
{
    protected $connection = 'mongodb';

    protected $database = 'trig_essalama';

    protected $collection = 'equipes_intervention';

    protected $fillable = [
        'nom',
        'zone',
        'disponible',
        'membres',
        'current_problem_id',
    ];

    protected function casts(): array
    {
        return [
            'disponible' => 'boolean',
            'membres' => 'array',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function isAssignable(): bool
    {
        if (! $this->disponible) {
            return false;
        }

        $pid = $this->current_problem_id ?? null;

        return $pid === null || $pid === '';
    }

    public function teamKey(): string
    {
        $slug = strtolower((string) preg_replace('/\s+/', '_', (string) $this->nom));
        $slug = (string) preg_replace('/[^a-z0-9_]/', '', $slug);
        if ($slug === '' || $slug === '_') {
            $slug = 'equipe';
        }
        $idSuffix = substr(preg_replace('/[^a-f0-9]/i', '', (string) $this->getKey()), -8);
        if ($idSuffix === '') {
            $idSuffix = 'id';
        }

        return 'equipe_'.$slug.'_'.$idSuffix;
    }
}
