<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Admin;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class CreateFirstAdmin extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'admin:create-first 
                            {--email= : Email de l\'administrateur}
                            {--name= : Nom complet de l\'administrateur}
                            {--role=technique : Rôle (technique ou autoritaire)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Créer le premier administrateur technique (Super Admin)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔐 Création du premier Administrateur Technique');
        $this->newLine();

        // Vérifier s'il existe déjà des admins
        if (Admin::count() > 0) {
            $this->warn('⚠️  Des administrateurs existent déjà dans le système.');
            if (!$this->confirm('Voulez-vous continuer ?', false)) {
                $this->info('Opération annulée.');
                return 0;
            }
        }

        // Demander les informations
        $email = $this->option('email') ?: $this->ask('Email de l\'administrateur');
        $first_name = $this->option('name') ?: $this->ask('Prénom de l\'administrateur');
        $last_name = $this->ask('Nom de l\'administrateur');
        $role = $this->option('role');

        if (!in_array($role, [Admin::ROLE_TECHNICAL, Admin::ROLE_AUTORITAIRE])) {
            $this->error('Le rôle doit être "technical" ou "authoritaire".');
            return 1;
        }

        // Vérifier si l'email existe déjà
        if (Admin::where('email', $email)->exists()) {
            $this->error("Un administrateur avec l'email {$email} existe déjà.");
            return 1;
        }

        // Générer un mot de passe fort
        $password = Str::random(16);
        $this->newLine();
        $this->info('📝 Informations de l\'administrateur:');
        $this->line("   Email: {$email}");
        $this->line("   Prénom: {$first_name}");
        $this->line("   Nom: {$last_name}");
        $this->line("   Rôle: {$role}");
        $this->line("   Mot de passe généré: {$password}");
        $this->newLine();
        $this->warn('⚠️  IMPORTANT: Notez ce mot de passe, il ne sera plus affiché !');
        $this->newLine();

        if (!$this->confirm('Créer cet administrateur ?', true)) {
            $this->info('Opération annulée.');
            return 0;
        }

        try {
            // Créer l'admin
            $admin = Admin::create([
                'first_name' => $first_name,
                'last_name' => $last_name,
                'email' => $email,
                'password' => Hash::make($password),
                'role' => $role,
                'is_active' => true,
            ]);

            $this->newLine();
            $this->info('✅ Administrateur créé avec succès !');
            $this->newLine();
            $this->info('🔗 Vous pouvez maintenant vous connecter à: /admin/login');
            $this->newLine();
            $this->warn('📋 Informations de connexion:');
            $this->line("   Email: {$email}");
            $this->line("   Mot de passe: {$password}");
            $this->newLine();
            $this->warn('⚠️  Changez ce mot de passe après la première connexion !');

            return 0;
        } catch (\Exception $e) {
            $this->error('Erreur lors de la création: ' . $e->getMessage());
            return 1;
        }
    }
}
