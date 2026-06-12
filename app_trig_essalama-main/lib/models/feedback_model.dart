/// Avis utilisateur (synchronisé avec la collection MongoDB `user_feedback`).
class FeedbackModel {
  final String? id;
  final String userId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const FeedbackModel({
    this.id,
    required this.userId,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return FeedbackModel(
      id: json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      rating: (json['rating'] is int) ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
