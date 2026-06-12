<!DOCTYPE html>
<html lang="fr" class="trig-app trig-legacy">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mot de passe oublié - Trig-Essalama</title>
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

        /* Video background */
        .video-background {
            position: fixed;
            top: 50%;
            left: 50%;
            min-width: 100%;
            min-height: 100%;
            width: auto;
            height: auto;
            transform: translate(-50%, -50%);
            z-index: -1;
            object-fit: cover;
        }

        /* Overlay for better readability */
        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(10, 10, 10, 0.6);
            z-index: 0;
        }

        /* Animated overlay with blue and orange abstract shapes */
        body::after {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-image: 
                linear-gradient(90deg, transparent 0%, rgba(100, 150, 255, 0.1) 50%, transparent 100%),
                linear-gradient(0deg, transparent 0%, rgba(255, 140, 0, 0.1) 50%, transparent 100%),
                radial-gradient(circle, rgba(100, 150, 255, 0.15) 1px, transparent 1px),
                radial-gradient(circle, rgba(255, 140, 0, 0.15) 1px, transparent 1px);
            background-size: 200px 200px, 200px 200px, 50px 50px, 80px 80px;
            background-position: 0 0, 0 0, 0 0, 40px 40px;
            animation: linesMove 15s linear infinite;
            z-index: 0;
            opacity: 0.3;
        }

        @keyframes linesMove {
            0% { background-position: 0 0, 0 0, 0 0, 40px 40px; }
            100% { background-position: 200px 200px, -200px -200px, 50px 50px, 120px 120px; }
        }

        .forgot-container {
            background: linear-gradient(180deg, rgba(20, 20, 20, 0.95) 0%, rgba(10, 10, 10, 0.98) 100%);
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5), 0 0 40px rgba(100, 150, 255, 0.2);
            width: 100%;
            max-width: 380px;
            padding: 30px 25px;
            animation: slideUp 0.5s ease-out;
            position: relative;
            z-index: 1;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(100, 150, 255, 0.2);
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

        .back-button {
            position: absolute;
            top: 20px;
            left: 20px;
            background: none;
            border: none;
            color: white;
            font-size: 24px;
            cursor: pointer;
            z-index: 10;
            transition: transform 0.3s;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
        }

        .back-button:hover {
            transform: translateX(-3px);
        }

        .forgot-header {
            text-align: center;
            margin-bottom: 25px;
            margin-top: 10px;
        }

        .forgot-logo {
            width: 140px;
            height: 140px;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.05);
            padding: 12px;
            box-shadow: 0 0 30px rgba(100, 150, 255, 0.3), inset 0 0 20px rgba(100, 150, 255, 0.1);
        }

        .forgot-logo img {
            width: 100%;
            height: 100%;
            object-fit: contain;
            border-radius: 50%;
            filter: drop-shadow(0 0 10px rgba(100, 150, 255, 0.5));
        }

        .forgot-header h1 {
            font-size: 28px;
            font-weight: 700;
            color: white;
            margin-bottom: 10px;
            text-shadow: 0 0 10px rgba(100, 150, 255, 0.5);
        }

        .forgot-header p {
            font-size: 14px;
            color: rgba(255, 255, 255, 0.8);
            line-height: 1.5;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .form-group input {
            width: 100%;
            padding: 12px 45px 12px 14px;
            border: 2px solid rgba(100, 150, 255, 0.3);
            border-radius: 12px;
            font-size: 14px;
            font-family: inherit;
            transition: all 0.3s;
            background: rgba(255, 255, 255, 0.1);
            color: white;
        }

        .form-group input:focus {
            outline: none;
            border-color: rgba(100, 150, 255, 0.8);
            background: rgba(255, 255, 255, 0.15);
            box-shadow: 0 0 0 3px rgba(100, 150, 255, 0.2), 0 0 15px rgba(100, 150, 255, 0.3);
        }

        .form-group input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }

        .input-icon {
            position: absolute;
            right: 14px;
            color: rgba(255, 255, 255, 0.6);
            font-size: 18px;
            pointer-events: none;
        }

        .btn-send {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, rgba(100, 150, 255, 0.9) 0%, rgba(100, 150, 255, 0.7) 100%);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(100, 150, 255, 0.4), 0 0 20px rgba(100, 150, 255, 0.2);
            margin-bottom: 20px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .btn-send:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 25px rgba(100, 150, 255, 0.6), 0 0 30px rgba(100, 150, 255, 0.3);
            background: linear-gradient(135deg, rgba(100, 150, 255, 1) 0%, rgba(100, 150, 255, 0.8) 100%);
        }

        .btn-send:active {
            transform: translateY(0);
        }

        .signup-link {
            text-align: center;
            margin-top: 20px;
            font-size: 13px;
            color: rgba(255, 255, 255, 0.7);
        }

        .signup-link a {
            color: rgba(100, 150, 255, 0.9);
            text-decoration: none;
            font-weight: 600;
            transition: color 0.3s;
        }

        .signup-link a:hover {
            color: rgba(100, 150, 255, 1);
            text-decoration: underline;
        }

        .error-message {
            background: rgba(255, 0, 0, 0.2);
            border: 1px solid rgba(255, 0, 0, 0.4);
            color: #ff6b6b;
            padding: 10px 12px;
            border-radius: 8px;
            margin-bottom: 15px;
            font-size: 12px;
            display: none;
        }

        .error-message.show {
            display: block;
        }

        .success-message {
            background: rgba(0, 255, 0, 0.2);
            border: 1px solid rgba(0, 255, 0, 0.4);
            color: #51cf66;
            padding: 10px 12px;
            border-radius: 8px;
            margin-bottom: 15px;
            font-size: 12px;
            display: none;
        }

        .success-message.show {
            display: block;
        }

        @media (max-width: 480px) {
            .forgot-container {
                padding: 25px 20px;
            }

            .forgot-header h1 {
                font-size: 24px;
            }
        }
    </style>
    @include('partials.theme-assets')
