<?php

/**
 * Données Budget — dashboard admin TRIG Essalama (montants en DNT).
 * Toute l’interface lit cette config (titres, colonnes, lignes, KPI).
 */
return [
    'currency' => 'DNT',
    'monthly_income_dnt' => 100_000_000,

    'meta' => [
        'page_title' => 'Budget des chantiers',
        'page_subtitle' => 'Synthèse mensuelle : entrée, coûts estimés saisis à l’affectation des équipes.',
        'list_title' => 'Problèmes — type, localisation et coût estimé',
        'list_button' => 'Actualiser la vue',
    ],

    /** Libellés des cartes KPI (haut de page) */
    'kpi_labels' => [
        'entree' => 'Entrée mensuelle',
    ],

    /**
     * Colonnes du tableau (ordre = ordre d’affichage).
     * type: text | money | statut | paye | date
     */
    'table_columns' => [
        ['key' => 'chantier', 'label' => 'Chantier', 'type' => 'text'],
        ['key' => 'admin', 'label' => 'Administrateur', 'type' => 'text'],
        ['key' => 'budget_admin_dnt', 'label' => 'Budget', 'type' => 'money'],
        ['key' => 'mode_paiement', 'label' => 'Mode paiement', 'type' => 'text'],
        ['key' => 'statut', 'label' => 'Statut', 'type' => 'statut'],
        ['key' => 'paye', 'label' => 'Paiement', 'type' => 'paye'],
        ['key' => 'date_paiement', 'label' => 'Date paiement', 'type' => 'date'],
    ],

    'chantiers' => [
        [
            'chantier' => 'Résidence El Amen',
            'admin' => 'Ahmed Ben Salah',
            'budget_admin_dnt' => 2_500_000,
            'paye' => true,
            'mode_paiement' => 'Virement',
            'statut' => 'Validé DG',
            'date_paiement' => '2026-05-05',
        ],
        [
            'chantier' => 'Tour TRIG Centre Urbain',
            'admin' => 'Mohamed Trabelsi',
            'budget_admin_dnt' => 3_200_000,
            'paye' => true,
            'mode_paiement' => 'Espèces',
            'statut' => 'Validé DG',
            'date_paiement' => '2026-05-07',
        ],
        [
            'chantier' => 'Villa Les Jardins',
            'admin' => 'Sami Gharbi',
            'budget_admin_dnt' => 1_800_000,
            'paye' => false,
            'mode_paiement' => 'Virement',
            'statut' => 'En attente',
            'date_paiement' => null,
        ],
        [
            'chantier' => 'Immeuble Essalama Lac 2',
            'admin' => 'Walid Ben Amor',
            'budget_admin_dnt' => 4_100_000,
            'paye' => true,
            'mode_paiement' => 'Chèque',
            'statut' => 'Validé DG',
            'date_paiement' => '2026-05-10',
        ],
        [
            'chantier' => 'Complexe Commercial Ariana',
            'admin' => 'Youssef Khelifi',
            'budget_admin_dnt' => 2_900_000,
            'paye' => false,
            'mode_paiement' => 'Virement',
            'statut' => 'En attente',
            'date_paiement' => null,
        ],
        [
            'chantier' => 'Résidence Palmier',
            'admin' => 'Nader Chaabane',
            'budget_admin_dnt' => 2_300_000,
            'paye' => true,
            'mode_paiement' => 'Espèces',
            'statut' => 'Validé DG',
            'date_paiement' => '2026-05-12',
        ],
    ],
];
