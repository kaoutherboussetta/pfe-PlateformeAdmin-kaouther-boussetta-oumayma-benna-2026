import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème (clair / sombre / système) et langue (fr / en / ar), persistés localement.
class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();
  static final AppSettingsController instance = AppSettingsController._();

  static const String _keyTheme = 'app_theme_mode';
  static const String _keyLocale = 'app_locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('fr');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> load() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    _themeMode = _parseThemeMode(p.getString(_keyTheme));
    _locale = _parseLocale(p.getString(_keyLocale));
    notifyListeners();
  }

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Locale _parseLocale(String? raw) {
    final String c = (raw ?? 'fr').toLowerCase().split('_').first;
    if (c == 'en' || c == 'ar') return Locale(c);
    return const Locale('fr');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(
      _keyTheme,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  Future<void> setLocale(Locale locale) async {
    final Locale next = Locale(locale.languageCode);
    if (_locale.languageCode == next.languageCode) return;
    _locale = next;
    notifyListeners();
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(_keyLocale, next.languageCode);
    try {
      final String c = next.languageCode;
      if (c == 'ar') {
        await initializeDateFormatting('ar');
      } else if (c == 'en') {
        await initializeDateFormatting('en');
      } else {
        await initializeDateFormatting('fr_FR');
      }
    } catch (_) {}
  }

  /// Fusion optionnelle depuis le document profil API (`themeMode`, `preferredLanguage`, ancien `darkModeEnabled`).
  void applyFromProfileMap(Map<String, dynamic> p) {
    bool changed = false;

    final String? lang = p['preferredLanguage']?.toString().toLowerCase();
    if (lang != null && (lang == 'fr' || lang == 'en' || lang == 'ar')) {
      final Locale next = Locale(lang);
      if (_locale.languageCode != next.languageCode) {
        _locale = next;
        changed = true;
        SharedPreferences.getInstance().then((sp) => sp.setString(_keyLocale, lang));
      }
    }

    final String? tm = p['themeMode']?.toString().toLowerCase();
    ThemeMode? nextMode;
    if (tm == 'light') {
      nextMode = ThemeMode.light;
    } else if (tm == 'dark') {
      nextMode = ThemeMode.dark;
    } else if (tm == 'system') {
      nextMode = ThemeMode.system;
    } else if (p['darkModeEnabled'] == true) {
      nextMode = ThemeMode.dark;
    }
    if (nextMode != null && _themeMode != nextMode) {
      final ThemeMode m = nextMode;
      _themeMode = m;
      changed = true;
      SharedPreferences.getInstance().then((sp) => sp.setString(
            _keyTheme,
            switch (m) {
              ThemeMode.light => 'light',
              ThemeMode.dark => 'dark',
              ThemeMode.system => 'system',
            },
          ));
    }

    if (changed) notifyListeners();
  }
}
