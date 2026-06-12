import '../l10n/app_strings.dart';

class AlertModel {
  final String id;
  final String title;
  final String message;
  final String recommendation;
  final String status;
  final String priority;
  final String alertType;
  final String typeField;
  final String? locationNamed;
  final DateTime? createdAt;
  final double? temperatureC;
  /// Coordonnées si présentes dans le document API (filtre zone).
  final double? latitude;
  final double? longitude;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.recommendation,
    required this.status,
    required this.priority,
    required this.alertType,
    required this.typeField,
    required this.locationNamed,
    required this.createdAt,
    required this.temperatureC,
    this.latitude,
    this.longitude,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final title = _firstNonEmpty([
          json['title']?.toString(),
          json['alert_type']?.toString(),
          json['type']?.toString(),
        ]) ??
        'Alerte';

    final recommendation = _firstNonEmpty([
      json['recommendation']?.toString(),
      json['advice']?.toString(),
    ]);

    final loc = json['location'];
    String? locationNamed;
    if (loc is Map<String, dynamic>) {
      locationNamed = _firstNonEmpty([
        loc['name']?.toString(),
        loc['label']?.toString(),
        loc['address']?.toString(),
      ]);
    } else {
      locationNamed = json['location_named']?.toString();
    }

    final temp = json['temperature_c'];
    final temperatureC = temp is num ? temp.toDouble() : double.tryParse('${temp ?? ''}');

    final coords = _extractCoordinates(json);

    return AlertModel(
      id: _firstNonEmpty([json['_id']?.toString(), json['id']?.toString()]) ?? '',
      title: title,
      message: _firstNonEmpty([json['message']?.toString(), json['description']?.toString()]) ?? '',
      recommendation: recommendation ?? '',
      status: _firstNonEmpty([json['status']?.toString()]) ?? 'unknown',
      priority: _firstNonEmpty([json['priority']?.toString(), json['severity']?.toString()]) ?? 'info',
      alertType: _firstNonEmpty([json['alert_type']?.toString()]) ?? '',
      typeField: _firstNonEmpty([json['type']?.toString()]) ?? '',
      locationNamed: locationNamed,
      createdAt: _parseDate(json['timestamp']) ?? _parseDate(json['created_at']) ?? _parseDate(json['createdAt']),
      temperatureC: temperatureC,
      latitude: coords.$1,
      longitude: coords.$2,
    );
  }

  /// Retourne (lat, lng) si trouvés dans le JSON, sinon (null, null).
  static (double?, double?) _extractCoordinates(Map<String, dynamic> json) {
    double? lat = _parseDouble(json['latitude']) ?? _parseDouble(json['lat']);
    double? lng = _parseDouble(json['longitude']) ?? _parseDouble(json['lng']);
    if (lat != null && lng != null) return (lat, lng);

    final loc = json['location'];
    if (loc is Map) {
      final m = Map<String, dynamic>.from(loc);
      lat = _parseDouble(m['lat']) ?? _parseDouble(m['latitude']);
      lng = _parseDouble(m['lng']) ?? _parseDouble(m['longitude']);
      if (lat != null && lng != null) return (lat, lng);
      final coords = m['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = _parseDouble(coords[0]);
        lat = _parseDouble(coords[1]);
        if (lat != null && lng != null) return (lat, lng);
      }
    }

    final geom = json['geometry'];
    if (geom is Map && geom['type']?.toString() == 'Point') {
      final c = geom['coordinates'];
      if (c is List && c.length >= 2) {
        lng = _parseDouble(c[0]);
        lat = _parseDouble(c[1]);
        if (lat != null && lng != null) return (lat, lng);
      }
    }
    return (null, null);
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String get relativeTime {
    final d = createdAt;
    if (d == null) return 'Maintenant';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'Maintenant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }

  Map<String, String> toDisplayMap(AppStrings s) {
    final priorityNorm = priority.toLowerCase();
    final statusNorm = status.toLowerCase();
    String level = 'info';
    if (priorityNorm.contains('high') ||
        priorityNorm.contains('danger') ||
        priorityNorm.contains('crit') ||
        statusNorm.contains('danger')) {
      level = 'danger';
    } else if (priorityNorm.contains('med') ||
        priorityNorm.contains('warn') ||
        priorityNorm.contains('moyen') ||
        statusNorm.contains('warn')) {
      level = 'warning';
    }

    return {
      'title': title.isNotEmpty ? title : s.alertUntitled,
      'message': message,
      'location': (locationNamed == null || locationNamed!.trim().isEmpty) ? s.nearYou : locationNamed!.trim(),
      'recommendation': recommendation,
      'priority': priority.isEmpty ? 'info' : priority,
      'status': status.isEmpty ? 'unknown' : status,
      'typeLabel': (alertType.isNotEmpty ? alertType : typeField).ifEmpty('alerte'),
      'level': level,
    };
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
