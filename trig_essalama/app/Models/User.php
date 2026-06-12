<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use MongoDB\Laravel\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use Notifiable;

    /**
     * The connection name for the model.
     * Uses MongoDB connection for storing users in MongoDB Atlas.
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
     * IMPORTANT: Toutes les informations des comptes créés via le formulaire d'inscription
     * seront stockées dans la collection 'users_admin_tech' de MongoDB (pas 'users').
     *
     * @var string
     */
    protected $collection = 'users_admin_tech';

    /**
     * Get the collection name for the model.
     * Garantit que la collection utilisée est bien 'users_admin_tech'.
     *
     * @return string
     */
    public function getCollectionName(): string
    {
        return 'users_admin_tech';
    }

    /**
     * The attributes that are mass assignable.
     * Correspond aux champs du formulaire d'inscription.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',                    // Nom complet (first_name + last_name)
        'first_name',              // Prénom (requis dans le formulaire)
        'last_name',               // Nom (requis dans le formulaire)
        'email',                   // Email (requis dans le formulaire)
        'password',                // Mot de passe hashé (requis dans le formulaire)
        'role',                    // Rôle: technical (Admin Technique) ou authoritaire (Admin Autoritaire)
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
            'updated_at' => 'datetime',
        ];
    }
}
