<!DOCTYPE html>
<html lang="fr" class="trig-app trig-legacy">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inscription Désactivée - Trig-Essalama</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0a0a;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }

        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(10, 10, 10, 0.8);
            z-index: 0;
        }

        body::after {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: 
                linear-gradient(90deg, transparent 0%, rgba(220, 38, 38, 0.1) 50%, transparent 100%),
                linear-gradient(0deg, transparent 0%, rgba(220, 38, 38, 0.1) 50%, transparent 100%);
            background-size: 200px 200px;
            animation: linesMove 15s linear infinite;
            z-index: 0;
            opacity: 0.3;
        }

        @keyframes linesMove {
            0% { background-position: 0 0; }
            100% { background-position: 200px 200px; }
        }

        .message-container {
            background: linear-gradient(180deg, rgba(220, 38, 38, 0.15) 0%, rgba(20, 20, 20, 0.95) 100%);
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5), 0 0 40px rgba(220, 38, 38, 0.2);
            width: 100%;
            max-width: 500px;
            padding: 40px 30px;
            animation: slideUp 0.5s ease-out;
            position: relative;
            z-index: 1;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(220, 38, 38, 0.3);
            text-align: center;
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }

        h1 {
            font-size: 28px;
            font-weight: 700;
            color: #fff;
            margin-bottom: 15px;
            text-shadow: 0 0 10px rgba(220, 38, 38, 0.5);
        }

        .message {
            color: rgba(255, 255, 255, 0.9);
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 25px;
        }

        .info-box {
            background: rgba(0, 0, 0, 0.3);
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
            border-left: 3px solid rgba(220, 38, 38, 0.5);
            text-align: left;
        }

        .info-box p {
            color: rgba(255, 255, 255, 0.8);
            font-size: 14px;
            line-height: 1.6;
            margin-bottom: 10px;
        }

        .info-box p:last-child {
            margin-bottom: 0;
        }

        .info-box strong {
            color: #fca5a5;
        }

        .info-box ul {
            margin-left: 20px;
            margin-top: 8px;
            color: rgba(255, 255, 255, 0.7);
            list-style: none;
        }

        .info-box ul li {
            margin-bottom: 5px;
            padding-left: 20px;
            position: relative;
        }

        .info-box ul li::before {
            content: "→";
            position: absolute;
            left: 0;
            color: rgba(220, 38, 38, 0.8);
        }

        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s;
            font-size: 14px;
            margin-top: 10px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(220, 38, 38, 0.4);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #3b82f6 0%, #1e40af 100%);
            margin-left: 10px;
        }

        .links {
            margin-top: 25px;
            padding-top: 25px;
            border-top: 1px solid rgba(220, 38, 38, 0.2);
        }

        .links a {
            color: rgba(255, 255, 255, 0.8);
            text-decoration: none;
            font-size: 14px;
            transition: color 0.3s;
        }

        .links a:hover {
            color: #fca5a5;
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <div class="message-container">
        <div class="icon">🔒</div>
        <h1>Inscription Désactivée</h1>
        
        <div class="message">
            L'inscription publique est désactivée pour des raisons de sécurité.
        </div>

        <div class="info-box">
            <p><strong>🔐 Pourquoi l'inscription est désactivée ?</strong></p>
            <p>Le système Trig-Essalama est un système stratégique national qui nécessite un contrôle strict des accès. Seuls les administrateurs techniques autorisés peuvent créer des comptes pour garantir la sécurité et l'intégrité du système.</p>
            
            <p style="margin-top: 15px;"><strong>📋 Comment obtenir un compte ?</strong></p>
            <p>Pour demander la création d'un compte, veuillez :</p>
            <ul style="margin-left: 20px; margin-top: 8px; color: rgba(255, 255, 255, 0.7);">
                <li>Contacter votre administrateur technique</li>
                <li>Ou contacter le service responsable</li>
                <li>Ou vous rendre au bureau d'accueil</li>
            </ul>
        </div>

        <div style="display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;">
            <a href="{{ route('login') }}" class="btn">🔑 Se connecter</a>
        </div>

        <div class="links">
            <a href="{{ route('login') }}">← Retour à la page de connexion</a>
        </div>
    </div>
@include('partials.theme-toggle')
</body>
</html>
