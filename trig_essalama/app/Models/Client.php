<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Illuminate\Notifications\Notifiable;

class Client extends Model
{
    use Notifiable;

    /**
     * The connection name for the model.
     * Uses MongoDB connection for storing clients in MongoDB Atlas.
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
     * Collection pour les clients.
     *
     * @var string
     */
    protected $collection = 'clients';

    /**
     * Indicates if the model should be timestamped.
     * MongoDB utilise createdAt et updatedAt au lieu de created_at et updated_at.
     *
     * @var bool
     */
    public $timestamps = false;

    /**
     * Get the collection name for the model.
     *
     * @return string
     */
    public function getCollectionName(): string
    {
        return 'clients';
    }

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'telephone',
        'adresse',
        'ville',
        'codePostal',
        'createdAt',
        'updatedAt',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'createdAt' => 'datetime',
            'updatedAt' => 'datetime',
        ];
    }
}
