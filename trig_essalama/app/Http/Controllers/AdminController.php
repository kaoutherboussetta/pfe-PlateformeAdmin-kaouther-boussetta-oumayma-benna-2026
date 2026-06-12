<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\AdminAutoritaire;
use App\Models\AdminInvitation;
use App\Models\Citizen;
use App\Models\RegistrationCode;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\TwoFactorService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use MongoDB\BSON\ObjectId;

class AdminController extends Controller
{
    protected $auditLogService;

    protected $twoFactorService;

    public function __construct(AuditLogService $auditLogService, TwoFactorService $twoFactorService)
    {
        $this->auditLogService = $auditLogService;
        $this->twoFactorService = $twoFactorService;
    }

    /**
     * Dashboard admin
     */
    public function dashboard()
    {
        $admin = Auth::guard('admin')->user();

        $stats = [
            'total_admins' => Admin::count(),
            'active_admins' => Admin::where('is_active', true)->count(),
            'technical_admins' => Admin::where('role', Admin::ROLE_TECHNICAL)->count(),
            'authoritaire_admins' => Admin::where('role', Admin::ROLE_AUTORITAIRE)->count(),
        ];

        // Analyse dynamique des problèmes de voirie (tolérante si la collection n'existe pas)
        $problemsAnalysis = $this->getRoadProblemsAnalysis();

        return view('admin.dashboard', [
            'admin' => $admin,
            'stats' => $stats,
            'problemsAnalysis' => $problemsAnalysis,
        ]);
    }

    /**
     * Calculer des indicateurs à partir de la collection "problemes_de_voirie"
     * Schéma attendu (exemples fournis):
     *  - problem_type (ex: "crack", "pothole")
     *  - total_defects (int)
     *  - severity ("Faible" | "Moyenne" | "Élevée")
     *  - risk_score (float)
     *  - confidence (float)
     *  - date_detection (ISO string)
     */
    private function getRoadProblemsAnalysis(): array
    {
        try {
            // Tenter d'accéder à Mongo via Eloquent DB (connexion par défaut)
            // Si votre connexion Mongo s'appelle autrement, adaptez via DB::connection('mongodb')
            $collection = DB::table('problemes_de_voirie');

            // Totaux simples
            $total = (int) ($collection->count() ?? 0);

            // Moyenne des risk_score et confidence
            $avgRisk = (float) ($collection->avg('risk_score') ?? 0);
            $avgConfidence = (float) ($collection->avg('confidence') ?? 0);

            // Répartition par sévérité
            $bySeverityRows = $collection
                ->select('severity', DB::raw('COUNT(*) as c'))
                ->groupBy('severity')
                ->get();
            $bySeverity = [];
            foreach ($bySeverityRows as $r) {
                $key = (string) ($r->severity ?? 'Inconnue');
                $bySeverity[$key] = (int) $r->c;
            }

            // Top types
            $byType = $collection
                ->select('problem_type', DB::raw('COUNT(*) as c'))
                ->groupBy('problem_type')
                ->orderByDesc('c')
                ->limit(6)
                ->get();

            // Volume par mois (7 derniers mois incluant courant) en se basant sur date_detection
            $start = now()->subMonths(6)->startOfMonth();
            $end = now()->endOfMonth();

            // Pour compatibilité Mongo: on récupère brut et on bucketise en PHP sur date_detection (string)
            $rawDocs = DB::table('problemes_de_voirie')
                ->whereBetween('date_detection', [$start->toIso8601String(), $end->toIso8601String()])
                ->get();

            $months = collect(range(6, 0))->map(fn ($i) => now()->subMonths($i));
            $ymKeys = $months->map(fn ($d) => $d->format('Y-m'));
            $labels = $months->map(fn ($d) => $d->locale('fr_FR')->isoFormat('MMM'))->values();
            $perMonthMap = array_fill_keys($ymKeys->all(), 0);

            foreach ($rawDocs as $doc) {
                $dstr = $doc->date_detection ?? null;
                try {
                    $dt = \Carbon\Carbon::parse($dstr);
                    $ym = $dt->format('Y-m');
                    if (array_key_exists($ym, $perMonthMap)) {
                        $perMonthMap[$ym] += 1;
                    }
                } catch (\Throwable $e) {
                    // ignorer les dates invalides
                }
            }

            $perMonth = array_values($perMonthMap);

            return [
                'total' => $total,
                'avgRisk' => round($avgRisk, 2),
                'avgConfidence' => round($avgConfidence, 2),
                'bySeverity' => $bySeverity,
                'byType' => $byType,
                'labels' => $labels,
                'perMonth' => $perMonth,
            ];
        } catch (\Throwable $e) {
            \Log::warning('Analyse problemes_de_voirie indisponible: '.$e->getMessage());

            return [
                'total' => 0,
                'avgRisk' => 0,
                'avgConfidence' => 0,
                'bySeverity' => [],
                'byType' => collect(),
                'labels' => collect(),
                'perMonth' => [],
            ];
        }
    }

    /**
     * Liste des admins (uniquement Admin Technique)
     */
    public function index()
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $admins = Admin::orderBy('created_at', 'desc')->get();

