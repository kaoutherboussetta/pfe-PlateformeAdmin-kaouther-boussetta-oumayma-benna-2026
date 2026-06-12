class ProblemeVoirieLocation {
  const ProblemeVoirieLocation({
    this.type,
    this.coordinates,
    this.address,
    this.accuracy,
  });

  final String? type;
  final List<double>? coordinates;
  final String? address;
  final num? accuracy;

  static Map<String, dynamic>? _asStringKeyMap(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  /// Repère [lon, lat] (ordre GeoJSON) ou lat/lon à plat (ex. Atlas / traceurs GPS).
  factory ProblemeVoirieLocation.fromJson(dynamic json) {
    final Map<String, dynamic>? m = _asStringKeyMap(json);
    if (m == null) return const ProblemeVoirieLocation();

    List<double>? parsed;
    final dynamic coords = m['coordinates'];
    if (coords is List && coords.length >= 2) {
      final double? lo = ProblemeVoirie._toDouble(coords[0]);
      final double? la = ProblemeVoirie._toDouble(coords[1]);
      if (lo != null && la != null && lo.isFinite && la.isFinite) {
        parsed = <double>[lo, la];
      }
    }
    if (parsed == null) {
      final double? la = ProblemeVoirie._toDouble(
        m['lat'] ?? m['latitude'] ?? m['Latitude'],
      );
      final double? lo = ProblemeVoirie._toDouble(
        m['lon'] ?? m['lng'] ?? m['longitude'] ?? m['Longitude'],
      );
      if (la != null && lo != null && la.isFinite && lo.isFinite) {
        parsed = <double>[lo, la];
      }
    }

    num? accuracyNum;
    final dynamic acc = m['accuracy'];
    if (acc is num) {
      accuracyNum = acc;
    } else if (acc != null) {
      accuracyNum = num.tryParse(acc.toString());
    }

    String? addr = m['address']?.toString().trim();
    if (addr == null || addr.isEmpty) {
      addr = m['formatted_address']?.toString().trim() ?? m['label']?.toString().trim();
    }
    if ((addr == null || addr.isEmpty) && parsed != null && parsed.length >= 2) {
      final double la = parsed[1];
      final double lo = parsed[0];
      final String accStr =
          accuracyNum != null ? ', accuracy: ${accuracyNum}m' : '';
      addr = 'lat: $la, lon: $lo$accStr';
    }

    return ProblemeVoirieLocation(
      type: m['type']?.toString(),
      coordinates: parsed,
      address: addr,
      accuracy: accuracyNum,
    );
  }

  double? get longitude =>
      coordinates != null && coordinates!.isNotEmpty ? coordinates![0] : null;

  double? get latitude =>
      coordinates != null && coordinates!.length >= 2 ? coordinates![1] : null;

  /// Texte affichable ; chaîne vide si rien en base (éviter « Adresse non disponible » trompeur).
  String get resolvedAddress =>
      address?.trim().isNotEmpty == true ? address!.trim() : '';
}

class ProblemeVoirie {
  const ProblemeVoirie({
    required this.id,
    required this.problemType,
    required this.totalDefects,
    required this.location,
    required this.riskScore,
    required this.severity,
    required this.confidence,
    required this.aiModel,
    required this.dateDetection,
    required this.description,
    required this.descriptionFr,
    required this.descriptionAr,
    required this.status,
    required this.updatedAt,
    required this.assignedTeam,
    required this.equipe,
    required this.team,
    required this.coutEstime,
    required this.photos,
    required this.address,
    this.lat,
    this.lng,
  });

  final String id;
  final String problemType;
  final int totalDefects;
  final ProblemeVoirieLocation location;
  final double riskScore;
  final String severity;
  final double confidence;
  final String aiModel;
  final String dateDetection;
  final String description;
  final String descriptionFr;
  final String descriptionAr;
  final String status;
  final String updatedAt;
  final String assignedTeam;
  final String equipe;
  final String team;
  final String coutEstime;
  final List<dynamic> photos;
  final String address;

  /// Renseignés directement par l’API si GeoJSON présent (lat/lng déjà extraits).
  final double? lat;
  final double? lng;

  static String _mergedAddressFromJson(Map<String, dynamic> json, ProblemeVoirieLocation loc) {
    final String fromLoc = (loc.address ?? '').trim();
    if (fromLoc.isNotEmpty) return fromLoc;
    for (final String key in <String>[
      'address',
      'adresse',
      'street',
      'rue',
      'localisation',
    ]) {
      final String s = (json[key] ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  factory ProblemeVoirie.fromJson(Map<String, dynamic> json) {
    final ProblemeVoirieLocation loc = ProblemeVoirieLocation.fromJson(json['location']);
    double? lat = _toDouble(json['lat']) ?? loc.latitude;
    double? lng = _toDouble(json['lng'] ?? json['lon']) ?? loc.longitude;

    final List<dynamic> photosRaw = json['photos'] is List ? json['photos'] as List<dynamic> : const [];
    String addr = _mergedAddressFromJson(json, loc);
    if (addr.isEmpty && loc.resolvedAddress.isNotEmpty) {
      addr = loc.resolvedAddress;
    }

    return ProblemeVoirie(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      problemType: (json['problem_type'] ?? '').toString(),
      totalDefects: json['total_defects'] is num
          ? (json['total_defects'] as num).toInt()
          : int.tryParse('${json['total_defects']}') ?? 0,
      location: loc,
      riskScore: _toDouble(json['risk_score']) ?? 0,
      severity: (json['severity'] ?? '').toString(),
      confidence: _toDouble(json['confidence']) ?? 0,
      aiModel: (json['ai_model'] ?? '').toString(),
      dateDetection: (json['date_detection'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      descriptionFr: (json['description_fr'] ?? '').toString(),
      descriptionAr: (json['description_ar'] ?? '').toString(),
      status: (json['status'] ?? json['statut'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      assignedTeam: (json['assigned_team'] ?? '').toString(),
      equipe: (json['equipe'] ?? '').toString(),
      team: (json['team'] ?? '').toString(),
      coutEstime: (json['cout_estime'] ?? '').toString(),
      photos: photosRaw,
      lat: lat,
      lng: lng,
      address: addr.isEmpty ? 'Adresse non renseignée' : addr,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  double? get mapsLatitude => lat ?? location.latitude;

  double? get mapsLongitude => lng ?? location.longitude;
}
