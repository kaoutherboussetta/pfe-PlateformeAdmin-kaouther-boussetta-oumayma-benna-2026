import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_page.dart';
import 'register_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _focusNodeEmail = FocusNode();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset("assets/videos/intro.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.play();
        if (mounted) setState(() {});
      }).catchError((error) {
        debugPrint('Error loading video: $error');
        if (mounted) setState(() {});
      });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _focusNodeEmail.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
            children: [
          _buildBackground(),
          Container(color: Colors.white.withValues(alpha: 0.7)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return SizedBox.expand(
      child: _videoController.value.isInitialized
          ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          : Container(color: Colors.white),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Stack(
      clipBehavior: Clip.none,
                    children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 36),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha:0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.15),
                  width: 1,
                ),
              ),
              child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
            ),
          ),
        ),
        Positioned(
          top: -30,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              height: 80,
              width: 80,
              child: ClipOval(
                child: Image.asset(
                  "assets/images/logo_trig_essalama.png",
                  height: 96,
                  width: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white12,
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
                                ),
                        ),
                      ),
                    ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
          Text(
            'Mot de passe oublié',
                              style: TextStyle(
              color: Colors.white.withValues(alpha:0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre email pour recevoir un lien de réinitialisation',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            focusNode: _focusNodeEmail,
            hint: "Email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 24),
          _buildButton(
            label: 'Envoyer le lien',
            onPressed: _isLoading ? null : _sendResetEmail,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
              const Text(
                "Don't have an account ",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text(
                  "Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                                ),
                              ),
                            ],
                          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: Colors.greenAccent,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Email envoyé !',
                          style: TextStyle(
            color: Colors.white.withValues(alpha:0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez votre boîte de réception pour réinitialiser votre mot de passe.',
          style: TextStyle(
            color: Colors.white.withValues(alpha:0.6),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        _buildButton(
          label: 'Retour à la connexion',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: Text(
            "Renvoyer l'email",
                          style: TextStyle(
              color: Colors.white.withValues(alpha:0.8),
              fontSize: 13,
                        ),
                      ),
                    ),
                  ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha:0.45),
          fontSize: 15,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: Colors.black.withValues(alpha:0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha:0.20),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      ),
      validator: validator,
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.black,
          ),
        ),
      ),
    );
  }
}