        return view('admin.admins.index', compact('admins'));
    }

    /**
     * Afficher le formulaire de création d'admin
     */
    public function create()
    {
        // Le middleware admin.role:technical s'occupe de la vérification
        return view('admin.admins.create');
    }

    /**
     * Créer un nouvel admin avec invitation
     */
    public function store(Request $request)
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $request->validate([
            'email' => 'required|email|unique:admins,email',
            'role' => 'required|in:authoritaire',
        ], [
            'email.unique' => 'Cet email est déjà utilisé par un autre administrateur.',
            'role.required' => 'Le rôle est requis.',
            'role.in' => 'Le rôle doit être "authoritaire".',
        ]);

        // Forcer le rôle à "authoritaire" pour tous les nouveaux admins
        $request->merge(['role' => 'authoritaire']);

        try {
            // Générer un token d'invitation sécurisé (SHA256)
            $token = hash('sha256', Str::random(60));

            // Créer l'invitation dans la collection admin_invitations
            $invitation = AdminInvitation::create([
                'email' => $request->email,
                'role' => $request->role,
                'token' => $token,
                'expires_at' => now()->addHours(24),
                'used' => false,
            ]);

            // Enregistrer l'action
            $this->auditLogService->log('admin_created');

            // Générer le lien d'invitation
            $invitationLink = route('admin.setup', ['token' => $token]);

            // TODO: Envoyer l'email d'invitation
            // Mail::to($request->email)->send(new AdminInvitationMail($invitationLink));

            Log::info('Invitation admin créée', [
                'email' => $request->email,
                'role' => $request->role,
                'invitation_link' => $invitationLink,
            ]);

            return redirect()->route('admin.admins.index')
                ->with('success', 'Invitation créée avec succès. Lien: '.$invitationLink);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de l\'admin', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return back()->with('error', 'Erreur lors de la création de l\'administrateur: '.$e->getMessage())
                ->withInput();
        }
    }

    /**
     * Afficher le formulaire de configuration du mot de passe (via invitation)
     */
    public function showSetupForm(Request $request)
    {
        $token = $request->query('token');

        if (! $token) {
            return redirect('/admin/login')
                ->with('error', 'Token d\'invitation manquant.');
        }

        // Trouver l'invitation
        $invitation = AdminInvitation::where('token', $token)->first();

        if (! $invitation || ! $invitation->isValid()) {
            return redirect('/admin/login')
                ->with('error', 'Lien d\'invitation invalide ou expiré.');
        }

        return view('admin.setup', ['invitation' => $invitation, 'token' => $token]);
    }

    /**
     * Traiter la configuration du mot de passe
     */
    public function setupPassword(Request $request)
    {
        $token = $request->input('token');

        if (! $token) {
            return redirect()->route('admin.login')
                ->with('error', 'Token d\'invitation manquant.');
        }

        $request->validate([
            'password' => [
                'required',
                'confirmed',
                'min:12',
                'regex:/[A-Z]/',
                'regex:/[a-z]/',
                'regex:/[0-9]/',
                'regex:/[@$!%*#?&]/',
            ],
        ], [
            'password.required' => 'Le mot de passe est requis.',
            'password.confirmed' => 'Les mots de passe ne correspondent pas.',
            'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
            'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
        ]);

        // Trouver l'invitation
        $invitation = AdminInvitation::where('token', $token)->first();

        if (! $invitation || ! $invitation->isValid()) {
            return redirect('/admin/login')
                ->with('error', 'Lien d\'invitation invalide ou expiré.');
        }

        // Vérifier si l'admin existe déjà (dans AdminAutoritaire car tous les admins créés sont autoritaires)
        $admin = AdminAutoritaire::where('email', $invitation->email)->first();

        if (! $admin) {
            // Créer l'admin autoritaire
            $admin = AdminAutoritaire::create([
                'first_name' => '',
                'last_name' => '',
                'email' => $invitation->email,
                'password' => Hash::make($request->password),
                'is_active' => true,
                'email_verified_at' => now(), // Vérification automatique lors de la création
            ]);
        } else {
            // Mettre à jour le mot de passe
            $admin->password = Hash::make($request->password);
            $admin->save();
        }

        // Marquer l'invitation comme utilisée
        $invitation->markAsUsed();

        $this->auditLogService->log('admin_password_set');

        return redirect('/admin/login')
            ->with('success', 'Mot de passe défini avec succès. Vous pouvez maintenant vous connecter.');
    }

    /**
     * Activer/Désactiver un admin
     */
    public function toggleActive(Request $request, $id)
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $admin = Admin::findOrFail($id);

        // Ne pas permettre de désactiver soi-même
        if ($admin->_id === Auth::guard('admin')->id()) {
            return back()->with('error', 'Vous ne pouvez pas désactiver votre propre compte.');
        }

        $admin->is_active = ! $admin->is_active;
        $admin->save();

        $this->auditLogService->log('admin_toggled');

        return back()->with('success', 'Statut de l\'administrateur mis à jour.');
    }

    /**
     * Réinitialiser le mot de passe d'un admin
     */
    public function resetPassword(Request $request, $id)
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $admin = Admin::findOrFail($id);

        // Si un mot de passe est saisi (modale), l'utiliser.
        // Sinon, conserver le comportement historique (mot de passe temporaire).
        if ($request->filled('password')) {
            $request->validate([
                'password' => [
                    'required',
                    'confirmed',
                    'min:12',
                    'regex:/[A-Z]/',
                    'regex:/[a-z]/',
                    'regex:/[0-9]/',
                    'regex:/[@$!%*#?&]/',
                ],
            ], [
                'password.required' => 'Le mot de passe est requis.',
                'password.confirmed' => 'Les mots de passe ne correspondent pas.',
                'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
                'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
            ]);

            $admin->password = Hash::make($request->password);
            $successMessage = 'Mot de passe modifié avec succès.';
        } else {
            $tempPassword = Str::random(16);
            $admin->password = Hash::make($tempPassword);
            $successMessage = 'Mot de passe réinitialisé avec succès. Nouveau mot de passe temporaire: '.$tempPassword.' (Notez-le, il ne sera plus affiché)';
        }

        $admin->save();

        $this->auditLogService->log('admin_password_reset', [
            'admin_id' => $admin->_id,
            'admin_email' => $admin->email,
        ]);

        Log::info('Mot de passe admin réinitialisé', [
            'admin_id' => $admin->_id,
            'admin_email' => $admin->email,
        ]);

        return redirect()->route('admin.admins.index')
            ->with('success', $successMessage);
    }

    /**
     * Supprimer un admin
     */
    public function destroy(Request $request, $id)
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $admin = Admin::findOrFail($id);

        // Ne pas permettre de supprimer soi-même
        if ($admin->_id === Auth::guard('admin')->id()) {
            return back()->with('error', 'Vous ne pouvez pas supprimer votre propre compte.');
        }

        $admin->delete();

        $this->auditLogService->log('admin_deleted');

        return redirect()->route('admin.admins.index')
            ->with('success', 'Administrateur supprimé avec succès.');
    }

    /**
     * Interface Admin Technique avec toutes les données dynamiques
     */
    public function interfaceAdminTech()
    {
        // Récupérer l'admin technique depuis différentes sources
        $user = null;

        // 1. Vérifier si c'est un admin technique authentifié via User (collection users_admin_tech)
        if (session('authenticated_admin_technical') && session('admin_type') === 'technical') {
            $adminId = session('admin_id');
            if ($adminId) {
                $user = User::find($adminId);
            }
        }

        // 2. Vérifier si c'est un admin technique authentifié via guard (collection admins)
        if (! $user && Auth::guard('admin')->check()) {
            $admin = Auth::guard('admin')->user();
            if ($admin) {
                // Vérifier si c'est un admin technique (soit via méthode isTechnical, soit via rôle)
                $isTechnical = false;
                if (method_exists($admin, 'isTechnical')) {
                    $isTechnical = $admin->isTechnical();
                } elseif (isset($admin->role) && ($admin->role === 'technical' || $admin->role === Admin::ROLE_TECHNICAL)) {
                    $isTechnical = true;
                }

                if ($isTechnical) {
                    $user = $admin;
                }
            }
        }

        // 3. Fallback sur Auth::user() pour les utilisateurs classiques
        if (! $user) {
            $user = Auth::user();
        }

        // Si toujours pas d'utilisateur, rediriger vers login
        if (! $user) {
            return redirect()->route('login')->with('error', 'Vous devez être connecté pour accéder à cette page.');
        }

        // Statistiques et listes (échantillon récent, limites basses — évite timeout MongoDB 60s)
        $listLimit = 120;

        try {
            $admins = AdminAutoritaire::query()
                ->orderBy('_id', 'desc')
                ->limit($listLimit)
                ->get();
        } catch (\Throwable $e) {
            Log::warning('Admin tech: liste admins — '.$e->getMessage());
            $admins = collect();
        }

        try {
            $clients = Citizen::query()
                ->orderBy('_id', 'desc')
                ->limit($listLimit)
                ->get();
        } catch (\Throwable $e) {
            Log::warning('Admin tech: liste citoyens — '.$e->getMessage());
            $clients = collect();
        }

        $adminAutoritaireStats = $this->booleanActiveStatsFromCollection($admins, 'is_active');
        $citizenStats = $this->emailVerificationStatsFromCollection($clients);

        $adminsActive = $adminAutoritaireStats['active'];
        $adminsInactive = $adminAutoritaireStats['inactive'];
        $adminsTotal = $adminAutoritaireStats['total'];

        $clientsTotal = $citizenStats['total'];
        $clientsActive = $citizenStats['active'];
        $clientsPending = $citizenStats['pending'];

        // Intervenants (collections MongoDB `intervenants` / `intervenant`)
        $intervenantsPayload = $this->loadIntervenantsForAdminTech();

        // Informations de sauvegarde et stockage (sans scan disque récursif)
        $lastBackup = $this->getLastBackupTime();
        $storageInfo = $this->getStorageInfo();

        // API Services (vous pouvez personnaliser cela selon vos besoins)
        $apiServices = $this->getApiServicesStatus();

        $systemPerformance = $this->calculateSystemPerformance($clientsTotal, $clientsActive, $storageInfo);

        // Badges pour la sidebar
        $usersBadge = $clientsTotal;
        $alertsBadge = 0;

        return view('interface_admin_tech', array_merge([
            'user' => $user,
            'stats' => [
                'total_citizens' => $clientsTotal,
                'active_citizens' => $clientsActive,
                'citizens_this_month' => $citizenStats['this_month'],
                'authoritaire_admins' => $adminsTotal,
                'active_autoritaire_admins' => $adminsActive,
                'system_performance' => $systemPerformance,
            ],
            'admins' => $admins,
            'admins_stats' => [
                'total' => $adminsTotal,
                'active' => $adminsActive,
                'inactive' => $adminsInactive,
            ],
            'clients' => $clients,
            'clients_stats' => [
                'total' => $clientsTotal,
                'active' => $clientsActive,
                'pending' => $clientsPending,
            ],
            'storage' => $storageInfo,
            'last_backup' => $lastBackup,
            'api_services' => $apiServices,
            'users_badge' => $usersBadge,
            'alerts_badge' => $alertsBadge,
            'list_limit' => $listLimit,
        ], $intervenantsPayload));
    }

    /**
     * Charge les intervenants (MongoDB) et les normalise pour le tableau type « Comptes citoyens ».
     */
    private function loadIntervenantsForAdminTech(): array
    {
        $maxTotal = 120;
        $perCollection = 80;

        $merged = collect();
        $sources = [];

        foreach (['intervenants', 'intervenant'] as $collectionName) {
            if ($merged->count() >= $maxTotal) {
                break;
            }
            try {
                $take = min($perCollection, $maxTotal - $merged->count());
                $batch = DB::connection('mongodb')->table($collectionName)
                    ->orderBy('_id', 'desc')
                    ->limit($take)
                    ->get();
                foreach ($batch as $doc) {
                    $row = $this->mongoDocToFlatArray($doc);
                    $row['_collection'] = $collectionName;
                    $merged->push($this->normalizeIntervenantRowForTechTable($row));
                    if ($merged->count() >= $maxTotal) {
                        break 2;
                    }
                }
                if ($batch->count() > 0) {
                    $sources[] = $collectionName;
                }
            } catch (\Throwable $e) {
                Log::debug('Admin tech intervenants: '.$collectionName.' — '.$e->getMessage());
            }
        }

        return [
            'intervenants' => $merged,
            'intervenants_count_shown' => $merged->count(),
            'intervenants_sources' => $sources,
            'intervenants_max' => $maxTotal,
        ];
    }

    /**
     * @return array{nom: string, prenom: string, email: string, statut_ok: bool, statut_label: string, inscription: string, id: string, collection: string, raw: array}
     */
    private function normalizeIntervenantRowForTechTable(array $row): array
    {
        $nom = trim((string) (data_get($row, 'last_name')
            ?: data_get($row, 'nom')
            ?: data_get($row, 'equipe')
            ?: data_get($row, 'titre')
            ?: data_get($row, 'libelle')
            ?: ''));
        if ($nom === '') {
            $nom = 'N/A';
        }

        $prenom = trim((string) (data_get($row, 'first_name')
            ?: data_get($row, 'prenom')
            ?: data_get($row, 'contact')
            ?: ''));

        $email = trim((string) (data_get($row, 'email') ?: ''));
        if ($email === '') {
            $email = 'N/A';
        }

        $emailVerified = data_get($row, 'email_verified_at') !== null && data_get($row, 'email_verified_at') !== '';
        $actifChantier = $this->intervenantStatutEstActif($row);

        if ($emailVerified) {
            $statutOk = true;
            $statutLabel = 'VÉRIFIÉ';
        } elseif ($actifChantier) {
            $statutOk = true;
            $statutLabel = 'ACTIF';
        } else {
            $statutOk = false;
            $statutLabel = 'EN ATTENTE';
        }

        $created = data_get($row, 'created_at')
            ?? data_get($row, 'createdAt')
            ?? data_get($row, 'date_inscription')
            ?? data_get($row, 'date')
            ?? data_get($row, 'date_debut');
        $inscription = $this->formatIntervenantDateDisplay($created) ?? 'N/A';

        $id = (string) (data_get($row, '_id') ?? '');
        $collection = (string) (data_get($row, '_collection') ?? '');

        $raw = $row;
        unset($raw['__search']);

        return [
            'nom' => $nom,
            'prenom' => $prenom !== '' ? $prenom : '—',
            'email' => $email,
            'statut_ok' => $statutOk,
            'statut_label' => $statutLabel,
            'inscription' => $inscription,
            'id' => $id,
            'collection' => $collection,
            'raw' => $raw,
        ];
    }

    private function intervenantStatutEstActif(array $row): bool
    {
        if (! empty($row['is_active']) || ! empty($row['actif'])) {
            return true;
        }
        $s = strtolower((string) (data_get($row, 'statut') ?? data_get($row, 'status') ?? data_get($row, 'etat') ?? ''));

        foreach (['actif', 'active', 'validé', 'valide', 'terminé', 'termine', 'en cours', 'operationnel', 'opérationnel', 'chantier'] as $kw) {
            if ($kw !== '' && str_contains($s, $kw)) {
                return true;
            }
        }

        return false;
    }

    private function formatIntervenantDateDisplay(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        try {
            if (is_string($value)) {
                return \Carbon\Carbon::parse($value)->format('d/m/Y');
            }
            if (is_object($value) && method_exists($value, 'format')) {
                return $value->format('d/m/Y');
            }
            if (is_numeric($value)) {
                return \Carbon\Carbon::createFromTimestamp((int) $value)->format('d/m/Y');
            }
        } catch (\Throwable $e) {
            return null;
        }

        return null;
    }

    /**
     * @param  mixed  $doc  stdClass|array|BSONDocument
     */
    private function mongoDocToFlatArray(mixed $doc): array
    {
        $arr = json_decode(json_encode($doc), true);
        if (! is_array($arr)) {
            return [];
        }
        if (isset($arr['_id']) && is_array($arr['_id']) && isset($arr['_id']['$oid'])) {
            $arr['_id'] = (string) $arr['_id']['$oid'];
        }

        return $arr;
    }

    /**
     * Page de profil utilisateur
     */
    public function profile()
    {
        $user = $this->resolveCurrentProfileUser();

        // Si toujours pas d'utilisateur, rediriger vers login
        if (! $user) {
            return redirect()->route('login')->with('error', 'Vous devez être connecté pour accéder à cette page.');
        }

        return view('profile', [
            'user' => $user,
        ]);
    }

    /**
     * Page profil « Administrateur Autoritaire » (données persistées en MongoDB).
     */
    public function profilAdminAutoritaire()
    {
        $user = null;

        if (session('autoritaire_authenticated') && session('admin_type') === 'autoritaire') {
            $user = $this->findAdminAutoritaireForCurrentSession();
        }

        if (! $user && Auth::guard('admin')->check()) {
            $user = Auth::guard('admin')->user();
        }

        if (! $user && Auth::check()) {
            $user = Auth::user();
        }

        if (! $user) {
            return redirect()->route('login')
                ->with('error', 'Compte administrateur introuvable. Connectez-vous avec un compte enregistré pour conserver une photo de profil.');
        }

        return view('profil_admin_Autoritaire', ['user' => $user]);
    }

    /**
     * Obtenir le temps de la dernière sauvegarde
     */
    private function getLastBackupTime()
    {
        // Vérifier plusieurs emplacements possibles pour les sauvegardes
        $backupPaths = [
            storage_path('app/backups'),
            storage_path('backups'),
            database_path('backups'),
            base_path('backups'),
        ];

        $latestBackup = null;
        $latestTime = 0;

        foreach ($backupPaths as $backupPath) {
            if (! is_dir($backupPath)) {
                continue;
            }

            // Chercher différents types de fichiers de sauvegarde
            $patterns = ['*.sql', '*.sql.gz', '*.dump', '*.backup', '*.bak'];
            foreach ($patterns as $pattern) {
                $files = glob($backupPath.'/'.$pattern);
                foreach ($files as $file) {
                    if (is_file($file)) {
                        $fileTime = filemtime($file);
                        if ($fileTime > $latestTime) {
                            $latestTime = $fileTime;
                            $latestBackup = $file;
                        }
                    }
                }
            }
        }

        if ($latestBackup && $latestTime > 0) {
            return \Carbon\Carbon::createFromTimestamp($latestTime);
        }

        // Si aucune sauvegarde trouvée, retourner null pour afficher "N/A"
        return null;
    }

    /**
     * Obtenir les informations de stockage
     */
    private function getStorageInfo()
    {
        // Calculer l'espace disque du répertoire de stockage
        $storagePath = storage_path();
        $totalSpace = disk_total_space($storagePath);
        $freeSpace = disk_free_space($storagePath);

        if ($totalSpace === false || $freeSpace === false) {
            // Si on ne peut pas obtenir les infos, essayer avec le répertoire racine
            $storagePath = base_path();
            $totalSpace = disk_total_space($storagePath);
            $freeSpace = disk_free_space($storagePath);
        }

        if ($totalSpace === false || $freeSpace === false) {
            // Valeurs par défaut si on ne peut pas obtenir les infos
            return [
                'total' => 0,
                'used' => 0,
                'free' => 0,
                'percent' => 0,
                'used_gb' => 0,
                'total_gb' => 0,
            ];
        }

        $usedSpace = $totalSpace - $freeSpace;
        $usedPercent = ($totalSpace > 0) ? ($usedSpace / $totalSpace) * 100 : 0;

        // Ne pas parcourir récursivement storage/ (très lent, provoque des timeouts PHP).
        $usedForDisplay = $usedSpace;

        return [
            'total' => $totalSpace,
            'used' => $usedForDisplay,
            'free' => $freeSpace,
            'percent' => round($usedPercent, 1),
            'used_gb' => round($usedForDisplay / (1024 * 1024 * 1024), 2),
            'total_gb' => round($totalSpace / (1024 * 1024 * 1024), 2),
            'free_gb' => round($freeSpace / (1024 * 1024 * 1024), 2),
        ];
    }

    /**
     * Calculer la taille réelle d'un répertoire
     */
    private function getDirectorySize($directory)
    {
        $size = 0;

        if (! is_dir($directory)) {
            return 0;
        }

        try {
            $iterator = new \RecursiveIteratorIterator(
                new \RecursiveDirectoryIterator($directory, \FilesystemIterator::SKIP_DOTS),
                \RecursiveIteratorIterator::SELF_FIRST
            );

            foreach ($iterator as $file) {
                if ($file->isFile()) {
                    $size += $file->getSize();
                }
            }
        } catch (\Exception $e) {
            // En cas d'erreur, retourner 0
            return 0;
        }

        return $size;
    }

    /**
     * Obtenir le statut des services API
     */
    private function getApiServicesStatus()
    {
        // Vous pouvez personnaliser cela selon vos besoins réels
        // Pour l'instant, on simule des statuts
        return [
            [
                'name' => 'Google Earth Engine',
                'status' => 'connected',
                'color' => 'green',
            ],
            [
                'name' => 'Google Maps API',
                'status' => 'connected',
                'color' => 'green',
            ],
            [
                'name' => 'API Météo',
                'status' => 'warning',
                'color' => 'yellow',
            ],
        ];
    }

    /**
     * Calculer la performance du système
     */
    private function calculateSystemPerformance(?int $totalClients = null, ?int $activeClients = null, ?array $storageInfo = null)
    {
        // Calcul basique basé sur plusieurs facteurs
        $score = 100;

        // Réduire le score si le stockage est presque plein
        $storageInfo = $storageInfo ?? $this->getStorageInfo();
        if ($storageInfo['percent'] > 90) {
            $score -= 20;
        } elseif ($storageInfo['percent'] > 75) {
            $score -= 10;
        }

        // Réduire le score si beaucoup d'utilisateurs inactifs
        if ($totalClients !== null && $activeClients !== null && $totalClients > 0) {
            $activeRatio = ($activeClients / $totalClients) * 100;
            if ($activeRatio < 50) {
                $score -= 5;
            }
        }

        return max(0, min(100, $score));
    }

    /**
     * Compte les documents créés dans le mois courant sans whereMonth/whereYear
     * (sur MongoDB, whereMonth peut déclencher une aggregation coûteuse).
     */
    private function countDocumentsCreatedThisMonth(string $modelClass): int
    {
        try {
            $start = now()->startOfMonth();
            $end = now()->endOfMonth();

            return $modelClass::where('created_at', '>=', $start)
                ->where('created_at', '<=', $end)
                ->count();
        } catch (\Throwable $e) {
            Log::warning('Impossible de compter les créations du mois', [
                'model' => $modelClass,
                'error' => $e->getMessage(),
            ]);

            return 0;
        }
    }

    /**
     * Stats booléennes à partir d'une collection déjà chargée (évite un second scan MongoDB).
     *
     * @param  \Illuminate\Support\Collection<int, mixed>  $items
     * @return array{total:int, active:int, inactive:int}
     */
    private function booleanActiveStatsFromCollection($items, string $field = 'is_active'): array
    {
        $total = $items->count();
        $active = 0;

        foreach ($items as $doc) {
            $arr = is_array($doc) ? $doc : (method_exists($doc, 'toArray') ? $doc->toArray() : (array) $doc);
            if ((bool) data_get($arr, $field, false)) {
                $active++;
            }
        }

        return [
            'total' => $total,
            'active' => $active,
            'inactive' => max(0, $total - $active),
        ];
    }

    /**
     * Stats email_verified_at à partir d'une collection déjà chargée.
     *
     * @param  \Illuminate\Support\Collection<int, mixed>  $items
     * @return array{total:int, active:int, pending:int, this_month:int}
     */
    private function emailVerificationStatsFromCollection($items): array
    {
        $start = now()->startOfMonth();
        $end = now()->endOfMonth();
        $total = $items->count();
        $active = 0;
        $pending = 0;
        $thisMonth = 0;

        foreach ($items as $doc) {
            $arr = is_array($doc) ? $doc : (method_exists($doc, 'toArray') ? $doc->toArray() : (array) $doc);

            $verified = data_get($arr, 'email_verified_at') !== null && data_get($arr, 'email_verified_at') !== '';
            if ($verified) {
                $active++;
            } else {
                $pending++;
            }

            $created = data_get($arr, 'created_at') ?? data_get($arr, 'createdAt') ?? null;
            if ($created === null || $created === '') {
                continue;
            }

            try {
                $dt = $created instanceof \MongoDB\BSON\UTCDateTime
                    ? \Carbon\Carbon::instance($created->toDateTime())
                    : \Carbon\Carbon::parse((string) $created);
                if ($dt->between($start, $end)) {
                    $thisMonth++;
                }
            } catch (\Throwable $e) {
                // ignorer dates invalides
            }
        }

        return [
            'total' => $total,
            'active' => $active,
            'pending' => $pending,
            'this_month' => $thisMonth,
        ];
    }

    /**
     * Lit un échantillon récent de documents sans scans complets.
     *
     * @return \Illuminate\Support\Collection<int, mixed>
     */
    private function sampleRecentDocuments(string $modelClass, int $limit = 400)
    {
        try {
            return $modelClass::query()
                ->orderBy('_id', 'desc')
                ->limit($limit)
                ->get();
        } catch (\Throwable $e) {
            try {
                return $modelClass::query()
                    ->orderBy('created_at', 'desc')
                    ->limit($limit)
                    ->get();
            } catch (\Throwable $e2) {
                try {
                    return $modelClass::query()
                        ->limit($limit)
                        ->get();
                } catch (\Throwable $e3) {
                    Log::warning('Impossible de charger les documents récents', [
                        'model' => $modelClass,
                        'error' => $e3->getMessage(),
                    ]);

                    return collect();
                }
            }
        }
    }

    /**
     * Stats basées sur email_verified_at (actif/pending + créations du mois).
     *
     * @return array{total:int, active:int, pending:int, this_month:int}
     */
    private function sampledEmailVerificationStats(string $modelClass, int $limit = 2000): array
    {
        $docs = $this->sampleRecentDocuments($modelClass, $limit);
        $start = now()->startOfMonth();
        $end = now()->endOfMonth();

        $total = $docs->count();
        $active = 0;
        $pending = 0;
        $thisMonth = 0;

        foreach ($docs as $doc) {
            $arr = is_array($doc) ? $doc : (array) $doc;

            $verified = data_get($arr, 'email_verified_at') !== null && data_get($arr, 'email_verified_at') !== '';
            if ($verified) {
                $active++;
            } else {
                $pending++;
            }

            $created = data_get($arr, 'created_at') ?? data_get($arr, 'createdAt') ?? null;
            if ($created === null || $created === '') {
                continue;
            }

            try {
                $dt = $created instanceof \MongoDB\BSON\UTCDateTime
                    ? \Carbon\Carbon::instance($created->toDateTime())
                    : \Carbon\Carbon::parse((string) $created);
                if ($dt->between($start, $end)) {
                    $thisMonth++;
                }
            } catch (\Throwable $e) {
                // ignorer dates invalides
            }
        }

        return [
            'total' => $total,
            'active' => $active,
            'pending' => $pending,
            'this_month' => $thisMonth,
        ];
    }

    /**
     * Stats basées sur un champ booléen (ex: is_active).
     *
     * @return array{total:int, active:int, inactive:int}
     */
    private function sampledBooleanActiveStats(string $modelClass, string $field = 'is_active', int $limit = 2000): array
    {
        $docs = $this->sampleRecentDocuments($modelClass, $limit);
        $total = $docs->count();
        $active = 0;

        foreach ($docs as $doc) {
            $arr = is_array($doc) ? $doc : (array) $doc;
            if ((bool) data_get($arr, $field, false)) {
                $active++;
            }
        }

        return [
            'total' => $total,
            'active' => $active,
            'inactive' => max(0, $total - $active),
        ];
    }

    /**
     * Forcer une sauvegarde de la base de données
     */
    public function forceBackup()
    {
        try {
            $backupPath = storage_path('app/backups');

            // Créer le répertoire s'il n'existe pas
            if (! is_dir($backupPath)) {
                mkdir($backupPath, 0755, true);
            }

            $timestamp = now()->format('Y-m-d_H-i-s');
            $backupFile = $backupPath.'/backup_'.$timestamp.'.json';

            // Récupérer toutes les collections de MongoDB
            $database = config('database.connections.mongodb.database', 'trig_essalama');
            $collections = $this->backupMongoCollections($database, $backupFile);

            if ($collections > 0) {
                $this->auditLogService->log('backup_created', [
                    'file' => basename($backupFile),
                    'collections' => $collections,
                ]);

                return redirect()->route('interface_admin_tech')
                    ->with('success', "Sauvegarde créée avec succès ! ({$collections} collections sauvegardées)");
            } else {
                return redirect()->route('interface_admin_tech')
                    ->with('error', 'Aucune collection trouvée à sauvegarder.');
            }

        } catch (\Exception $e) {
            \Log::error('Erreur lors de la sauvegarde', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la création de la sauvegarde: '.$e->getMessage());
        }
    }

    /**
     * Sauvegarder les collections MongoDB
     */
    private function backupMongoCollections($database, $backupFile)
    {
        // Utiliser directement la méthode Eloquent qui est plus fiable
        return $this->backupMongoCollectionsEloquent($database, $backupFile);
    }

    /**
     * Sauvegarder les collections MongoDB via Eloquent (méthode alternative)
     */
    private function backupMongoCollectionsEloquent($database, $backupFile)
    {
        $collections = [];
        $backupData = [
            'database' => $database,
            'timestamp' => now()->toIso8601String(),
            'collections' => [],
        ];

        // Sauvegarder les collections connues
        $knownCollections = [
            'users_admin_tech' => User::class,           // Comptes techniques
            'users_citoyens' => Citizen::class,          // Comptes citoyens
            'admins_autoritaires' => AdminAutoritaire::class, // Admins autoritaires
        ];

        foreach ($knownCollections as $collectionName => $modelClass) {
            try {
                $documents = $modelClass::all()->toArray();

                $backupData['collections'][$collectionName] = [
                    'count' => count($documents),
                    'documents' => $documents,
                ];

                $collections[] = $collectionName;
            } catch (\Exception $e) {
                \Log::warning("Impossible de sauvegarder la collection {$collectionName}", [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Sauvegarder dans un fichier JSON
        file_put_contents($backupFile, json_encode($backupData, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        return count($collections);
    }

    /**
     * API: Récupérer les statistiques de statut en temps réel
     */
    public function getStatusStats()
    {
        try {
            // Statistiques des administrateurs
            $adminsTotal = AdminAutoritaire::count();
            $adminsActive = AdminAutoritaire::where('is_active', true)->count();
            $adminsInactive = AdminAutoritaire::where('is_active', false)->count();

            // Statistiques des citoyens
            $citizensTotal = Citizen::count();
            $citizensActive = Citizen::whereNotNull('email_verified_at')->count();
            $citizensPending = Citizen::whereNull('email_verified_at')->count();

            return response()->json([
                'success' => true,
                'admins' => [
                    'total' => $adminsTotal,
                    'active' => $adminsActive,
                    'inactive' => $adminsInactive,
                ],
                'citizens' => [
                    'total' => $citizensTotal,
                    'active' => $citizensActive,
                    'pending' => $citizensPending,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function zones()
    {
        return DB::connection('mongodb')
            ->collection('zones_risque')
            ->get();
    }

    /**
     * Créer un nouvel administrateur autoritaire
     */
    public function storeAutoritaire(Request $request)
    {
        // Vérifier si l'email existe déjà dans la collection MongoDB
        $existingAdmin = AdminAutoritaire::where('email', $request->email)->first();

        $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => [
                'required',
                'email',
                function ($attribute, $value, $fail) use ($existingAdmin) {
                    if ($existingAdmin) {
                        $fail('Cet email est déjà utilisé.');
                    }
                },
            ],
            'phone' => 'required|string|max:50',
            'city' => 'required|string|max:120',
            'country' => 'required|string|max:120',
            'password' => [
                'required',
                'confirmed',
                'min:12',
                'regex:/[A-Z]/',
                'regex:/[a-z]/',
                'regex:/[0-9]/',
                'regex:/[@$!%*#?&]/',
            ],
            'creation_code' => 'required|string|size:8',
        ], [
            'first_name.required' => 'Le prénom est requis.',
            'last_name.required' => 'Le nom est requis.',
            'phone.required' => 'Le téléphone est requis.',
            'city.required' => 'La ville est requise.',
            'country.required' => 'Le pays est requis.',
            'email.required' => 'L\'email est requis.',
            'email.email' => 'L\'email doit être valide.',
            'email.unique' => 'Cet email est déjà utilisé.',
            'password.required' => 'Le mot de passe est requis.',
            'password.confirmed' => 'Les mots de passe ne correspondent pas.',
            'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
            'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
            'creation_code.required' => 'Le code de sécurité est requis.',
            'creation_code.size' => 'Le code de sécurité doit contenir exactement 8 caractères.',
        ]);

        // Vérification du code de sécurité
        $securityCode = strtoupper($request->creation_code);
        $universalCode = 'D8HWZA5M';
        $code = null;

        if ($securityCode !== $universalCode) {
            $code = RegistrationCode::where('code', $securityCode)->first();
            if (! $code || ! $code->isValid()) {
                return back()
                    ->with('error', 'Code de sécurité invalide ou expiré.')
                    ->withInput($request->except('password', 'password_confirmation', 'creation_code'));
            }
        }

        try {
            $admin = AdminAutoritaire::create([
                'first_name' => $request->first_name,
                'last_name' => $request->last_name,
                'email' => $request->email,
                'phone' => $request->phone,
                'city' => $request->city,
                'country' => $request->country,
                'password' => Hash::make($request->password),
                'is_active' => true,
                'email_verified_at' => now(), // Vérification automatique lors de la création
            ]);

            // Marquer le code comme utilisé si ce n'est pas le code universel
            if ($code) {
                $code->markAsUsed($request->email);
            }

            $this->auditLogService->log('admin_autoritaire_created', [
                'admin_id' => $admin->_id,
                'email' => $admin->email,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Administrateur autoritaire créé avec succès !');

        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de l\'admin autoritaire', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return back()
                ->withInput()
                ->with('error', 'Erreur lors de la création de l\'administrateur: '.$e->getMessage());
        }
    }

    /**
     * Activer/Désactiver un administrateur autoritaire
     */
    public function toggleAdminStatus($id)
    {
        try {
            $admin = AdminAutoritaire::findOrFail($id);

            $admin->is_active = ! $admin->is_active;
            $admin->save();

            $this->auditLogService->log('admin_autoritaire_toggled', [
                'admin_id' => $admin->_id,
                'status' => $admin->is_active ? 'activated' : 'deactivated',
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Statut de l\'administrateur mis à jour avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la modification du statut de l\'admin', [
                'error' => $e->getMessage(),
                'admin_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la modification du statut: '.$e->getMessage());
        }
    }

    /**
     * Supprimer un administrateur autoritaire
     */
    public function deleteAdmin($id)
    {
        try {
            $admin = AdminAutoritaire::findOrFail($id);
            $adminEmail = $admin->email;

            $admin->delete();

            $this->auditLogService->log('admin_autoritaire_deleted', [
                'admin_email' => $adminEmail,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Administrateur supprimé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l\'admin', [
                'error' => $e->getMessage(),
                'admin_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la suppression: '.$e->getMessage());
        }
    }

    /**
     * Réinitialiser le mot de passe d'un administrateur autoritaire
     */
    public function resetAdminPassword(Request $request, $id)
    {
        try {
            $request->validate([
                'password' => [
                    'required',
                    'confirmed',
                    'min:12',
                    'regex:/[A-Z]/',
                    'regex:/[a-z]/',
                    'regex:/[0-9]/',
                    'regex:/[@$!%*#?&]/',
                ],
            ], [
                'password.required' => 'Le mot de passe est requis.',
                'password.confirmed' => 'Les mots de passe ne correspondent pas.',
                'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
                'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
            ]);

            $admin = AdminAutoritaire::findOrFail($id);
            $admin->password = Hash::make($request->password);
            $admin->save();

            $this->auditLogService->log('admin_autoritaire_password_reset', [
                'admin_id' => $admin->_id,
                'admin_email' => $admin->email,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Mot de passe réinitialisé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la réinitialisation du mot de passe', [
                'error' => $e->getMessage(),
                'admin_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la réinitialisation: '.$e->getMessage());
        }
    }

    /**
     * Changer le mot de passe de l'utilisateur connecté
     */
    public function changeUserPassword(Request $request)
    {
        try {
            $request->validate([
                'password' => [
                    'required',
                    'confirmed',
                    'min:12',
                    'regex:/[A-Z]/',
                    'regex:/[a-z]/',
                    'regex:/[0-9]/',
                    'regex:/[@$!%*#?&]/',
                ],
            ], [
                'password.required' => 'Le mot de passe est requis.',
                'password.confirmed' => 'Les mots de passe ne correspondent pas.',
                'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
                'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
            ]);

            $user = $this->resolveCurrentProfileUser();
            if (! $user) {
                return redirect()->route('interface_admin_tech')
                    ->with('error', 'Utilisateur non authentifié.');
            }

            $user->password = Hash::make($request->password);
            $user->save();

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Votre mot de passe a été changé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors du changement de mot de passe', [
                'error' => $e->getMessage(),
                'user_id' => Auth::id(),
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors du changement de mot de passe: '.$e->getMessage());
        }
    }

    /**
     * Mettre à jour les informations du compte connecté.
     */
    public function updateProfile(Request $request)
    {
        $profileRoute = $this->currentEditableProfileRoute();

        try {
            $user = $this->resolveCurrentProfileUser();
            if (! $user) {
                return redirect()->route($profileRoute)
                    ->with('error', 'Utilisateur non authentifié.');
            }

            $validated = $request->validate([
                'name' => 'required|string|min:2|max:120',
                'email' => 'required|email|max:190',
                'phone' => 'nullable|string|max:40',
                'region' => 'nullable|string|max:120',
                'avatar_file' => 'nullable|image|mimes:jpg,jpeg,png,webp,gif|max:4096',
            ], [
                'name.required' => 'Le nom complet est requis.',
                'email.required' => 'L\'email est requis.',
                'email.email' => 'Veuillez saisir une adresse email valide.',
                'avatar_file.image' => 'Le fichier sélectionné doit être une image.',
                'avatar_file.mimes' => 'Formats acceptés: jpg, jpeg, png, webp, gif.',
                'avatar_file.max' => 'La taille de la photo ne doit pas dépasser 4 Mo.',
            ]);

            $emailExists = $user::where('email', $validated['email'])
                ->where('_id', '!=', $user->getKey())
                ->exists();

            if ($emailExists) {
                return redirect()->route($profileRoute)
                    ->withInput()
                    ->withErrors(['email' => 'Cet email est déjà utilisé par un autre compte.']);
            }

            $user->email = $validated['email'];
            $user->phone = $validated['phone'] ?? null;
            $user->region = $validated['region'] ?? null;

            if ($request->hasFile('avatar_file')) {
                $this->deleteStoredProfileAvatarIfOwned($user->avatar_url ?? null);
                $path = $request->file('avatar_file')->store('profile-avatars', 'public');
                $user->avatar_url = Storage::url($path);
            }

            // Les champs de nom diffèrent selon le modèle.
            $fullName = trim($validated['name']);
            if (in_array(get_class($user), [Admin::class, AdminAutoritaire::class], true)) {
                [$firstName, $lastName] = $this->splitName($fullName);
                $user->first_name = $firstName;
                $user->last_name = $lastName;
            } else {
                $user->name = $fullName;
                [$firstName, $lastName] = $this->splitName($fullName);
                if (array_key_exists('first_name', $user->getAttributes())) {
                    $user->first_name = $firstName;
                }
                if (array_key_exists('last_name', $user->getAttributes())) {
                    $user->last_name = $lastName;
                }
            }

            $user->save();

            return redirect()->route($profileRoute)
                ->with('success', 'Vos informations de compte ont été mises à jour avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour du profil', [
                'error' => $e->getMessage(),
                'user_id' => optional($this->resolveCurrentProfileUser())->getKey(),
            ]);

            return redirect()->route($profileRoute)
                ->withInput()
                ->with('error', 'Erreur lors de la mise à jour du profil: '.$e->getMessage());
        }
    }

    /**
     * Enregistrer uniquement la photo de profil (admin autoritaire en base MongoDB).
     */
    public function updateProfilePhoto(Request $request)
    {
        $profileRoute = $this->currentEditableProfileRoute();

        try {
            $user = $this->resolveCurrentProfileUser();
            if (! $user instanceof AdminAutoritaire) {
                return redirect()->route($profileRoute)
                    ->with('error', 'Seul un compte administrateur autoritaire enregistré peut enregistrer une photo ici.');
            }

            $request->validate([
                'avatar_file' => 'required|image|mimes:jpg,jpeg,png,webp,gif|max:4096',
            ], [
                'avatar_file.required' => 'Veuillez choisir une image.',
                'avatar_file.image' => 'Le fichier sélectionné doit être une image.',
                'avatar_file.mimes' => 'Formats acceptés : jpg, jpeg, png, webp, gif.',
                'avatar_file.max' => 'La taille de la photo ne doit pas dépasser 4 Mo.',
            ]);

            $this->deleteStoredProfileAvatarIfOwned($user->avatar_url ?? null);

            $path = $request->file('avatar_file')->store('profile-avatars', 'public');
            $user->avatar_url = Storage::url($path);
            $user->save();

            return redirect()->route($profileRoute)
                ->with('success', 'Votre photo de profil a été enregistrée. Elle restera affichée à chaque connexion.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('Erreur lors de la mise à jour de la photo de profil', [
                'error' => $e->getMessage(),
                'user_id' => optional($this->resolveCurrentProfileUser())->getKey(),
            ]);

            return redirect()->route($profileRoute)
                ->with('error', 'Erreur lors de l\'enregistrement de la photo : '.$e->getMessage());
        }
    }

    /**
     * Admin autoritaire lié à la session (id Mongo ou email).
     */
    private function findAdminAutoritaireForCurrentSession(): ?AdminAutoritaire
    {
        $adminId = session('admin_id');
        if ($adminId) {
            $found = AdminAutoritaire::find($adminId);
            if ($found) {
                return $found;
            }
        }

        $email = strtolower(trim((string) (session('admin_email') ?? '')));
        if ($email === '') {
            return null;
        }

        $byExact = AdminAutoritaire::where('email', $email)->first();
        if ($byExact) {
            return $byExact;
        }

        return AdminAutoritaire::where('email', 'regex', '/^'.preg_quote($email, '/').'$/i')->first();
    }

    /**
     * Supprime un ancien fichier avatar stocké sur le disque public (si c'est le nôtre).
     */
    private function deleteStoredProfileAvatarIfOwned(?string $avatarUrl): void
    {
        if (empty($avatarUrl)) {
            return;
        }
        if (! preg_match('#^/storage/(.+)$#', (string) $avatarUrl, $m)) {
            return;
        }
        $relative = $m[1];
        if (! str_starts_with($relative, 'profile-avatars/')) {
            return;
        }
        Storage::disk('public')->delete($relative);
    }

    /**
     * Récupérer l'utilisateur à afficher/éditer dans la page profil.
     */
    /**
     * Route de la page profil à utiliser pour redirections (autoritaire vs autres).
     */
    private function currentEditableProfileRoute(): string
    {
        if (session('autoritaire_authenticated') && session('admin_type') === 'autoritaire') {
            return 'profil_admin_Autoritaire';
        }

        return 'profile';
    }

    private function resolveCurrentProfileUser()
    {
        $user = null;

        if (session('authenticated_admin_technical') && session('admin_type') === 'technical') {
            $adminId = session('admin_id');
            if ($adminId) {
                $user = User::find($adminId);
            }
        }

        if (! $user && session('autoritaire_authenticated') && session('admin_type') === 'autoritaire') {
            $user = $this->findAdminAutoritaireForCurrentSession();
        }

        if (! $user && Auth::guard('admin')->check()) {
            $admin = Auth::guard('admin')->user();
            if ($admin) {
                $isTechnical = false;
                if (method_exists($admin, 'isTechnical')) {
                    $isTechnical = $admin->isTechnical();
                } elseif (isset($admin->role) && ($admin->role === 'technical' || $admin->role === Admin::ROLE_TECHNICAL)) {
                    $isTechnical = true;
                }

                if ($isTechnical) {
                    $user = $admin;
                } elseif ($admin instanceof AdminAutoritaire) {
                    $user = $admin;
                }
            }
        }

        if (! $user) {
            $user = Auth::user();
        }

        return $user;
    }

    /**
     * Séparer un nom complet en prénom/nom.
     */
    private function splitName(string $fullName): array
    {
        $parts = preg_split('/\s+/', trim($fullName)) ?: [];
        if (empty($parts)) {
            return ['', ''];
        }

        $firstName = array_shift($parts);
        $lastName = implode(' ', $parts);

        return [$firstName, $lastName];
    }

    /**
     * Activer/Désactiver un compte citoyen (vérifier/déverifier l'email)
     */
    public function toggleCitizenStatus($id)
    {
        try {
            $citizen = Citizen::findOrFail($id);

            if ($citizen->email_verified_at) {
                // Désactiver : retirer la vérification
                $citizen->email_verified_at = null;
                $status = 'deactivated';
            } else {
                // Activer : vérifier l'email
                $citizen->email_verified_at = now();
                $status = 'activated';
            }

            $citizen->save();

            $this->auditLogService->log('citizen_toggled', [
                'citizen_id' => $citizen->_id,
                'status' => $status,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Statut du compte citoyen mis à jour avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la modification du statut du citoyen', [
                'error' => $e->getMessage(),
                'citizen_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la modification du statut: '.$e->getMessage());
        }
    }

    /**
     * Supprimer un compte citoyen
     */
    public function deleteCitizen($id)
    {
        try {
            $citizen = Citizen::findOrFail($id);
            $citizenEmail = $citizen->email;

            $citizen->delete();

            $this->auditLogService->log('citizen_deleted', [
                'citizen_email' => $citizenEmail,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Compte citoyen supprimé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression du citoyen', [
                'error' => $e->getMessage(),
                'citizen_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la suppression: '.$e->getMessage());
        }
    }

    /**
     * Supprimer un compte intervenant (document MongoDB).
     */
    public function deleteIntervenant(string $collection, string $id)
    {
        $allowed = ['intervenants', 'intervenant'];
        if (! in_array($collection, $allowed, true)) {
            return redirect()->route('interface_admin_tech')
                ->with('error', 'Collection invalide.');
        }

        try {
            $query = DB::connection('mongodb')->table($collection);

            // Certains documents utilisent ObjectId, d'autres un ID texte.
            if (preg_match('/^[a-fA-F0-9]{24}$/', $id) === 1) {
                try {
                    $deleted = (int) (clone $query)->where('_id', '=', new ObjectId($id))->delete();
                } catch (\Throwable $e) {
                    $deleted = 0;
                }
            } else {
                $deleted = 0;
            }

            if ($deleted === 0) {
                $deleted = (int) (clone $query)->where('_id', '=', $id)->delete();
            }

            if ($deleted === 0) {
                return redirect()->route('interface_admin_tech')
                    ->with('error', 'Aucun intervenant trouvé avec cet identifiant.');
            }

            $this->auditLogService->log('intervenant_deleted', [
                'intervenant_id' => $id,
                'collection' => $collection,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Compte intervenant supprimé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la suppression de l’intervenant', [
                'error' => $e->getMessage(),
                'collection' => $collection,
                'intervenant_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la suppression: '.$e->getMessage());
        }
    }

    /**
     * Réinitialiser le mot de passe d'un citoyen
     */
    public function resetCitizenPassword(Request $request, $id)
    {
        try {
            $request->validate([
                'password' => [
                    'required',
                    'confirmed',
                    'min:12',
                    'regex:/[A-Z]/',
                    'regex:/[a-z]/',
                    'regex:/[0-9]/',
                    'regex:/[@$!%*#?&]/',
                ],
            ], [
                'password.required' => 'Le mot de passe est requis.',
                'password.confirmed' => 'Les mots de passe ne correspondent pas.',
                'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
                'password.regex' => 'Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial (@$!%*#?&).',
            ]);

            $citizen = Citizen::findOrFail($id);
            $citizen->password = Hash::make($request->password);
            $citizen->save();

            $this->auditLogService->log('citizen_password_reset', [
                'citizen_id' => $citizen->_id,
                'citizen_email' => $citizen->email,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('success', 'Mot de passe réinitialisé avec succès.');
        } catch (\Exception $e) {
            Log::error('Erreur lors de la réinitialisation du mot de passe du citoyen', [
                'error' => $e->getMessage(),
                'citizen_id' => $id,
            ]);

            return redirect()->route('interface_admin_tech')
                ->with('error', 'Erreur lors de la réinitialisation: '.$e->getMessage());
        }
    }
}
