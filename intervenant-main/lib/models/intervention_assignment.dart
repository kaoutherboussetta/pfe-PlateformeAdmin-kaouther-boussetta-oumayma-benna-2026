class InterventionAssignment {
  const InterventionAssignment({
    required this.id,
    required this.problemId,
    required this.team,
    required this.title,
    required this.type,
    required this.description,
    required this.address,
    required this.status,
    required this.estimatedCost,
    required this.riskScore,
    required this.severity,
    required this.confidence,
    required this.detectedAt,
    required this.priority,
    this.lat,
    this.lng,
    required this.updatedAt,
  });

  final String id;
  final String problemId;
  final String team;
  final String title;
  final String type;
  final String description;
  final String address;
  final String status;
  final String estimatedCost;
  final int riskScore;
  final String severity;
  final int confidence;
  final String detectedAt;
  final String priority;
  final double? lat;
  final double? lng;
  final String updatedAt;

  factory InterventionAssignment.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return InterventionAssignment(
      id: (json['id'] as String? ?? '').trim(),
      problemId: (json['problem_id'] as String? ?? '').trim(),
      team: (json['team'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? 'Intervention').trim(),
      type: (json['type'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      address: (json['address'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      estimatedCost: (json['estimated_cost'] as String? ?? '').trim(),
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      severity: (json['severity'] as String? ?? '').trim(),
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      detectedAt: (json['detected_at'] as String? ?? '').trim(),
      priority: (json['priority'] as String? ?? '').trim(),
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
      updatedAt: (json['updated_at'] as String? ?? '').trim(),
    );
  }
}
