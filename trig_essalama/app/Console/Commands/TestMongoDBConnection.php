<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class TestMongoDBConnection extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'mongodb:test';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Teste la connexion à MongoDB Atlas et affiche les informations de connexion';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔍 Test de la connexion MongoDB...');
        $this->newLine();

        try {
            // Test 1: Vérifier la configuration
            $this->info('1️⃣ Vérification de la configuration...');
            $connection = config('database.default');
            $this->line("   Connexion par défaut: {$connection}");
            
            if ($connection !== 'mongodb') {
                $this->warn('   ⚠️  La connexion par défaut n\'est pas MongoDB!');
                $this->line('   Vérifiez votre fichier .env: DB_CONNECTION=mongodb');
            } else {
                $this->info('   ✅ Connexion MongoDB configurée');
            }
            
            // Afficher la configuration MongoDB (sans mot de passe)
            $mongodbConfig = config('database.connections.mongodb');
            $this->line('   Configuration MongoDB:');
            if (!empty($mongodbConfig['dsn'])) {
                // Masquer le mot de passe dans le DSN
                $dsn = $mongodbConfig['dsn'];
                $dsn = preg_replace('/mongodb\+srv:\/\/([^:]+):([^@]+)@/', 'mongodb+srv://$1:***@', $dsn);
                $this->line("      DSN: {$dsn}");
            } else {
                $this->line("      Host: {$mongodbConfig['host']}");
                $this->line("      Port: {$mongodbConfig['port']}");
                $this->line("      Username: " . (!empty($mongodbConfig['username']) ? $mongodbConfig['username'] : '(non défini)'));
                $this->line("      Password: " . (!empty($mongodbConfig['password']) ? '***' : '(non défini)'));
            }
            $this->line("      Database: {$mongodbConfig['database']}");
            $this->line("      Auth Database: " . ($mongodbConfig['options']['database'] ?? 'admin'));
            $this->newLine();

            // Test 2: Tester la connexion
            $this->info('2️⃣ Test de connexion à MongoDB Atlas...');
            $databaseName = DB::connection('mongodb')->getDatabaseName();
            $this->info("   ✅ Connecté à la base de données: {$databaseName}");
            $this->newLine();

            // Test 3: Lister les bases de données
            $this->info('3️⃣ Bases de données disponibles:');
            try {
                $databases = DB::connection('mongodb')->getMongoClient()->listDatabases();
                foreach ($databases as $database) {
                    $this->line("   - {$database->getName()}");
                }
            } catch (\Exception $e) {
                $this->warn("   ⚠️  Impossible de lister les bases de données: {$e->getMessage()}");
            }
            $this->newLine();

            // Test 4: Vérifier la collection admin
            $this->info('4️⃣ Vérification de la collection "admin"...');
            try {
                $collection = DB::connection('mongodb')->collection('admin');
                $count = $collection->count();
                $this->info("   ✅ Collection 'admin' trouvée avec {$count} document(s)");
            } catch (\Exception $e) {
                $this->warn("   ⚠️  Collection 'admin' non trouvée ou vide: {$e->getMessage()}");
                $this->line('   (C\'est normal si c\'est la première fois)');
            }
            $this->newLine();

            // Test 5: Tester le modèle User
            $this->info('5️⃣ Test du modèle User...');
            try {
                $userCount = User::count();
                $this->info("   ✅ Modèle User fonctionne! {$userCount} utilisateur(s) trouvé(s)");
                
                if ($userCount > 0) {
                    $this->line('   Derniers utilisateurs:');
                    $users = User::take(3)->get(['name', 'email', 'created_at']);
                    foreach ($users as $user) {
                        $this->line("   - {$user->name} ({$user->email})");
                    }
                }
            } catch (\Exception $e) {
                $this->error("   ❌ Erreur avec le modèle User: {$e->getMessage()}");
            }
            $this->newLine();

            // Résumé
            $this->info('✅ Connexion MongoDB réussie!');
            $this->line("   Base de données: {$databaseName}");
            $this->line("   Collection: admin");
            $this->newLine();
            $this->comment('💡 Vous pouvez maintenant utiliser le formulaire d\'inscription pour créer des utilisateurs!');

            return Command::SUCCESS;

        } catch (\MongoDB\Driver\Exception\AuthenticationException $e) {
            $this->error('❌ Erreur d\'authentification MongoDB!');
            $this->error("   Message: {$e->getMessage()}");
            $this->newLine();
            $this->warn('🔧 Solutions pour l\'erreur d\'authentification:');
            $this->line('   1. Vérifiez votre fichier .env:');
            $this->line('      - MONGODB_DSN doit contenir le bon username et password');
            $this->line('      - OU MONGODB_USERNAME et MONGODB_PASSWORD doivent être corrects');
            $this->line('   2. Si votre mot de passe contient des caractères spéciaux (@, #, $, etc.)');
            $this->line('      vous devez les encoder en URL dans le DSN:');
            $this->line('      @ → %40, # → %23, $ → %24, etc.');
            $this->line('   3. Vérifiez que MONGODB_AUTHENTICATION_DATABASE=admin dans .env');
            $this->line('   4. Vérifiez dans MongoDB Atlas que:');
            $this->line('      - L\'utilisateur existe dans Database Access');
            $this->line('      - Le mot de passe est correct');
            $this->line('      - L\'utilisateur a les permissions nécessaires');
            $this->newLine();
            $this->comment('📖 Consultez FIX_MONGODB_AUTH.md pour un guide détaillé');
            return Command::FAILURE;
        } catch (\Exception $e) {
            $this->error('❌ Erreur de connexion à MongoDB!');
            $this->error("   Message: {$e->getMessage()}");
            $this->newLine();
            $this->warn('🔧 Vérifications à faire:');
            $this->line('   1. Vérifiez votre fichier .env (MONGODB_DSN, MONGODB_DATABASE)');
            $this->line('   2. Vérifiez que votre IP est autorisée dans MongoDB Atlas');
            $this->line('   3. Vérifiez que l\'extension PHP MongoDB est installée: php -m | grep mongodb');
            $this->line('   4. Vérifiez que le mot de passe dans le DSN est correctement encodé');
            $this->newLine();
            $this->comment('📖 Consultez FIX_MONGODB_AUTH.md pour plus d\'informations');

            return Command::FAILURE;
        }
    }
}
