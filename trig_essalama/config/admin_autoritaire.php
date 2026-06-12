<?php

/**
 * Configuration sécurisée pour l'Administrateur Autoritaire
 * 
 * IMPORTANT: Les identifiants de l'admin autoritaire ne sont PAS stockés en base de données.
 * Ils sont validés directement via cette configuration.
 * 
 * Pour générer un hash de mot de passe, utilisez:
 * php artisan tinker
 * Hash::make('votre_mot_de_passe')
 */

return [
    /**
     * Email de l'administrateur autoritaire
     */
    'email' => env('ADMIN_AUTORITAIRE_EMAIL', 'ts@gmail.com'),

    /**
     * Hash du mot de passe de l'administrateur autoritaire
     * Généré avec Hash::make('votre_mot_de_passe')
     * 
     * IMPORTANT: Pour la production, vous DEVEZ configurer cette variable dans votre fichier .env
     * Exemple: ADMIN_AUTORITAIRE_PASSWORD_HASH=$2y$12$VotreHashIci
     * 
     * Hash par défaut pour le développement (mot de passe: admin123)
     * ⚠️ CHANGEZ-LE EN PRODUCTION !
     */
    'password_hash' => env('ADMIN_AUTORITAIRE_PASSWORD_HASH', '$2y$12$ynJkUCA/0TDWWPWpDtPV.e972qvFkAOcguaeSt2ndJpRKDzuHADaW'),

    /**
     * Code de sécurité requis pour la connexion
     * Peut être un code unique ou un tableau de codes valides
     */
    'security_codes' => [
        env('ADMIN_AUTORITAIRE_SECURITY_CODE', 'AUTOR001'),
        // Vous pouvez ajouter d'autres codes ici si nécessaire
    ],

    /**
     * Informations de l'administrateur (pour l'affichage)
     */
    'name' => env('ADMIN_AUTORITAIRE_NAME', 'Administrateur Autoritaire'),
    'first_name' => env('ADMIN_AUTORITAIRE_FIRST_NAME', 'Admin'),
    'last_name' => env('ADMIN_AUTORITAIRE_LAST_NAME', 'Autoritaire'),
];
