<?php

namespace App\Models;

use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Hash;

class Admin extends Authenticatable
{
    use Notifiable;

    /**
     * Types de rôles admin
     */
    const ROLE_TECHNICAL = 'technical';
    const ROLE_AUTORITAIRE = 'authoritaire';

    /**
     * The connection name for the model.
     *
     * @var string
     */
    protected $connection = 'mongodb';

    /**
     * The database associated with the model.
     *
     * @var string
     */
    protected $database = 'trig_essalama';

    /**
     * The collection associated with the model.
     *
     * @var string
     */
    protected $collection = 'admins';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'password',
        'role',
        'is_active',
        'two_factor_secret',
        'last_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'two_factor_secret',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'password' => 'hashed',
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Vérifier si l'admin est un Admin Technique
     */
    public function isTechnical(): bool
    {
        return $this->role === self::ROLE_TECHNICAL;
    }

    /**
     * Vérifier si l'admin est un Admin Autoritaire
     */
    public function isAuthoritaire(): bool
    {
        return $this->role === self::ROLE_AUTORITAIRE;
    }

    /**
     * Vérifier si l'admin peut créer d'autres admins
     */
    public function canCreateAdmins(): bool
    {
        return $this->isTechnical();
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
     * Obtenir le nom complet de l'admin
     */
    public function getFullNameAttribute(): string
    {
        $parts = array_filter([$this->first_name, $this->last_name]);
        return !empty($parts) ? implode(' ', $parts) : ($this->email ?? 'Admin');
    }
}
