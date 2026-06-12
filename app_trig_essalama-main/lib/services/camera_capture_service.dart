import 'dart:convert';
import 'dart:typed_data';

import 'api_client.dart';

class CameraCaptureService {
  final ApiClient api;
  CameraCaptureService(this.api);

  Future<List<CameraCaptureItem>> fetchMyCaptures({int limit = 50}) async {
    final safeLimit = limit < 1 ? 1 : (limit > 200 ? 200 : limit);
    final res = await api.get('/camera-captures?limit=$safeLimit');
    if (res.statusCode != 200) {
      var msg = 'Impossible de charger les captures';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return const [];
    final list = decoded['captures'];
    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map(
          (raw) => CameraCaptureItem(
            id: raw['id']?.toString() ?? '',
            imageBase64: raw['imageBase64']?.toString() ?? '',
            latitude: (raw['latitude'] as num?)?.toDouble() ?? 0,
            longitude: (raw['longitude'] as num?)?.toDouble() ?? 0,
            createdAt: DateTime.tryParse(raw['createdAt']?.toString() ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> uploadCapture({
    required Uint8List imageBytes,
    required double latitude,
    required double longitude,
  }) async {
    final res = await api.post('/camera-captures', {
      'imageBase64': base64Encode(imageBytes),
      'latitude': latitude,
      'longitude': longitude,
    });
    if (res.statusCode != 201) {
      var msg = 'Impossible d\'enregistrer la capture';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }
  }
}

class CameraCaptureItem {
  final String id;
  final String imageBase64;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const CameraCaptureItem({
    required this.id,
    required this.imageBase64,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Uint8List? decodeImageBytes() {
    if (imageBase64.isEmpty) return null;
    try {
      final raw = imageBase64.trim();
      // Supporte les 2 formats:
      // 1) base64 pur: "/9j/4AAQ..."
      // 2) data URI: "data:image/jpeg;base64,/9j/4AAQ..."
      final payload = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}
