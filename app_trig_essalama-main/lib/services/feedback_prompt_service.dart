import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';

const String _kPrefsPrefix = 'feedback_prompt_week_';

/// Limite l’affichage automatique du dialogue de feedback à **une fois par 7 jours** par compte.
class FeedbackPromptService {
  FeedbackPromptService._();

  /// Clé stable par compte (id MongoDB si présent, sinon email).
  static String? _storageKey(AuthProvider auth) {
    if (!auth.isLoggedIn) return null;
    final id = auth.currentUser?.id;
    if (id != null && id.isNotEmpty) {
      return '$_kPrefsPrefix$id';
    }
    final email = auth.userEmail ?? auth.currentUser?.email;
    if (email != null && email.isNotEmpty) {
      return '$_kPrefsPrefix${email.toLowerCase()}';
    }
    return null;
  }

  /// `true` si le dialogue peut s’afficher pour ce compte (au plus une fois tous les 7 jours).
  static Future<bool> shouldShowAndMarkIfEligible(AuthProvider auth) async {
    final key = _storageKey(auth);
    if (key == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastEpochMs = prefs.getInt(key);
    if (lastEpochMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastEpochMs);
      final elapsed = now.difference(last);
      if (elapsed < const Duration(days: 7)) return false;
    }

    await prefs.setInt(key, now.millisecondsSinceEpoch);
    return true;
  }
}
