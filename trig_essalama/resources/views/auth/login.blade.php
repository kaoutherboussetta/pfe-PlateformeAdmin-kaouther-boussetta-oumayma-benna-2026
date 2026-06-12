<!DOCTYPE html>
<html lang="fr" class="trig-app trig-auth-gradient">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <title>Trig-Essalama</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
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
            font-family: Arial, sans-serif;
        }

        body::before{
            content:"";
            position:absolute;
            width:100%;
            height:100%;
            background:
            radial-gradient(circle at 20% 30%, rgba(0,150,255,0.4), transparent 40%),
            radial-gradient(circle at 80% 70%, rgba(255,120,0,0.4), transparent 40%);
            animation: move 10s infinite alternate;
            z-index:0;
        }

        @keyframes move{
            from{transform:translate(0,0);}
            to{transform:translate(-20px,-20px);}
        }

        .card{
            position:relative;
            z-index:1;
            width:360px;
            background:rgba(0,0,0,0.6);
            border-radius:25px;
            padding:30px 25px;
            backdrop-filter:blur(12px);
            box-shadow:0 0 30px rgba(0,150,255,0.4);
            color:white;
        }

        .logo{
            width:90px;
            height:90px;
            margin:auto;
            border-radius:50%;
            background:rgba(255,255,255,0.1);
            display:flex;
            align-items:center;
            justify-content:center;
            box-shadow:0 0 20px #00aaff;
        }

        .logo img{
            width:70px;
            height:70px;
        }

        h2{text-align:center;margin-top:10px;}
        p{text-align:center;font-size:14px;color:#ccc;}

        .input-group{
            margin-top:15px;
        }

        input{
            width:100%;
            padding:12px 18px;
            border-radius:30px;
            border:none;
            outline:none;
            font-size:14px;
        }

        button{
            width:100%;
            margin-top:20px;
            padding:12px;
            border-radius:30px;
            border:none;
            background:white;
            color:black;
            font-weight:bold;
            cursor:pointer;
        }

        button:hover{
            background:#ddd;
        }

        .link{
            text-align:center;
            margin-top:15px;
        }

        .link a{
            color:#00aaff;
            text-decoration:none;
        }
    </style>
    @include('partials.theme-assets')
</head>

<body>

<div class="card">

    <div class="logo">
        <img src="{{ asset('image/logo.png') }}">
    </div>

    <h2>Trig-Essalama</h2>
    <p>La sécurité des citoyens, notre priorité</p>

    @if(session('error'))
        <div style="background:rgba(255,0,0,0.2);padding:10px;border-radius:10px;margin-bottom:15px;">
            <p style="color:#ff6b6b;margin:0;font-size:13px;">{{ session('error') }}</p>
        </div>
    @endif

    <form method="POST" action="{{ route('login.post') }}">
        @csrf

        <div class="input-group">
            <input type="email" name="email" value="{{ old('email') }}" placeholder="Email" required>
        </div>

        <div class="input-group">
            <input type="password" name="password" placeholder="Mot de passe" required>
        </div>

        <button type="submit">Se connecter</button>
    </form>

    <div class="link">
        <a href="{{ route('register') }}">Créer un compte</a>
    </div>

</div>

@include('partials.theme-toggle')
</body>
</html>
