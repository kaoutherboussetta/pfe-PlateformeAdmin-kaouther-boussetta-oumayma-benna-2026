<!DOCTYPE html>
<html lang="fr" class="trig-app trig-outfit">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestion Administrateurs - Trig-Essalama</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

        :root {
            --orange: #FF6B35;
            --orange-light: #FF8C5A;
            --orange-glow: rgba(255, 107, 53, 0.25);
            --yellow: #FFD700;
            --yellow-glow: rgba(255, 215, 0, 0.2);
            --cyan: #00D4FF;
            --cyan-glow: rgba(0, 212, 255, 0.2);
            --green: #00E676;
            --green-glow: rgba(0, 230, 118, 0.2);
            --red: #FF3D57;
            --bg: #080C14;
            --bg2: #0D1320;
            --bg3: #111827;
            --surface: rgba(255,255,255,0.04);
            --surface2: rgba(255,255,255,0.07);
            --border: rgba(255,255,255,0.08);
            --border-accent: rgba(255, 107, 53, 0.4);
            --text: #F0F4FF;
            --text2: #8A9BBE;
            --text3: #5A6882;
        }

        body {
            font-family: 'Outfit', sans-serif;
            background: var(--bg);
            color: var(--text);
            min-height: 100vh;
            overflow-x: hidden;
        }

        /* Animated background */
        .bg-canvas {
            position: fixed; inset: 0; z-index: 0; overflow: hidden; pointer-events: none;
        }
        .bg-canvas::before {
            content: '';
            position: absolute;
            width: 900px; height: 900px;
            top: -300px; left: -200px;
            background: radial-gradient(circle, rgba(255,107,53,0.07) 0%, transparent 65%);
            animation: pulse1 8s ease-in-out infinite;
        }
        .bg-canvas::after {
            content: '';
            position: absolute;
            width: 700px; height: 700px;
            bottom: -200px; right: -100px;
            background: radial-gradient(circle, rgba(0,212,255,0.06) 0%, transparent 65%);
            animation: pulse2 10s ease-in-out infinite;
        }
        @keyframes pulse1 { 0%,100%{transform:scale(1) translate(0,0)} 50%{transform:scale(1.1) translate(30px,20px)} }
        @keyframes pulse2 { 0%,100%{transform:scale(1) translate(0,0)} 50%{transform:scale(1.15) translate(-20px,-30px)} }

        /* Grid lines */
        .grid-overlay {
            position: fixed; inset: 0; z-index: 0; pointer-events: none;
            background-image:
                linear-gradient(rgba(255,107,53,0.03) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,107,53,0.03) 1px, transparent 1px);
            background-size: 60px 60px;
        }

        .container {
            position: relative; z-index: 1;
            max-width: 1400px;
            margin: 0 auto;
            padding: 40px 32px;
        }

        /* Header Section */
        .header-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 32px;
        }

        .header-title {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .header-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            background: rgba(255,107,53,0.15);
            color: var(--orange);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            box-shadow: 0 0 20px rgba(255,107,53,0.2);
        }

        .header-title h1 {
            font-size: 28px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: -0.5px;
        }

        .btn-create {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            border-radius: 12px;
            background: var(--orange);
            color: #fff;
            font-size: 14px;
            font-weight: 700;
            letter-spacing: 0.3px;
            border: none;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 0 20px rgba(255,107,53,0.3);
            text-decoration: none;
        }
        .btn-create:hover {
            background: var(--orange-light);
            transform: translateY(-2px);
            box-shadow: 0 0 30px rgba(255,107,53,0.5);
        }

        /* Alerts */
        .alert {
            padding: 14px 18px;
            border-radius: 10px;
            margin-bottom: 24px;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-success {
            background: rgba(0,230,118,0.1);
            color: var(--green);
            border: 1px solid rgba(0,230,118,0.25);
        }
        .alert-error {
            background: rgba(255,61,87,0.1);
            color: var(--red);
            border: 1px solid rgba(255,61,87,0.25);
        }

        /* Table Container */
        .table-container {
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
        }

        thead tr {
            background: rgba(0,0,0,0.2);
        }

        th {
            padding: 16px 20px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: var(--text3);
            text-align: left;
            white-space: nowrap;
            border-bottom: 1px solid var(--border);
        }

        td {
            padding: 18px 20px;
            font-size: 13px;
            color: var(--text2);
            border-bottom: 1px solid rgba(255,255,255,0.04);
            vertical-align: middle;
        }

        tbody tr {
            transition: background 0.15s;
        }

        tbody tr:hover {
            background: rgba(255,255,255,0.025);
        }

        tbody tr:last-child td {
            border-bottom: none;
        }

        .td-name {
            font-weight: 600;
            color: var(--text);
            font-size: 14px;
        }

        .td-email {
            font-family: monospace;
            font-size: 12px;
            color: var(--text2);
        }

        /* Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 6px 14px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            white-space: nowrap;
        }

        .badge::before {
            content: '●';
            font-size: 8px;
        }

        .badge-yellow {
            background: rgba(255,215,0,0.12);
            color: #fff;
            border: 1px solid rgba(255,215,0,0.3);
        }

        .badge-yellow::before {
            color: var(--yellow);
        }

        .badge-orange {
            background: rgba(255,107,53,0.15);
            color: #fff;
            border: 1px solid rgba(255,107,53,0.3);
        }

        .badge-orange::before {
            color: var(--orange);
        }

        .badge-green {
            background: rgba(0,230,118,0.12);
            color: #fff;
            border: 1px solid rgba(0,230,118,0.3);
        }

        .badge-green::before {
            color: var(--green);
        }

        /* Actions */
        .actions {
            display: flex;
            gap: 8px;
            align-items: center;
        }

        .btn-act {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid var(--border);
            background: var(--bg2);
            color: var(--text2);
            text-decoration: none;
        }

        .btn-act:hover {
            color: var(--text);
            border-color: rgba(255,255,255,0.2);
            background: var(--surface);
            transform: translateY(-1px);
        }

        .btn-act.danger {
            border-color: rgba(255,61,87,0.3);
            color: var(--red);
            background: rgba(255,61,87,0.06);
        }

        .btn-act.danger:hover {
            background: rgba(255,61,87,0.15);
            border-color: rgba(255,61,87,0.5);
        }

        .btn-act-text {
            padding: 6px 14px;
            border-radius: 8px;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid var(--border);
            background: var(--bg2);
            color: var(--text2);
            text-decoration: none;
            white-space: nowrap;
        }

        .btn-act-text:hover {
            color: var(--text);
            border-color: rgba(255,255,255,0.2);
            background: var(--surface);
        }

        /* Modal */
        .modal-overlay {
            position: fixed;
            inset: 0;
            z-index: 1000;
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(4px);
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.25s ease;
        }
        .modal-overlay.active {
            opacity: 1;
            pointer-events: all;
        }
        .modal {
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 14px;
            width: 90%;
            max-width: 500px;
            max-height: 90vh;
            overflow-y: auto;
            transform: scale(0.92);
            transition: transform 0.3s;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
        }
        .modal-overlay.active .modal {
            transform: scale(1);
        }
        .modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            background: rgba(0, 0, 0, 0.15);
        }
        .modal-title {
            font-size: 16px;
            font-weight: 700;
            color: var(--text);
        }
        .modal-close {
            width: 30px;
            height: 30px;
            border-radius: 7px;
            background: var(--surface);
            border: 1px solid var(--border);
            color: var(--text2);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.2s;
            font-size: 12px;
        }
        .modal-close:hover {
            background: var(--surface2);
            color: var(--text);
            border-color: var(--border-accent);
        }
        .modal-body {
            padding: 22px 24px;
        }
        .form-group {
            margin-bottom: 14px;
        }
        .form-label {
            font-size: 11px;
            color: var(--text3);
            margin-bottom: 6px;
            display: block;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-weight: 600;
        }
        .form-input {
            width: 100%;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 10px;
            padding: 11px 12px;
            color: var(--text);
            font-size: 13px;
            transition: all 0.2s;
        }
        .form-input:focus {
            outline: none;
            border-color: var(--orange);
            box-shadow: 0 0 0 3px var(--orange-glow);
        }
        .form-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 18px;
        }
        .btn-modal {
            border: none;
            cursor: pointer;
            padding: 10px 16px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 600;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-modal-cancel {
            background: var(--surface);
            border: 1px solid var(--border);
            color: var(--text2);
        }
        .btn-modal-cancel:hover {
            background: var(--surface2);
            color: var(--text);
        }
        .btn-modal-submit {
            background: linear-gradient(135deg, var(--orange), #ff8f5f);
            color: #fff;
            box-shadow: 0 0 18px rgba(255,107,53,0.28);
        }
        .btn-modal-submit:hover {
            transform: translateY(-1px);
            box-shadow: 0 0 24px rgba(255,107,53,0.4);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text3);
        }

        .empty-state i {
            font-size: 48px;
            margin-bottom: 16px;
            opacity: 0.3;
        }

        .empty-state p {
            font-size: 14px;
        }

        /* Scrollbar */
        ::-webkit-scrollbar {
            width: 6px;
            height: 6px;
        }
        ::-webkit-scrollbar-track {
            background: transparent;
        }
        ::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,0.1);
            border-radius: 3px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: rgba(255,255,255,0.15);
        }

        @media (max-width: 768px) {
            .container {
                padding: 20px 16px;
            }
            .header-section {
                flex-direction: column;
                align-items: flex-start;
                gap: 16px;
            }
            .table-wrap {
                overflow-x: scroll;
            }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <div class="bg-canvas"></div>
    <div class="grid-overlay"></div>

    <div class="container">
        <!-- Header -->
        <div class="header-section">
            <div class="header-title">
                <div class="header-icon">
                    <i class="fas fa-user-shield"></i>
                </div>
                <h1>Gestion Administrateurs</h1>
            </div>
            <a href="{{ route('admin.admins.create') }}" class="btn-create">
                <i class="fas fa-plus"></i>
                Créer Admin
            </a>
        </div>

        <!-- Alerts -->
        @if(session('success'))
            <div class="alert alert-success">
                <i class="fas fa-check-circle"></i>
                {{ session('success') }}
            </div>
        @endif

        @if(session('error'))
            <div class="alert alert-error">
                <i class="fas fa-exclamation-circle"></i>
                {{ session('error') }}
            </div>
        @endif

        <!-- Table -->
        <div class="table-container">
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>NOM</th>
                            <th>EMAIL</th>
                            <th>RÔLE</th>
                            <th>CRÉATION</th>
                            <th>STATUT</th>
                            <th>ACTIONS</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($admins as $admin)
                            <tr>
                                <td class="td-name">
                                    {{ $admin->full_name }}
                                </td>
                                <td class="td-email">
                                    {{ $admin->email }}
                                </td>
                                <td>
                                    @if($admin->role === 'authoritaire')
                                        <span class="badge badge-yellow">AUTORITAIRE</span>
                                    @else
                                        <span class="badge badge-green">TECHNIQUE</span>
                                    @endif
                                </td>
                                <td>
                                    {{ $admin->created_at ? $admin->created_at->format('d/m/Y') : 'N/A' }}
                                </td>
                                <td>
                                    @if($admin->is_active)
                                        <span class="badge badge-green">ACTIF</span>
                                    @else
                                        <span class="badge badge-orange">INACTIF</span>
                                    @endif
                                </td>
                                <td>
                                    <div class="actions">
                                        <button
                                            type="button"
                                            class="btn-act"
                                            title="Changer le mot de passe"
                                            onclick="openChangePasswordModal('{{ $admin->_id }}', '{{ addslashes($admin->full_name) }}', '{{ $admin->email }}')">
                                            <i class="fas fa-key"></i>
                                        </button>
                                        
                                        <form method="POST" action="{{ route('admin.admins.toggle-active', $admin->_id) }}" style="display: inline;">
                                            @csrf
                                            <button type="submit" class="btn-act-text">
                                                {{ $admin->is_active ? 'Désactiver' : 'Activer' }}
                                            </button>
                                        </form>
                                        
                                        <form method="POST" action="{{ route('admin.admins.destroy', $admin->_id) }}" style="display: inline;" onsubmit="return confirm('Êtes-vous sûr de vouloir supprimer cet administrateur ?');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn-act danger" title="Supprimer">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="empty-state">
                                    <i class="fas fa-users"></i>
                                    <p>Aucun administrateur trouvé.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Modal Changer MDP Admin -->
    <div class="modal-overlay" id="changePasswordModal" onclick="if(event.target===this)closeChangePasswordModal()">
        <div class="modal">
            <div class="modal-header">
                <h3 class="modal-title">Changer le mot de passe</h3>
                <button class="modal-close" type="button" onclick="closeChangePasswordModal()"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-body">
                <form id="changePasswordForm" method="POST" action="">
                    @csrf
                    <div style="background:var(--surface);border:1px solid var(--border);border-radius:9px;padding:13px;margin-bottom:17px;">
                        <div style="font-size:11px;color:var(--text3);margin-bottom:4px;">Administrateur</div>
                        <div style="font-size:13px;font-weight:600;color:var(--text);" id="changePasswordAdminName"></div>
                        <div style="font-size:11px;color:var(--text2);margin-top:3px;" id="changePasswordAdminEmail"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Nouveau mot de passe</label>
                        <input type="password" id="new_password" name="password" class="form-input" placeholder="Minimum 12 caractères" required minlength="12">
                        <div style="font-size:10.5px;color:var(--text3);margin-top:5px;">Min. 12 car. — majuscule, minuscule, chiffre et caractère spécial (@$!%*#?&).</div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Confirmer le mot de passe</label>
                        <input type="password" name="password_confirmation" class="form-input" placeholder="Répétez le mot de passe" required>
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-modal btn-modal-cancel" onclick="closeChangePasswordModal()">Annuler</button>
                        <button type="submit" class="btn-modal btn-modal-submit"><i class="fas fa-key"></i> Changer</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function openChangePasswordModal(id, name, email) {
            const form = document.getElementById('changePasswordForm');
            const baseUrl = '{{ url('/admin/admins') }}';
            form.action = baseUrl + '/' + id + '/reset-password';
            document.getElementById('changePasswordAdminName').textContent = name;
            document.getElementById('changePasswordAdminEmail').textContent = email;
            document.getElementById('changePasswordModal').classList.add('active');
            document.body.style.overflow = 'hidden';
            form.reset();
            setTimeout(() => document.getElementById('new_password').focus(), 100);
        }

        function closeChangePasswordModal() {
            document.getElementById('changePasswordModal').classList.remove('active');
            document.body.style.overflow = '';
            document.getElementById('changePasswordForm').reset();
        }

        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') {
                closeChangePasswordModal();
            }
        });
    </script>
@include('partials.theme-toggle')
</body>
</html>