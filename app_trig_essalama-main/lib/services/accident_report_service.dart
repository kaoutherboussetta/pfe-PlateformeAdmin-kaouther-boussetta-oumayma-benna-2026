import 'dart:convert';

import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';

class AccidentReportService {
  static String get _baseUrl => kBaseUrl;

  static Future<Map<String, dynamic>> reportAccident({
    required double latitude,
    required double longitude,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/accidents/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'accident',
          'latitude': latitude,
          'longitude': longitude,
          'userId': userId ?? 'anonymous',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'message': 'Accident signale'};
      }
      throw Exception('Erreur: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur reseau: $e');
    }
  }

  static Future<List<AccidentReport>> getAccidents({
    double? lat,
    double? lng,
    double radius = 10000,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lng'] = lng.toString();
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse('$_baseUrl/api/accidents')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map<String, dynamic>
            ? (decoded['accidents'] as List<dynamic>? ?? <dynamic>[])
            : (decoded as List<dynamic>? ?? <dynamic>[]);
        return data
            .whereType<Map<String, dynamic>>()
            .map(AccidentReport.fromJson)
            .where((accident) => !accident.isExpired)
            .toList();
      }
      throw Exception('Erreur chargement: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur reseau: $e');
    }
  }
}

class AccidentReport {
  static const Duration _defaultTtl = Duration(hours: 6);

  final String id;
  final double latitude;
  final double longitude;
  final int reportCount;
  final bool confirmed;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final List<String> userIds;

  const AccidentReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.reportCount,
    required this.confirmed,
    required this.createdAt,
    this.expiresAt,
    this.userIds = const [],
  });

  factory AccidentReport.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final latValue = location is Map<String, dynamic>
        ? (location['lat'] ?? json['latitude'] ?? 0)
        : (json['latitude'] ?? 0);
    final lngValue = location is Map<String, dynamic>
        ? (location['lng'] ?? json['longitude'] ?? 0)
        : (json['longitude'] ?? 0);

    return AccidentReport(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      latitude: (latValue as num).toDouble(),
      longitude: (lngValue as num).toDouble(),
      reportCount: (json['reportCount'] as num? ?? 1).toInt(),
      confirmed: (json['confirmed'] ?? false) as bool,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      userIds: (json['userIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  DateTime get effectiveExpiresAt => expiresAt ?? createdAt.add(_defaultTtl);

  bool get isExpired => DateTime.now().isAfter(effectiveExpiresAt);
  bool get isConfirmed => reportCount >= 3 || confirmed;
}
