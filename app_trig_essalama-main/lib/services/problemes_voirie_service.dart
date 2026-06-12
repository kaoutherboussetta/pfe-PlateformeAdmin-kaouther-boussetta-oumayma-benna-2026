import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../utils/route_hazard_utils.dart';

class ProblemeVoirie {
  final String id;
  final String problemType;
  final int totalDefects;
  final LatLng location;
  final double riskScore;
  final String severity;
  final double confidence;
  final String dateDetection;
  final String description;
  final String? diagnostic;
  final String? problemState;
  final String? maintenancePriority;
  final String status;
  /// Adresse lisible depuis MongoDB (`location.address`, rue, etc.) si disponible.
  final String? mongoAddress;

  ProblemeVoirie({
    required this.id,
    required this.problemType,
    required this.totalDefects,
    required this.location,
    required this.riskScore,
    required this.severity,
    required this.confidence,
    required this.dateDetection,
    required this.description,
    this.diagnostic,
    this.problemState,
    this.maintenancePriority,
    required this.status,
    this.mongoAddress,
  });

  factory ProblemeVoirie.fromJson(Map<String, dynamic> json) {
    var location = _parseLocation(json['location']);
    if (!isPlausibleMapLocation(location)) {
      final alt = _parseLatLngFromRoot(json);
      if (alt != null) location = alt;
    }
    if (!isPlausibleMapLocation(location)) {
      final fromLoc = _parseLatLngFromRoot(
        json['location'] is Map ? Map<String, dynamic>.from(json['location'] as Map) : {},
      );
      if (fromLoc != null) location = fromLoc;
    }

    return ProblemeVoirie(
      id: _parseMongoId(json['_id']),
      problemType: json['problem_type']?.toString() ?? 'unknown',
      totalDefects: _asInt(json['total_defects']),
      location: location,
      riskScore: _asDouble(json['risk_score']),
      severity: json['severity']?.toString() ?? 'Inconnue',
      confidence: _asDouble(json['confidence']),
      dateDetection: json['date_detection']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      diagnostic: json['diagnostic']?.toString(),
      problemState: json['problem_state']?.toString(),
      maintenancePriority: json['maintenance_priority']?.toString(),
      status:
          json['status']?.toString() ??
          json['statut']?.toString() ??
          'Nouveau',
      mongoAddress: extractMongoDisplayAddress(json['location']) ??
          extractMongoDisplayAddress(json['adresse']) ??
          extractMongoDisplayAddress(json['address']),
    );
  }

  /// Adresse textuelle MongoDB (hors format GPS `lat: …, lon: …`).
  static String? extractMongoDisplayAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      if (parseLatLngFromAddressString(s) != null) return null;
      return s;
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final addr = map['address']?.toString().trim() ?? '';
    if (addr.isNotEmpty && parseLatLngFromAddressString(addr) == null) {
      return addr;
    }
    for (final key in ['street', 'label', 'name', 'lieu', 'adresse', 'ville', 'city']) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Format Atlas : `location.address` = "lat: 29.300676, lon: 47.909588, accuracy: 212m"
  static LatLng? parseLatLngFromAddressString(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final latMatch = RegExp(
      r'lat:\s*([\d.+-]+)',
      caseSensitive: false,
    ).firstMatch(address);
    final lonMatch = RegExp(
      r'lon:\s*([\d.+-]+)',
      caseSensitive: false,
    ).firstMatch(address);
    if (latMatch == null || lonMatch == null) return null;
    final lat = double.tryParse(latMatch.group(1)!);
    final lon = double.tryParse(lonMatch.group(1)!);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  static String _parseMongoId(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      final oid = raw[r'$oid'] ?? raw['oid'];
      if (oid != null) return oid.toString();
    }
    return raw.toString();
  }

  static LatLng _parseLocation(dynamic rawLocation) {
    const invalid = LatLng(0, 0);
    if (rawLocation == null) return invalid;

    if (rawLocation is String) {
      return parseLatLngFromAddressString(rawLocation) ?? invalid;
    }

    if (rawLocation is! Map) return invalid;
    final map = Map<String, dynamic>.from(rawLocation);

    // 1) Adresse texte (format le plus courant dans problemes_de_voirie)
    final fromAddress = parseLatLngFromAddressString(map['address']?.toString());
    if (fromAddress != null && isPlausibleMapLocation(fromAddress)) {
      return fromAddress;
    }

    // 2) lat/lon déjà extraits côté API
    final latDirect = _asDouble(map['lat'] ?? map['latitude']);
    final lngDirect = _asDouble(map['lon'] ?? map['lng'] ?? map['longitude']);
    if (latDirect != null && lngDirect != null) {
      final p = LatLng(latDirect, lngDirect);
      if (isPlausibleMapLocation(p)) return p;
    }

    // 3) GeoJSON { coordinates: [lon, lat] }
    final coordinates = map['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final lon = _coordComponent(coordinates[0]);
      final lat = _coordComponent(coordinates[1]);
      if (lat != null && lon != null) {
        final p = LatLng(lat, lon);
        if (isPlausibleMapLocation(p)) return p;
      }
    }

    return invalid;
  }

