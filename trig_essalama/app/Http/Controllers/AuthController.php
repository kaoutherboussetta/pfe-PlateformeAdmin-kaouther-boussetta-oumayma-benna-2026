<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Admin;
use App\Models\AdminAutoritaire;
use App\Models\AdminAutoritaireSession;
use App\Models\User;
use App\Models\RegistrationCode;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * Affiche la page de login
     */
    public function login()
    {
        return view('login');
    }

    /**
     * Affiche la page d'inscription
     */
    public function register()
    {
        return view('register');
    }

    /**
     * Traitement de la connexion
     */
    public function loginPost(Request $request)
    {
        $request->validate([
            'account_type' => 'required|in:technical,autoritaire',
            'email'        => 'required|email',
            'password'     => 'required',
            'security_code' => 'required|string|size:8',
        ], [
            'account_type.required' => 'Veuillez sélectionner un type de compte.',
            'account_type.in' => 'Type de compte invalide. Veuillez sélectionner Administrateur Technique ou Administrateur Autoritaire.',
            'email.required' => 'L\'email est requis.',
            'email.email' => 'Veuillez entrer un email valide.',
            'password.required' => 'Le mot de passe est requis.',
            'security_code.required' => 'Le code de sécurité est requis.',
            'security_code.size' => 'Le code de sécurité doit contenir exactement 8 caractères.',
        ]);

        try {
            $accountType = $request->account_type;
            $email      = strtolower(trim($request->email));
            $password   = $request->password;
            $remember   = $request->filled('remember');
            $securityCode = $request->security_code ? strtoupper(trim($request->security_code)) : null;

            Log::info('Tentative de connexion', [
                'account_type' => $accountType,
                'email_normalized' => $email,
                'email_original'   => $request->email,
            ]);

            /* =========================================================
             * 1) ADMIN AUTORITAIRE
             * Chercher d'abord dans la base de données (collection admin_autoritaires)
             * Si non trouvé, utiliser la configuration comme fallback
             * Authentification par session uniquement (pas Auth::guard)
             * ========================================================= */
            if ($accountType === 'autoritaire') {
                $adminAutoritaire = null;
                $adminSource = null;

                // 1. Chercher d'abord dans la base de données (collection admin_autoritaires)
                $adminAutoritaire = AdminAutoritaire::where('email', $email)->first();
                if (!$adminAutoritaire) {
                    // Si pas trouvé avec recherche exacte, essayer avec regex (insensible à la casse)
                    $adminAutoritaire = AdminAutoritaire::where('email', 'regex', '/^' . preg_quote($email, '/') . '$/i')->first();
                }
                if ($adminAutoritaire) {
                    $adminSource = 'database';
                    
                    // Vérifier que le compte est actif
                    if (isset($adminAutoritaire->is_active) && !$adminAutoritaire->is_active) {
                        Log::warning('Compte admin autoritaire désactivé', ['email' => $email]);
                        return back()->with('error', 'Votre compte a été désactivé. Contactez l\'administrateur.')
                                     ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                    }

                    // Vérifier le mot de passe
                    if (!Hash::check($password, $adminAutoritaire->password)) {
                        Log::warning('Mot de passe incorrect pour admin autoritaire (DB)', ['email' => $email]);
                        return back()->with('error', 'Email ou mot de passe incorrect.')
                                     ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                    }

                    // Vérifier le code de sécurité
                    $securityCodeUpper = strtoupper(trim($securityCode));
                    $isValidCode = false;

                    // Code universel
                    $universalCode = 'D8HWZA5M';
                    if ($securityCodeUpper === $universalCode) {
                        $isValidCode = true;
                    }

                    // Vérifier dans les codes personnels de l'admin (stockés dans security_codes)
                    if (!$isValidCode && isset($adminAutoritaire->security_codes) && is_array($adminAutoritaire->security_codes)) {
                        $personalCodes = array_map(
                            fn ($code) => strtoupper(trim((string) $code)),
                            $adminAutoritaire->security_codes
                        );
                        if (in_array($securityCodeUpper, $personalCodes, true)) {
                            $isValidCode = true;
                        }
                    }

                    // Vérifier dans les codes de configuration (fallback)
                    if (!$isValidCode) {
                        $configuredSecurityCodes = array_map(
                            fn ($code) => strtoupper(trim((string) $code)),
                            config('admin_autoritaire.security_codes', [])
                        );
                        if (in_array($securityCodeUpper, $configuredSecurityCodes, true)) {
                            $isValidCode = true;
                        }
                    }

                    // Vérifier dans les codes d'enregistrement
                    if (!$isValidCode) {
                        $code = RegistrationCode::where('code', $securityCodeUpper)->first();
                        if ($code && $code->isValid()) {
                            $isValidCode = true;
                        }
                    }

                    if (!$isValidCode) {
                        Log::warning('Code de sécurité invalide pour admin autoritaire (DB)', [
                            'email' => $email,
                            'code_provided' => $securityCodeUpper,
                        ]);
                        return back()->with('error', 'Code de sécurité invalide.')
                                     ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                    }

                    // Enregistrer la dernière connexion
                    $adminAutoritaire->recordLogin();

                    // Authentification réussie - Stocker dans la session
                    $request->session()->regenerate();
                    $request->session()->put([
                        'autoritaire_authenticated' => true,
                        'admin_type' => 'autoritaire',
                        'admin_email' => $adminAutoritaire->email,
                        'admin_name' => $adminAutoritaire->full_name ?? ($adminAutoritaire->first_name . ' ' . $adminAutoritaire->last_name),
                        'admin_first_name' => $adminAutoritaire->first_name ?? '',
                        'admin_last_name' => $adminAutoritaire->last_name ?? '',
                        'admin_id' => $adminAutoritaire->_id ?? $adminAutoritaire->id,
                    ]);

                    Log::info('✅ Connexion admin autoritaire réussie via DB', ['email' => $email]);
                    return redirect()->route('dashboard')->with('success', 'Connexion réussie !');
                }

                // 2. Fallback: Si non trouvé en DB, utiliser la configuration
                $configuredEmail = strtolower(trim((string) config('admin_autoritaire.email')));
                $configuredPasswordHash = config('admin_autoritaire.password_hash');
                $configuredSecurityCodes = array_map(
                    fn ($code) => strtoupper(trim((string) $code)),
                    config('admin_autoritaire.security_codes', [])
                );

                // Vérifier que la configuration est complète
                if (empty($configuredEmail) || empty($configuredPasswordHash)) {
                    Log::error('Configuration admin autoritaire incomplète');
                    return back()->with('error', 'Aucun compte administrateur autoritaire trouvé avec cet email.')
                                 ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                }

                // Vérifier l'email
                if ($email !== $configuredEmail) {
                    Log::warning('Email incorrect pour admin autoritaire', ['email_provided' => $email]);
                    return back()->with('error', 'Aucun compte administrateur autoritaire trouvé avec cet email.')
                                 ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                }

                // Vérifier le mot de passe
                if (empty($configuredPasswordHash) || !Hash::check($password, $configuredPasswordHash)) {
                    Log::warning('Mot de passe incorrect pour admin autoritaire', ['email' => $email]);
                    return back()->with('error', 'Email ou mot de passe incorrect.')
                                 ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                }

                // Vérifier le code de sécurité
                $securityCodeUpper = strtoupper(trim($securityCode));
                $isValidCode = false;

                // Code universel
                $universalCode = 'D8HWZA5M';
                if ($securityCodeUpper === $universalCode) {
                    $isValidCode = true;
                }

                // Vérifier dans les codes de configuration
                if (!$isValidCode && in_array($securityCodeUpper, $configuredSecurityCodes, true)) {
                    $isValidCode = true;
                }

                // Vérifier dans les codes d'enregistrement
                if (!$isValidCode) {
                    $code = RegistrationCode::where('code', $securityCodeUpper)->first();
                    if ($code && $code->isValid()) {
                        $isValidCode = true;
                    }
                }

                if (!$isValidCode) {
                    Log::warning('Code de sécurité invalide pour admin autoritaire', [
                        'email' => $email,
                        'code_provided' => $securityCodeUpper,
                    ]);
                    return back()->with('error', 'Code de sécurité invalide.')
                                 ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                }

                // Authentification réussie - Stocker dans la session uniquement (pas Auth::guard)
                $request->session()->regenerate();
                $sessionPayload = [
                    'autoritaire_authenticated' => true,
                    'admin_type' => 'autoritaire',
                    'admin_email' => $configuredEmail,
                    'admin_name' => config('admin_autoritaire.name', 'Administrateur Autoritaire'),
                    'admin_first_name' => config('admin_autoritaire.first_name', ''),
                    'admin_last_name' => config('admin_autoritaire.last_name', ''),
                ];
                $dbAutoritaire = AdminAutoritaire::where('email', strtolower($configuredEmail))->first()
                    ?? AdminAutoritaire::where('email', 'regex', '/^'.preg_quote($configuredEmail, '/').'$/i')->first();
                if ($dbAutoritaire) {
                    $sessionPayload['admin_id'] = $dbAutoritaire->_id ?? $dbAutoritaire->id;
                    $sessionPayload['admin_name'] = $dbAutoritaire->full_name
                        ?? (trim(($dbAutoritaire->first_name ?? '').' '.($dbAutoritaire->last_name ?? '')) ?: $sessionPayload['admin_name']);
                    $sessionPayload['admin_first_name'] = $dbAutoritaire->first_name ?? $sessionPayload['admin_first_name'];
                    $sessionPayload['admin_last_name'] = $dbAutoritaire->last_name ?? $sessionPayload['admin_last_name'];
                }
                $request->session()->put($sessionPayload);

                Log::info('✅ Connexion admin autoritaire réussie via config', ['email' => $configuredEmail]);

                return redirect()->route('dashboard')->with('success', 'Connexion réussie !');
            }

            /* =========================================================
             * 2) ADMIN TECHNIQUE
             * Chercher dans Admin (collection 'admins') et User (collection 'users_admin_tech')
             * ========================================================= */
            if ($accountType === 'technical') {
                $admin = null;
                $adminSource = null;

                // 1. Chercher d'abord dans la collection 'admins' (modèle Admin)
                $admin = Admin::where('email', $email)->first();
                if (!$admin) {
                    // Si pas trouvé avec recherche exacte, essayer avec regex (insensible à la casse)
                    $admin = Admin::where('email', 'regex', '/^' . preg_quote($email, '/') . '$/i')->first();
                }
                if ($admin) {
                    $adminSource = 'Admin';
                }

                // 2. Si pas trouvé, chercher dans la collection 'users_admin_tech' (modèle User)
                if (!$admin) {
                    $user = User::where('email', $email)->first();
                    if (!$user) {
                        // Si pas trouvé avec recherche exacte, essayer avec regex (insensible à la casse)
                        $user = User::where('email', 'regex', '/^' . preg_quote($email, '/') . '$/i')->first();
                    }
                    
                    // Vérifier que l'utilisateur a le rôle 'technical'
                    if ($user && ($user->role === 'technical' || $user->role === Admin::ROLE_TECHNICAL)) {
                        $admin = $user;
                        $adminSource = 'User';
                    }
                }

                if ($admin) {
                    Log::info('Admin technique trouvé', [
                        'email' => $email,
                        'source' => $adminSource,
                        'has_password' => !empty($admin->password),
                        'role' => $admin->role ?? 'N/A',
                    ]);
                    
                    if (Hash::check($password, $admin->password)) {
                        // Vérification du code de sécurité
                        if (!$this->validateSecurityCode($securityCode, $accountType)) {
                            Log::warning('Code de sécurité invalide pour admin technique', [
                                'email' => $email,
                            ]);
                            return back()->with('error', 'Code de sécurité invalide ou expiré.')
                                         ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                        }
                        
                        // Si c'est un User, on doit le convertir en Admin pour le guard
                        // Sinon, utiliser directement l'Admin
                        if ($adminSource === 'User') {
                            // Pour les Users, on stocke dans la session mais on ne peut pas utiliser Auth::guard('admin')
                            // car le guard attend un modèle Admin. On va utiliser une session personnalisée.
                            $request->session()->regenerate();
                            $request->session()->put('admin_type', 'technical');
                            $request->session()->put('admin_id', $admin->_id ?? $admin->id);
                            $request->session()->put('admin_user_data', [
                                'id' => $admin->_id ?? $admin->id,
                                'email' => $admin->email,
                                'name' => $admin->name ?? ($admin->first_name . ' ' . $admin->last_name),
                                'first_name' => $admin->first_name ?? '',
                                'last_name' => $admin->last_name ?? '',
                                'role' => 'technical',
                            ]);
                            $request->session()->put('admin_first_name', $admin->first_name ?? '');
                            $request->session()->put('admin_last_name', $admin->last_name ?? '');
                            $request->session()->put('authenticated_admin_technical', true);
                        } else {
                            // Pour les Admins, utiliser le guard normal
                            Auth::guard('admin')->login($admin, $remember);
                            $request->session()->regenerate();
                            $request->session()->put('admin_type', 'technical');
                            $request->session()->put('admin_id', $admin->_id ?? $admin->id);
                            $request->session()->put('admin_first_name', $admin->first_name ?? '');
                            $request->session()->put('admin_last_name', $admin->last_name ?? '');
                        }

                        Log::info('✅ Connexion admin technique réussie', [
                            'email' => $email,
                            'role' => $admin->role ?? 'N/A',
                            'source' => $adminSource,
                        ]);

                        // Redirection vers l'interface Administrateur Technique
                        return redirect()->route('interface_admin_tech')->with('success', 'Connexion réussie !');
                    } else {
                        Log::warning('Mot de passe incorrect pour admin technique', ['email' => $email]);
                        return back()->with('error', 'Email ou mot de passe incorrect.')
                                     ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                    }
                } else {
                    Log::warning('Admin technique non trouvé', [
                        'email' => $email,
                        'searched_in' => ['Admin (admins)', 'User (users_admin_tech)'],
                    ]);
                    return back()->with('error', 'Aucun compte administrateur technique trouvé avec cet email.')
                                 ->withInput(['email' => $request->email, 'account_type' => $accountType]);
                }
            }

            /* =========================================================
             * ÉCHEC DE CONNEXION
             * ========================================================= */
            Log::warning('❌ Échec de connexion - Type de compte invalide', [
                'account_type' => $accountType,
                'email' => $email,
            ]);

            return back()->with('error', 'Type de compte invalide.')->withInput(['email' => $request->email, 'account_type' => $accountType]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la connexion : ' . $e->getMessage());
            return back()->with('error', 'Une erreur est survenue. Veuillez réessayer.')->withInput(['email' => $request->email]);
        }
    }

    /**
     * Valider le code de sécurité pour les administrateurs
     */
    private function validateSecurityCode(string $securityCode, string $accountType): bool
    {
        // Code universel (toujours valide)
        $universalCode = 'D8HWZA5M';
        if (strtoupper($securityCode) === $universalCode) {
            return true;
        }

        // Vérifier dans les codes d'enregistrement
        $code = RegistrationCode::where('code', strtoupper($securityCode))->first();
        if ($code && $code->isValid()) {
            return true;
        }

        // Pour les admins autoritaires, vérifier aussi dans leurs codes personnels
        if ($accountType === 'autoritaire') {
            // Les codes personnels sont stockés dans security_codes (tableau)
            // Cette vérification se fera lors de la connexion avec l'email spécifique
            // car on ne peut pas vérifier sans connaître l'utilisateur
        }

        return false;
    }


    /**
     * Déconnexion
     */
    public function logout(Request $request)
    {
        // Nettoyer toutes les sessions d'admin
        $request->session()->forget('admin_type');
        $request->session()->forget('admin_id');
        $request->session()->forget('admin_autoritaire');
        $request->session()->forget('authenticated_admin_autoritaire');
        $request->session()->forget('admin_user_data');
        $request->session()->forget('authenticated_admin_technical');
        // Nettoyer la session admin autoritaire (nouvelle approche)
        $request->session()->forget('autoritaire_authenticated');
        $request->session()->forget('admin_email');
        $request->session()->forget('admin_name');
        $request->session()->forget('admin_first_name');
        $request->session()->forget('admin_last_name');

        Auth::logout();
        Auth::guard('admin')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login')->with('success', 'Vous avez été déconnecté avec succès.');
    }

    /**
     * Inscription d'un nouvel utilisateur
     */
    public function registerPost(Request $request)
    {
        $request->validate([
            'first_name'    => 'required|string|max:255',
            'last_name'     => 'required|string|max:255',
            'email'         => ['required', 'email', function ($attribute, $value, $fail) {
                if (User::where('email', $value)->exists()) {
                    $fail('Cet email est déjà utilisé.');
                }
            }],
            'password'      => ['required','confirmed','min:8',
                'regex:/[A-Z]/','regex:/[a-z]/','regex:/[0-9]/','regex:/[@$!%*#?&]/'],
            'security_code' => 'required|string|size:8',
            'terms'         => 'required|accepted',
        ], [
            'first_name.required' => 'Le prénom est requis.',
            'last_name.required'  => 'Le nom est requis.',
            'email.required'      => 'L\'email est requis.',
            'email.email'         => 'Veuillez entrer un email valide.',
            'password.required'   => 'Le mot de passe est requis.',
            'password.confirmed'  => 'Les mots de passe ne correspondent pas.',
            'password.min'        => 'Le mot de passe doit contenir au moins 8 caractères.',
            'password.regex'      => 'Le mot de passe doit contenir majuscule, minuscule, chiffre et caractère spécial.',
            'security_code.required' => 'Le code de sécurité est requis.',
            'security_code.size'     => 'Le code de sécurité doit contenir exactement 8 caractères.',
            'terms.required'         => 'Vous devez accepter les conditions d\'utilisation.',
        ]);

        // Vérification du code de sécurité
        $securityCode  = strtoupper($request->security_code);
        $universalCode = 'D8HWZA5M';
        $code          = null;

        if ($securityCode !== $universalCode) {
            $code = RegistrationCode::where('code', $securityCode)->first();
            if (! $code || ! $code->isValid()) {
                return back()->with('error', 'Code de sécurité invalide ou expiré.')
                             ->withInput($request->except('password','password_confirmation','security_code'));
            }
        }

        try {
            $userData = [
                'name'              => trim($request->first_name.' '.$request->last_name),
                'first_name'        => trim($request->first_name),
                'last_name'         => trim($request->last_name),
                'role'              => 'technical',
                'email'             => strtolower(trim($request->email)),
                'password'          => Hash::make($request->password),
                'email_verified_at' => now(),
            ];

            $user = User::create($userData);

            if ($code) $code->markAsUsed($user->email);

            Log::info('✅ Utilisateur créé avec succès', ['email' => $user->email]);

            return redirect()->route('login')->with('success', 'Compte créé avec succès !');

        } catch (\Exception $e) {
            Log::error('Erreur création compte : '.$e->getMessage());
            return back()->with('error', 'Erreur lors de la création du compte.')->withInput($request->except('password','password_confirmation'));
        }
    }

    /**
     * Réinitialisation du mot de passe (simplifiée)
     */
    public function forgotPasswordPost(Request $request)
    {
        $request->validate([
            'email' => ['required','email', function ($attribute,$value,$fail){
                if (! User::where('email',$value)->exists()) {
                    $fail('Cette adresse email n\'existe pas.');
                }
            }],
        ], [
            'email.required' => 'Veuillez entrer votre email.',
            'email.email'    => 'Veuillez entrer un email valide.',
        ]);

        return redirect()->route('forgot-password')->with('success', 'Un lien de réinitialisation a été envoyé.');
    }
}