import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/login_history_service.dart';
import '../services/nominatim_service.dart';

/// URL du backend. Utilisation du lien ngrok pour une connexion universelle.
String _kBaseUrl = 'https://alibi-deepen-pursuant.ngrok-free.dev';
String get kBaseUrl => _kBaseUrl;

/// En-têtes JSON pour les appels API (ngrok exige un header dédié).
Map<String, String> apiJsonHeaders({String? token}) {
  return {
    'Content-Type': 'application/json',
    if (kBaseUrl.contains('ngrok')) 'ngrok-skip-browser-warning': '69420',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

/// Initialise l'URL de base selon la plateforme et l'appareil.
Future<void> initApiConfig() async {
  const envUrl = String.fromEnvironment('BASE_URL');
  if (envUrl.isNotEmpty) {
    _kBaseUrl = envUrl;
    return;
  }

  if (kIsWeb) {
    _kBaseUrl = 'http://localhost:3000';
    return;
  }

  try {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Si c'est un émulateur, utiliser 10.0.2.2
      if (!androidInfo.isPhysicalDevice) {
        _kBaseUrl = 'http://10.0.2.2:3000';
        return;
      }
    }
  } catch (e) {
    debugPrint('Erreur lors de la détection de l\'appareil: $e');
  }

  // Fallback : URL ngrok pour accès depuis n'importe quel réseau
  _kBaseUrl = 'https://alibi-deepen-pursuant.ngrok-free.dev';
}

/// Service d'appel API pour connexion / inscription (relation Backend → MongoDB).
class ConnexionService {
  Future<bool> emailExists(String email) async {
    try {
      final uri = Uri.parse('$kBaseUrl/check-email').replace(queryParameters: {'email': email});
      final res = await http.get(uri, headers: apiJsonHeaders()).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>?;
        return data?['exists'] == true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('ConnexionService emailExists: $e');
      rethrow;
    }
  }
}

class AuthProvider with ChangeNotifier {
  final ConnexionService _connexionService = ConnexionService();
  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userFullName;
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userFullName => _userFullName;
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;

  ConnexionService get connexionService => _connexionService;

  AuthProvider() {
    _loadStoredToken(); // Charger le token au démarrage
  }

  /// Charger le token stocké dans SharedPreferences
  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token != null && userData != null) {
        _token = token;
        final decodedUser = jsonDecode(userData);
        _currentUser = UserModel.fromJson(decodedUser);
        _userFullName = _currentUser?.fullName;
        _userEmail = _currentUser?.email;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider _loadStoredToken: $e');
    }
  }

  /// Méthode setToken pour les connexions sociales et la connexion standard.
  Future<void> setToken(String token, {Map<String, dynamic>? userData}) async {
    _token = token;
    _isLoggedIn = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);

    if (userData != null) {
      _currentUser = UserModel.fromJson(userData);
      _userFullName = _currentUser?.fullName;
      _userEmail = _currentUser?.email;
      await prefs.setString('user_data', jsonEncode(userData));
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Inscription : envoie fullName (prénom + nom), email, password au backend (collection user_citoyen).
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required bool acceptTerms,
  }) async {
    _setLoading(true);
    try {
      final fullName = '$firstName $lastName'.trim();
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/addUser'),
            headers: apiJsonHeaders(),
            body: jsonEncode({
              'fullName': fullName,
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['token'] != null) {
          await setToken(data['token'], userData: data['user']);
        }
        return true;
      }
      final body = jsonDecode(res.body);
      final msg = body is Map ? (body['message'] ?? res.body) : res.body;
      throw Exception(msg.toString());
    } on TimeoutException catch (_) {
      if (kDebugMode) debugPrint('AuthProvider register: TimeoutException');
      throw Exception(
        'Le serveur ne répond pas. Vérifiez que le serveur est démarré (npm run dev) '
        'et que sur téléphone réel vous utilisez l\'IP de votre PC dans le code (pas 10.0.2.2).',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider register: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion : vérifie email/password via le backend (user_citoyen).
  Future<bool> login(String email, String password, bool rememberMe) async {
    _setLoading(true);
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/login'),
            headers: apiJsonHeaders(),
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200 && data?['success'] == true) {
        final token = data!['token'] ?? 'fake-jwt-token'; 
        await setToken(token, userData: data['user']);

        unawaited(Future(() async {
          String? dynamicLocation;
          try {
            // Tentative de récupération de la position actuelle
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 3),
            );
            dynamicLocation = await NominatimService.getPlaceName(position.latitude, position.longitude);
          } catch (e) {
            debugPrint('AuthProvider dynamic location error: $e');
            // Fallback sur les infos profil si le GPS échoue
            dynamicLocation = _currentUser?.cityRegion ?? _currentUser?.location;
          }
          await LoginHistoryService.recordSuccessfulLogin(location: dynamicLocation);
        }));
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = null;
    _userFullName = null;
    _currentUser = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  /// Met à jour le profil (et optionnellement la photo en base64) → API → MongoDB.
  Future<void> updateUserProfile(UserModel updatedUser, [String? profileImageBase64]) async {
    final userId = _currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }
    _setLoading(true);
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'fullName': updatedUser.fullName,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
        'location': updatedUser.location,
        if (updatedUser.dateOfBirth != null) 'dateOfBirth': updatedUser.dateOfBirth!.toIso8601String(),
        'gender': updatedUser.gender,
        'cityRegion': updatedUser.cityRegion,
      };
      if (profileImageBase64 != null) {
        body['profileImage'] = profileImageBase64;
      }
      final timeout = profileImageBase64 != null
          ? const Duration(seconds: 45)
          : const Duration(seconds: 15);
      final res = await http
          .put(
            Uri.parse('$kBaseUrl/updateProfile'),
            headers: apiJsonHeaders(token: _token),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200 && data?['success'] == true) {
        final user = data!['user'] as Map<String, dynamic>?;
        if (user != null) {
          _currentUser = UserModel.fromJson(user);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(user));
        } else {
          _currentUser = updatedUser.copyWith(
            profileImage: profileImageBase64 ?? updatedUser.profileImage,
          );
        }
        _userFullName = _currentUser!.fullName;
        _userEmail = _currentUser!.email;
        notifyListeners();
        return;
      }
      final msg = data?['message'] ?? res.body;
      throw Exception(msg.toString());
    } on TimeoutException catch (_) {
      if (kDebugMode) debugPrint('AuthProvider updateUserProfile: TimeoutException');
      throw Exception('Le serveur ne répond pas.');
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider updateUserProfile: $e');
      if (e.toString().contains('Connection closed') ||
          e.toString().contains('Connection reset')) {
        throw Exception(
          'Impossible de joindre le serveur. Vérifiez que ngrok et le backend (npm run dev) sont actifs.',
        );
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Change le mot de passe (mot de passe actuel + nouveau) → API → MongoDB.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final userId = _currentUser?.id;
    final email = _currentUser?.email;
    if ((userId == null || userId.isEmpty) && (email == null || email.isEmpty)) {
      throw Exception('Utilisateur non connecté');
    }
    _setLoading(true);
    try {
      final body = <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword.trim(),
      };
      if (userId != null && userId.isNotEmpty) body['userId'] = userId;
      if (email != null && email.isNotEmpty) body['email'] = email;
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/changePassword'),
            headers: apiJsonHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      if (res.statusCode == 200 && data?['success'] == true) return;
      final msg = data?['message'] ?? res.body;
      throw Exception(msg.toString());
    } on TimeoutException catch (_) {
      if (kDebugMode) debugPrint('AuthProvider changePassword: TimeoutException');
      throw Exception('Le serveur ne répond pas.');
    } catch (e) {
      if (kDebugMode) debugPrint('AuthProvider changePassword: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
