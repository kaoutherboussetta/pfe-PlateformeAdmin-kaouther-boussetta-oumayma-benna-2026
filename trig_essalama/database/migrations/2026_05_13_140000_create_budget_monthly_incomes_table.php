<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    protected $connection = 'budget';

    public function up(): void
    {
        Schema::connection($this->connection)->create('budget_monthly_incomes', function (Blueprint $table) {
            $table->id();
            $table->string('year_month', 7)->unique();
            $table->unsignedBigInteger('income_amount');
            $table->string('currency', 8)->default('DNT');
            $table->string('saved_by', 191)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::connection($this->connection)->dropIfExists('budget_monthly_incomes');
    }
};
