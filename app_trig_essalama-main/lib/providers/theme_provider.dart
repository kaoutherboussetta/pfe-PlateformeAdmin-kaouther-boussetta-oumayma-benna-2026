import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode_key';
  
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void toggleTheme(bool isOn) {
    _isDarkMode = isOn;
    _saveThemeToPrefs();
    notifyListeners();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false (thème clair)
    _isDarkMode = prefs.getBool(_themeModeKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, _isDarkMode);
  }
}
