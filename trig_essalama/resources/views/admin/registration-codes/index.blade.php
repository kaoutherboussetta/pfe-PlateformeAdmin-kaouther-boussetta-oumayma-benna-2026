<!DOCTYPE html>
<html lang="fr" class="trig-app trig-legacy">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestion Codes de Sécurité - Trig-Essalama</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0a0a;
            color: #fff;
            min-height: 100vh;
        }

        .header {
            background: linear-gradient(135deg, rgba(220, 38, 38, 0.2) 0%, rgba(20, 20, 20, 0.95) 100%);
            padding: 20px 30px;
            border-bottom: 1px solid rgba(220, 38, 38, 0.3);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 24px;
            font-weight: 700;
        }

        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            font-size: 14px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(220, 38, 38, 0.4);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #3b82f6 0%, #1e40af 100%);
        }

        .btn-danger {
            background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
        }

        .container {
            max-width: 1200px;
            margin: 40px auto;
            padding: 0 30px;
        }

        .table-container {
            background: linear-gradient(135deg, rgba(220, 38, 38, 0.1) 0%, rgba(20, 20, 20, 0.8) 100%);
            border: 1px solid rgba(220, 38, 38, 0.2);
            border-radius: 12px;
            padding: 24px;
            backdrop-filter: blur(10px);
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid rgba(220, 38, 38, 0.1);
        }

        th {
            color: rgba(255, 255, 255, 0.9);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 12px;
            letter-spacing: 1px;
        }

        td {
            color: rgba(255, 255, 255, 0.8);
            font-size: 14px;
        }

        .code {
            font-family: 'Courier New', monospace;
            font-size: 18px;
            font-weight: 700;
            color: #fca5a5;
            letter-spacing: 3px;
        }

        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .badge-valid {
            background: rgba(34, 197, 94, 0.2);
            color: #86efac;
            border: 1px solid rgba(34, 197, 94, 0.3);
        }

        .badge-expired {
            background: rgba(107, 114, 128, 0.2);
            color: #9ca3af;
            border: 1px solid rgba(107, 114, 128, 0.3);
        }

        .badge-used {
            background: rgba(220, 38, 38, 0.2);
            color: #fca5a5;
            border: 1px solid rgba(220, 38, 38, 0.3);
        }

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }

        .alert-success {
            background: rgba(34, 197, 94, 0.2);
            color: #86efac;
            border: 1px solid rgba(34, 197, 94, 0.3);
        }

        .alert-success strong {
            color: #86efac;
            font-size: 16px;
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <div class="header">
        <h1>🔐 Gestion des Codes de Sécurité</h1>
        <a href="{{ route('admin.registration-codes.create') }}" class="btn">+ Générer un Code</a>
    </div>

    <div class="container">
        @if(session('success'))
            <div class="alert alert-success">
                {!! session('success') !!}
            </div>
        @endif

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Utilisations</th>
                        <th>Max Utilisations</th>
                        <th>Expire le</th>
                        <th>Statut</th>
                        <th>Utilisé par</th>
                        <th>Créé le</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($codes as $code)
                        <tr>
                            <td><span class="code">{{ $code->code }}</span></td>
                            <td>{{ $code->current_uses ?? 0 }}</td>
                            <td>{{ $code->max_uses }}</td>
                            <td>{{ $code->expires_at ? $code->expires_at->format('d/m/Y') : 'Jamais' }}</td>
                            <td>
                                @if($code->isValid())
                                    <span class="badge badge-valid">Valide</span>
                                @elseif($code->expires_at && $code->expires_at->isPast())
                                    <span class="badge badge-expired">Expiré</span>
                                @else
                                    <span class="badge badge-used">Utilisé</span>
                                @endif
                            </td>
                            <td>{{ $code->used_by ?? 'N/A' }}</td>
                            <td>{{ $code->created_at ? $code->created_at->format('d/m/Y H:i') : 'N/A' }}</td>
                            <td>
                                <form method="POST" action="{{ route('admin.registration-codes.destroy', $code->_id) }}" style="display: inline;" onsubmit="return confirm('Êtes-vous sûr de vouloir supprimer ce code ?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-danger" style="padding: 6px 12px; font-size: 12px;">Supprimer</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" style="text-align: center; padding: 40px; color: rgba(255, 255, 255, 0.5);">
                                Aucun code de sécurité trouvé.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div style="margin-top: 20px;">
            <a href="{{ route('admin.dashboard') }}" class="btn btn-secondary">Retour au Dashboard</a>
        </div>
    </div>
@include('partials.theme-toggle')
</body>
</html>