</head>
<body>
    <video autoplay muted loop playsinline class="video-background">
        <source src="{{ asset('image/intro.mp4') }}" type="video/mp4">
    </video>
    <div class="forgot-container">
        <a href="{{ route('login') }}" class="back-button">←</a>

        <div class="forgot-header">
            <div class="forgot-logo">
                <img src="{{ asset('image/logo.png') }}" alt="Trig-Essalama Logo">
            </div>
            <h1>Mot de passe oublié</h1>
            <p>Entrez votre email pour recevoir un lien de réinitialisation</p>
        </div>

        @if($errors->any())
            <div class="error-message" style="display: block;">
                @foreach($errors->all() as $error)
                    <p style="margin: 5px 0;">{{ $error }}</p>
                @endforeach
            </div>
        @endif

        @if(session('success'))
            <div class="success-message" style="display: block;">
                <p style="margin: 0;">{{ session('success') }}</p>
            </div>
        @endif

        <div id="errorMessage" class="error-message"></div>
        <div id="successMessage" class="success-message"></div>

        <form id="forgotPasswordForm" method="POST" action="{{ route('forgot-password.post') }}">
            @csrf
            <div class="form-group">
                <div class="input-wrapper">
                    <input 
                        type="email" 
                        id="email" 
                        name="email" 
                        placeholder="Email" 
                        required
                        autocomplete="email"
                    >
                    <span class="input-icon">✉️</span>
                </div>
            </div>

            <button type="submit" class="btn-send">Envoyer le lien</button>
        </form>

        <div class="signup-link">
            Don't have an account? <a href="{{ route('register') }}">Sign Up</a>
        </div>
    </div>

    <script>
        // Form validation
        document.getElementById('forgotPasswordForm').addEventListener('submit', function(e) {
            const email = document.getElementById('email').value;
            const errorMessage = document.getElementById('errorMessage');
            const successMessage = document.getElementById('successMessage');

            // Hide previous messages
            errorMessage.classList.remove('show');
            successMessage.classList.remove('show');

            // Basic validation
            if (!email) {
                e.preventDefault();
                errorMessage.textContent = 'Veuillez entrer votre adresse email.';
                errorMessage.classList.add('show');
                return false;
            }

            // Email validation
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(email)) {
                e.preventDefault();
                errorMessage.textContent = 'Veuillez entrer une adresse email valide.';
                errorMessage.classList.add('show');
                return false;
            }
        });

        // Show success message if redirected
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('sent') === 'true') {
            document.getElementById('successMessage').textContent = 'Un lien de réinitialisation a été envoyé à votre adresse email.';
            document.getElementById('successMessage').classList.add('show');
        }
    </script>
@include('partials.theme-toggle')
</body>
</html>
