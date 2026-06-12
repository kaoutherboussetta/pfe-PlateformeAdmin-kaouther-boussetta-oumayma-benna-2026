import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimService {
  static const String _searchBase =
      'https://nominatim.openstreetmap.org/search';
  static const String _reverseBase =
      'https://nominatim.openstreetmap.org/reverse';

  static const Map<String, String> _headers = {
    'User-Agent': 'Trig_Essalama_App/1.0',
  };

  static Map<String, dynamic> _normalizePlace(Map<String, dynamic> item) {
    return {
      'display_name': item['display_name'],
      'lat': double.tryParse('${item['lat']}') ?? 0.0,
      'lon': double.tryParse('${item['lon']}') ?? 0.0,
      'type': item['type'],
      'address': item['address'],
      if (item['name'] != null) 'name': item['name'],
    };
  }

  /// Alias utilisé par l’app (recherche + carte).
  static Future<List<Map<String, dynamic>>> getSuggestions(
    String query, {
    int limit = 12,
    String countrycodes = 'tn',
  }) async {
    return searchLocation(query, limit: limit, countrycodes: countrycodes);
  }

  /// Recherche de lieux (Tunisie par défaut).
  static Future<List<Map<String, dynamic>>> searchLocation(
    String query, {
    int limit = 5,
    String countrycodes = 'tn',
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_searchBase?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=$limit&countrycodes=$countrycodes&addressdetails=1',
      );
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => _normalizePlace(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur Nominatim: $e');
      return [];
    }
  }

  /// Recherche textuelle dans une boîte autour d’un point (mètres).
  static Future<List<Map<String, dynamic>>> searchNearby(
    double lat,
    double lng,
    String query, {
    int radiusMeters = 8000,
    int limit = 15,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final latRad = lat * math.pi / 180.0;
      final deltaLat = radiusMeters / 111320.0;
      final cosLat = math.cos(latRad).abs() < 0.01 ? 0.01 : math.cos(latRad);
      final deltaLng = radiusMeters / (111320.0 * cosLat);

      final minLon = lng - deltaLng;
      final maxLon = lng + deltaLng;
      final minLat = lat - deltaLat;
      final maxLat = lat + deltaLat;
      final viewbox = '$minLon,$maxLat,$maxLon,$minLat';

      final uri = Uri.parse(
        '$_searchBase?q=${Uri.encodeComponent(q)}'
        '&format=json&limit=$limit&bounded=1&viewbox=$viewbox'
        '&addressdetails=1&countrycodes=tn&accept-language=fr',
      );
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => _normalizePlace(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur searchNearby: $e');
      return [];
    }
  }

  /// Géocodage inverse (adresse lisible).
  static Future<String?> reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        '$_reverseBase?format=json&lat=${point.latitude}'
        '&lon=${point.longitude}&zoom=18&addressdetails=1&accept-language=fr',
      );
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'];
      if (address is Map<String, dynamic>) {
        final road = '${address['road'] ?? ''}'.trim();
        final suburb = '${address['suburb'] ?? ''}'.trim();
        final city = '${address['city'] ?? address['town'] ?? address['village'] ?? ''}'
            .trim();
        final country = '${address['country'] ?? ''}'.trim();

        final parts = <String>[];
        if (road.isNotEmpty) parts.add(road);
        if (suburb.isNotEmpty) parts.add(suburb);
        if (city.isNotEmpty) parts.add(city);
        if (country.isNotEmpty) parts.add(country);
        if (parts.isNotEmpty) return parts.join(', ');
      }

      return data['display_name'] as String?;
    } catch (e) {
      debugPrint('Erreur reverseGeocode: $e');
      return null;
    }
  }

  static Future<String?> getReverseGeocoding(double lat, double lon) async {
    return reverseGeocode(LatLng(lat, lon));
  }

  static Future<String> getPlaceName(double lat, double lon) async {
    final fullName = await getReverseGeocoding(lat, lon);
    if (fullName != null && fullName.isNotEmpty) {
      return fullName.split(',').first;
    }
    return 'Position inconnue';
  }

  static Future<LatLng?> getCoordinates(String query) async {
    final suggestions = await getSuggestions(query);
    if (suggestions.isNotEmpty) {
      return LatLng(
        suggestions[0]['lat'] as double,
        suggestions[0]['lon'] as double,
      );
    }
    return null;
  }
}
