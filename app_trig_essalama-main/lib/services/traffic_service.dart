import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'api_client.dart';
import '../providers/auth_provider.dart';

class TrafficZone {
  final List<LatLng> points;
  final String status; // 'jam', 'slow', 'normal'
  final int averageSpeed;

  TrafficZone({
    required this.points,
    required this.status,
    required this.averageSpeed,
  });

  factory TrafficZone.fromJson(Map<String, dynamic> json) {
    final List<dynamic> coords = json['location']?['coordinates'] ?? [];
    List<LatLng> points = [];
    
    // Si c'est une LineString (plusieurs points)
    if (json['location']?['type'] == 'LineString') {
      points = coords
          .whereType<List>()
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
          )
          .toList();
    } else if (json['location']?['type'] == 'Point') {
      // Si c'est un point unique, on peut créer un petit cercle ou segment
      final dynamic latRaw =
          json['latitude'] ?? (coords.length > 1 ? coords[1] : null);
      final dynamic lonRaw =
          json['longitude'] ?? (coords.isNotEmpty ? coords[0] : null);
      if (latRaw is num && lonRaw is num) {
        points = [LatLng(latRaw.toDouble(), lonRaw.toDouble())];
      }
    } else {
      // Fallback: certains documents peuvent ne pas avoir location.type
      final dynamic latRaw = json['latitude'];
      final dynamic lonRaw = json['longitude'];
      if (latRaw is num && lonRaw is num) {
        points = [LatLng(latRaw.toDouble(), lonRaw.toDouble())];
      }
    }

    return TrafficZone(
      points: points,
      status: json['level'] ?? 'normal',
      averageSpeed: json['averageSpeed'] ?? 0,
    );
  }
}

class TrafficService {
  static String get _baseUrl => kBaseUrl;

  static Future<List<TrafficZone>> getTrafficZones() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/embouteillages'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['embouteillages'] ?? [];
        return data.map((json) => TrafficZone.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching traffic: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> getTrafficStats() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/embouteillages/stats/summary'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error fetching traffic stats: $e');
    }
    return {'jamZones': 0};
  }

  static Future<bool> reportProblem({
    required double lat,
    required double lng,
    required String type,
    int? congestionLevel,
    String? description,
    String? cause,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/embouteillages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'congestionLevel': congestionLevel ?? 50,
          'description': description ?? '',
          'cause': cause ?? 'unknown',
          'source': 'user_report',
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error reporting traffic: $e');
      return false;
    }
  }

  static Future<void> sendTelemetry({
    required double lat,
    required double lng,
    required double speedKmh,
    double? accuracyM,
    required DateTime timestamp,
  }) async {
    // Optionnel: envoyer la télémétrie anonyme pour améliorer les données de trafic
    try {
       http.post(
        Uri.parse('$_baseUrl/api/embouteillages/telemetry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'speed': speedKmh,
          if (accuracyM != null) 'accuracy': accuracyM,
          'timestamp': timestamp.toIso8601String(),
        }),
      );
    } catch (_) {}
  }
}
