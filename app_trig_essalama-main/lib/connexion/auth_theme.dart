import 'package:flutter/material.dart';

/// Style et couleurs communs pour les pages Connexion, Inscription, Mot de passe oublié.
/// Design professionnel : cartes épurées, typographie claire, hiérarchie visuelle.
class AuthTheme {
  AuthTheme._();

  static const Color primary = Color(0xFF0088CC);
  static const Color primaryDark = Color(0xFF006699);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF78909C);
  static const Color border = Color(0xFF37474F);
  static const Color error = Color(0xFFEF5350);

  static const double inputRadius = 12.0;
  static const double buttonRadius = 12.0;
  static const double cardRadius = 20.0;

  /// Carte de formulaire type glassmorphism (fond semi-transparent, bordure discrète).
  static BoxDecoration get formCardDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Titre de section (ex: "Connexion").
  static TextStyle get titleStyle => const TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  /// Sous-titre / description.
  static TextStyle get subtitleStyle => const TextStyle(
        color: textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static InputDecoration inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      prefixIcon: Icon(prefixIcon, color: primary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      errorStyle: const TextStyle(color: error, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: textPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  static ButtonStyle outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: const BorderSide(color: primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
