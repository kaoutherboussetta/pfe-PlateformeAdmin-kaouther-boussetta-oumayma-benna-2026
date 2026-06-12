<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('users_admin_tech', function (Blueprint $table) {
            $table->id();
            $table->string('name');                    // Nom complet (first_name + last_name)
            $table->string('first_name');              // Prénom (requis dans le formulaire)
            $table->string('last_name');               // Nom (requis dans le formulaire)
            $table->string('email')->unique();         // Email (requis dans le formulaire)
            $table->timestamp('email_verified_at')->nullable(); // Date de confirmation
            $table->string('password');                // Mot de passe hashé (requis dans le formulaire)
            $table->rememberToken();                   // Token pour "Se souvenir de moi"
            $table->timestamps();                      // created_at et updated_at
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users_admin_tech');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('sessions');
    }
};
