<?php

namespace App\Console\Commands;

use App\Models\Citizen;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class InsertCitizensData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'citizens:insert';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Insérer des données de test dans la collection user_citoyen';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Insertion des données dans la collection user_citoyen...');

        // Vérifier si des données existent déjà
        $existingCount = Citizen::count();
        if ($existingCount > 0) {
            if (!$this->confirm("Il existe déjà {$existingCount} citoyen(s) dans la collection. Voulez-vous continuer ?")) {
                $this->info('Opération annulée.');
                return;
            }
        }

        // Données de test
        $citizens = [
            [
                'first_name' => 'Ahmed',
                'last_name' => 'Benali',
                'name' => 'Ahmed Benali',
                'email' => 'ahmed.benali@example.com',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
                'created_at' => now()->subDays(10),
                'updated_at' => now()->subDays(10),
            ],
            [
                'first_name' => 'Fatima',
                'last_name' => 'Alaoui',
                'name' => 'Fatima Alaoui',
                'email' => 'fatima.alaoui@example.com',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'first_name' => 'Mohammed',
                'last_name' => 'Tazi',
                'name' => 'Mohammed Tazi',
                'email' => 'mohammed.tazi@example.com',
                'password' => Hash::make('password123'),
                'email_verified_at' => null,
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            [
                'first_name' => 'Aicha',
                'last_name' => 'Idrissi',
                'name' => 'Aicha Idrissi',
                'email' => 'aicha.idrissi@example.com',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
                'created_at' => now()->subDays(15),
                'updated_at' => now()->subDays(15),
            ],
            [
                'first_name' => 'Youssef',
                'last_name' => 'Bennani',
                'name' => 'Youssef Bennani',
                'email' => 'youssef.bennani@example.com',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
                'created_at' => now()->subDays(1),
                'updated_at' => now()->subDays(1),
            ],
        ];

        $bar = $this->output->createProgressBar(count($citizens));
        $bar->start();

        foreach ($citizens as $citizenData) {
            // Vérifier si l'email existe déjà
            $existing = Citizen::where('email', $citizenData['email'])->first();
            if (!$existing) {
                Citizen::create($citizenData);
            }
            $bar->advance();
        }

        $bar->finish();
        $this->newLine();
        $this->info('Données insérées avec succès dans la collection user_citoyen !');
        $this->info('Total de citoyens: ' . Citizen::count());
    }
}
