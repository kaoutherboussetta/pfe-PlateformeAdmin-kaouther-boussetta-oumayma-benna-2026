import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/probleme_signale_map_item.dart';
import '../providers/auth_provider.dart';
import 'problemes_voirie_service.dart';

/// Résultat du scan « corridor » (buffer autour de la polyligne) côté serveur (Turf + Mongo $geoWithin).
class RouteCorridorScan {
  final List<ProblemeSignaleMapItem> signales;
  final List<ProblemeVoirie> voirie;
  final int signalesCount;
  final int voirieCount;
  final int totalCount;

  const RouteCorridorScan({
    required this.signales,
    required this.voirie,
    required this.signalesCount,
    required this.voirieCount,
    required this.totalCount,
  });
}

class RouteCorridorProblemsService {
  static String get _baseUrl => kBaseUrl;

  /// [details] : si false, seuls [counts] sont fiables (listes vides).
  static Future<RouteCorridorScan?> scan(
    List<LatLng> route, {
    double bufferMeters = 75,
    int sinceDays = 90,
    bool details = true,
    int limitSignales = 500,
    int limitVoirie = 500,
  }) async {
    if (route.length < 2) return null;
    try {
      final coords = route.map((p) => [p.longitude, p.latitude]).toList();
      final uri = Uri.parse('$_baseUrl/api/route-corridor-problems');
      final body = jsonEncode({
        'route': coords,
        'bufferMeters': bufferMeters,
        'sinceDays': sinceDays,
        'details': details,
        'limitSignales': limitSignales,
        'limitVoirie': limitVoirie,
      });
      final response = await http.post(
        uri,
        headers: apiJsonHeaders(),
        body: body,
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true) return null;

      var ts = 0;
      var tv = 0;
      var tt = 0;
      final counts = decoded['counts'];
      if (counts is Map) {
        ts = (counts['signales'] as num?)?.toInt() ?? 0;
        tv = (counts['voirie'] as num?)?.toInt() ?? 0;
        tt = (counts['total'] as num?)?.toInt() ?? (ts + tv);
      }

      var v = <ProblemeVoirie>[];
      var s = <ProblemeSignaleMapItem>[];
      if (details) {
        final vRaw = decoded['voirie'];
        if (vRaw is List) {
          v = ProblemesVoirieService.filterForMapDisplay(
            vRaw
                .whereType<Map>()
                .map((e) => ProblemeVoirie.fromJson(Map<String, dynamic>.from(e))),
          );
        }
        final sRaw = decoded['signales'];
        if (sRaw is List) {
          s = sRaw
              .whereType<Map>()
              .map((e) => ProblemeSignaleMapItem.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty)
              .toList();
        }
      }

      return RouteCorridorScan(
        signales: s,
        voirie: v,
        signalesCount: ts,
        voirieCount: tv,
        totalCount: tt,
      );
    } catch (_) {
      return null;
    }
  }
}
