<!DOCTYPE html>
<html lang="fr" class="trig-app trig-legacy">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Créer un Administrateur - Trig-Essalama</title>
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
        }

        .header h1 {
            font-size: 24px;
            font-weight: 700;
        }

        .container {
            max-width: 600px;
            margin: 40px auto;
            padding: 0 30px;
        }

        .form-container {
            background: linear-gradient(135deg, rgba(220, 38, 38, 0.1) 0%, rgba(20, 20, 20, 0.8) 100%);
            border: 1px solid rgba(220, 38, 38, 0.2);
            border-radius: 12px;
            padding: 30px;
            backdrop-filter: blur(10px);
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            color: rgba(255, 255, 255, 0.9);
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 8px;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 12px 16px;
            background: rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(220, 38, 38, 0.2);
            border-radius: 8px;
            color: #fff;
            font-size: 14px;
            transition: all 0.3s;
        }

        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: rgba(220, 38, 38, 0.5);
            box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1);
        }

        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
            color: white;
            text-decoration: none;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
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

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 14px;
        }

        .alert-error {
            background: rgba(220, 38, 38, 0.2);
            color: #fca5a5;
            border: 1px solid rgba(220, 38, 38, 0.3);
        }

        .errors {
            background: rgba(220, 38, 38, 0.2);
            color: #fca5a5;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 13px;
        }

        .errors ul {
            list-style: none;
            margin: 0;
            padding: 0;
        }

        .info-box {
            background: rgba(59, 130, 246, 0.1);
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 3px solid rgba(59, 130, 246, 0.5);
        }

        .info-box p {
            color: rgba(255, 255, 255, 0.8);
            font-size: 12px;
            line-height: 1.5;
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <div class="header">
        <h1>➕ Créer un Administrateur</h1>
    </div>

    <div class="container">
        @if($errors->any())
            <div class="errors">
                <ul>
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <div class="form-container">
            <div class="info-box">
                <p><strong>ℹ️ Information:</strong> Un email d'invitation avec un lien sécurisé sera envoyé à l'administrateur. Le lien expirera dans 24 heures.</p>
            </div>

            <form method="POST" action="{{ route('admin.admins.store') }}">
                @csrf

                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" value="{{ old('email') }}" required>
                </div>

                <!-- Rôle forcé à "authoritaire" - caché car tous les admins créés sont autoritaires -->
                <input type="hidden" name="role" value="authoritaire">

                <div style="display: flex; gap: 12px; margin-top: 30px;">
                    <button type="submit" class="btn">Créer l'Administrateur</button>
                    <a href="{{ route('admin.admins.index') }}" class="btn btn-secondary">Annuler</a>
                </div>
            </form>
        </div>
    </div>
@include('partials.theme-toggle')
</body>
</html>
