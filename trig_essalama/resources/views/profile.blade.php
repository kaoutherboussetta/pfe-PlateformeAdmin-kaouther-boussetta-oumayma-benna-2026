<!DOCTYPE html>
<html lang="fr">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mon Profil</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root { --bg:#f4f4f5; --card:#fff; --text:#0a0a0a; --text2:#525252; --line:rgba(0,0,0,.1); --primary:#ff6b35; --primary-dark:#c2410c; --primary-soft:rgba(255,107,53,.1); --success:#ea580c; --shadow:0 14px 36px rgba(0,0,0,.08);}
        *{box-sizing:border-box;margin:0;padding:0} body{font-family:'Outfit',sans-serif;background:linear-gradient(155deg, rgba(255,107,53,.28) 0%, rgba(194,65,12,.2) 32%, rgba(244,244,245,.97) 32%);color:var(--text);min-height:100vh;padding:34px 22px}
        .page{max-width:1120px;margin:0 auto}.page-head{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:14px}.page-title{font-size:20px;font-weight:800}
        .head-btn{text-decoration:none;font-size:13px;font-weight:600;color:#fff;background:linear-gradient(135deg,var(--primary),var(--primary-dark));border:1px solid rgba(194,65,12,.45);border-radius:999px;padding:9px 14px;box-shadow:0 10px 22px rgba(255,107,53,.24)}
        .layout{display:grid;grid-template-columns:270px minmax(0,1fr);gap:18px;align-items:start}.profile-side,.profile-main{background:var(--card);border:1px solid var(--line);border-radius:16px;box-shadow:var(--shadow)}.profile-side{padding:22px 18px;background:linear-gradient(180deg,rgba(255,107,53,.05) 0%,#fff 40%)}
        .avatar{width:92px;height:92px;border-radius:50%;background:linear-gradient(145deg,rgba(255,107,53,.16),rgba(194,65,12,.08));color:var(--primary-dark);border:4px solid rgba(255,107,53,.18);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:800;margin:0 auto 12px;background-size:cover;background-position:center}.avatar.has-image{color:transparent;text-indent:-9999px;overflow:hidden}
        .side-name{text-align:center;font-weight:800;font-size:17px}.side-role{text-align:center;color:var(--text2);font-size:12px;margin-top:4px}
        .side-metrics{margin-top:16px;border-top:1px dashed var(--line);border-bottom:1px dashed var(--line);padding:12px 0;display:grid;gap:8px}.metric-row{display:flex;justify-content:space-between;font-size:13px;padding:7px 8px;border-radius:8px;background:rgba(255,255,255,.7);border:1px solid rgba(0,0,0,.04)}.metric-label{color:var(--text2)}.metric-value{font-weight:700;color:var(--primary-dark)}.metric-value.success{color:var(--success)}
        .side-actions{margin-top:16px;display:grid;gap:10px}.btn{width:100%;border:none;border-radius:10px;padding:11px 12px;font-size:13px;font-weight:700;cursor:pointer}.btn-primary{background:linear-gradient(135deg,var(--primary),var(--primary-dark));color:#fff}.btn-soft{background:var(--primary-soft);color:var(--primary-dark);border:1px solid rgba(255,107,53,.35)}
        .tabs{display:flex;border-bottom:1px solid var(--line);background:rgba(255,107,53,.04)}.tab{padding:14px 18px;font-size:13px;color:var(--text2);font-weight:600;border-bottom:2px solid transparent}.tab.active{color:var(--primary-dark);border-bottom-color:var(--primary);background:#fff}
        .profile-topline{padding:16px 22px 0;display:flex;flex-wrap:wrap;gap:10px}.profile-chip{display:inline-flex;align-items:center;gap:7px;font-size:12px;font-weight:700;border-radius:999px;padding:7px 12px;border:1px solid rgba(255,107,53,.26);background:rgba(255,107,53,.08);color:var(--primary-dark)}.profile-chip.dot::before{content:'';width:7px;height:7px;border-radius:50%;background:var(--primary)}
        .form-wrap{padding:16px 22px 24px}.form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px 18px}.group label{display:block;font-size:12px;font-weight:700;color:var(--text2);margin-bottom:6px;text-transform:uppercase}.readonly-field{width:100%;border:1px solid rgba(0,0,0,.12);border-radius:10px;padding:12px;font-size:14px;color:var(--text2);background:#f9fafb}
        .flash-message{border-radius:12px;padding:12px 14px;margin-bottom:18px;border:1px solid;font-size:13px;font-weight:600}.flash-message.success{color:#166534;border-color:rgba(34,197,94,.35);background:rgba(34,197,94,.08)}.flash-message.error{color:#b91c1c;border-color:rgba(239,68,68,.35);background:rgba(239,68,68,.08)}
        .modal-overlay{position:fixed;inset:0;z-index:1000;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}.modal-overlay.active{opacity:1;pointer-events:all}.modal{background:#fff;border:1px solid var(--line);border-radius:14px;width:90%;max-width:520px;max-height:90vh;overflow-y:auto}
        .modal-header{padding:18px 20px;border-bottom:1px solid var(--line);display:flex;justify-content:space-between;align-items:center}.modal-title{font-size:16px;font-weight:700}.modal-close{width:30px;height:30px;border-radius:7px;background:#fff;border:1px solid var(--line);cursor:pointer}.modal-body{padding:18px 20px}
        .form-group{margin-bottom:14px}.form-label{display:block;font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--text2);margin-bottom:6px}.form-input{width:100%;padding:11px 13px;border-radius:9px;background:#fff;border:1px solid rgba(0,0,0,.14);font-size:13px}.form-input:focus{outline:none;border-color:rgba(255,107,53,.5);box-shadow:0 0 0 3px rgba(255,107,53,.12)}
        .form-actions{display:flex;gap:10px;margin-top:20px;justify-content:flex-end}.btn-modal{padding:10px 18px;border-radius:8px;font-size:13px;font-weight:700;cursor:pointer;border:none}.btn-modal-cancel{background:#f3f4f6;border:1px solid var(--line);color:#374151}.btn-modal-submit{background:linear-gradient(135deg,var(--primary),var(--primary-dark));color:#fff}
        .form-error{color:#b91c1c;font-size:11px;margin-top:5px;display:flex;align-items:center;gap:5px}.field-help{font-size:10.5px;color:var(--text2);margin-top:5px}.avatar-preview-wrapper{margin-top:12px;width:88px;height:88px;border-radius:18px;overflow:hidden;border:1px solid var(--line);background:#f9fafb;display:flex;align-items:center;justify-content:center}.avatar-preview-wrapper img{width:100%;height:100%;object-fit:cover}.avatar-preview-fallback{width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:700;color:#fff;background:linear-gradient(135deg,#FF6B35,#FFD38C)}
        @media (max-width:960px){.layout{grid-template-columns:1fr}.form-grid{grid-template-columns:1fr}}
    </style>
    @include('partials.theme-assets')
</head>
<body>
@php
    $profileName = trim((string) ($user->name ?? ($user->first_name ?? '').' '.($user->last_name ?? '')));
    $profileName = $profileName !== '' ? $profileName : 'Administrateur';
    $nameParts = preg_split('/\s+/', $profileName) ?: [];
    $firstName = (string) ($user->first_name ?? ($nameParts[0] ?? ''));
    $lastName = (string) ($user->last_name ?? (count($nameParts) > 1 ? implode(' ', array_slice($nameParts, 1)) : ''));
    $initials = strtoupper(substr($firstName ?: $profileName, 0, 1).substr($lastName, 0, 1));
    $initials = trim($initials) !== '' ? $initials : 'AT';
    $avatarUrl = $user->avatar_url ?? null;
@endphp
<div class="page">
    @if(session('success'))<div class="flash-message success">{{ session('success') }}</div>@endif
    @if(session('error'))<div class="flash-message error">{{ session('error') }}</div>@endif
    <div class="page-head"><div class="page-title">Profil Administrateur Technique</div><a class="head-btn" href="{{ route('interface_admin_tech') }}">Retour Dashboard</a></div>
    <div class="layout">
        <aside class="profile-side">
            <div class="avatar{{ !empty($avatarUrl) ? ' has-image' : '' }}" @if(!empty($avatarUrl)) style="background-image:url('{{ $avatarUrl }}');" @endif>{{ $initials }}</div>
            <div class="side-name">{{ $profileName }}</div><div class="side-role">Administrateur technique</div>
            <div class="side-metrics"><div class="metric-row"><span class="metric-label">Email vérifié</span><span class="metric-value success">{{ !empty($user->email_verified_at) ? 'Oui' : 'Non' }}</span></div><div class="metric-row"><span class="metric-label">Statut</span><span class="metric-value success">Actif</span></div></div>
            <div class="side-actions">
                <button class="btn btn-primary" type="button" onclick='openEditProfileModal(@json($profileName), @json($user->email ?? ""), @json($user->phone ?? ""), @json($user->region ?? ""))'>Modifier le profil</button>
                <button class="btn btn-soft" type="button" onclick='openChangeUserPasswordModal(@json($profileName), @json($user->email ?? ""))'>Sécurité du compte</button>
                <form method="POST" action="{{ route('logout') }}">@csrf<button class="btn btn-soft" type="submit">Déconnexion</button></form>
            </div>
        </aside>
        <section class="profile-main">
            <div class="tabs"><div class="tab active">Profil</div></div>
            <div class="profile-topline"><span class="profile-chip dot">Compte actif</span><span class="profile-chip">Niveau: Administrateur Technique</span><span class="profile-chip">Mise a jour securisee</span></div>
            <div class="form-wrap"><div class="form-grid">
                <div class="group"><label>Prénom</label><div class="readonly-field">{{ $firstName !== '' ? $firstName : 'Non renseigné' }}</div></div>
                <div class="group"><label>Nom</label><div class="readonly-field">{{ $lastName !== '' ? $lastName : 'Non renseigné' }}</div></div>
                <div class="group"><label>Email</label><div class="readonly-field">{{ $user->email ?? 'Non renseigné' }}</div></div>
                <div class="group"><label>Téléphone</label><div class="readonly-field">{{ $user->phone ?? 'Non renseigné' }}</div></div>
                <div class="group"><label>Ville / Région</label><div class="readonly-field">{{ $user->city ?? $user->region ?? 'Non renseigné' }}</div></div>
                <div class="group"><label>Pays</label><div class="readonly-field">{{ $user->country ?? 'Tunisie' }}</div></div>
            </div></div>
        </section>
    </div>
</div>
<div class="modal-overlay" id="editProfileModal" onclick="if(event.target===this)closeEditProfileModal()"><div class="modal"><div class="modal-header"><h3 class="modal-title">Modifier mes informations</h3><button class="modal-close" onclick="closeEditProfileModal()"><i class="fas fa-times"></i></button></div><div class="modal-body"><form id="editProfileForm" method="POST" action="{{ route('user.update-profile') }}" enctype="multipart/form-data">@csrf
    <div class="form-group"><label class="form-label" for="profile_name">Nom complet</label><input type="text" id="profile_name" name="name" class="form-input" value="{{ old('name', $profileName) }}" required minlength="2" maxlength="120">@error('name')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-group"><label class="form-label" for="profile_email">Email</label><input type="email" id="profile_email" name="email" class="form-input" value="{{ old('email', $user->email ?? '') }}" required maxlength="190">@error('email')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-group"><label class="form-label" for="profile_phone">Téléphone</label><input type="text" id="profile_phone" name="phone" class="form-input" value="{{ old('phone', $user->phone ?? '') }}" maxlength="40">@error('phone')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-group"><label class="form-label" for="profile_region">Région</label><input type="text" id="profile_region" name="region" class="form-input" value="{{ old('region', $user->region ?? '') }}" maxlength="120">@error('region')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-group"><label class="form-label" for="profile_avatar_file">Photo de profil (depuis votre PC)</label><input type="file" id="profile_avatar_file" name="avatar_file" class="form-input" accept="image/*" data-current-avatar="{{ $avatarUrl ?? '' }}" data-initials="{{ $initials }}"><div class="avatar-preview-wrapper"><img id="avatarPreviewImage" src="{{ $avatarUrl ?? '' }}" alt="Apercu de la photo" style="{{ !empty($avatarUrl) ? '' : 'display:none;' }}"><div id="avatarPreviewFallback" class="avatar-preview-fallback" style="{{ !empty($avatarUrl) ? 'display:none;' : '' }}">{{ $initials }}</div></div><div class="field-help">Choisissez une image depuis votre galerie (max 4 Mo).</div>@error('avatar_file')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-actions"><button type="button" class="btn-modal btn-modal-cancel" onclick="closeEditProfileModal()">Annuler</button><button type="submit" class="btn-modal btn-modal-submit"><i class="fas fa-save"></i> Enregistrer</button></div>
</form></div></div></div>
<div class="modal-overlay" id="changeUserPasswordModal" onclick="if(event.target===this)closeChangeUserPasswordModal()"><div class="modal"><div class="modal-header"><h3 class="modal-title">Changer mon mot de passe</h3><button class="modal-close" onclick="closeChangeUserPasswordModal()"><i class="fas fa-times"></i></button></div><div class="modal-body"><form id="changeUserPasswordForm" method="POST" action="{{ route('user.change-password') }}">@csrf
    <div style="background:#f9fafb;border:1px solid var(--line);border-radius:9px;padding:13px;margin-bottom:17px;"><div style="font-size:11px;color:var(--text2);margin-bottom:4px;">Votre compte</div><div style="font-size:13px;font-weight:600;color:var(--text);" id="changeUserPasswordName"></div><div style="font-size:11px;color:var(--text2);margin-top:3px;" id="changeUserPasswordEmail"></div></div>
    <div class="form-group"><label class="form-label">Nouveau mot de passe</label><input type="password" id="new_user_password" name="password" class="form-input" placeholder="Minimum 12 caractères" required minlength="12"><div class="field-help">Min. 12 car. — majuscule, minuscule, chiffre et caractère spécial (@$!%*#?&).</div>@error('password')<div class="form-error"><i class="fas fa-exclamation-circle"></i>{{ $message }}</div>@enderror</div>
    <div class="form-group"><label class="form-label">Confirmer le mot de passe</label><input type="password" name="password_confirmation" class="form-input" placeholder="Répétez le mot de passe" required></div>
    <div class="form-actions"><button type="button" class="btn-modal btn-modal-cancel" onclick="closeChangeUserPasswordModal()">Annuler</button><button type="submit" class="btn-modal btn-modal-submit"><i class="fas fa-key"></i> Changer mon mot de passe</button></div>
</form></div></div></div>
<script>
    const avatarInput=document.getElementById('profile_avatar_file'),avatarPreviewImage=document.getElementById('avatarPreviewImage'),avatarPreviewFallback=document.getElementById('avatarPreviewFallback'),profileAvatarContainer=document.querySelector('.avatar');
    function setAvatarPreview(u){if(u){avatarPreviewImage.src=u;avatarPreviewImage.style.display='block';avatarPreviewFallback.style.display='none';}else{avatarPreviewImage.removeAttribute('src');avatarPreviewImage.style.display='none';avatarPreviewFallback.style.display='flex';}}
    function setProfileAvatar(u){if(!profileAvatarContainer)return;if(u){profileAvatarContainer.classList.add('has-image');profileAvatarContainer.style.backgroundImage=`url('${u}')`;profileAvatarContainer.textContent='';}else{profileAvatarContainer.classList.remove('has-image');profileAvatarContainer.style.backgroundImage='';profileAvatarContainer.textContent=avatarInput.dataset.initials||'AT';}}
    function resetAvatarPreviewToCurrent(){const c=avatarInput.dataset.currentAvatar||'';setAvatarPreview(c);setProfileAvatar(c);}
    avatarInput.addEventListener('change',function(){const f=this.files&&this.files[0]?this.files[0]:null;if(!f){resetAvatarPreviewToCurrent();return;}const u=URL.createObjectURL(f);setAvatarPreview(u);setProfileAvatar(u);});
    function openEditProfileModal(n,e,p,r){document.getElementById('profile_name').value=n||'';document.getElementById('profile_email').value=e||'';document.getElementById('profile_phone').value=p||'';document.getElementById('profile_region').value=r||'';avatarInput.value='';resetAvatarPreviewToCurrent();document.getElementById('editProfileModal').classList.add('active');document.body.style.overflow='hidden';}
    function closeEditProfileModal(){document.getElementById('editProfileModal').classList.remove('active');document.body.style.overflow='';}
    function openChangeUserPasswordModal(n,e){document.getElementById('changeUserPasswordName').textContent=n;document.getElementById('changeUserPasswordEmail').textContent=e;document.getElementById('changeUserPasswordModal').classList.add('active');document.body.style.overflow='hidden';document.getElementById('changeUserPasswordForm').reset();}
    function closeChangeUserPasswordModal(){document.getElementById('changeUserPasswordModal').classList.remove('active');document.body.style.overflow='';document.getElementById('changeUserPasswordForm').reset();}
    document.addEventListener('keydown',e=>{if(e.key==='Escape'){closeEditProfileModal();closeChangeUserPasswordModal();}});
    @if($errors->has('name') || $errors->has('email') || $errors->has('phone') || $errors->has('region') || $errors->has('avatar_file'))openEditProfileModal(@json(old('name', $profileName)),@json(old('email', $user->email ?? '')),@json(old('phone', $user->phone ?? '')),@json(old('region', $user->region ?? '')));@endif
</script>
@include('partials.theme-toggle')
</body>
</html>
