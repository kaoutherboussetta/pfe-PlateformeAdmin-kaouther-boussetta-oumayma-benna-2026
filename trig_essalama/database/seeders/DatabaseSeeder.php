<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Admin;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Créer un administrateur technique de test dans la collection users_admin_tech
        $existingUser = User::where('email', 'test@gmail.com')->first();
        if (!$existingUser) {
            User::create([
                'name' => 'Test Admin',
                'first_name' => 'Test',
                'last_name' => 'Admin',
                'email' => 'test@gmail.com',
                'password' => Hash::make('password123'),
                'role' => 'technical',
                'email_verified_at' => now(),
            ]);
            $this->command->info('✅ Compte administrateur technique créé: test@gmail.com / password123');
        } else {
            $this->command->info('ℹ️  Le compte test@gmail.com existe déjà.');
        }

        // Créer également un admin dans la collection admins (optionnel)
        $existingAdmin = Admin::where('email', 'test@gmail.com')->first();
        if (!$existingAdmin) {
            Admin::create([
                'first_name' => 'Test',
                'last_name' => 'Admin',
                'email' => 'test@gmail.com',
                'password' => Hash::make('password123'),
                'role' => Admin::ROLE_TECHNICAL,
                'is_active' => true,
            ]);
            $this->command->info('✅ Admin créé dans la collection admins: test@gmail.com / password123');
        }

        // Insérer les données des citoyens
        $this->call([
            CitizenSeeder::class,
        ]);
    }
}
