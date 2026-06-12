<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use MongoDB\Laravel\Connection;

class AuditLogService
{
    protected $connection;

    public function __construct()
    {
        $this->connection = DB::connection('mongodb');
    }

    /**
     * Enregistrer une action dans les logs d'audit
     */
    public function log(string $action, array $data = []): void
    {
        try {
            $adminId = auth('admin')->check() ? auth('admin')->id() : ($data['admin_id'] ?? null);
            
            $logData = [
                'admin_id' => $adminId,
                'action' => $action,
                'ip' => request()->ip(),
                'user_agent' => request()->userAgent(),
                'created_at' => now(),
            ];

            // Enregistrer dans MongoDB (collection admin_logs)
            // Utiliser DB::table() pour MongoDB Laravel
            DB::connection('mongodb')->table('admin_logs')->insert($logData);

            // Aussi dans les logs Laravel
            Log::channel('daily')->info("Audit: {$action}", $logData);

        } catch (\Exception $e) {
            // En cas d'erreur, au moins logger dans les logs Laravel
            Log::error('Erreur lors de l\'enregistrement de l\'audit log', [
                'action' => $action,
                'error' => $e->getMessage(),
                'data' => $data,
            ]);
        }
    }

    /**
     * Récupérer les logs d'audit
     */
    public function getLogs(array $filters = [], int $limit = 100)
    {
        $query = DB::connection('mongodb')->table('admin_logs');

        if (isset($filters['action'])) {
            $query = $query->where('action', $filters['action']);
        }

        if (isset($filters['admin_id'])) {
            $query = $query->where('admin_id', $filters['admin_id']);
        }

        if (isset($filters['ip'])) {
            $query = $query->where('ip', $filters['ip']);
        }

        if (isset($filters['date_from'])) {
            $query = $query->where('created_at', '>=', $filters['date_from']);
        }

        if (isset($filters['date_to'])) {
            $query = $query->where('created_at', '<=', $filters['date_to']);
        }

        return $query->orderBy('created_at', 'desc')->limit($limit)->get();
    }
}
