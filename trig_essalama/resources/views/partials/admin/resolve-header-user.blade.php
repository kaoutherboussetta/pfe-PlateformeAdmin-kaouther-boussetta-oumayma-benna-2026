@php
    // Peut être passé explicitement (évite tout souci de portée) : @include(..., ['headerSourceUser' => $user])
    $u = $headerSourceUser ?? ($user ?? null);

    $headerDisplayName = 'Administrateur';
    $headerInitials = 'A';
    $headerAvatarUrl = null;
    $apFirstName = '';
    $apLastName = '';
    $headerRoleLabel = 'Administrateur';

    $genericNames = [
        'administrateur',
        'administrateur autoritaire',
        'admin',
        'admin autoritaire',
        'admin autorisateur',
    ];

    $isGenericName = function (string $name) use ($genericNames): bool {
        $t = mb_strtolower(trim($name), 'UTF-8');

        return $t === '' || in_array($t, $genericNames, true);
    };

    $sessionUserData = session('admin_user_data', []);
    $sessionFirstName = trim((string) (session('admin_first_name', '') ?: data_get($sessionUserData, 'first_name', '')));
    $sessionLastName = trim((string) (session('admin_last_name', '') ?: data_get($sessionUserData, 'last_name', '')));
    $sessionFullName = trim(implode(' ', array_filter([$sessionFirstName, $sessionLastName])));

    // Aucun modèle : afficher au minimum ce qui est en session (connexion admin autoritaire)
    if (! $u && session('autoritaire_authenticated')) {
        $headerDisplayName = $sessionFullName !== '' ? $sessionFullName : trim((string) session('admin_name', ''));
        if ($headerDisplayName === '') {
            $headerDisplayName = trim((string) session('admin_email', ''));
        }
        if ($headerDisplayName === '') {
            $headerDisplayName = 'Administrateur';
        }
        $headerRoleLabel = 'Administrateur Autoritaire';
        $parts = preg_split('/\s+/', $headerDisplayName) ?: [];
        $firstTok = (string) ($parts[0] ?? 'A');
        $lastTok = count($parts) > 1 ? (string) end($parts) : '';
        $headerInitials = strtoupper(substr($firstTok, 0, 1).substr($lastTok, 0, 1));
        if (trim($headerInitials) === '') {
            $headerInitials = 'A';
        }
        $apFirstName = $sessionFirstName !== '' ? $sessionFirstName : ($parts[0] ?? '');
        $apLastName = $sessionLastName !== '' ? $sessionLastName : (count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : '');
    } elseif ($u) {
        $fn = trim((string) data_get($u, 'first_name', data_get($u, 'prenom', data_get($u, 'firstname', ''))));
        $ln = trim((string) data_get($u, 'last_name', data_get($u, 'nom', data_get($u, 'lastname', data_get($u, 'family_name', '')))));

        $fromParts = trim(implode(' ', array_filter([$fn, $ln])));

        if ($u instanceof \App\Models\AdminAutoritaire) {
            $headerDisplayName = $fromParts;
            if ($headerDisplayName === '') {
                $headerDisplayName = trim((string) ($u->full_name ?? ''));
            }
            if ($headerDisplayName === '') {
                $headerDisplayName = trim((string) ($u->name ?? ''));
            }
        } else {
            $headerDisplayName = trim((string) ($u->name ?? ''));
            if ($fromParts !== '' && $isGenericName($headerDisplayName)) {
                $headerDisplayName = $fromParts;
            }
            if ($headerDisplayName === '') {
                $headerDisplayName = $fromParts;
            }
            if ($headerDisplayName === '' && $u instanceof \App\Models\AdminAutoritaireSession) {
                $headerDisplayName = trim((string) $u->getFullNameAttribute());
            }
            if ($headerDisplayName === '') {
                $headerDisplayName = trim((string) ($u->full_name ?? ''));
            }
        }

        if ($headerDisplayName === '' && session('autoritaire_authenticated')) {
            $headerDisplayName = trim((string) session('admin_name', ''));
        }
        if ($headerDisplayName === '') {
            $headerDisplayName = trim((string) ($u->email ?? ''));
        }
        if ($headerDisplayName === '') {
            $headerDisplayName = 'Administrateur';
        }

        // Session : nom posé à la connexion (souvent fiable) si le libellé en base est vide ou générique
        if ($sessionFullName !== '' && $isGenericName($headerDisplayName)) {
            $headerDisplayName = $sessionFullName;
        }

        if ($isGenericName($headerDisplayName)) {
            $sessionEmail = strtolower(trim((string) session('admin_email', '')));
            if ($sessionEmail !== '') {
                try {
                    $sessionAdmin = \App\Models\Admin::where('email', $sessionEmail)->first()
                        ?? \App\Models\User::where('email', $sessionEmail)->first()
                        ?? \App\Models\AdminAutoritaire::where('email', $sessionEmail)->first();
                    if ($sessionAdmin) {
                        $dbFirst = trim((string) data_get($sessionAdmin, 'first_name', data_get($sessionAdmin, 'prenom', '')));
                        $dbLast = trim((string) data_get($sessionAdmin, 'last_name', data_get($sessionAdmin, 'nom', '')));
                        $dbFullName = trim(implode(' ', array_filter([$dbFirst, $dbLast])));
                        if ($dbFullName !== '') {
                            $headerDisplayName = $dbFullName;
                            $apFirstName = $dbFirst;
                            $apLastName = $dbLast;
                        }
                    }
                } catch (\Throwable) {
                    // Garder le libellé existant si MongoDB est indisponible.
                }
            }
        }

        if (session('autoritaire_authenticated')) {
            $sn = trim((string) session('admin_name', ''));
            if ($sn !== '' && $isGenericName($headerDisplayName)) {
                $headerDisplayName = $sn;
            }
        }

        $parts = preg_split('/\s+/', $headerDisplayName) ?: [];
        $firstTok = (string) ($parts[0] ?? 'A');
        $lastTok = count($parts) > 1 ? (string) end($parts) : '';
        $headerInitials = strtoupper(substr($firstTok, 0, 1).substr($lastTok, 0, 1));
        if (trim($headerInitials) === '') {
            $headerInitials = 'A';
        }

        $rawAvatar = trim((string) ($u->avatar_url ?? ''));
        $headerAvatarUrl = $rawAvatar !== '' ? $rawAvatar : null;

        $apFirstName = $sessionFirstName !== '' ? $sessionFirstName : ($fn !== '' ? $fn : (trim((string) ($u->first_name ?? ''))));
        $apLastName = $sessionLastName !== '' ? $sessionLastName : ($ln !== '' ? $ln : (trim((string) ($u->last_name ?? ''))));
        if ($apFirstName === '' && $apLastName === '' && $headerDisplayName !== '') {
            $apFirstName = $parts[0] ?? '';
            $apLastName = count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : '';
        }

        if (session('autoritaire_authenticated')) {
            $headerRoleLabel = 'Administrateur Autoritaire';
        } elseif (session('authenticated_admin_technical')) {
            $headerRoleLabel = 'Administrateur technique';
        } elseif ($u instanceof \App\Models\AdminAutoritaire) {
            $headerRoleLabel = 'Administrateur Autoritaire';
        }
    }
@endphp
