<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use App\Models\RegistrationCode;
use App\Services\AuditLogService;

class RegistrationCodeController extends Controller
{
    protected $auditLogService;

    public function __construct(AuditLogService $auditLogService)
    {
        $this->auditLogService = $auditLogService;
    }

    /**
     * Liste des codes de sécurité (Admin Technique uniquement)
     */
    public function index()
    {
        // Le middleware admin.role:technical s'occupe de la vérification
        $codes = RegistrationCode::orderBy('created_at', 'desc')->get();
        
        return view('admin.registration-codes.index', compact('codes'));
    }

    /**
     * Afficher le formulaire de création de code
     */
    public function create()
    {
        // Le middleware admin.role:technical s'occupe de la vérification
        return view('admin.registration-codes.create');
    }

    /**
     * Générer un nouveau code de sécurité
     */
    public function store(Request $request)
    {
        // Le middleware admin.role:technical s'occupe de la vérification

        $request->validate([
            'max_uses' => 'required|integer|min:1|max:100',
            'expire_days' => 'required|integer|min:1|max:365',
        ], [
            'max_uses.required' => 'Le nombre maximum d\'utilisations est requis.',
            'max_uses.min' => 'Le nombre minimum d\'utilisations est 1.',
            'max_uses.max' => 'Le nombre maximum d\'utilisations ne peut pas dépasser 100.',
            'expire_days.required' => 'Le nombre de jours d\'expiration est requis.',
            'expire_days.min' => 'Le nombre minimum de jours est 1.',
            'expire_days.max' => 'Le nombre maximum de jours est 365.',
        ]);

        try {
            // Générer un code unique
            $code = RegistrationCode::generate();
            
            $registrationCode = RegistrationCode::create([
                'code' => $code,
                'used' => false,
                'max_uses' => $request->max_uses,
                'current_uses' => 0,
                'expires_at' => now()->addDays($request->expire_days),
                'created_by' => Auth::guard('admin')->id(),
            ]);

            // Enregistrer l'action
            $this->auditLogService->log('registration_code_created');

            Log::info('Code de sécurité créé', [
                'code' => $code,
                'max_uses' => $request->max_uses,
                'expire_days' => $request->expire_days,
                'created_by' => Auth::guard('admin')->id(),
            ]);

            return redirect()->route('admin.registration-codes.index')
                ->with('success', 'Code de sécurité créé avec succès: <strong>' . $code . '</strong>');

        } catch (\Exception $e) {
            Log::error('Erreur lors de la création du code de sécurité', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return back()->with('error', 'Erreur lors de la création du code: ' . $e->getMessage())
                ->withInput();
        }
    }

    /**
     * Supprimer un code de sécurité
     */
    public function destroy($id)
    {
        $code = RegistrationCode::findOrFail($id);
        $codeValue = $code->code;
        $code->delete();

        $this->auditLogService->log('registration_code_deleted');

        return redirect()->route('admin.registration-codes.index')
            ->with('success', 'Code de sécurité supprimé avec succès.');
    }
}
