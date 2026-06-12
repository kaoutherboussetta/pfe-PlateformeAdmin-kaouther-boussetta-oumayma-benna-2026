<!DOCTYPE html>
<html lang="fr" class="trig-app trig-outfit">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trig-Essalama · Admin Technique</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @include('partials.admin_technique_styles')
    </style>
    @include('partials.theme-assets')
</head>
<body>
@include('partials.admin.resolve-header-user', ['headerSourceUser' => $user])
@php
    $headerDisplayName = $headerDisplayName ?? 'Administrateur';
    $headerInitials = $headerInitials ?? 'A';
    $headerAvatarUrl = $headerAvatarUrl ?? null;
    $headerRoleLabel = $headerRoleLabel ?? 'Administrateur';
@endphp
<div class="bg-canvas"></div>
<div class="grid-overlay"></div>

<div class="app">
    @include('partials.admin_technique_sidebar')

    <div class="main">
        @include('partials.admin.navbar', [
            'title' => 'Administration Technique',
            'breadcrumb' => 'Trig-Essalama / <span>Dashboard</span>'
        ])

        <div class="content">
            @if(session('success'))
            <div class="alert alert-success"><i class="fas fa-check-circle"></i><span>{{ session('success') }}</span></div>
            @endif
            @if(session('error'))
            <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i><span>{{ session('error') }}</span></div>
            @endif

            <div class="section-header fade-in">
                <h3>Vue d'ensemble du Système</h3>
                <p>Surveillance et gestion en temps réel de la plateforme Trig-Essalama</p>
            </div>

            <div class="stats-grid">
                <div class="stat-card orange">
                    <div class="stat-top">
                        <div class="stat-label">Gestion Administrateurs</div>
                        <div class="stat-icon-wrap"><i class="fas fa-user-shield"></i></div>
                    </div>
                    <div class="stat-value counter" id="cnt1">{{ $admins_stats['total'] ?? ($stats['authoritaire_admins'] ?? 0) }}</div>
                    <div class="stat-sub">{{ $admins_stats['active'] ?? ($stats['active_autoritaire_admins'] ?? 0) }} actif(s)</div>
                    <div class="stat-bar"><div class="stat-bar-fill"></div></div>
                </div>
                <div class="stat-card yellow">
                    <div class="stat-top">
                        <div class="stat-label">Comptes Citoyens</div>
                        <div class="stat-icon-wrap"><i class="fas fa-users"></i></div>
                    </div>
                    <div class="stat-value">{{ $clients_stats['total'] ?? ($stats['total_citizens'] ?? 0) }}</div>
                    <div class="stat-sub">{{ $clients_stats['active'] ?? ($stats['active_citizens'] ?? 0) }} vérifié(s)</div>
                    <div class="stat-bar"><div class="stat-bar-fill"></div></div>
                </div>
                <div class="stat-card cyan">
                    <div class="stat-top">
                        <div class="stat-label">Intervenants</div>
                        <div class="stat-icon-wrap"><i class="fas fa-hard-hat"></i></div>
                    </div>
                    <div class="stat-value">{{ $intervenants_count_shown ?? 0 }}</div>
                    <div class="stat-sub">Comptes intervenants affichés</div>
                    <div class="stat-bar"><div class="stat-bar-fill"></div></div>
                </div>
            </div>

            <div class="layout-grid">
                <!-- Tables -->
                <div style="display:flex;flex-direction:column;gap:16px;min-width:0;">

                    <!-- Admins -->
                    <div class="card">
                        <div class="card-head">
                            <div class="card-title-wrap">
                                <div class="card-icon"><i class="fas fa-user-shield"></i></div>
                                <span class="card-title">Gestion Administrateurs</span>
                            </div>
                            <div style="display:flex;align-items:center;gap:8px;">
                                <button class="btn-create" onclick="openCreateAdminModal()">
                                    <i class="fas fa-plus"></i> Créer Admin
                                </button>
                            </div>
                        </div>
                        <div class="table-wrap">
                            <table>
                                <thead>
                                    <tr>
                                        <th>NOM COMPLET</th>
                                        <th>EMAIL</th>
                                        <th>TÉLÉPHONE</th>
                                        <th>VILLE</th>
                                        <th>PAYS</th>
                                        <th>RÔLE</th>
                                        <th>CRÉATION</th>
                                        <th>STATUT</th>
                                        <th>ACTIONS</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse($admins ?? [] as $admin)
                                    <tr class="admin-row-clickable" style="cursor:pointer;" onclick="redirectToDashboard(event, '{{ route('admin.dashboard') }}')">
                                        <td><span class="td-name">{{ $admin->full_name ?? ($admin->first_name . ' ' . $admin->last_name) }}</span></td>
                                        <td><span class="td-email td-clip">{{ $admin->email }}</span></td>
                                        <td><span class="td-clip" style="max-width:110px">{{ $admin->phone ?? '—' }}</span></td>
                                        <td><span class="td-clip" style="max-width:100px">{{ $admin->city ?? '—' }}</span></td>
                                        <td><span class="td-clip" style="max-width:100px">{{ $admin->country ?? '—' }}</span></td>
                                        <td><span class="badge badge-yellow">AUTORITAIRE</span></td>
                                        <td style="white-space:nowrap">{{ $admin->created_at ? $admin->created_at->format('d/m/Y') : 'N/A' }}</td>
                                        <td>
                                            <span class="badge {{ $admin->is_active ? 'badge-green' : 'badge-orange' }}">
                                                {{ $admin->is_active ? 'ACTIF' : 'INACTIF' }}
                                            </span>
                                        </td>
                                        <td>
                                            <div class="actions" onclick="event.stopPropagation();">
                                                <button
                                                    type="button"
                                                    class="btn-act js-open-change-password"
                                                    title="Changer le mot de passe"
                                                    data-admin-id="{{ $admin->id }}"
                                                    data-admin-name="{{ $admin->full_name ?? ($admin->first_name . ' ' . $admin->last_name) }}"
                                                    data-admin-email="{{ $admin->email }}">
                                                    <i class="fas fa-key"></i>
                                                </button>
                                                <form method="POST" action="{{ route('admin.autoritaire.toggle', $admin->id) }}" style="display:inline;">
                                                    @csrf
                                                    <button type="submit" class="btn-sm-text">{{ $admin->is_active ? 'Désactiver' : 'Activer' }}</button>
                                                </form>
                                                <form method="POST" action="{{ route('admin.autoritaire.delete', $admin->id) }}" style="display:inline;"
                                                    onsubmit="return confirm('Supprimer cet administrateur ? Action irréversible.')">
                                                    @csrf @method('DELETE')
                                                    <button type="submit" class="btn-act danger"><i class="fas fa-trash"></i></button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                    @empty
                                    <tr><td colspan="9" style="text-align:center;padding:26px;color:var(--text3);">Aucun administrateur trouvé</td></tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Clients -->
                    <div class="card">
                        <div class="card-head">
                            <div class="card-title-wrap">
                                <div class="card-icon"><i class="fas fa-id-card"></i></div>
                                <span class="card-title">Comptes Citoyens</span>
                            </div>
                            <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
                                <div class="search-container">
                                    <input type="text" id="searchClients" class="search-input" placeholder="Rechercher un client...">
                                    <i class="fas fa-search search-icon"></i>
                                    <button type="button" class="search-clear" id="clearSearch"><i class="fas fa-times"></i></button>
                                </div>
                                <span class="client-count" id="clientCount">{{ count($clients ?? []) }} client(s)</span>
                            </div>
                        </div>
                        <div class="table-wrap table-wrap--citizens-scroll">
                            <table>
                                <thead>
                                    <tr>
                                        <th>NOM</th>
                                        <th>PRÉNOM</th>
                                        <th>EMAIL</th>
                                        <th>STATUT</th>
                                        <th>INSCRIPTION</th>
                                        <th>ACTIONS</th>
                                    </tr>
                                </thead>
                                <tbody id="clientsTableBody">
                                    {{-- Debug temporaire --}}
                                    @if(config('app.debug'))
                                        <!-- Debug: Nombre de clients: {{ count($clients ?? []) }} -->
                                    @endif
                                    @forelse($clients ?? [] as $client)
                                    @php
                                        // Accéder aux attributs directement (MongoDB peut utiliser différents formats)
                                        $clientArray = $client->toArray();
                                        
                                        // Récupérer le nom complet depuis fullName, name, ou combiner first_name/last_name
                                        $fullName = $clientArray['fullName'] ?? $clientArray['name'] ?? $client->fullName ?? $client->name ?? '';
                                        if (empty($fullName)) {
                                            $first = $clientArray['first_name'] ?? $client->first_name ?? '';
                                            $last = $clientArray['last_name'] ?? $client->last_name ?? '';
                                            $fullName = trim($first . ' ' . $last);
                                        }
                                        
                                        // Séparer le nom complet en prénom et nom
                                        $nameParts = explode(' ', trim($fullName), 2);
                                        $prenom = $nameParts[0] ?? '';
                                        $nom = $nameParts[1] ?? '';
                                        
                                        // Si pas de nom séparé et qu'on a un fullName, mettre tout dans le prénom
                                        if (empty($nom) && !empty($fullName) && count($nameParts) == 1) {
                                            $prenom = $fullName;
                                            $nom = '';
                                        }
                                        
                                        // Pour l'affichage, utiliser les champs existants ou les valeurs séparées
                                        $displayNom = $clientArray['last_name'] ?? $client->last_name ?? $nom;
                                        $displayPrenom = $clientArray['first_name'] ?? $client->first_name ?? $prenom;
                                        
                                        // Si toujours vide, utiliser fullName
                                        if (empty($displayNom) && empty($displayPrenom) && !empty($fullName)) {
                                            $displayPrenom = $fullName;
                                        }
                                        
                                        // Pour la recherche
                                        $searchNom = strtolower($displayNom ?: '');
                                        $searchPrenom = strtolower($displayPrenom ?: '');
                                        $searchFullName = strtolower($fullName ?: '');
                                        
                                        // Email
                                        $email = $clientArray['email'] ?? $client->email ?? 'N/A';
                                        
                                        // ID
                                        $clientId = $clientArray['_id'] ?? $client->_id ?? $client->id ?? '';
                                        
                                        // Dates
                                        $createdAt = $clientArray['createdAt'] ?? $client->createdAt ?? $clientArray['created_at'] ?? $client->created_at ?? null;
                                        $updatedAt = $clientArray['updatedAt'] ?? $client->updatedAt ?? $clientArray['updated_at'] ?? $client->updated_at ?? null;
                                        
                                        // Email vérifié
                                        $emailVerified = $clientArray['email_verified_at'] ?? $client->email_verified_at ?? null;
                                    @endphp
                                    <tr class="client-row"
                                        data-nom="{{ $searchNom }}"
                                        data-prenom="{{ $searchPrenom }}"
                                        data-fullname="{{ $searchFullName }}"
                                        data-email="{{ strtolower($email) }}">
                                        <td><span class="td-name">{{ $displayNom ?: 'N/A' }}</span></td>
                                        <td>{{ $displayPrenom ?: 'N/A' }}</td>
                                        <td><span class="td-email td-clip" style="max-width:150px">{{ $email }}</span></td>
                                        <td>
                                            <span class="badge {{ $emailVerified ? 'badge-green' : 'badge-orange' }}">
                                                {{ $emailVerified ? 'VÉRIFIÉ' : 'EN ATTENTE' }}
                                            </span>
                                        </td>
                                        <td style="white-space:nowrap">
                                            @if($createdAt)
                                                @php
                                                    if (is_string($createdAt)) {
                                                        $createdDate = \Carbon\Carbon::parse($createdAt);
                                                    } elseif (is_object($createdAt) && method_exists($createdAt, 'format')) {
                                                        $createdDate = $createdAt;
                                                    } else {
                                                        $createdDate = \Carbon\Carbon::createFromTimestamp($createdAt);
                                                    }
                                                @endphp
                                                {{ $createdDate->format('d/m/Y') }}
                                            @else N/A @endif
                                        </td>
                                        <td>
                                            <div class="actions">
                                                <button type="button" class="btn-sm-text"
                                                    onclick="showClientDetails('{{ $clientId }}','{{ addslashes($displayNom) }}','{{ addslashes($displayPrenom) }}','{{ addslashes($email) }}','','','','','{{ $createdAt ? (is_string($createdAt) ? \Carbon\Carbon::parse($createdAt)->format('d/m/Y H:i') : (is_object($createdAt) && method_exists($createdAt, 'format') ? $createdAt->format('d/m/Y H:i') : 'N/A')) : 'N/A' }}','{{ $updatedAt ? (is_string($updatedAt) ? \Carbon\Carbon::parse($updatedAt)->format('d/m/Y H:i') : (is_object($updatedAt) && method_exists($updatedAt, 'format') ? $updatedAt->format('d/m/Y H:i') : 'N/A')) : 'N/A' }}')">
                                                    Détails
                                                </button>
                                                @if($clientId)
                                                <form method="POST" action="{{ route('citizen.delete', $clientId) }}" style="display:inline;"
                                                    onsubmit="return confirm('Supprimer ce compte citoyen ? Action irréversible.')">
                                                    @csrf @method('DELETE')
                                                    <button type="submit" class="btn-act danger"><i class="fas fa-trash"></i></button>
                                                </form>
                                                @endif
                                            </div>
                                        </td>
                                    </tr>
                                    @empty
                                    <tr id="noClientsMessage">
                                        <td colspan="6" style="text-align:center;padding:26px;color:var(--text3);">Aucun compte citoyen trouvé</td>
                                    </tr>
                                    @endforelse
                                    <tr id="noSearchResults" style="display:none;">
                                        <td colspan="6" style="text-align:center;padding:26px;color:var(--text3);">Aucun résultat pour votre recherche</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Intervenants (même présentation que Comptes citoyens) -->
                    <div class="card">
                        <div class="card-head">
                            <div class="card-title-wrap">
                                <div class="card-icon"><i class="fas fa-hard-hat"></i></div>
                                <span class="card-title">Intervenants</span>
                            </div>
                            <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap;">
                                <div class="search-container">
                                    <input type="text" id="searchIntervenants" class="search-input" placeholder="Rechercher un intervenant...">
                                    <i class="fas fa-search search-icon"></i>
                                    <button type="button" class="search-clear" id="clearSearchIntervenants"><i class="fas fa-times"></i></button>
                                </div>
                                <span class="client-count" id="intervenantCount">{{ $intervenants_count_shown ?? 0 }} intervenant(s)</span>
                            </div>
                        </div>
                        <div class="table-wrap table-wrap--citizens-scroll">
                            <table>
                                <thead>
                                    <tr>
                                        <th>NOM</th>
                                        <th>PRÉNOM</th>
                                        <th>EMAIL</th>
                                        <th>STATUT</th>
                                        <th>INSCRIPTION</th>
                                        <th>ACTIONS</th>
                                    </tr>
                                </thead>
                                <tbody id="intervenantsTableBody">
                                    @forelse(($intervenants ?? collect()) as $iv)
                                        @php
                                            $ivNom = strtolower($iv['nom'] ?? '');
                                            $ivPrenom = strtolower($iv['prenom'] ?? '');
                                            $ivEmail = strtolower($iv['email'] ?? '');
                                            $ivFull = strtolower(trim(($iv['prenom'] ?? '').' '.($iv['nom'] ?? '')));
                                            $ivId = (string) ($iv['id'] ?? data_get($iv, 'raw._id', ''));
                                            $ivCollection = (string) ($iv['collection'] ?? data_get($iv, 'raw._collection', ''));
                                        @endphp
                                        <tr class="intervenant-row"
                                            data-nom="{{ $ivNom }}"
                                            data-prenom="{{ $ivPrenom }}"
                                            data-fullname="{{ $ivFull }}"
                                            data-email="{{ $ivEmail }}">
                                            <td><span class="td-name">{{ $iv['nom'] ?? 'N/A' }}</span></td>
                                            <td>{{ $iv['prenom'] ?? '—' }}</td>
                                            <td><span class="td-email td-clip" style="max-width:180px">{{ $iv['email'] ?? 'N/A' }}</span></td>
                                            <td>
                                                <span class="badge {{ ($iv['statut_ok'] ?? false) ? 'badge-green' : 'badge-orange' }}">
                                                    {{ ($iv['statut_ok'] ?? false) ? ($iv['statut_label'] ?? 'VÉRIFIÉ') : 'EN ATTENTE' }}
                                                </span>
                                            </td>
                                            <td style="white-space:nowrap">{{ $iv['inscription'] ?? 'N/A' }}</td>
                                            <td>
                                                <div class="actions">
                                                    <button type="button" class="btn-sm-text" onclick="showIntervenantDetails(@js($iv['raw'] ?? []))">Détails</button>
                                                    @if($ivId !== '' && $ivCollection !== '')
                                                    <form method="POST" action="{{ route('intervenant.delete', ['collection' => $ivCollection, 'id' => $ivId]) }}" style="display:inline;"
                                                        onsubmit="return confirm('Supprimer ce compte intervenant ? Action irréversible.')">
                                                        @csrf
                                                        @method('DELETE')
                                                        <button type="submit" class="btn-act danger" title="Supprimer"><i class="fas fa-trash"></i></button>
                                                    </form>
                                                    @endif
                                                </div>
                                            </td>
                                        </tr>
                                    @empty
                                        <tr id="noIntervenantsMessage">
                                            <td colspan="6" style="text-align:center;padding:26px;color:var(--text3);">Aucun intervenant trouvé (collections <code>intervenants</code> / <code>intervenant</code>).</td>
                                        </tr>
                                    @endforelse
                                    <tr id="noIntervenantSearchResults" style="display:none;">
                                        <td colspan="6" style="text-align:center;padding:26px;color:var(--text3);">Aucun résultat pour votre recherche</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Right -->
                <div class="right-col">
                    <div class="card">
                        <div class="card-head">
                            <div class="card-title-wrap">
                                <div class="card-icon"><i class="fas fa-database"></i></div>
                                <span class="card-title">Sauvegarde & Stockage</span>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="info-row">
                                <span class="info-row-label"><i class="fas fa-clock"></i>Dernière sauvegarde</span>
                                <span class="info-row-val">
                                    @if($last_backup ?? null)
                                        @php $diff = now()->diffInHours($last_backup); $diffMin = now()->diffInMinutes($last_backup); @endphp
                                        @if($diffMin < 60) {{ $diffMin }} min
                                        @elseif($diff < 24) {{ $diff }}h
                                        @else {{ now()->diffInDays($last_backup) }} j @endif
                                    @else N/A @endif
                                </span>
                            </div>
                            <div class="info-row">
                                <span class="info-row-label"><i class="fas fa-hdd"></i>Stockage utilisé</span>
                                <span class="info-row-val">{{ number_format($storage['used_gb'] ?? 0, 2) }} GB</span>
                            </div>
                            <div class="info-row">
                                <span class="info-row-label"><i class="fas fa-server"></i>Espace libre</span>
                                <span class="info-row-val">{{ number_format($storage['free_gb'] ?? 0, 2) }} GB</span>
                            </div>
                            <div style="margin-top:14px">
                                <div style="display:flex;justify-content:space-between;margin-bottom:5px">
                                    <span style="font-size:11px;color:var(--text2)">Utilisation disque</span>
                                    <span style="font-size:11px;font-weight:700;color:var(--orange)">{{ number_format($storage['percent'] ?? 0, 1) }}%</span>
                                </div>
                                <div class="storage-bar">
                                    <div class="storage-fill" style="width:{{ min($storage['percent'] ?? 0, 100) }}%"></div>
                                </div>
                                <div class="storage-info">
                                    <span>0 GB</span>
                                    <span>{{ number_format($storage['used_gb'] ?? 0, 1) }}/{{ number_format($storage['total_gb'] ?? 0, 1) }} GB</span>
                                    <span>{{ number_format($storage['total_gb'] ?? 0, 1) }} GB</span>
                                </div>
                            </div>
                            <form method="POST" action="{{ route('admin.force_backup') }}">
                                @csrf
                                <button type="submit" class="btn-full"
                                    onclick="this.disabled=true;this.innerHTML='<i class=\'fas fa-spinner fa-spin\'></i> En cours...';this.form.submit()">
                                    <i class="fas fa-database"></i> Forcer une sauvegarde
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Modal Créer Admin -->
<div class="modal-overlay" id="createAdminModal" onclick="if(event.target===this)closeCreateAdminModal()">
    <div class="modal">
        <div class="modal-header">
            <h3 class="modal-title">Créer un Administrateur</h3>
            <button class="modal-close" onclick="closeCreateAdminModal()"><i class="fas fa-times"></i></button>
        </div>
        <div class="modal-body">
            <form id="createAdminForm" method="POST" action="{{ route('admin.autoritaire.store') }}">
                @csrf
                <div class="form-group">
                    <label class="form-label">Prénom</label>
                    <input type="text" name="first_name" class="form-input" placeholder="Prénom" required value="{{ old('first_name') }}">
                    @error('first_name')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Nom</label>
                    <input type="text" name="last_name" class="form-input" placeholder="Nom" required value="{{ old('last_name') }}">
                    @error('last_name')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" name="email" class="form-input" placeholder="email@example.com" required value="{{ old('email') }}">
                    @error('email')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Téléphone</label>
                    <input type="tel" name="phone" class="form-input" placeholder="+216 XX XXX XXX" required value="{{ old('phone') }}">
                    @error('phone')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="profile-grid" style="margin-bottom:17px;">
                    <div class="form-group" style="margin-bottom:0;">
                        <label class="form-label">Ville</label>
                        <input type="text" name="city" class="form-input" placeholder="Ville" required value="{{ old('city') }}">
                        @error('city')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                    </div>
                    <div class="form-group" style="margin-bottom:0;">
                        <label class="form-label">Pays</label>
                        <input type="text" name="country" class="form-input" placeholder="Pays" required value="{{ old('country') }}">
                        @error('country')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">Mot de passe</label>
                    <input type="password" name="password" class="form-input" placeholder="Minimum 12 caractères" required minlength="12">
                    @error('password')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Code de sécurité</label>
                    <input type="password" name="creation_code" id="creation_code" class="form-input" placeholder="Code secret requis pour créer un administrateur" required maxlength="8" style="text-transform:uppercase;letter-spacing:2px;font-weight:600;">
                    <div style="font-size:10.5px;color:var(--text3);margin-top:5px;">
                        Ce code est connu uniquement des administrateurs techniques autorisés. (8 caractères)
                    </div>
                    @error('creation_code')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Confirmer le mot de passe</label>
                    <input type="password" name="password_confirmation" class="form-input" placeholder="Répétez le mot de passe" required>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn-modal btn-modal-cancel" onclick="closeCreateAdminModal()">Annuler</button>
                    <button type="submit" class="btn-modal btn-modal-submit"><i class="fas fa-save"></i> Créer</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Changer MDP Admin -->
