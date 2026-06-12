import 'package:intervenant/models/probleme_voirie.dart';

class NotificationPosition {
  const NotificationPosition({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  static NotificationPosition? tryParse(dynamic v) {
    if (v == null) return null;
    if (v is! Map) return null;
    final Map<String, dynamic> m = Map<String, dynamic>.from(v);
    final dynamic latRaw = m['latitude'] ?? m['lat'];
    final dynamic lngRaw = m['longitude'] ?? m['lng'] ?? m['lon'];
    double? lat = latRaw is num ? latRaw.toDouble() : double.tryParse('$latRaw');
    double? lng = lngRaw is num ? lngRaw.toDouble() : double.tryParse('$lngRaw');
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      return NotificationPosition(latitude: lat, longitude: lng);
    }
    final dynamic coords = m['coordinates'];
    if (coords is List && coords.length >= 2) {
      final double? lo = _num(coords[0]);
      final double? la = _num(coords[1]);
      if (la != null && lo != null && la.isFinite && lo.isFinite) {
        return NotificationPosition(latitude: la, longitude: lo);
      }
    }
    return null;
  }

  static double? _num(dynamic x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.typeNotification,
    required this.typeProbleme,
    required this.gravite,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.position,
    this.relatedId,
    this.temperatureC,
    this.feedType,
  });

  final String id;
  final String title;
  final String message;

  /// Champ historique (API `type`) — préférer [typeNotification].
  final String type;

  /// nouveau_probleme | danger_route | mise_a_jour | reponse_admin | …
  final String typeNotification;

  /// nid_de_poule | fissure | danger | route_cassee | …
  final String typeProbleme;

  /// faible | moyenne | grave
  final String gravite;

  /// en_attente | urgent | traité | …
  final String status;

  final bool isRead;
  final DateTime createdAt;
  final NotificationPosition? position;
  final String? relatedId;

  /// Présent pour les alertes météo / température (collection `alert`).
  final double? temperatureC;

  /// `alert` | `problem` | null (API sans discriminateur / ancien flux).
  final String? feedType;

  bool get hasPosition => position != null;

  String get _feedTypeNorm => (feedType ?? '').trim().toLowerCase();

  bool get isAlertFeed => _feedTypeNorm == 'alert';

