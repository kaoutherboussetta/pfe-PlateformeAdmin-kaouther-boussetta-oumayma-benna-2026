<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\RegistrationCode;
use Illuminate\Support\Facades\Log;

class GenerateSecurityCode extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'security-code:generate 
                            {--max-uses=1 : Nombre maximum d\'utilisations}
                            {--expire-days=30 : Nombre de jours avant expiration}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Génère un nouveau code de sécurité pour l\'inscription';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $maxUses = (int) $this->option('max-uses');
        $expireDays = (int) $this->option('expire-days');

        // Validation
        if ($maxUses < 1 || $maxUses > 100) {
            $this->error('Le nombre maximum d\'utilisations doit être entre 1 et 100.');
            return 1;
        }

        if ($expireDays < 1 || $expireDays > 365) {
            $this->error('Le nombre de jours d\'expiration doit être entre 1 et 365.');
            return 1;
        }

        try {
            // Générer un code unique
            $code = RegistrationCode::generate();
            
            // Créer le code de sécurité
            $registrationCode = RegistrationCode::create([
                'code' => $code,
                'used' => false,
                'max_uses' => $maxUses,
                'current_uses' => 0,
                'expires_at' => now()->addDays($expireDays),
            ]);

            $this->info('');
            $this->info('═══════════════════════════════════════════════════════════');
            $this->info('  ✅ CODE DE SÉCURITÉ GÉNÉRÉ AVEC SUCCÈS');
            $this->info('═══════════════════════════════════════════════════════════');
            $this->info('');
            $this->line('  Code de sécurité : <fg=cyan;options=bold>' . $code . '</>');
            $this->info('');
            $this->line('  📊 Informations :');
            $this->line('     • Utilisations max : ' . $maxUses);
            $this->line('     • Expire dans : ' . $expireDays . ' jour(s)');
            $this->line('     • Date d\'expiration : ' . $registrationCode->expires_at->format('d/m/Y à H:i'));
            $this->info('');
            $this->info('═══════════════════════════════════════════════════════════');
            $this->info('');

            Log::info('Code de sécurité généré via commande artisan', [
                'code' => $code,
                'max_uses' => $maxUses,
                'expire_days' => $expireDays,
            ]);

            return 0;
        } catch (\Exception $e) {
            $this->error('Erreur lors de la génération du code : ' . $e->getMessage());
            Log::error('Erreur lors de la génération du code de sécurité', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return 1;
        }
    }
}
