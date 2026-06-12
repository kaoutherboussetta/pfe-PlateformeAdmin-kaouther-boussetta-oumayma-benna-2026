import 'package:flutter/material.dart';

/// État global : thème et locale, pour mise à jour dynamique depuis le profil.
class AppStateScope extends InheritedWidget {
  const AppStateScope({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;

  static AppStateScope of(BuildContext context) {
    final AppStateScope? r = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(r != null, 'AppStateScope introuvable');
    return r!;
  }

  static AppStateScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStateScope>();
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return themeMode != oldWidget.themeMode || locale != oldWidget.locale;
  }
}
