import 'dart:convert';

import 'package:intervenant/models/app_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nouvelles alertes = pas encore ouvertes une fois dans l’app (IDs stockés en local).
/// Au premier chargement, toutes les alertes déjà présentes sont marquées « vues » pour éviter un badge énorme.
class NotificationAlertsBadgePrefs {
  NotificationAlertsBadgePrefs._();

  static const String _keyOpenedIds = 'notif_alerts_opened_ids_json';
  static const String _keyBaseline = 'notif_alerts_opened_baseline_done';

  static Future<Set<String>> _loadOpened() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String? s = p.getString(_keyOpenedIds);
    if (s == null || s.isEmpty) return <String>{};
    try {
      final List<dynamic> list = jsonDecode(s) as List<dynamic>;
      return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _saveOpened(Set<String> ids) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(_keyOpenedIds, jsonEncode(ids.toList()));
  }

  /// Premier lancement : considère toutes les alertes actuelles comme déjà vues (0 « nouvelle »).
  static Future<void> ensureBaselineIfNeeded(List<AppNotification> alerts) async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    if (p.getBool(_keyBaseline) == true) return;
    final Set<String> opened = await _loadOpened();
    for (final AppNotification a in alerts) {
      final String id = a.id.trim();
      if (id.isNotEmpty) opened.add(id);
    }
    await _saveOpened(opened);
    await p.setBool(_keyBaseline, true);
  }

  static Future<Set<String>> readOpenedIds() async {
    return Set<String>.from(await _loadOpened());
  }

  /// Nombre d’alertes dont l’ID n’est pas encore dans la liste « ouverte une fois ».
  static Future<int> newAlertsCount(List<AppNotification> alerts) async {
    await ensureBaselineIfNeeded(alerts);
    final Set<String> opened = await _loadOpened();
    return alerts.where((AppNotification a) {
      final String id = a.id.trim();
      return id.isNotEmpty && !opened.contains(id);
    }).length;
  }

  static Future<void> markAlertOpened(String id) async {
    final String tid = id.trim();
    if (tid.isEmpty) return;
    final Set<String> opened = await _loadOpened();
    if (!opened.add(tid)) return;
    await _saveOpened(opened);
  }

  static Future<void> markAllAlertsOpened(Iterable<AppNotification> alerts) async {
    final Set<String> opened = await _loadOpened();
    bool changed = false;
    for (final AppNotification a in alerts) {
      final String id = a.id.trim();
      if (id.isNotEmpty && opened.add(id)) changed = true;
    }
    if (changed) await _saveOpened(opened);
  }

  /// Badge barre de navigation / en-têts : même logique que [newAlertsCount].
  static Future<int> unreadBadgeFromAlerts(List<AppNotification> alerts) =>
      newAlertsCount(alerts);
}
