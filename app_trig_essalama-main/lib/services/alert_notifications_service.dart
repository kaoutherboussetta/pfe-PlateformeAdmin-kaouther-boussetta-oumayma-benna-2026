import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_model.dart';

/// Détecte les nouvelles alertes (baseline persistée dans [SharedPreferences]).
///
/// Les notifications **système** (barre d’état) ont été retirées : le plugin
/// `flutter_local_notifications` impose le *core library desugaring* sur Android,
/// ce qui peut faire échouer Gradle (`l8DexDesugarLibDebug`, cache Gradle sur Windows).
/// L’app signale les nouveautés via la page Alertes + SnackBars ([AlertsFeedNotifier]).
class AlertNotificationsService {
  AlertNotificationsService._();

  static const _prefsKey = 'alert_last_known_ids';

  /// Conservé pour compatibilité ; aucune initialisation native.
  static Future<void> initialize() async {}

  static String stableKey(AlertModel a) {
    if (a.id.isNotEmpty) return a.id;
    return 'k_${a.title.hashCode}_${a.createdAt?.millisecondsSinceEpoch ?? 0}_${a.message.hashCode}';
  }

  /// Met à jour la baseline et retourne les clés des alertes **nouvelles**.
  static Future<Set<String>> processNewAlerts(List<AlertModel> current) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      Set<String> last = {};
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          last = list.map((e) => e.toString()).toSet();
        } catch (_) {}
      }

      final keys = current.map(stableKey).where((k) => k.isNotEmpty).toSet();

      if (last.isEmpty) {
        await prefs.setString(_prefsKey, jsonEncode(keys.toList()));
        return {};
      }

      final newly = keys.difference(last);
      await prefs.setString(_prefsKey, jsonEncode(keys.toList()));

      if (newly.isEmpty) return {};
      return newly;
    } catch (e, st) {
      debugPrint('AlertNotificationsService.processNewAlerts: $e\n$st');
      return {};
    }
  }
}
