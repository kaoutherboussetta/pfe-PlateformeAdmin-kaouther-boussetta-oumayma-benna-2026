<?php

namespace App\Models;

/**
 * Classe pour représenter l'Administrateur Autoritaire dans la session
 * 
 * Cette classe n'est PAS un modèle de base de données.
 * Elle est utilisée uniquement pour stocker les informations de l'admin autoritaire
 * dans la session après authentification via configuration.
 */
class AdminAutoritaireSession
{
    public $id;
    public $email;
    public $name;
    public $first_name;
    public $last_name;
    public $role = 'autoritaire';
    public $is_active = true;
    public $email_verified_at;
    public $created_at;
    public $updated_at;

    public function __construct(array $attributes = [])
    {
        $this->id = $attributes['id'] ?? 'autoritaire_1';
        $this->email = $attributes['email'] ?? '';
        $this->name = $attributes['name'] ?? '';
        $this->first_name = $attributes['first_name'] ?? '';
        $this->last_name = $attributes['last_name'] ?? '';
        $this->email_verified_at = $attributes['email_verified_at'] ?? now();
        $this->created_at = $attributes['created_at'] ?? now();
        $this->updated_at = $attributes['updated_at'] ?? now();
    }

    /**
     * Obtenir le nom complet
     */
    public function getFullNameAttribute(): string
    {
        $parts = array_filter([$this->first_name, $this->last_name]);
        return !empty($parts) ? implode(' ', $parts) : $this->name;
    }

    /**
     * Vérifier si c'est un admin technique
     */
    public function isTechnical(): bool
    {
        return $this->role === 'technical';
    }

    /**
     * Vérifier si c'est un admin autoritaire
     */
    public function isAutoritaire(): bool
    {
        return $this->role === 'autoritaire';
    }

    /**
     * Convertir en tableau pour la session
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
            'name' => $this->name,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'role' => $this->role,
            'is_active' => $this->is_active,
            'email_verified_at' => $this->email_verified_at,
        ];
    }
}
