<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class IsAdminTechnique
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Vérifier si c'est un admin technique authentifié via User (collection users_admin_tech)
        $isAdminTechnicalFromSession = session('authenticated_admin_technical') && session('admin_type') === 'technical';
        
        // Vérifier si c'est un admin technique authentifié via guard (collection admins)
        $admin = Auth::guard('admin')->user();
        $isAdminTechnicalFromGuard = $admin && method_exists($admin, 'isTechnical') && $admin->isTechnical();

        if (!$isAdminTechnicalFromSession && !$isAdminTechnicalFromGuard) {
            abort(403, 'Accès refusé. Seuls les Administrateurs Techniques ont accès à cette ressource.');
        }

        return $next($request);
    }
}
