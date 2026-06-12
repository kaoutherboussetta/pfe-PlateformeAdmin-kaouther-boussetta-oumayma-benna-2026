import 'dart:convert';

import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../models/traffic_jam_model.dart';

class TrafficJamService {
  static String get _baseUrl => kBaseUrl;

  static Future<List<TrafficJamModel>> getTrafficJams({
    double? lat,
    double? lng,
    int radius = 5000,
    int limit = 100,
    String? level,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lng'] = lng.toString();
        queryParams['radius'] = radius.toString();
      }
      if (limit > 0) queryParams['limit'] = limit.toString();
      if (level != null && level.isNotEmpty) queryParams['level'] = level;

      final uri = Uri.parse('$_baseUrl/api/embouteillages')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jams = data['embouteillages'];
        if (data['success'] == true && jams is List) {
          return jams
              .whereType<Map<String, dynamic>>()
              .map(TrafficJamModel.fromJson)
              .where((jam) => jam.isActive)
              .toList();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement embouteillages: $e');
    }
    return [];
  }

  static Future<bool> reportTrafficJam({
    required double latitude,
    required double longitude,
    required int congestionLevel,
    double averageSpeed = 0,
    String cause = 'unknown',
    String description = '',
    int radius = 100,
    List<String> affectedRoads = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/embouteillages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'congestionLevel': congestionLevel,
          'averageSpeed': averageSpeed,
          'cause': cause,
          'description': description,
          'radius': radius,
          'affectedRoads': affectedRoads,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur signalement embouteillage: $e');
      return false;
    }
  }
}
