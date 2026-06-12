<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Support\Str;

class RegistrationCode extends Model
{
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
    protected $collection = 'registration_codes';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'code',
        'used',
        'used_by',
        'used_at',
        'expires_at',
        'max_uses',
        'current_uses',
        'created_by',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'used' => 'boolean',
            'used_at' => 'datetime',
            'expires_at' => 'datetime',
            'max_uses' => 'integer',
            'current_uses' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Générer un nouveau code de sécurité unique
     */
    public static function generate(): string
    {
        // Générer un code alphanumérique de 8 caractères
        $code = strtoupper(Str::random(8));
        
        // S'assurer que le code est unique
        while (self::where('code', $code)->exists()) {
            $code = strtoupper(Str::random(8));
        }

        return $code;
    }

    /**
     * Vérifier si le code est valide
     */
    public function isValid(): bool
    {
        // Vérifier si le code a expiré
        if ($this->expires_at && $this->expires_at->isPast()) {
            return false;
        }

        // Vérifier si le code a atteint le nombre maximum d'utilisations
        if ($this->max_uses && $this->current_uses >= $this->max_uses) {
            return false;
        }

        return true;
    }

    /**
     * Marquer le code comme utilisé
     */
    public function markAsUsed(string $email): void
    {
        $this->current_uses = ($this->current_uses ?? 0) + 1;
        
        if ($this->current_uses >= $this->max_uses) {
            $this->used = true;
        }
        
        $this->used_by = $email;
        $this->used_at = now();
        $this->save();
    }
}
