import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entrée d'historique de connexion (affichée dans Informations personnelles).
class LoginHistoryEntry {
  final DateTime at;
  final String location;
  final String device;
  final bool success;

  const LoginHistoryEntry({
    required this.at,
    required this.location,
    required this.device,
    this.success = true,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'location': location,
        'device': device,
        'success': success,
      };

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      at: DateTime.parse(json['at'] as String),
      location: json['location'] as String? ?? '—',
      device: json['device'] as String? ?? '—',
      success: json['success'] as bool? ?? true,
    );
  }
}

class LoginHistoryService {
  LoginHistoryService._();

  static const String _key = 'login_history_entries_v1';
  static const int _maxEntries = 50;

  static String _platformLabel() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    } catch (_) {}
    return 'Appareil';
  }

  static Future<List<LoginHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LoginHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// À appeler après une connexion réussie.
  static Future<void> recordSuccessfulLogin({String? location}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    final entry = LoginHistoryEntry(
      at: DateTime.now(),
      location: location?.trim().isNotEmpty == true ? location!.trim() : 'Sfax, Tunisie',
      device: _platformLabel(),
      success: true,
    );
    final next = [entry, ...existing];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}
