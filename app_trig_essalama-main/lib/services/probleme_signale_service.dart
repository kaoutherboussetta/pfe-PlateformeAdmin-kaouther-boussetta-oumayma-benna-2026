import 'api_client.dart';

/// Envoie les signalements vers la collection MongoDB unifiée `problemes_signales`.
class ProblemeSignaleService {
  final ApiClient api;

  ProblemeSignaleService(this.api);

  Future<bool> submit({
    required String type,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        if (meta != null && meta.isNotEmpty) 'meta': meta,
      };
      final res = await api.post('/api/problemes-signales', body);
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
