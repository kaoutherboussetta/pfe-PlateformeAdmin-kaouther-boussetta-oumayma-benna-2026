<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/**
 * Compteurs sidebar « Problèmes de Voirie » (badge en attente, etc.).
 */
class ProblemesSidebarStats
{
    public static function counts(): array
    {
        $defaults = [
            'en_attente' => 0,
            'en_cours' => 0,
            'termine' => 0,
            'critiques' => 0,
        ];

        try {
            $rows = DB::connection('mongodb')
                ->table('problemes_de_voirie')
                ->orderBy('_id', 'desc')
                ->limit(300)
                ->get();

            $enAttente = 0;
            $enCours = 0;
            $termine = 0;
            $critiques = 0;

            foreach ($rows as $row) {
                $arr = is_array($row) ? $row : (array) $row;
                $st = strtolower(trim((string) (data_get($arr, 'statut') ?? data_get($arr, 'status') ?? '')));
                $norm = match (true) {
                    str_contains($st, 'cours') => 'en_cours',
                    str_contains($st, 'term') => 'termine',
                    default => 'en_attente',
                };

                match ($norm) {
                    'en_cours' => $enCours++,
                    'termine' => $termine++,
                    default => $enAttente++,
                };

                $gravite = strtolower(trim((string) (data_get($arr, 'gravite') ?? data_get($arr, 'severity') ?? '')));
                $risk = (int) (data_get($arr, 'risk_score') ?? data_get($arr, 'score_risque') ?? data_get($arr, 'score') ?? 0);
                if ($gravite === 'critique' || $risk >= 85) {
                    $critiques++;
                }
            }

            return [
                'en_attente' => $enAttente,
                'en_cours' => $enCours,
                'termine' => $termine,
                'critiques' => $critiques,
            ];
        } catch (\Throwable $e) {
            return $defaults;
        }
    }
}
