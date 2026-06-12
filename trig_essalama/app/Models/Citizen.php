<?php

namespace App\Models;

use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class Citizen extends Authenticatable
{
    use Notifiable;

    /**
     * The connection name for the model.
     * Uses MongoDB connection for storing citizens in MongoDB Atlas.
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
     * Collection pour les comptes citoyens.
     *
     * @var string
     */
    protected $collection = 'user_citoyen';

    /**
     * Get the collection name for the model.
     * Force l'utilisation de la collection 'user_citoyen'
     *
     * @return string
     */
    public function getCollectionName(): string
    {
        return 'user_citoyen';
    }
    
    /**
     * Get the table associated with the model.
     * Pour MongoDB, cela retourne le nom de la collection
     *
     * @return string
     */
    public function getTable()
    {
        return $this->collection ?? 'user_citoyen';
    }

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',                    // Nom complet (first_name + last_name)
        'fullName',                // Nom complet (format utilisé dans MongoDB)
        'first_name',              // Prénom
        'last_name',               // Nom
        'email',                   // Email
        'password',                // Mot de passe hashé
        'email_verified_at',        // Date de confirmation du compte
        'remember_token',           // Token pour "Se souvenir de moi"
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'created_at' => 'datetime',
            'createdAt' => 'datetime',
            'updated_at' => 'datetime',
            'updatedAt' => 'datetime',
        ];
    }

    /**
     * Get an attribute from the model.
     * Support both Laravel format (created_at) and MongoDB format (createdAt)
     */
    public function getAttribute($key)
    {
        $value = parent::getAttribute($key);
        
        // Si la valeur n'existe pas, essayer les variantes
        if ($value === null) {
            // Si on cherche created_at mais qu'on a createdAt
            if ($key === 'created_at' && isset($this->attributes['createdAt'])) {
                return $this->attributes['createdAt'];
            }
            // Si on cherche updated_at mais qu'on a updatedAt
            if ($key === 'updated_at' && isset($this->attributes['updatedAt'])) {
                return $this->attributes['updatedAt'];
            }
            // Si on cherche createdAt mais qu'on a created_at
            if ($key === 'createdAt' && isset($this->attributes['created_at'])) {
                return $this->attributes['created_at'];
            }
            // Si on cherche updatedAt mais qu'on a updated_at
            if ($key === 'updatedAt' && isset($this->attributes['updated_at'])) {
                return $this->attributes['updated_at'];
            }
        }
        
        return $value;
    }
}