  static LatLng? _parseLatLngFromRoot(Map<String, dynamic> json) {
    final lat = _asDouble(json['latitude'] ?? json['lat']);
    final lng = _asDouble(json['longitude'] ?? json['lng'] ?? json['lon']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  static double? _coordComponent(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool isPlausibleMapLocation(LatLng p) {
    if (p.latitude.abs() < 1e-6 && p.longitude.abs() < 1e-6) return false;
    if (p.latitude < -90 || p.latitude > 90) return false;
    if (p.longitude < -180 || p.longitude > 180) return false;
    return true;
  }
}

class ProblemesVoirieService {
  static String get _baseUrl => kBaseUrl;

  static const Map<String, String> _apiHeaders = {
    'ngrok-skip-browser-warning': '69420',
    'Accept': 'application/json',
  };

  /// Statuts affichés en navigation : `problemes_de_voirie` MongoDB.
  static bool isActiveMapStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == 'en cours' || s == 'en attente';
  }

  static String _normalizeStatus(String status) =>
      status.trim().toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e');

  /// Exclut les problèmes clôturés (statut « terminé »).
  static bool isTerminatedStatus(String status) {
    final s = _normalizeStatus(status);
    return s == 'termine' || s == 'terminee';
  }

  static List<ProblemeVoirie> filterActiveStatuses(Iterable<ProblemeVoirie> items) =>
      items.where((p) => isActiveMapStatus(p.status)).toList();

  static List<ProblemeVoirie> filterTerminatedStatuses(Iterable<ProblemeVoirie> items) =>
      items.where((p) => !isTerminatedStatus(p.status)).toList();

  /// Exclut les entrées sans id, sans coordonnées ou au statut « terminé ».
  static List<ProblemeVoirie> filterForMapDisplay(Iterable<ProblemeVoirie> items) =>
      items.where((p) => hasValidMapLocation(p) && !isTerminatedStatus(p.status)).toList();

  static bool hasValidMapLocation(ProblemeVoirie p) =>
      p.id.isNotEmpty && ProblemeVoirie.isPlausibleMapLocation(p.location);

  /// Point d'affichage sur la carte (décalé si plusieurs docs au même GPS).
  static ({ProblemeVoirie probleme, LatLng displayPoint}) voirieMapPlacement({
    required ProblemeVoirie probleme,
    required LatLng displayPoint,
  }) =>
      (probleme: probleme, displayPoint: displayPoint);

  static String _locationKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

  static LatLng _offsetMeters(LatLng center, double eastMeters, double northMeters) {
    final latRad = center.latitude * math.pi / 180;
    final dLat = northMeters / 110574.0;
    final dLng = eastMeters / (111320.0 * math.max(0.2, math.cos(latRad)));
    return LatLng(center.latitude + dLat, center.longitude + dLng);
  }

  /// Écarte les marqueurs qui partagent exactement les mêmes coordonnées.
  /// Préférer [MapProblemClusterService.cluster] pour un regroupement avec badge.
  static List<({ProblemeVoirie probleme, LatLng displayPoint})> layoutMapMarkers(
    Iterable<ProblemeVoirie> items, {
    double spreadRadiusMeters = 22,
  }) {
    final grouped = <String, List<ProblemeVoirie>>{};
    for (final p in items) {
      grouped.putIfAbsent(_locationKey(p.location), () => []).add(p);
    }

    final out = <({ProblemeVoirie probleme, LatLng displayPoint})>[];
    for (final group in grouped.values) {
      if (group.length == 1) {
        out.add(voirieMapPlacement(probleme: group.first, displayPoint: group.first.location));
        continue;
      }
      final center = group.first.location;
      final n = group.length;
      for (var i = 0; i < n; i++) {
        final angle = (2 * math.pi * i) / n;
        final dx = spreadRadiusMeters * math.cos(angle);
        final dy = spreadRadiusMeters * math.sin(angle);
        out.add(
          voirieMapPlacement(
            probleme: group[i],
            displayPoint: _offsetMeters(center, dx, dy),
          ),
        );
      }
    }
    return out;
  }

  static List<ProblemeVoirie> _parseProblemesList(dynamic data) {
    if (data is! List) return const [];
    final out = <ProblemeVoirie>[];
    for (final item in data) {
      if (item is Map) {
        out.add(ProblemeVoirie.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return out;
  }

  /// Tous les documents de la collection MongoDB `problemes_de_voirie` (pagination).
  static Future<List<ProblemeVoirie>> getAllForMap({int pageSize = 1000}) async {
    const maxPages = 50;
    var skip = 0;
    final merged = <ProblemeVoirie>[];
    int? totalInDb;

    try {
      for (var page = 0; page < maxPages; page++) {
        final capped = pageSize.clamp(100, 5000);
        final uri = Uri.parse('$_baseUrl/api/problemes-voirie').replace(
          queryParameters: {
            'all': '1',
            'limit': capped.toString(),
            'skip': skip.toString(),
          },
        );
        final response = await http.get(uri, headers: _apiHeaders);
        if (response.statusCode != 200) break;

        final dynamic decoded = jsonDecode(response.body);
        if (decoded is! Map) break;

        totalInDb ??= (decoded['total'] as num?)?.toInt();
        totalInDb ??= (decoded['count'] as num?)?.toInt();
        final batch = _parseProblemesList(decoded['problemes']);
        if (batch.isEmpty) break;

        merged.addAll(batch);
        skip += batch.length;

        if (batch.length < capped) break;
        if (totalInDb != null && merged.length >= totalInDb) break;
      }

      return filterForMapDisplay(merged);
    } catch (e) {
      print('Error fetching all road problems (problemes_de_voirie): $e');
      return filterForMapDisplay(merged);
    }
  }

  /// Problèmes de voirie dans une bbox (pas de données de secours — pour filtre itinéraire).
  static Future<List<ProblemeVoirie>> getProblemesInBounds(
    GeoBounds bounds, {
    int limit = 400,
    bool activeOnly = false,
    bool fetchAll = false,
  }) async {
    try {
      final capped = limit.clamp(1, 10000);
      final params = <String, String>{
        'minLat': bounds.minLat.toString(),
        'maxLat': bounds.maxLat.toString(),
        'minLng': bounds.minLng.toString(),
        'maxLng': bounds.maxLng.toString(),
        'limit': capped.toString(),
      };
      if (fetchAll) params['all'] = '1';
      if (activeOnly) params['activeOnly'] = '1';
      final uri = Uri.parse('$_baseUrl/api/problemes-voirie').replace(
        queryParameters: params,
      );
      final response = await http.get(uri, headers: _apiHeaders);
      if (response.statusCode != 200) return const [];
      final dynamic decoded = jsonDecode(response.body);
      final list = _parseProblemesList(
        decoded is Map ? decoded['problemes'] : null,
      );
      final filtered = activeOnly ? filterActiveStatuses(list) : list;
      return filterForMapDisplay(filtered);
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching road problems (bounds): $e');
      return const [];
    }
  }

  static Future<List<ProblemeVoirie>> getProblemes({bool activeOnly = false}) async {
    try {
      // On utilise l'URL absolue ou celle du ApiClient
      final response = await http.get(Uri.parse('$_baseUrl/api/problemes-voirie'));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = (decoded is Map) ? (decoded['problemes'] ?? []) : [];
        
        if (data.isNotEmpty) {
          final list = data
              .map((item) => ProblemeVoirie.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList();
          final visible = filterForMapDisplay(list);
          return activeOnly ? filterActiveStatuses(visible) : visible;
        }
      }
    } catch (e) {
      print('Error fetching road problems: $e');
    }

    if (activeOnly) return const [];

    // Données de secours si l'API ne répond pas ou est vide
    return [
      ProblemeVoirie(
        id: '69de45937f9290dd03699fc2',
        problemType: 'crack',
        totalDefects: 9,
        location: const LatLng(33.736851, 10.918882),
        riskScore: 32.44,
        severity: 'Moyenne',
        confidence: 0.8303240537643433,
        dateDetection: '2026-04-14T13:48:38.570037+00:00',
        description:
            'IA: fissure de chaussee detectee. Recommendation: prudence et reduction de vitesse.',
        diagnostic:
            'Fissuration de surface pouvant evoluer sous effet du trafic et des intemperies.',
        problemState: 'degrade',
        maintenancePriority: 'P2',
        status: 'En cours',
      ),
      ProblemeVoirie(
        id: '69de889aff34c86c85743bf4',
        problemType: 'crack',
        totalDefects: 12,
        location: const LatLng(33.737267, 10.920932),
        riskScore: 38.64,
        severity: 'Moyenne',
        confidence: 0.7268766760826111,
        dateDetection: '2026-04-14T18:34:53.495403+00:00',
        description:
            'IA: fissure de chaussee detectee. Recommendation: prudence et reduction de vitesse.',
        diagnostic:
            'Fissuration de surface pouvant evoluer sous effet du trafic et des intemperies.',
        problemState: 'degrade',
        maintenancePriority: 'P2',
        status: 'En cours',
      ),
      ProblemeVoirie(
        id: '69de889eff34c86c85743bf5',
        problemType: 'pothole',
        totalDefects: 2,
        location: const LatLng(33.737267, 10.920932),
        riskScore: 54.51,
        severity: 'Élevée',
        confidence: 0.6056204438209534,
        dateDetection: '2026-04-14T18:34:03.188229+00:00',
        description:
            'IA: nid-de-poule detecte, risque pour pneus et suspension.',
        diagnostic:
            'Defaut localise de la couche de roulement avec impact probable sur pneus et suspension.',
        problemState: 'surveillance',
        maintenancePriority: 'P3',
        status: 'En cours',
      ),
    ];
  }
}
