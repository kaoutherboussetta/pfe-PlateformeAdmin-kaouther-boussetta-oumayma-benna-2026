<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class CreateUserAdminCollection extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'mongodb:create-user-admin-collection';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Créer la collection users_admin_tech dans MongoDB Atlas';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔄 Création de la collection users_admin_tech dans MongoDB...');

        try {
            // Vérifier la connexion MongoDB
            $database = DB::connection('mongodb')->getDatabaseName();
            $this->info("📊 Base de données: {$database}");

            // Obtenir le client MongoDB
            $client = DB::connection('mongodb')->getMongoClient();
            $db = $client->selectDatabase($database);
            
            // Créer la collection users_admin_tech
            // MongoDB crée automatiquement la collection lors de la première insertion
            // On va créer un document temporaire pour initialiser la collection
            $collection = $db->selectCollection('users_admin_tech');
            
            // Insérer un document temporaire pour créer la collection
            $collection->insertOne([
                '_initialized' => true,
                'created_at' => new \MongoDB\BSON\UTCDateTime(),
                'description' => 'Collection pour stocker les comptes utilisateurs créés via le formulaire d\'inscription'
            ]);

            // Supprimer le document d'initialisation
            $collection->deleteOne(['_initialized' => true]);

            $this->info('✅ Collection users_admin_tech créée avec succès !');
            $this->info('📍 Emplacement: Base de données "trig_essalama" > Collection "users_admin_tech"');
            $this->newLine();
            $this->info('💡 Vous pouvez maintenant créer des comptes via le formulaire d\'inscription.');
            $this->info('💡 Les données seront automatiquement stockées dans cette collection.');

            return Command::SUCCESS;
        } catch (\Exception $e) {
            $this->error('❌ Erreur lors de la création de la collection:');
            $this->error($e->getMessage());
            $this->newLine();
            $this->warn('💡 Vérifiez votre configuration MongoDB dans le fichier .env');
            $this->warn('💡 Assurez-vous que MONGODB_DSN et MONGODB_DATABASE sont correctement configurés.');

            return Command::FAILURE;
        }
    }
}
