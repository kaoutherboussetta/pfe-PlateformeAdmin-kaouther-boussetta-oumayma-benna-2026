<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use App\Models\Admin;
use App\Services\AuditLogService;
use App\Services\TwoFactorService;

class AdminAuthController extends Controller
{
    protected $auditLogService;
    protected $twoFactorService;

    public function __construct(AuditLogService $auditLogService, TwoFactorService $twoFactorService)
    {
        $this->auditLogService = $auditLogService;
        $this->twoFactorService = $twoFactorService;
    }

    /**
     * Afficher le formulaire de connexion admin
     */
    public function showLoginForm()
    {
        return view('admin.login');
    }

    /**
     * Traiter la connexion admin
     */
    public function login(Request $request)
    {
        // Throttling: 5 tentatives par minute
        $key = 'admin-login:' . $request->ip();
        
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            $this->auditLogService->log('admin_login_throttled', [
                'ip' => $request->ip(),
                'email' => $request->email,
            ]);
            return back()->withErrors([
                'email' => "Trop de tentatives. Veuillez réessayer dans {$seconds} secondes."
            ])->withInput($request->only('email'));
        }

        // Validation
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|min:12',
        ], [
            'email.required' => 'L\'adresse email est requise.',
            'email.email' => 'Veuillez entrer une adresse email valide.',
            'password.required' => 'Le mot de passe est requis.',
            'password.min' => 'Le mot de passe doit contenir au moins 12 caractères.',
        ]);

        // Rechercher l'admin
        $admin = Admin::where('email', $request->email)->first();

        if (!$admin) {
            RateLimiter::hit($key);
            $this->auditLogService->log('admin_login_failed', [
                'ip' => $request->ip(),
                'email' => $request->email,
                'reason' => 'admin_not_found',
            ]);
            return back()->withErrors([
                'email' => 'Identifiants incorrects.'
            ])->withInput($request->only('email'));
        }

        // Vérifier si l'admin est actif
        if (!$admin->is_active) {
            RateLimiter::hit($key);
            $this->auditLogService->log('admin_login_failed', [
                'ip' => $request->ip(),
                'email' => $request->email,
                'admin_id' => $admin->_id,
                'reason' => 'account_inactive',
            ]);
            return back()->withErrors([
                'email' => 'Votre compte est désactivé. Contactez l\'administrateur technique.'
            ])->withInput($request->only('email'));
        }

        // Vérifier le mot de passe
        if (!Hash::check($request->password, $admin->password)) {
            RateLimiter::hit($key);
            $this->auditLogService->log('admin_login_failed', [
                'ip' => $request->ip(),
                'email' => $request->email,
                'admin_id' => $admin->_id,
                'reason' => 'invalid_password',
            ]);
            return back()->withErrors([
                'email' => 'Identifiants incorrects.'
            ])->withInput($request->only('email'));
        }


        // Authentification réussie - vérifier 2FA
        RateLimiter::clear($key);

        // Si 2FA est activé, rediriger vers la vérification
        if ($admin->two_factor_enabled) {
            $request->session()->put('admin_2fa_pending', $admin->_id);
            return redirect()->route('admin.2fa.verify');
        }

        // Connexion sans 2FA
        Auth::guard('admin')->login($admin, $request->filled('remember'));
        $request->session()->regenerate();

        // Enregistrer la connexion
        $admin->recordLogin();
        $this->auditLogService->log('login');

        return redirect('/admin/dashboard')->with('success', 'Connexion réussie !');
    }

    /**
     * Afficher le formulaire de vérification 2FA
     */
    public function show2FAForm()
    {
        if (!session()->has('admin_2fa_pending')) {
            return redirect()->route('admin.login');
        }

        return view('admin.2fa-verify');
    }

    /**
     * Vérifier le code 2FA
     */
    public function verify2FA(Request $request)
    {
        $request->validate([
            'code' => 'required|string|size:6',
        ]);

        $adminId = session()->get('admin_2fa_pending');
        if (!$adminId) {
            return redirect()->route('admin.login');
        }

        $admin = Admin::find($adminId);
        if (!$admin || !$admin->two_factor_enabled) {
            session()->forget('admin_2fa_pending');
            return redirect()->route('admin.login');
        }

        if ($this->twoFactorService->verify($admin, $request->code)) {
            session()->forget('admin_2fa_pending');
            Auth::guard('admin')->login($admin, $request->filled('remember'));
            $request->session()->regenerate();

            $admin->recordLogin();
            $this->auditLogService->log('login');

            return redirect('/admin/dashboard')->with('success', 'Connexion réussie !');
        }

        $this->auditLogService->log('admin_2fa_failed', [
            'ip' => $request->ip(),
            'admin_id' => $admin->_id,
            'email' => $admin->email,
        ]);

        return back()->withErrors(['code' => 'Code 2FA invalide.']);
    }

    /**
     * Déconnexion admin
     */
    public function logout(Request $request)
    {
        $admin = Auth::guard('admin')->user();
        
        if ($admin) {
        $this->auditLogService->log('logout');
        }

        Auth::guard('admin')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('success', 'Vous avez été déconnecté avec succès.');
    }
}
