<!DOCTYPE html>
<html lang="fr" class="trig-app trig-auth-gradient">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <title>Inscription</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
/* même style que login */
:root {
    --ag1: #020024;
    --ag2: #0a1f44;
    --ag3: #1b0033;
}
body{
margin:0;
min-height:100vh;
display:flex;
justify-content:center;
align-items:center;
background: linear-gradient(135deg, var(--ag1), var(--ag2), var(--ag3));
font-family: Arial;
}

.card{
width:360px;
background:rgba(0,0,0,0.6);
border-radius:25px;
padding:30px;
color:white;
backdrop-filter:blur(12px);
box-shadow:0 0 30px rgba(255,120,0,0.4);
}

input{
width:100%;
padding:12px 18px;
border-radius:30px;
border:none;
margin-top:12px;
}

button{
width:100%;
padding:12px;
border-radius:30px;
margin-top:20px;
background:white;
border:none;
font-weight:bold;
}
</style>
    @include('partials.theme-assets')
</head>

<body>

<div class="card">
<h2 style="text-align:center">Créer un compte</h2>

@if($errors->any())
    <div style="background:rgba(255,0,0,0.2);padding:10px;border-radius:10px;margin-bottom:15px;">
        @foreach($errors->all() as $error)
            <p style="color:#ff6b6b;margin:5px 0;font-size:13px;">{{ $error }}</p>
        @endforeach
    </div>
@endif

<form method="POST" action="{{ route('register.post') }}">
@csrf

<input type="text" name="name" value="{{ old('name') }}" placeholder="Nom complet" required>
<input type="email" name="email" value="{{ old('email') }}" placeholder="Email" required>
<input type="password" name="password" placeholder="Mot de passe" required>
<input type="password" name="password_confirmation" placeholder="Confirmer mot de passe" required>

<button type="submit">S'inscrire</button>
</form>

</div>

@include('partials.theme-toggle')
</body>
</html>
