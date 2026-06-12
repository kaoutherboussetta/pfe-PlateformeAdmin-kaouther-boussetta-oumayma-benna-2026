import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  late final VideoPlayerController _videoController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _focusNodeFirstName = FocusNode();
  final _focusNodeLastName = FocusNode();
  final _focusNodeEmail = FocusNode();
  final _focusNodePassword = FocusNode();
  final _focusNodeConfirmPassword = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;
  bool _isValidatingEmail = false;
  String? _emailError;
  Timer? _emailValidationTimer;

  final ConnexionService _authService = ConnexionService();

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
    _emailValidationTimer?.cancel();
    _videoController.dispose();
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _focusNodeFirstName.dispose();
    _focusNodeLastName.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();
    super.dispose();
  }

  void _scheduleEmailValidation() {
    _emailValidationTimer?.cancel();
    _emailValidationTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) _validateEmailField();
    });
  }

  Future<void> _validateEmailField() async {
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    setState(() {
      _isValidatingEmail = true;
      _emailError = null;
    });
    try {
      final exists = await _authService.emailExists(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailError = exists ? context.read<LocaleProvider>().strings.emailAlreadyExists : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = null);
      }
      if (kDebugMode) {
        debugPrint('Vérification email: indisponible (réseau ou backend)');
      }
    } finally {
      if (mounted) setState(() => _isValidatingEmail = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return _emailError;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      final msg = context.read<LocaleProvider>().strings.acceptTermsSnack;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        acceptTerms: _acceptTerms,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LocaleProvider>().strings.registerSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
        final displayMsg = msg.length <= 120 ? msg : '${msg.substring(0, 120)}...';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.95),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rejoignez SmartRoad',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha:0.6),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            focusNode: _focusNodeFirstName,
                            hint: 'Prénom',
                            icon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (v.length < 2) return 'Min. 2 caractères';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            focusNode: _focusNodeLastName,
                            hint: 'Nom',
                            icon: Icons.person_outline_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (v.length < 2) return 'Min. 2 caractères';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      focusNode: _focusNodeEmail,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      suffixWidget: _isValidatingEmail
                          ? const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (_emailError != null && !_isValidatingEmail)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Text(
                          _emailError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _focusNodePassword,
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_showPassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 8) return 'Min. 8 caractères';
                        if (!v.contains(RegExp(r'[A-Z]'))) return 'Une majuscule';
                        if (!v.contains(RegExp(r'[0-9]'))) return 'Un chiffre';
                        if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                          return 'Un caractère spécial';
                        }
                        return null;
                      },
                      suffixWidget: GestureDetector(
                        onTap: () => setState(() => _showPassword = !_showPassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      focusNode: _focusNodeConfirmPassword,
                      hint: 'Confirmer le mot de passe',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_showConfirmPassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v != _passwordController.text) {
                          return 'Ne correspond pas';
                        }
                        return null;
                      },
                      suffixWidget: GestureDetector(
                        onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            _showConfirmPassword ? Icons.lock_open_outlined : Icons.lock_outline_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) return Colors.white;
                              return Colors.transparent;
                            }),
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white60, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Conditions d\'utilisation'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'En utilisant SmartRoad, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'J\'accepte les '),
                                  const TextSpan(
                                    text: 'conditions d\'utilisation',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' et la '),
                                  const TextSpan(
                                    text: 'politique de confidentialité',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildButton(
                      label: "S'inscrire",
                      onPressed: _isLoading ? null : _register,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Déjà un compte ? ",
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          ),
                          child: const Text(
                            "Se connecter",
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
              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixWidget,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      onChanged: keyboardType == TextInputType.emailAddress
          ? (_) => _scheduleEmailValidation()
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha:0.45),
          fontSize: 15,
        ),
        suffixIcon: suffixWidget ??
            Padding(
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
