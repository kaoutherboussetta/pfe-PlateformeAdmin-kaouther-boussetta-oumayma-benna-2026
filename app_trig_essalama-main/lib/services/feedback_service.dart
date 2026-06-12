import 'dart:convert';

import '../models/feedback_model.dart';
import 'api_client.dart';

/// Envoie les avis vers le backend (MongoDB via Express).
class FeedbackService {
  final ApiClient api;

  FeedbackService(this.api);

  /// Enregistre un avis pour l'utilisateur authentifié (JWT).
  Future<FeedbackModel> submitFeedback({
    required int rating,
    String comment = '',
  }) async {
    final res = await api.post('/feedback', {
      'rating': rating,
      'comment': comment,
    });

    if (res.statusCode != 201) {
      var msg = 'Impossible d\'envoyer l\'avis';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        }
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final fb = data?['feedback'] as Map<String, dynamic>?;
    if (fb == null) throw Exception('Réponse serveur invalide');
    return FeedbackModel.fromJson(fb);
  }
}
