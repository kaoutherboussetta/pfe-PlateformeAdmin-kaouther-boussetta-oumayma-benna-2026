import 'dart:io';

import '../models/user_model.dart';

/// Service pour charger les données utilisateur (profil, stats, activités, badges).
/// Utilise les données en mémoire / à terme un backend.
class UserService {
  Future<UserModel?> getCurrentUser(String userId) async {
    // Pour l'instant, on construit un utilisateur à partir de l'id (ex: email utilisé comme id).
    return UserModel(
      id: userId,
      fullName: null,
      email: null,
      bio: null,
      phone: null,
      location: null,
      website: null,
      profileImage: null,
    );
  }

  Future<UserModel?> getUserById(String id) async {
    return getCurrentUser(id);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return {
      'trajets': 0,
      'km': 0,
      'jours': 0,
    };
  }

  Future<List<dynamic>> getUserActivities(String userId) async {
    return [];
  }

  Future<List<dynamic>> getUserBadges(String userId) async {
    return [];
  }

  /// Télécharge la photo de profil (stub : à brancher sur votre API).
  /// Retourne l'URL de l'image ou null.
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  /// Met à jour le profil utilisateur (stub : à brancher sur votre API).
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
