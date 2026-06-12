import 'dart:convert';
import '../models/emergency_contact_model.dart';
import 'api_client.dart';

/// Service API pour les contacts d'urgence (backend MongoDB).
class EmergencyContactsService {
  final ApiClient api;

  EmergencyContactsService(this.api);

  Future<List<EmergencyContact>> getContacts(String userId) async {
    final res = await api.get('/emergency-contacts?userId=$userId');
    
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : 'Erreur serveur';
      throw Exception(msg.toString());
    }
    
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final list = data?['contacts'] as List<dynamic>? ?? [];
    return list
        .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EmergencyContact> addContact(String userId, EmergencyContact contact) async {
    final res = await api.post(
      '/emergency-contacts',
      {
        'userId': userId,
        'name': contact.name,
        'phone': contact.phone,
        'relationship': contact.relationship,
        'email': contact.email,
        'isPrimary': contact.isPrimary,
      },
    );
    
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : 'Erreur serveur';
      throw Exception(msg.toString());
    }
    
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final c = data?['contact'] as Map<String, dynamic>?;
    if (c == null) throw Exception('Réponse invalide');
    return EmergencyContact.fromJson(c);
  }

  Future<EmergencyContact> updateContact(
    String userId,
    String contactId,
    EmergencyContact contact,
  ) async {
    final res = await api.put(
      '/emergency-contacts/$contactId',
      {
        'userId': userId,
        'name': contact.name,
        'phone': contact.phone,
        'relationship': contact.relationship,
        'email': contact.email,
        'isPrimary': contact.isPrimary,
      },
    );
    
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : 'Erreur serveur';
      throw Exception(msg.toString());
    }
    
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final c = data?['contact'] as Map<String, dynamic>?;
    if (c == null) throw Exception('Réponse invalide');
    return EmergencyContact.fromJson(c);
  }

  Future<void> deleteContact(String userId, String contactId) async {
    final res = await api.delete('/emergency-contacts/$contactId?userId=$userId');
    
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      final msg = body is Map ? body['message'] : 'Erreur serveur';
      throw Exception(msg.toString());
    }
  }
}
