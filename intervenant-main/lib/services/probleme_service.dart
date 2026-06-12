import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/services/auth_api_service.dart';

class ProblemeService {
  ProblemeService._();

  /// Android Emulator: 10.0.2.2 ; appareil réel: IP PC ; tunnel: URL ngrok.
  /// Utilise la même racine que le reste de l'app.
  static String get baseUrl => AuthApiService.baseUrl;

  static Future<List<ProblemeVoirie>> getProblemes() async {
    Future<List<ProblemeVoirie>> loadFrom(String path) async {
      final Uri url = AuthApiService.backendPathUri(baseUrl, path);
      final response = await http.get(url, headers: const {'Accept': 'application/json'});

      if (response.statusCode != 200) {
        throw Exception('Erreur chargement (${response.statusCode})');
      }

      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ProblemeVoirie.fromJson)
            .toList(growable: false);
      }
      if (data is Map<String, dynamic>) {
        final List<dynamic> items = (data['items'] as List<dynamic>?) ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(ProblemeVoirie.fromJson)
            .toList(growable: false);
      }
      throw Exception('Format de réponse invalide.');
    }

    try {
      return await loadFrom('/api/problemes');
    } catch (_) {
      return loadFrom('/api/problemes-voirie');
    }
  }
}
