/// Modèle pour un contact d'urgence (API + page).
class EmergencyContact {
  final String? id;
  final String name;
  final String phone;
  final String relationship;
  final String email;
  final bool isPrimary;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.email = '',
    this.isPrimary = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      relationship: (json['relationship'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      isPrimary: json['isPrimary'] == true,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    String? email,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
