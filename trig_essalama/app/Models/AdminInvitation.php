<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class AdminInvitation extends Model
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
    protected $collection = 'admin_invitations';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'email',
        'role',
        'token',
        'expires_at',
        'used',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'used' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    /**
     * Vérifier si l'invitation est valide
     */
    public function isValid(): bool
    {
        return !$this->used 
            && $this->expires_at !== null 
            && $this->expires_at->isFuture();
    }

    /**
     * Marquer l'invitation comme utilisée
     */
    public function markAsUsed(): void
    {
        $this->update(['used' => true]);
    }
}