<div class="modal-overlay" id="changePasswordModal" onclick="if(event.target===this)closeChangePasswordModal()">
    <div class="modal">
        <div class="modal-header">
            <h3 class="modal-title">Changer le mot de passe</h3>
            <button class="modal-close" onclick="closeChangePasswordModal()"><i class="fas fa-times"></i></button>
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
                    <div style="font-size:10.5px;color:var(--text3);margin-top:5px;">Min. 12 car. — majuscule, minuscule, chiffre et caractère spécial.</div>
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

<!-- Modal Changer MDP Utilisateur Connecté -->
<div class="modal-overlay" id="changeUserPasswordModal" onclick="if(event.target===this)closeChangeUserPasswordModal()">
    <div class="modal">
        <div class="modal-header">
            <h3 class="modal-title">Changer mon mot de passe</h3>
            <button class="modal-close" onclick="closeChangeUserPasswordModal()"><i class="fas fa-times"></i></button>
        </div>
        <div class="modal-body">
            <form id="changeUserPasswordForm" method="POST" action="{{ route('user.change-password') }}">
                @csrf
                <div style="background:var(--surface);border:1px solid var(--border);border-radius:9px;padding:13px;margin-bottom:17px;">
                    <div style="font-size:11px;color:var(--text3);margin-bottom:4px;">Votre compte</div>
                    <div style="font-size:13px;font-weight:600;color:var(--text);" id="changeUserPasswordName"></div>
                    <div style="font-size:11px;color:var(--text2);margin-top:3px;" id="changeUserPasswordEmail"></div>
                </div>
                <div class="form-group">
                    <label class="form-label">Nouveau mot de passe</label>
                    <input type="password" id="new_user_password" name="password" class="form-input" placeholder="Minimum 12 caractères" required minlength="12">
                    <div style="font-size:10.5px;color:var(--text3);margin-top:5px;">Min. 12 car. — majuscule, minuscule, chiffre et caractère spécial (@$!%*#?&).</div>
                    @error('password')
                        <div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>
                    @enderror
                </div>
                <div class="form-group">
                    <label class="form-label">Confirmer le mot de passe</label>
                    <input type="password" name="password_confirmation" class="form-input" placeholder="Répétez le mot de passe" required>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn-modal btn-modal-cancel" onclick="closeChangeUserPasswordModal()">Annuler</button>
                    <button type="submit" class="btn-modal btn-modal-submit"><i class="fas fa-key"></i> Changer mon mot de passe</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Modal Profil Utilisateur -->
<div class="modal-overlay" id="profileModal" onclick="if(event.target===this)closeProfileModal()">
    <div class="modal">
        <div class="modal-header">
            <h3 class="modal-title">Mon profil</h3>
            <button class="modal-close" onclick="closeProfileModal()"><i class="fas fa-times"></i></button>
        </div>
        <div class="modal-body">
            <div class="profile-layout">
                <!-- ================= LEFT CARD ================= -->
                <div class="profile-card">
                    @php
                        $profileName = $user->name ?? 'Admin Trig Essalama';
                        $initials = collect(explode(' ', $profileName))->map(fn($p) => mb_substr($p, 0, 1))->join('');
                        if (empty($initials)) $initials = 'A';
                    @endphp
                    <div class="profile-avatar">{{ $initials }}</div>
                    <div class="profile-name">{{ $profileName }}</div>
                    <div class="profile-email">{{ $user->email ?? 'admin@trig-essalama.tn' }}</div>
                    <div class="profile-role">Super Admin</div>

                    <!-- STATS -->
                    <div class="profile-meta">
                        <div class="profile-meta-item">
                            <div class="profile-meta-label">Alertes gérées</div>
                            <div class="profile-meta-value">1,245</div>
                        </div>
                        <div class="profile-meta-item">
                            <div class="profile-meta-label">Interventions</div>
                            <div class="profile-meta-value">320</div>
                        </div>
                        <div class="profile-meta-item">
                            <div class="profile-meta-label">Zones surveillées</div>
                            <div class="profile-meta-value">58</div>
                        </div>
                        <div class="profile-meta-item">
                            <div class="profile-meta-label">Statut</div>
                            <div class="profile-meta-value">🟢 Actif</div>
                        </div>
                    </div>

                    <!-- ACTIONS -->
                    <div class="profile-actions">
                        @if(isset($user) && $user->_id)
                            <button class="btn-profile primary" type="button" onclick="openChangeUserPasswordModal('{{ addslashes($user->name ?? 'Admin Technique') }}', '{{ $user->email ?? '' }}')">Modifier profil</button>
                        @endif
                        <button class="btn-profile secondary" type="button">Sécurité</button>
                        <form method="POST" action="{{ route('logout') }}" style="margin:0;">
                            @csrf
                            <button type="submit" class="btn-profile secondary">Déconnexion</button>
                        </form>
                    </div>
                </div>

                <!-- ================= RIGHT CONTENT ================= -->
                <div>
                    <!-- INFOS PERSONNELLES -->
                    <div class="profile-section">
                        <div class="profile-section-title">👤 Informations personnelles</div>
                        <div class="profile-grid">
                            <div>
                                <div class="profile-field-label">Nom complet</div>
                                <div class="profile-field-value">{{ $profileName }}</div>
                            </div>
                            <div>
                                <div class="profile-field-label">Téléphone</div>
                                <div class="profile-field-value">{{ $user->phone ?? '+216 99 999 999' }}</div>
                            </div>
                            <div>
                                <div class="profile-field-label">Email</div>
                                <div class="profile-field-value">{{ $user->email ?? 'admin@trig.tn' }}</div>
                            </div>
                            <div>
                                <div class="profile-field-label">Région</div>
                                <div class="profile-field-value">{{ $user->region ?? 'Tunis' }}</div>
                            </div>
                        </div>
                    </div>

                    <!-- PERMISSIONS -->
                    <div class="profile-section">
                        <div class="profile-section-title">🔐 Permissions</div>
                        <div class="profile-grid">
                            <div class="profile-field-value">✔ Gestion des alertes</div>
                            <div class="profile-field-value">✔ Accès IA</div>
                            <div class="profile-field-value">✔ Gestion utilisateurs</div>
                            <div class="profile-field-value">✔ Tableau de bord complet</div>
                        </div>
                    </div>

                    <!-- ACTIVITÉ -->
                    <div class="profile-section">
                        <div class="profile-section-title">📊 Activité récente</div>
                        <div class="activity-list">
                            <div class="activity-item">🚧 Intervention validée – Route X</div>
                            <div class="activity-item">⚠️ Alerte envoyée – Zone inondation</div>
                            <div class="activity-item">🤖 Analyse IA exécutée</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    function animateCounter(el, target, duration = 1200) {
        let start = 0, step = target / (duration / 16);
        const t = setInterval(() => {
            start += step;
            if (start >= target) { el.textContent = target; clearInterval(t); }
            else el.textContent = Math.floor(start);
        }, 16);
    }
    window.addEventListener('load', () => {
        const c = document.getElementById('cnt1');
        if (c) animateCounter(c, parseInt(c.textContent) || 0);
    });

    function openCreateAdminModal() { document.getElementById('createAdminModal').classList.add('active'); document.body.style.overflow = 'hidden'; }
    function closeCreateAdminModal() { document.getElementById('createAdminModal').classList.remove('active'); document.body.style.overflow = ''; document.getElementById('createAdminForm').reset(); }

    function openChangePasswordModal(id, name, email) {
        const form = document.getElementById('changePasswordForm');
        const baseUrl = '{{ url("/") }}';
        form.action = baseUrl + '/admin/autoritaire/' + id + '/reset-password';
        document.getElementById('changePasswordAdminName').textContent = name;
        document.getElementById('changePasswordAdminEmail').textContent = email;
        document.getElementById('changePasswordModal').classList.add('active');
        document.body.style.overflow = 'hidden';
        form.reset();
        setTimeout(() => document.getElementById('new_password').focus(), 100);
    }
    function closeChangePasswordModal() { document.getElementById('changePasswordModal').classList.remove('active'); document.body.style.overflow = ''; document.getElementById('changePasswordForm').reset(); }

    function openChangeUserPasswordModal(name, email) {
        document.getElementById('changeUserPasswordName').textContent = name;
        document.getElementById('changeUserPasswordEmail').textContent = email;
        document.getElementById('changeUserPasswordModal').classList.add('active');
        document.body.style.overflow = 'hidden';
        document.getElementById('changeUserPasswordForm').reset();
        setTimeout(() => document.getElementById('new_user_password').focus(), 100);
    }
    function closeChangeUserPasswordModal() {
        document.getElementById('changeUserPasswordModal').classList.remove('active');
        document.body.style.overflow = '';
        document.getElementById('changeUserPasswordForm').reset();
    }

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
            closeCreateAdminModal();
            closeChangePasswordModal();
            closeChangeUserPasswordModal();
            closeProfileModal();
        }
    });

    function showClientDetails(id, nom, prenom, email, tel, adresse, ville, cp, created, updated) {
        alert(`Détails du client\n\nID: ${id}\nNom: ${nom} ${prenom}\nEmail: ${email}\nTéléphone: ${tel}\nAdresse: ${adresse}\nVille: ${ville} — ${cp}\nCréé le: ${created}\nMis à jour: ${updated}`);
    }

    function redirectToDashboard(event, url) {
        // Ne pas rediriger si on clique sur un bouton ou un formulaire
        if (event.target.closest('button') || event.target.closest('form') || event.target.closest('.actions')) {
            return;
        }
        window.location.href = url;
    }

    // Convertir automatiquement le code de sécurité en majuscules
    document.addEventListener('DOMContentLoaded', () => {
        @if($errors->hasAny(['first_name', 'last_name', 'email', 'phone', 'city', 'country', 'password', 'password_confirmation', 'creation_code']))
        openCreateAdminModal();
        @endif
        const creationCodeInput = document.getElementById('creation_code');
        if (creationCodeInput) {
            creationCodeInput.addEventListener('input', function() {
                this.value = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
            });
        }

        const changePasswordButtons = document.querySelectorAll('.js-open-change-password');
        changePasswordButtons.forEach(button => {
            button.addEventListener('click', function (event) {
                event.preventDefault();
                event.stopPropagation();
                openChangePasswordModal(
                    this.dataset.adminId,
                    this.dataset.adminName || '',
                    this.dataset.adminEmail || ''
                );
            });
        });
    });

    document.addEventListener('DOMContentLoaded', () => {
        const input = document.getElementById('searchClients');
        const clearBtn = document.getElementById('clearSearch');
        const rows = document.querySelectorAll('.client-row');
        const noResults = document.getElementById('noSearchResults');
        const countEl = document.getElementById('clientCount');
        const total = rows.length;

        function filter() {
            const q = input.value.toLowerCase().trim();
            let vis = 0;
            rows.forEach(r => {
                const match = !q || 
                    (r.dataset.nom && r.dataset.nom.includes(q)) ||
                    (r.dataset.prenom && r.dataset.prenom.includes(q)) ||
                    (r.dataset.fullname && r.dataset.fullname.includes(q)) ||
                    (r.dataset.email && r.dataset.email.includes(q));
                r.style.display = match ? '' : 'none';
                if (match) vis++;
            });
            if (noResults) noResults.style.display = (q && vis === 0) ? 'table-row' : 'none';
            if (countEl) countEl.textContent = q ? `${vis} résultat(s) / ${total}` : `${total} client(s)`;
            if (clearBtn) clearBtn.style.display = q ? 'block' : 'none';
        }
        if (input) {
            input.addEventListener('input', filter);
            if (clearBtn) clearBtn.onclick = () => { input.value = ''; filter(); input.focus(); };
        }
    });

    function showIntervenantDetails(row) {
        try {
            const copy = Object.assign({}, row || {});
            delete copy.__search;
            alert(JSON.stringify(copy, null, 2));
        } catch (e) {
            alert('Impossible d’afficher le détail.');
        }
    }

    document.addEventListener('DOMContentLoaded', () => {
        const inputIv = document.getElementById('searchIntervenants');
        const clearIv = document.getElementById('clearSearchIntervenants');
        const rowsIv = document.querySelectorAll('.intervenant-row');
        const noIv = document.getElementById('noIntervenantSearchResults');
        const cntIv = document.getElementById('intervenantCount');
        const totalIv = rowsIv.length;

        function filterIv() {
            if (!inputIv) return;
            const q = inputIv.value.toLowerCase().trim();
            let vis = 0;
            rowsIv.forEach(function (r) {
                const match = !q ||
                    (r.dataset.nom && r.dataset.nom.includes(q)) ||
                    (r.dataset.prenom && r.dataset.prenom.includes(q)) ||
                    (r.dataset.fullname && r.dataset.fullname.includes(q)) ||
                    (r.dataset.email && r.dataset.email.includes(q));
                r.style.display = match ? '' : 'none';
                if (match) vis++;
            });
            if (noIv) noIv.style.display = (q && vis === 0) ? 'table-row' : 'none';
            if (cntIv) cntIv.textContent = q ? (vis + ' résultat(s) / ' + totalIv) : (totalIv + ' intervenant(s)');
            if (clearIv) clearIv.style.display = q ? 'block' : 'none';
        }
        if (inputIv) {
            inputIv.addEventListener('input', filterIv);
            if (clearIv) clearIv.onclick = function () { inputIv.value = ''; filterIv(); inputIv.focus(); };
        }
    });

    function openProfileModal() {
        const modal = document.getElementById('profileModal');
        if (!modal) return;
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    function closeProfileModal() {
        const modal = document.getElementById('profileModal');
        if (!modal) return;
        modal.classList.remove('active');
        document.body.style.overflow = '';
    }
</script>
@include('partials.theme-toggle')
</body>
