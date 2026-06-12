import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème et langue persistés (mode dynamique = [ThemeMode.system] et locale null = système).
class AppPreferences {
  AppPreferences._();

  static const String _kTheme = 'app_theme_mode';
  static const String _kLocale = 'app_locale';

  static Future<ThemeMode> loadThemeMode() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    switch (p.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String v = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await p.setString(_kTheme, v);
  }

  /// `null` = suivre la langue de l’appareil.
  static Future<Locale?> loadLocale() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? s = p.getString(_kLocale);
    if (s == null || s.isEmpty || s == 'system') return null;
    return Locale(s);
  }

  static Future<void> saveLocale(Locale? locale) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (locale == null) {
      await p.remove(_kLocale);
    } else {
      await p.setString(_kLocale, locale.languageCode);
    }
  }
}
