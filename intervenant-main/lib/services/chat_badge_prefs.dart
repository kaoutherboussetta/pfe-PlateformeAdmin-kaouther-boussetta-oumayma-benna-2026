import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stockage local des messages admin déjà vus pour le badge Chat.
class ChatBadgePrefs {
  ChatBadgePrefs._();

  static const String _keyOpenedIds = 'chat_admin_opened_ids_json';
  static const String _keyBaseline = 'chat_admin_opened_baseline_done';

  static Future<Set<String>> _loadOpened() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyOpenedIds);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => '$e').where((String e) => e.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _saveOpened(Set<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOpenedIds, jsonEncode(ids.toList(growable: false)));
  }

  /// Premier lancement: considère les messages admin actuels comme déjà vus.
  static Future<void> ensureBaselineIfNeeded(Iterable<String> adminMessageIds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyBaseline) == true) return;
    final Set<String> opened = await _loadOpened();
    for (final String id in adminMessageIds) {
      final String v = id.trim();
      if (v.isNotEmpty) opened.add(v);
    }
    await _saveOpened(opened);
    await prefs.setBool(_keyBaseline, true);
  }

  static Future<int> unreadCount(Iterable<String> adminMessageIds) async {
    await ensureBaselineIfNeeded(adminMessageIds);
    final Set<String> opened = await _loadOpened();
    int count = 0;
    for (final String id in adminMessageIds) {
      final String v = id.trim();
      if (v.isEmpty) continue;
      if (!opened.contains(v)) count++;
    }
    return count;
  }

  static Future<void> markOpened(String messageId) async {
    final String id = messageId.trim();
    if (id.isEmpty) return;
    final Set<String> opened = await _loadOpened();
    if (!opened.add(id)) return;
    await _saveOpened(opened);
  }

  static Future<void> markAllOpened(Iterable<String> adminMessageIds) async {
    final Set<String> opened = await _loadOpened();
    bool changed = false;
    for (final String id in adminMessageIds) {
      final String v = id.trim();
      if (v.isNotEmpty && opened.add(v)) changed = true;
    }
    if (changed) await _saveOpened(opened);
  }
}
