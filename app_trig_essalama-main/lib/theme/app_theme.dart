import 'package:flutter/material.dart';

/// Thème pour le tableau de bord : cartes interactives, style premium.
/// Inclut aussi le thème profil / alerte (Trig Essalama).
class AppTheme {
  AppTheme._();

  // --- Profile / Safety Alert theme ---
  static const Color primaryBlack = Color(0xFF0F0F0F);
  static const Color alertOrange = Color(0xFFFF7A00);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color secondaryGrey = Color(0xFF8A8A8A);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color dividerColor = Color(0xFF2A2A2A);
  
  // Profile Redesign Colors
  static const Color softGreen = Color(0xFF4ADE80);
  static const Color softRed = Color(0xFFF87171);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color iosBlue = Color(0xFF007AFF);

  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 30.0;

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryBlack,
        primaryColor: alertOrange,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: whiteText, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: whiteText, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: whiteText),
          bodyMedium: TextStyle(color: secondaryGrey),
          labelLarge: TextStyle(color: whiteText),
        ),
        colorScheme: const ColorScheme.dark(
          primary: alertOrange,
          secondary: secondaryGrey,
          surface: surfaceDark,
          background: primaryBlack,
          onPrimary: whiteText,
          onSecondary: whiteText,
          onSurface: whiteText,
          onBackground: whiteText,
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: alertOrange,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
          labelLarge: TextStyle(color: Colors.black),
        ),
        colorScheme: const ColorScheme.light(
          primary: alertOrange,
          secondary: Colors.black54,
          surface: Colors.white,
          background: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onBackground: Colors.black,
        ),
      );

  // --- Existing dashboard theme ---
  static const Color primary = Color(0xFF0088CC);
  static const Color primaryDark = Color(0xFF006699);
  static const Color accent = Color(0xFF00B894);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF78909C);
  static const Color cardBackground = Color(0xFF1E2A33);
  static const Color cardBorder = Color(0xFF37474F);
  static const Color statusConnected = Color(0xFF00B894);
  static const Color statusWarning = Color(0xFFF39C12);

  static const double cardRadius = 16.0;
  static const double cardRadiusSmall = 12.0;

  static BoxDecoration cardDecoration({bool elevated = true}) {
    return BoxDecoration(
      color: cardBackground,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: cardBorder, width: 1),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  static TextStyle get sectionTitle => const TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get cardTitle => const TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get cardSubtitle => const TextStyle(
        color: textSecondary,
        fontSize: 13,
      );

  static TextStyle get statValue => const TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get statLabel => const TextStyle(
        color: textTertiary,
        fontSize: 12,
      );
}
