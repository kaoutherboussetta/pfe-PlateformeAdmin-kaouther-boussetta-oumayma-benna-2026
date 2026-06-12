import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/probleme_signale_map_item.dart';
import '../providers/auth_provider.dart';
import '../utils/route_hazard_utils.dart';

/// Lecture des signalements pour la carte (GET public, bbox optionnelle).
class ProblemesSignalesMapService {
  static String get _baseUrl => kBaseUrl;

  static Map<String, String> get _headers => apiJsonHeaders();

  /// Tous les documents de la collection `problemes_signales` (limite serveur, sans filtre date si `all=1`).
  static Future<List<ProblemeSignaleMapItem>> fetchAll({int limit = 5000}) async {
    try {
      final capped = limit.clamp(1, 5000);
      final uri = Uri.parse('$_baseUrl/api/problemes-signales').replace(
        queryParameters: {
          'all': '1',
          'limit': capped.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];
      final list = decoded['problemes'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => ProblemeSignaleMapItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<ProblemeSignaleMapItem>> fetchInBounds(
    GeoBounds bounds, {
    int limit = 300,
    int sinceDays = 21,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/problemes-signales').replace(
        queryParameters: {
          'minLat': bounds.minLat.toString(),
          'maxLat': bounds.maxLat.toString(),
          'minLng': bounds.minLng.toString(),
          'maxLng': bounds.maxLng.toString(),
          'limit': limit.toString(),
          'sinceDays': sinceDays.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];
      final list = decoded['problemes'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => ProblemeSignaleMapItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
