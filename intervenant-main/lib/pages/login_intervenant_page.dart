import 'package:flutter/material.dart';
import 'package:intervenant/dialogs/api_url_dialog.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/models/account_info.dart';
import 'package:intervenant/pages/home_page.dart';
import 'package:intervenant/pages/register_intervenant_page.dart';
import 'package:intervenant/services/auth_api_service.dart';

class LoginIntervenantPage extends StatefulWidget {
  const LoginIntervenantPage({super.key});

  @override
  State<LoginIntervenantPage> createState() =>
      _LoginIntervenantPageState();
}

class _LoginIntervenantPageState
    extends State<LoginIntervenantPage> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  ////////////////////////////////////////////////////////////
  /// DISPOSE
  ////////////////////////////////////////////////////////////

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////////
  /// LOGIN
  ////////////////////////////////////////////////////////////

  Future<bool> _ensureServerUrlConfigured() async {
    if (await AuthApiService.ensureBackendReachable()) return true;
    await showApiUrlEditorDialog(
      context,
      onSaved: () {
        if (mounted) setState(() {});
      },
    );
    return AuthApiService.ensureBackendReachable();
  }

  Future<void> _openApiSettings() => showApiUrlEditorDialog(
        context,
        onSaved: () {
          if (mounted) setState(() {});
        },
      );

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await _ensureServerUrlConfigured()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String email =
        _emailController.text.trim().toLowerCase();

    final String password =
        _passwordController.text.trim();

    try {
      final result =
          await AuthApiService.instance.login(
        email: email,
        password: password,
      );

      if (result.account != null) {
        await AuthApiService.saveSessionAfterLogin(
          email: result.account!.email,
          name: result.account!.name,
        );

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => HomePage(
              intervenantName: result.account!.name,
              intervenantEmail: result.account!.email,
              intervenantTeam: result.account!.equipe,
              projectName: 'TRIG Essalama',
            ),
          ),
        );

        return;
      }

      setState(() {
        _isLoading = false;

        _errorMessage =
            result.errorMessage ??
                'Identifiants invalides';
      });
    } catch (_) {
      setState(() {
        _isLoading = false;

        _errorMessage =
            'Connexion impossible vers '
            '${AuthApiService.baseUrl.isNotEmpty ? AuthApiService.baseUrl : 'le serveur'}.';
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// OPEN REGISTER PAGE
  ////////////////////////////////////////////////////////////

  Future<void> _openRegisterPage() async {
    final AccountInfo? createdAccount =
        await Navigator.of(context)
            .push<AccountInfo>(
      MaterialPageRoute<AccountInfo>(
        builder: (_) =>
            const RegisterIntervenantPage(),
      ),
    );

    if (createdAccount == null) return;

    _emailController.text =
        createdAccount.email;

    _passwordController.text =
        createdAccount.password;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            const Color(0xFF6F4E37),
        content: Text(
          AppLocalizations.of(context)
              .accountCreatedSnackbar,
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final bool keyboardOpen = keyboardBottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactLayout = keyboardOpen || constraints.maxHeight < 520;
            final double headerHeight = keyboardOpen
                ? 0
                : compactLayout
                    ? 72
                    : (constraints.maxHeight * 0.28).clamp(120.0, 168.0);

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboardBottom + 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (headerHeight > 0)
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: _buildHeader(l10n, compactLayout),
                      ),
                    Transform.translate(
                      offset: Offset(0, keyboardOpen ? 0 : (compactLayout ? -16 : -32)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Connexion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compactLayout ? 22 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3E2723),
                                  ),
                                ),
                                if (!compactLayout) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Connectez-vous à votre compte chantier',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                SizedBox(height: compactLayout ? 10 : 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: l10n.loginEmail,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF6F4E37),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F5F2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.loginEmailRequired;
                                    }
                                    if (!value.contains('@')) {
                                      return l10n.loginEmailInvalid;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: l10n.loginPassword,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF6F4E37),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F5F2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.loginPasswordRequired;
                                    }
                                    return null;
                                  },
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: compactLayout ? 12 : 16),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6F4E37),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            l10n.loginSubmit,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _openRegisterPage,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF6F4E37)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.loginCreateAccount,
                                      style: const TextStyle(
                                        color: Color(0xFF6F4E37),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _openApiSettings,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.link, size: 16, color: Color(0xFF6F4E37)),
                                  label: Text(
                                    '${l10n.loginServerUrl} : ${AuthApiService.baseUrlLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6F4E37),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool compactLayout) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6F4E37),
            Color(0xFFB08968),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(45),
          bottomRight: Radius.circular(45),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(compactLayout ? 10 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.engineering,
                        color: Colors.white,
                        size: compactLayout ? 26 : 36,
                      ),
                    ),
                    if (!compactLayout) ...[
                      const SizedBox(height: 14),
                      Text(
                        l10n.loginTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}