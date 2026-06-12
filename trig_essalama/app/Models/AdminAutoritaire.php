<?php

namespace App\Models;

use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class AdminAutoritaire extends Authenticatable
{
    use Notifiable;

    /**
     * Connection MongoDB
     */
    protected $connection = 'mongodb';

    /**
     * Database name
     */
    protected $database = 'trig_essalama';

    /**
     * Collection name
     */
    protected $collection = 'admin_autoritaires';

    /**
     * Mass assignable fields
     */
    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'phone',
        'city',
        'country',
        'password',
        'is_active',
        // Tableau de codes de sécurité propres à chaque admin
        'security_codes',
        'two_factor_secret',
        'last_login_at',
        'email_verified_at',
        'remember_token',
        'avatar_url',
    ];

    /**
     * Hidden fields
     */
    protected $hidden = [
        'password',
        'two_factor_secret',
        'remember_token',
    ];

    /**
     * Casts
     */
    protected function casts(): array
    {
        return [
            // Permet de stocker plusieurs codes de sécurité sous forme de tableau
            'security_codes' => 'array',
            'password' => 'hashed',
            'is_active' => 'boolean',
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Enregistrer la dernière connexion
     */
    public function recordLogin(): void
    {
        $this->update([
            'last_login_at' => now(),
        ]);
    }

    /**
     * Nom complet de l'admin
     */
    public function getFullNameAttribute(): string
    {
        $parts = array_filter([$this->first_name, $this->last_name]);

        return !empty($parts)
            ? implode(' ', $parts)
            : ($this->email ?? 'Admin Autoritaire');
    }
}