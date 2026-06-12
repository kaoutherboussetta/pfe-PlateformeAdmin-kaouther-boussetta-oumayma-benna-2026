<?php

namespace Database\Seeders;

use App\Models\Citizen;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class CitizenSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Données de test pour la collection user_citoyen
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
                'email_verified_at' => null, // Non vérifié
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

        foreach ($citizens as $citizenData) {
            Citizen::create($citizenData);
        }

        $this->command->info('Données de test insérées dans la collection user_citoyen avec succès !');
    }
}
