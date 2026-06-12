import 'dart:convert';

import 'api_client.dart';

/// Service API pour les indicateurs / zones de risque (collection MongoDB `risques`).
class RisqueService {
  final ApiClient api;

  RisqueService(this.api);

  /// Risques à proximité (serveur filtre par [radiusMeters] si lat/lng fournis).
  Future<List<Map<String, dynamic>>> fetchRisquesNear({
    required double latitude,
    required double longitude,
    int radiusMeters = 8000,
    int limit = 500,
  }) async {
    try {
      final response = await api.get(
        '/risques?lat=$latitude&lng=$longitude&radius=$radiusMeters&limit=$limit',
      );
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return const [];
      final list = decoded['risques'];
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
