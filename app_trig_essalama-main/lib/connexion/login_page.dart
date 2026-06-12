import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "575819831562-imrr8u7d98lrhcct53fgcc2saj9m2iql.apps.googleusercontent.com",
  );
  late final VideoPlayerController _videoController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // URL de votre backend API dynamique
  String get _apiUrl => '$kBaseUrl/api';

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
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  // Connexion avec email/mot de passe
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final s = context.read<LocaleProvider>().strings;
      setState(() => _isLoading = true);
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final ok = await auth.login(
          _emailController.text.trim(),
          _passwordController.text,
          _rememberMe,
        );
        if (!mounted) return;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.loginSuccess),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.loginFailed),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.errorPrefix}$e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Connexion dynamique avec Google
  Future<void> _handleGoogleLogin() async {
    final s = context.read<LocaleProvider>().strings;
    setState(() => _isLoading = true);
    
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(s.googleTokenError);
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.setToken(data['token'], userData: data['user']);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.googleLoginOk),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? s.googleAuthFailed;
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.googleLoginError}$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value, AppStrings s) {
    if (value == null || value.isEmpty) return s.validateEmailEmpty;
    final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) return s.validateEmailInvalid;
    return null;
  }

  String? _validatePassword(String? value, AppStrings s) {
    if (value == null || value.isEmpty) return s.validatePasswordEmpty;
    if (value.length < 6) return s.validatePasswordShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
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
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
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
            child: _buildMainContent(s),
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

  Widget _buildMainContent(AppStrings s) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: _buildCard(s),
        ),
      ),
    );
  }

  Widget _buildCard(AppStrings s) {
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
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      focusNode: _focusNodeEmail,
                      hint: s.emailHint,
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => _validateEmail(v, s),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _focusNodePassword,
                      hint: s.passwordHint,
                      obscureText: _obscurePassword,
                      validator: (v) => _validatePassword(v, s),
                      suffixWidget: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            _obscurePassword
                                ? Icons.lock_outline_rounded
                                : Icons.lock_open_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildOptionsRow(s),
                    const SizedBox(height: 30),
                    _buildLoginButton(s),
                    const SizedBox(height: 22),
                    _buildSignUpLink(s),
                    const SizedBox(height: 28),
                    _buildSocialButtons(s),
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
            child: Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 15,
        ),
        suffixIcon: suffixWidget ??
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 1.2,
          ),
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

  Widget _buildOptionsRow(AppStrings s) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
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
            Text(
              s.rememberMe,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
          ),
          child: Text(
            s.forgotPassword,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AppStrings s) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Text(
                s.loginButton,
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

  Widget _buildSignUpLink(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.noAccount,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterPage()),
          ),
          child: Text(
            s.signUp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(AppStrings s) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.orContinueWith,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(child: _buildGoogleButton()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleLogin,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.g_mobiledata,
                  color: Colors.white.withValues(alpha: _isLoading ? 0.4 : 1),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Google',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _isLoading ? 0.4 : 1),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}