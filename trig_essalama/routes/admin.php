<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\RegistrationCodeController;

/*
|--------------------------------------------------------------------------
| Routes Admin Sécurisées
|--------------------------------------------------------------------------
|
| Toutes les routes admin sont protégées et nécessitent une authentification.
| Pas d'inscription publique admin - création uniquement par Admin Technique.
|
*/

// Routes publiques admin (login uniquement)
Route::prefix('admin')->name('admin.')->group(function () {
    // Login admin
    Route::get('/login', [AdminAuthController::class, 'showLoginForm'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:5,1')
        ->name('login.post');

    // 2FA
    Route::get('/2fa/verify', [AdminAuthController::class, 'show2FAForm'])->name('2fa.verify');
    Route::post('/2fa/verify', [AdminAuthController::class, 'verify2FA'])->name('2fa.verify.post');

    // Setup password via invitation (publique mais sécurisée par token)
    Route::get('/setup', [AdminController::class, 'showSetupForm'])->name('setup');
    Route::post('/setup', [AdminController::class, 'setupPassword'])->name('setup.post');
});

// Routes protégées admin (nécessitent authentification)
Route::prefix('admin')->name('admin.')->middleware('auth:admin')->group(function () {
    // Dashboard
    Route::get('/dashboard', [AdminController::class, 'dashboard'])->name('dashboard');

    // Logout
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

    // Gestion des admins (uniquement Admin Technique)
    Route::middleware('admin.role:technical')->prefix('admins')->name('admins.')->group(function () {
        Route::get('/', [AdminController::class, 'index'])->name('index');
        Route::get('/create', [AdminController::class, 'create'])->name('create');
        Route::post('/', [AdminController::class, 'store'])->name('store');
        Route::post('/{id}/toggle-active', [AdminController::class, 'toggleActive'])->name('toggle-active');
        Route::post('/{id}/reset-password', [AdminController::class, 'resetPassword'])->name('reset-password');
        Route::delete('/{id}', [AdminController::class, 'destroy'])->name('destroy');
    });

    // Gestion des codes de sécurité (uniquement Admin Technique)
    Route::middleware('admin.role:technical')->prefix('registration-codes')->name('registration-codes.')->group(function () {
        Route::get('/', [RegistrationCodeController::class, 'index'])->name('index');
        Route::get('/create', [RegistrationCodeController::class, 'create'])->name('create');
        Route::post('/', [RegistrationCodeController::class, 'store'])->name('store');
        Route::delete('/{id}', [RegistrationCodeController::class, 'destroy'])->name('destroy');
    });
});
