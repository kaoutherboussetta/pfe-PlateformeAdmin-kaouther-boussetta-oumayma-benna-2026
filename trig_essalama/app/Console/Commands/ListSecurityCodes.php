<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\RegistrationCode;
use Carbon\Carbon;

class ListSecurityCodes extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'security-code:list {--valid-only : Afficher uniquement les codes valides}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Liste tous les codes de sécurité disponibles';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $validOnly = $this->option('valid-only');

        try {
            $query = RegistrationCode::orderBy('created_at', 'desc');
            
            if ($validOnly) {
                $codes = $query->get()->filter(function ($code) {
                    return $code->isValid();
                });
            } else {
                $codes = $query->get();
            }

            if ($codes->isEmpty()) {
                $this->warn('Aucun code de sécurité trouvé.');
                return 0;
            }

            $this->info('');
            $this->info('═══════════════════════════════════════════════════════════════════════════════');
            $this->info('  📋 LISTE DES CODES DE SÉCURITÉ');
            $this->info('═══════════════════════════════════════════════════════════════════════════════');
            $this->info('');

            $headers = ['Code', 'Utilisations', 'Max', 'Expire le', 'Statut'];
            $rows = [];

            foreach ($codes as $code) {
                $isValid = $code->isValid();
                $status = $isValid ? '<fg=green>✓ Valide</>' : '<fg=red>✗ Invalide</>';
                
                $expiresAt = $code->expires_at 
                    ? $code->expires_at->format('d/m/Y H:i')
                    : 'Jamais';
                
                $rows[] = [
                    '<fg=cyan;options=bold>' . $code->code . '</>',
                    $code->current_uses ?? 0,
                    $code->max_uses ?? 1,
                    $expiresAt,
                    $status,
                ];
            }

            $this->table($headers, $rows);
            $this->info('');

            // Afficher les codes valides en surbrillance
            $validCodes = $codes->filter(function ($code) {
                return $code->isValid();
            });

            if ($validCodes->isNotEmpty()) {
                $this->info('  ✅ Codes valides disponibles :');
                foreach ($validCodes as $code) {
                    $this->line('     • <fg=cyan;options=bold>' . $code->code . '</>');
                }
                $this->info('');
            }

            $this->info('═══════════════════════════════════════════════════════════════════════════════');
            $this->info('');

            return 0;
        } catch (\Exception $e) {
            $this->error('Erreur lors de la récupération des codes : ' . $e->getMessage());
            return 1;
        }
    }
}
