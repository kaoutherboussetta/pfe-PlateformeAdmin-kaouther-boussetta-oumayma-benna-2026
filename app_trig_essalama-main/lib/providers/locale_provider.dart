import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

const String kAppLanguagePrefsKey = 'app_language_code';

class LocaleProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.fr;
  bool _ready = false;

  AppLanguage get language => _language;
  bool get isReady => _ready;

  AppStrings get strings => AppStrings(_language);

  /// Locale pour Material (widgets système). Darija : contenu via [strings], locale Material en anglais.
  Locale get materialLocale {
    switch (_language) {
      case AppLanguage.fr:
        return const Locale('fr');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.tnd:
        return const Locale('en');
    }
  }

  Future<void> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AppLanguage.fromCode(prefs.getString(kAppLanguagePrefsKey));
    if (saved != null) {
      _language = saved;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAppLanguagePrefsKey, lang.code);
    notifyListeners();
  }
}
