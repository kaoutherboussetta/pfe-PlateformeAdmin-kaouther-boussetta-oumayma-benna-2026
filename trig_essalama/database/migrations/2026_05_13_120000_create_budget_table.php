<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Table SQL des coûts estimés (saisie admin à l’affectation d’équipe).
     * Connexion dédiée : voir config/database.php — `budget`.
     */
    protected $connection = 'budget';

    public function up(): void
    {
        Schema::connection($this->connection)->create('budget', function (Blueprint $table) {
            $table->id();
            $table->string('problem_id', 64)->unique();
            $table->string('team_key', 120)->nullable();
            $table->string('team_label', 160)->nullable();
            $table->string('cout_estime', 160);
            $table->decimal('cout_estime_numeric', 18, 2)->nullable();
            $table->string('assigned_by', 191)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection($this->connection)->dropIfExists('budget');
    }
};
