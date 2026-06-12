/// Modèle utilisateur pour le profil.
class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? bio;
  final String? phone;
  final String? location;
  final String? website;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? dateOfBirth;
  final String? gender; // 'Homme', 'Femme'
  final String? cityRegion; // Ville / Région
  final double? safetyScore; // Score de sécurité routière
  final int? tripsCount; // Nombre de trajets effectués
  // Profile / safety stats (optional, for profile screen)
  final int alertsSent;
  final int monitoredZones;
  final int emergencyContactsCount;
  final String securityLevel; // 'High', 'Medium', 'Low'
  final bool isDarkModeEnabled;

  const UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.bio,
    this.phone,
    this.location,
    this.website,
    this.profileImage,
    this.createdAt,
    this.dateOfBirth,
    this.gender,
    this.cityRegion,
    this.safetyScore,
    this.tripsCount,
    this.alertsSent = 24,
    this.monitoredZones = 5,
    this.emergencyContactsCount = 8,
    this.securityLevel = 'High',
    this.isDarkModeEnabled = true,
  });

  /// Alias for profile UI (fullName ?? '').
  String get name => fullName ?? email ?? '';

  /// Prénom (premier mot de fullName).
  String get firstName {
    final f = fullName?.trim() ?? '';
    if (f.isEmpty) return '';
    return f.split(RegExp(r'\s+')).first;
  }

  /// Nom (reste après le prénom).
  String get lastName {
    final f = fullName?.trim() ?? '';
    if (f.isEmpty) return '';
    final parts = f.split(RegExp(r'\s+'));
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      profileImage: json['profileImage'] as String?,
      createdAt: parseDate(json['createdAt']),
      dateOfBirth: parseDate(json['dateOfBirth']),
      gender: json['gender'] as String?,
      cityRegion: json['cityRegion'] as String?,
      safetyScore: (json['safetyScore'] as num?)?.toDouble(),
      tripsCount: json['tripsCount'] as int?,
      alertsSent: json['alertsSent'] as int? ?? 24,
      monitoredZones: json['monitoredZones'] as int? ?? 5,
      emergencyContactsCount: json['emergencyContactsCount'] as int? ?? 8,
      securityLevel: json['securityLevel'] as String? ?? 'High',
      isDarkModeEnabled: json['isDarkModeEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'phone': phone,
      'location': location,
      'website': website,
      'profileImage': profileImage,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      'gender': gender,
      'cityRegion': cityRegion,
      'safetyScore': safetyScore,
      'tripsCount': tripsCount,
      'alertsSent': alertsSent,
      'monitoredZones': monitoredZones,
      'emergencyContactsCount': emergencyContactsCount,
      'securityLevel': securityLevel,
      'isDarkModeEnabled': isDarkModeEnabled,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? bio,
    String? phone,
    String? location,
    String? website,
    String? profileImage,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    String? gender,
    String? cityRegion,
    double? safetyScore,
    int? tripsCount,
    int? alertsSent,
    int? monitoredZones,
    int? emergencyContactsCount,
    String? securityLevel,
    bool? isDarkModeEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      website: website ?? this.website,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      cityRegion: cityRegion ?? this.cityRegion,
      safetyScore: safetyScore ?? this.safetyScore,
      tripsCount: tripsCount ?? this.tripsCount,
      alertsSent: alertsSent ?? this.alertsSent,
      monitoredZones: monitoredZones ?? this.monitoredZones,
      emergencyContactsCount: emergencyContactsCount ?? this.emergencyContactsCount,
      securityLevel: securityLevel ?? this.securityLevel,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
    );
  }
}
