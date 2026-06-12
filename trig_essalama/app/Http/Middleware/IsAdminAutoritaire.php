<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class IsAdminAutoritaire
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Vérifier si c'est un admin autoritaire authentifié via session (nouvelle approche)
        $isAdminAutoritaire = $request->session()->get('autoritaire_authenticated') === true;
        
        // Vérifier si c'est un admin autoritaire authentifié via guard (ancien système - pour compatibilité)
        $admin = Auth::guard('admin')->user();
        $isAdminAutoritaireFromGuard = $admin && method_exists($admin, 'isAutoritaire') && $admin->isAutoritaire();

        if (!$isAdminAutoritaire && !$isAdminAutoritaireFromGuard) {
            abort(403, 'Accès refusé. Seuls les Administrateurs Autoritaires ont accès à cette ressource.');
        }

        return $next($request);
    }
}