  bool get isProblemFeed => _feedTypeNorm == 'problem';

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      typeNotification: typeNotification,
      typeProbleme: typeProbleme,
      gravite: gravite,
      status: status,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      position: position,
      relatedId: relatedId,
      temperatureC: temperatureC,
      feedType: feedType,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  static double? _parseTemperatureC(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _graviteFromPriority(dynamic priority) {
    final String p = priority?.toString().trim().toLowerCase() ?? '';
    if (p == 'low' || p == 'basse' || p == 'faible') return 'faible';
    if (p == 'medium' || p == 'moderate' || p == 'moderee' || p == 'moyenne' || p == 'normal') {
      return 'moyenne';
    }
    if (p == 'high' || p == 'haute' || p == 'critical' || p == 'grave' || p == 'severe') {
      return 'grave';
    }
    return '';
  }

  static String _slugAlertType(dynamic alertType) {
    final String t = alertType?.toString().trim().toLowerCase() ?? '';
    if (t.isEmpty) return '';
    final String ascii = t
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c');
    return ascii
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Alimente l’écran Notifications depuis la collection Mongo `problemes_de_voirie` (API `/api/problemes-voirie`).
  factory AppNotification.fromProblemeVoirie(ProblemeVoirie p) {
    final String det = p.dateDetection.trim();
    final String upd = p.updatedAt.trim();
    final DateTime createdAt = det.isNotEmpty
        ? (DateTime.tryParse(det) ?? _parseDate(det))
        : (upd.isNotEmpty ? (DateTime.tryParse(upd) ?? DateTime.now()) : DateTime.now());

    final String sev = p.severity.trim().toLowerCase();
    String gravite = graviteRawFromStrings(sev);
    if (gravite.isEmpty) {
      final double r = p.riskScore;
      if (r >= 0.66) {
        gravite = 'grave';
      } else if (r >= 0.33) {
        gravite = 'moyenne';
      } else if (r > 0) {
        gravite = 'faible';
      }
    }

    final String typeSlug = p.problemType.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final String title = p.problemType.trim().isNotEmpty ? p.problemType.trim() : 'Problème de voirie';
    final String body = p.descriptionFr.trim().isNotEmpty
        ? p.descriptionFr.trim()
        : (p.description.trim().isNotEmpty ? p.description.trim() : p.address.trim());

    NotificationPosition? position;
    final double? la = p.mapsLatitude;
    final double? lo = p.mapsLongitude;
    if (la != null && lo != null && la.isFinite && lo.isFinite) {
      position = NotificationPosition(latitude: la, longitude: lo);
    }

    return AppNotification(
      id: p.id,
      title: title,
      message: body,
      type: 'problem',
      typeNotification: 'nouveau_probleme',
      typeProbleme: typeSlug.isNotEmpty ? typeSlug : 'voirie',
      gravite: gravite,
      status: p.status.trim().toLowerCase(),
      isRead: false,
      createdAt: createdAt,
      position: position,
      relatedId: p.id.trim().isNotEmpty ? p.id.trim() : null,
      temperatureC: null,
      feedType: 'problem',
    );
  }

  /// Gravité normalisée (`faible` | `moyenne` | `grave`) pour filtres UI — réutilisable hors JSON alerte.
  static String graviteRawFromStrings(String graviteRaw) {
    final String g = graviteRaw.trim().toLowerCase();
    if (g.isEmpty) return '';
    if (g == 'low' || g == 'basse' || g == 'faible') return 'faible';
    if (g == 'medium' || g == 'moderate' || g == 'moderee' || g == 'moyenne' || g == 'normal') {
      return 'moyenne';
    }
    if (g == 'high' || g == 'haute' || g == 'critical' || g == 'grave' || g == 'severe') {
      return 'grave';
    }
    return g;
  }

  static AppNotification fromJson(Map<String, dynamic> json) {
    final String? rid = json['relatedId'] as String?;
    final String? parsedFeedType = () {
      final dynamic v = json['feedType'];
      if (v == null) return null;
      final String s = v.toString().trim().toLowerCase();
      return s.isEmpty ? null : s;
    }();
    final String source = (json['source'] ?? '').toString().trim().toLowerCase().replaceAll('-', '_');
    final String explicitType = (json['type'] ?? '').toString().trim().toLowerCase();
    final String tn = () {
      final dynamic rawTn = json['typeNotification'];
      if (rawTn != null && rawTn.toString().trim().isNotEmpty) {
        return rawTn.toString().trim().toLowerCase();
      }
      if (parsedFeedType == 'problem' && explicitType == 'problem') {
        return 'nouveau_probleme';
      }
      if (parsedFeedType == 'alert' && explicitType == 'alert') {
        return source.isNotEmpty ? source : 'alert';
      }
      if (explicitType.isNotEmpty && explicitType != 'alert' && explicitType != 'problem') {
        return explicitType;
      }
      if (source.isNotEmpty) return source;
      return 'system_update';
    }();
    final String legacyType = (explicitType.isNotEmpty && explicitType != 'alert' && explicitType != 'problem')
        ? explicitType
        : tn;
    final String graviteRaw =
        (json['gravite'] ?? json['gravity'] ?? '').toString().trim().toLowerCase();
    final String gravite =
        graviteRaw.isNotEmpty ? graviteRaw : _graviteFromPriority(json['priority']);
    String typeProbleme =
        (json['typeProbleme'] ?? json['type_probleme'] ?? '').toString().trim().toLowerCase();
    if (typeProbleme.isEmpty) {
      typeProbleme = _slugAlertType(json['alert_type']);
    }
    if (typeProbleme.isEmpty && source.isNotEmpty) {
      typeProbleme = source;
    }
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['titre'] ?? json['alert_type'] ?? '').toString(),
      message: (json['message'] as String?) ?? '',
      type: legacyType.isNotEmpty ? legacyType : tn,
      typeNotification: tn.isNotEmpty ? tn : legacyType,
      typeProbleme: typeProbleme,
      gravite: gravite,
      status: (json['status'] ?? json['statut'] ?? '').toString().trim().toLowerCase(),
      isRead: json['isRead'] == true || json['lu'] == true || json['read'] == true,
      createdAt: _parseDate(
        json['createdAt'] ?? json['timestamp'] ?? json['created_at'] ?? json['detected_at'],
      ),
      position: NotificationPosition.tryParse(json['position']) ?? NotificationPosition.tryParse(json['location']),
      relatedId: (rid != null && rid.trim().isNotEmpty) ? rid.trim() : null,
      temperatureC: _parseTemperatureC(json['temperature_c'] ?? json['temperatureC']),
      feedType: parsedFeedType,
    );
  }
}
