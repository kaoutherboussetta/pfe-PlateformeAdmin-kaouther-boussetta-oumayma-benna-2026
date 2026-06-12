import 'package:flutter/material.dart';
import 'package:intervenant/dialogs/api_url_dialog.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/models/account_info.dart';
import 'package:intervenant/services/auth_api_service.dart';

class RegisterIntervenantPage extends StatefulWidget {
  const RegisterIntervenantPage({super.key});

  @override
  State<RegisterIntervenantPage> createState() => _RegisterIntervenantPageState();
}

class _RegisterIntervenantPageState extends State<RegisterIntervenantPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final List<String> _equipes = const ['Équipe 1', 'Équipe 2', 'Équipe 3', 'Équipe 5'];
  String? _selectedEquipe;

  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _brown = Color(0xFF6F4E37);
  static const Color _beigeBg = Color(0xFFF5EFE6);
  static const Color _fieldFill = Color(0xFFF8F5F2);

  InputDecoration _fieldDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _brown)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  void _showRegisterError(String message) {
    final bool needsUrl = message.contains('URL du backend') ||
        message.contains('URL du serveur') ||
        !AuthApiService.isServerUrlConfigured;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: needsUrl
            ? SnackBarAction(
                label: 'URL',
                textColor: Colors.white,
                onPressed: _openApiSettings,
              )
            : null,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await _ensureServerUrlConfigured()) return;

    setState(() {
      _isSaving = true;
    });

    final String nom = _nomController.text.trim();
    final String prenom = _prenomController.text.trim();
    final String fullName = '$nom $prenom (${_selectedEquipe!})'.trim();

    final AccountInfo account = AccountInfo(
      name: fullName,
      email: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
      equipe: _selectedEquipe,
    );

    try {
      final String? error = await AuthApiService.instance.register(
        name: account.name,
        nom: nom,
        prenom: prenom,
        equipe: _selectedEquipe!,
        email: account.email,
        password: account.password,
      );

      if (error != null) {
        setState(() {
          _isSaving = false;
        });
        if (!mounted) return;
        _showRegisterError(error);
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (_) {
      setState(() {
        _isSaving = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Pas de connexion vers ${AuthApiService.baseUrl.isNotEmpty ? AuthApiService.baseUrl : 'le serveur'}. '
            'Lancez npm start dans backend/, vérifiez l’URL pour ce réseau, puis « URL du serveur ».',
          ),
          action: SnackBarAction(
            label: 'URL',
            textColor: Colors.white,
            onPressed: () => showApiUrlEditorDialog(
              context,
              onSaved: () {
                if (mounted) setState(() {});
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAuthHeader({
    required double height,
    required bool compact,
    required String title,
  }) {
    final double iconSize = compact ? 26 : 36;
    final double iconPadding = compact ? 10 : 14;
    final double titleSize = compact ? 18 : 24;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Container(
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
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.engineering,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(height: compact ? 8 : 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final bool keyboardOpen = keyboardBottom > 0;

    return Scaffold(
      backgroundColor: _beigeBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactLayout = keyboardOpen || constraints.maxHeight < 520;
            final double headerHeight = compactLayout
                ? 72
                : (constraints.maxHeight * 0.26).clamp(120.0, 168.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAuthHeader(
                  height: headerHeight,
                  compact: compactLayout,
                  title: 'Inscription intervenant',
                ),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(0, compactLayout ? -16 : -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
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
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: keyboardBottom > 0 ? 8 : 0),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Créer un compte',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compactLayout ? 22 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3E2723),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Renseignez vos informations pour l’équipe de chantier',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _nomController,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isSaving,
                                  decoration: _fieldDecoration(
                                    hint: 'Nom',
                                    prefixIcon: Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Nom obligatoire';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _prenomController,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isSaving,
                                  decoration: _fieldDecoration(
                                    hint: 'Prénom',
                                    prefixIcon: Icons.badge_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Prénom obligatoire';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isSaving,
                                  decoration: _fieldDecoration(
                                    hint: l10n.loginEmail,
                                    prefixIcon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email obligatoire';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Email invalide';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  key: ValueKey<String?>(_selectedEquipe),
                                  initialValue: _selectedEquipe,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey.shade700,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF212121),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return _equipes.map((String e) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          e,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF212121),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items: _equipes
                                      .map(
                                        (equipe) => DropdownMenuItem<String>(
                                          value: equipe,
                                          child: Text(equipe),
                                        ),
                                      )
                                      .toList(),
                                  decoration: _fieldDecoration(
                                    hint: 'Équipe de chantier',
                                    prefixIcon: Icons.groups_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Équipe obligatoire';
                                    }
                                    return null;
                                  },
                                  onChanged: _isSaving
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedEquipe = value;
                                          });
                                        },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isSaving,
                                  decoration: _fieldDecoration(
                                    hint: l10n.loginPassword,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Mot de passe obligatoire';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'Minimum 6 caractères';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !_isSaving,
                                  onFieldSubmitted: (_) {
                                    if (!_isSaving) _register();
                                  },
                                  decoration: _fieldDecoration(
                                    hint: 'Confirmer le mot de passe',
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Confirmation obligatoire';
                                    }
                                    if (value.trim() != _passwordController.text.trim()) {
                                      return 'Les mots de passe ne correspondent pas';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brown,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "S'inscrire",
                                            style: TextStyle(
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
                                    onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: _brown),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      'Retour à la connexion',
                                      style: TextStyle(
                                        color: _brown,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: _isSaving ? null : _openApiSettings,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.link, size: 16, color: _brown),
                                  label: Text(
                                    '${AppLocalizations.of(context).loginServerUrl} : ${AuthApiService.baseUrlLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: _brown, fontSize: 11),
                                  ),
                                ),
                                SizedBox(height: keyboardBottom > 0 ? 12 : 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
