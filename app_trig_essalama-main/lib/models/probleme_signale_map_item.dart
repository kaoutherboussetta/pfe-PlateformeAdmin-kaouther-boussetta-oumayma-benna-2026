import 'package:latlong2/latlong.dart';

/// Point de signalement citoyen pour affichage carte (collection `problemes_signales`).
class ProblemeSignaleMapItem {
  final String id;
  final String type;
  final LatLng location;
  final String? userId;
  final String? source;
  final Map<String, dynamic> meta;
  final DateTime? createdAt;

  const ProblemeSignaleMapItem({
    required this.id,
    required this.type,
    required this.location,
    this.userId,
    this.source,
    this.meta = const {},
    this.createdAt,
  });

  factory ProblemeSignaleMapItem.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final raw = json['createdAt'];
    if (raw is String) {
      created = DateTime.tryParse(raw);
    }

    final lat = _asDouble(json['latitude']) ?? _latFromPosition(json['position']);
    final lng = _asDouble(json['longitude']) ?? _lngFromPosition(json['position']);
    final loc = (lat != null && lng != null) ? LatLng(lat, lng) : const LatLng(0, 0);

    Map<String, dynamic> metaMap = {};
    final m = json['meta'];
    if (m is Map) {
      metaMap = Map<String, dynamic>.from(m);
    }

    return ProblemeSignaleMapItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'danger',
      location: loc,
      userId: json['userId']?.toString(),
      source: json['source']?.toString(),
      meta: metaMap,
      createdAt: created,
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double? _latFromPosition(dynamic position) {
    if (position is! Map) return null;
    final coords = position['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    return _asDouble(coords[1]);
  }

  static double? _lngFromPosition(dynamic position) {
    if (position is! Map) return null;
    final coords = position['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    return _asDouble(coords[0]);
  }
}
