<!DOCTYPE html>
<html lang="fr" class="trig-app trig-legacy">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vérification 2FA - Trig-Essalama</title>
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

        .verify-container {
            background: linear-gradient(180deg, rgba(168, 85, 247, 0.15) 0%, rgba(20, 20, 20, 0.95) 100%);
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5), 0 0 40px rgba(168, 85, 247, 0.2);
            width: 100%;
            max-width: 400px;
            padding: 40px 30px;
            animation: slideUp 0.5s ease-out;
            position: relative;
            z-index: 1;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(168, 85, 247, 0.3);
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

        .verify-header {
            text-align: center;
            margin-bottom: 30px;
        }

        .verify-header h1 {
            font-size: 28px;
            font-weight: 700;
            color: #fff;
            margin-bottom: 8px;
        }

        .verify-header p {
            color: rgba(255, 255, 255, 0.7);
            font-size: 14px;
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

        .form-group input {
            width: 100%;
            padding: 12px 16px;
            background: rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(168, 85, 247, 0.2);
            border-radius: 8px;
            color: #fff;
            font-size: 18px;
            text-align: center;
            letter-spacing: 8px;
            transition: all 0.3s;
        }

        .form-group input:focus {
            outline: none;
            border-color: rgba(168, 85, 247, 0.5);
            box-shadow: 0 0 0 3px rgba(168, 85, 247, 0.1);
        }

        .btn-verify {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #a855f7 0%, #7c3aed 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(168, 85, 247, 0.3);
        }

        .btn-verify:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(168, 85, 247, 0.4);
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
            background: rgba(168, 85, 247, 0.1);
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 3px solid rgba(168, 85, 247, 0.5);
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
    <div class="verify-container">
        <div class="verify-header">
            <h1>🔐 Vérification 2FA</h1>
            <p>Entrez le code de votre application d'authentification</p>
        </div>

        @if($errors->any())
            <div class="errors">
                <ul>
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.2fa.verify.post') }}">
            @csrf

            <div class="form-group">
                <label for="code">Code à 6 chiffres</label>
                <input type="text" id="code" name="code" placeholder="000000" maxlength="6" pattern="[0-9]{6}" required autofocus>
            </div>

            <button type="submit" class="btn-verify">Vérifier</button>
        </form>

        <div class="info-box">
            <p><strong>💡 Astuce:</strong> Ouvrez votre application d'authentification (Google Authenticator, Microsoft Authenticator, etc.) et entrez le code à 6 chiffres affiché.</p>
        </div>
    </div>

    <script>
        // Auto-format code input
        document.getElementById('code').addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '');
        });
    </script>
@include('partials.theme-toggle')
</body>
</html>
