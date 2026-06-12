<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAutoritaireAuthenticated
{
    /**
     * Handle an incoming request.
     * 
     * Permet l'accès si :
     * - Admin autoritaire authentifié via session
     * - Admin technique authentifié via Auth::guard('admin')
     * - Utilisateur authentifié via Auth::check()
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Vérifier admin autoritaire (session)
        $isAutoritaire = $request->session()->get('autoritaire_authenticated') === true;
        
        // Vérifier admin technique (guard) - si le guard est authentifié, permettre l'accès
        $isTechnical = Auth::guard('admin')->check();
        
        // Vérifier utilisateur classique
        $isUser = Auth::check();
        
        // Vérifier admin technique via User (session)
        $isTechnicalUser = session('authenticated_admin_technical') === true;

        // Si aucun type d'authentification n'est trouvé, rediriger vers login
        if (!$isAutoritaire && !$isTechnical && !$isUser && !$isTechnicalUser) {
            return redirect()->route('login')->with('error', 'Veuillez vous connecter.');
        }

        return $next($request);
    }
}
