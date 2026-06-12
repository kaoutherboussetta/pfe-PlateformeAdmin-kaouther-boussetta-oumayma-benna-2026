import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intervenant/constants/backend_defaults.dart';
import 'package:intervenant/models/account_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intervenant/models/intervention_assignment.dart';
import 'package:intervenant/models/app_notification.dart';
import 'package:intervenant/models/probleme_voirie.dart';

class AuthApiService {
  AuthApiService._();

  static final AuthApiService instance = AuthApiService._();
  static String? _customBaseUrl;

  /// Android / iOS (app native ou Flutter Web ouvert sur le téléphone) : `localhost` = l’appareil, pas le PC.
  static bool get _runningOnPhone =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool _isLoopbackHost(Uri? u) =>
      u != null && u.hasAuthority && (u.host == 'localhost' || u.host == '127.0.0.1');

  /// Oublie une URL sauvegardée en localhost / 127.0.0.1 sur téléphone.
  static void _dropLoopbackCustomOnMobile() {
    if (!_runningOnPhone) return;
    final String? c = _customBaseUrl;
    if (c == null || c.isEmpty) return;
    if (!_isLoopbackHost(Uri.tryParse(c))) return;
    _customBaseUrl = null;
    SharedPreferences.getInstance().then((SharedPreferences p) => p.remove(_prefsKeyApiUrl));
  }

  /// Build: `--dart-define=API_BASE_URL=https://votre-api.example.com` (n’importe quelle IP / domaine / ngrok).
  static const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Vrai si une racine API est connue (build, préférences, ou liste de repli).
  static bool get isServerUrlConfigured {
    _dropLoopbackCustomOnMobile();
    if (baseUrl.trim().isNotEmpty) return true;
    return kBackendFallbackBaseUrls.isNotEmpty;
  }

  /// Libellé pour l’UI.
  static String get baseUrlLabel {
    final String u = baseUrl.trim();
    if (u.isNotEmpty) return u;
    if (kBackendFallbackBaseUrls.isNotEmpty) {
      return 'Auto (${kBackendFallbackBaseUrls.length} adresses)';
    }
    if (_runningOnPhone) {
      return 'Non configuré — saisissez l’URL (Wi‑Fi ou ngrok)';
    }
    return 'http://127.0.0.1:$kBackendDefaultPort ou URL ngrok';
  }

  /// Indication pour tester l’API (sans IP codée) : utilise `baseUrl` ou renvoie un texte générique.
  static String backendHealthConnectivityHint() {
    final String root = baseUrl.trim();
    if (root.isNotEmpty) {
      return '$root/api/health';
    }
    return 'Saisissez la racine sur l’écran de connexion : '
        'http://<IP_PC>:$kBackendDefaultPort (même Wi‑Fi) ou l’URL « Forwarding » ngrok (https://….ngrok-free.dev, '
        'backend sur PORT=$kBackendDefaultPort). Au npm start, le terminal affiche aussi les liens /api/health.';
  }

  static String get baseUrl {
    _dropLoopbackCustomOnMobile();

    final String fromEnv = _apiBaseUrlFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return normalizeBackendBaseUrl(fromEnv);
    }
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return normalizeBackendBaseUrl(_customBaseUrl!);
    }
    return kBackendDefaultBaseUrl;
  }

  static String? _missingBaseUrlOnPhoneMessage() {
    if (!_runningOnPhone) return null;
    if (baseUrl.trim().isNotEmpty || kBackendFallbackBaseUrls.isNotEmpty) return null;
    return 'Saisissez l’URL du backend (bouton ci-dessous), par exemple ngrok ou l’IP affichée au npm start.';
  }

  /// Toutes les racines à tester (URL enregistrée, build, ngrok, IP locale…).
  static List<String> candidateBackendBases() {
    _dropLoopbackCustomOnMobile();
    final List<String> out = <String>[];

    void add(String? raw) {
      if (raw == null || raw.trim().isEmpty) return;
      final String normalized = normalizeBackendBaseUrl(raw);
      if (normalized.isEmpty) return;
      if (_runningOnPhone && _isLoopbackHost(Uri.tryParse(normalized))) return;
      if (!out.contains(normalized)) out.add(normalized);
    }

    add(_customBaseUrl);
    add(_apiBaseUrlFromEnv);
    for (final String fallback in kBackendFallbackBaseUrls) {
      add(fallback);
    }
    if (!_runningOnPhone) {
      add('http://127.0.0.1:$kBackendDefaultPort');
    }
    return out;
  }

  static Future<bool> _probeBackendHealth(String base) async {
    try {
      final http.Response res = await http
          .get(
            Uri.parse('$base/api/health'),
            headers: <String, String>{
              'Accept': 'application/json',
              ..._extraHeadersForBase(base),
            },
          )
          .timeout(const Duration(seconds: 8));
      final Map<String, dynamic>? body = _tryDecodeJsonObject(res.body);
      return res.statusCode >= 200 &&
          res.statusCode < 300 &&
          body != null &&
          body['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Teste ngrok, IP locale, etc. et enregistre la première URL qui répond.
  static Future<bool> autoDiscoverBackend({bool persist = true}) async {
    for (final String base in candidateBackendBases()) {
      if (await _probeBackendHealth(base)) {
        if (persist) {
          await saveBaseUrl(base);
        } else {
          setCustomBaseUrl(base);
        }
        return true;
      }
    }
    return false;
  }

  /// Utilise l’URL courante ou bascule automatiquement sur une adresse de repli.
  static Future<bool> ensureBackendReachable() async {
    final String current = baseUrl.trim();
    if (current.isNotEmpty && await _probeBackendHealth(current)) {
      return true;
    }
    return autoDiscoverBackend();
  }

  /// Construit une URL API à partir de la racine (évite les doubles `/api` si la base est mal collée).
  static Uri backendPathUri(String baseRoot, String path, [Map<String, String>? query]) {
    final String root = normalizeBackendBaseUrl(baseRoot.trim());
    final Uri u = Uri.parse(root);
    final String p = path.startsWith('/') ? path : '/$path';
    return u.replace(path: p, queryParameters: query);
  }

  /// URL racine uniquement (`scheme://hôte:port`). Ignore tout chemin (/api, /ancien-chemin…) pour éviter les 404 HTML.
  static String normalizeBackendBaseUrl(String value) {
    final String v = value.trim().replaceAll(RegExp(r'\/+$'), '');
    final Uri? u = Uri.tryParse(v);
    if (u == null || !u.hasScheme || u.host.isEmpty) return v;
    if (!u.hasAuthority) return v;
    return u.origin;
  }

  static void setCustomBaseUrl(String value) {
    final String normalized = normalizeBackendBaseUrl(value);
    if (normalized.isNotEmpty) {
      _customBaseUrl = normalized;
    }
  }

  static const String _prefsKeyApiUrl = 'api_base_url';
  static const String _prefsKeySessionEmail = 'session_intervenant_email';
  static const String _prefsKeySessionName = 'session_intervenant_name';

  /// Après login réussi : garde une trace locale (sans mot de passe) pour logout / UX.
  static Future<void> saveSessionAfterLogin({required String email, required String name}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeySessionEmail, email.trim().toLowerCase());
    await prefs.setString(_prefsKeySessionName, name.trim());
  }

  /// Déconnexion : efface uniquement la session locale (ne supprime pas l’URL du serveur).
  static Future<void> logoutClearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeySessionEmail);
    await prefs.remove(_prefsKeySessionName);
  }

  static Future<void> loadSavedBaseUrl() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKeyApiUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      final Uri? parsed = Uri.tryParse(saved.trim());
      if (_runningOnPhone && _isLoopbackHost(parsed)) {
        await prefs.remove(_prefsKeyApiUrl);
        _customBaseUrl = null;
        return;
      }
      setCustomBaseUrl(saved);
    }
  }

  static Map<String, String> _extraHeadersForBase(String base) {
    final Uri? u = Uri.tryParse(base);
    if (u == null || !u.hasAuthority) return const {};
    final String host = u.host.toLowerCase();
    if (host.contains('ngrok-free.') ||
        host.contains('ngrok.app') ||
        host.contains('ngrok.io') ||
        host.endsWith('.ngrok.app')) {
      return const {'ngrok-skip-browser-warning': '69420'};
    }
    return const {};
  }

  static String _prepareJsonBody(String body) {
    var s = body.trim();
    if (s.startsWith('\uFEFF')) {
      s = s.substring(1).trim();
    }
    return s;
  }

  static Map<String, dynamic> _decodeJsonMap(String body, {int? statusCode}) {
    final String s = _prepareJsonBody(body);
    if (s.isEmpty) {
      return {
        'message': 'Réponse vide du serveur (HTTP ${statusCode ?? '?'}). Vérifiez que le backend tourne.',
      };
    }
    try {
      final Object? decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      /* handled below */
    }
    final String lower = s.toLowerCase();
    final bool looksHtml = lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('<body') ||
        s.trimLeft().startsWith('<');
    final String snippet = s.length > 160 ? '${s.substring(0, 160)}…' : s;
    return {
      'message': looksHtml
          ? 'HTTP ${statusCode ?? '?'} : page HTML au lieu du JSON. '
              'Testez depuis le téléphone : .../api/health (JSON attendu). '
              'Utilisez une URL sans chemin après le port : `http://IP:PORT`. '
              'Relancez le backend (node server.js) et fermez tout autre outil qui utiliserait le même port.'
          : 'Réponse non JSON (HTTP ${statusCode ?? '?'}): $snippet',
    };
  }

  static bool _responseSuccess(dynamic value) {
    if (value == true) return true;
    if (value == 1) return true;
    if (value is String && value.toLowerCase() == 'true') return true;
    return false;
  }

  /// Retourne `false` si l’URL est refusée (ex. localhost sur téléphone).
  static Future<bool> saveBaseUrl(String value) async {
    final String normalized = normalizeBackendBaseUrl(value);
    if (normalized.isEmpty) return false;
    if (_runningOnPhone && _isLoopbackHost(Uri.tryParse(normalized))) {
      return false;
    }
    setCustomBaseUrl(normalized);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyApiUrl, baseUrl);
    return true;
  }

  List<String> _candidateBackendBasesForAssignments() {
    final List<String> bases = candidateBackendBases();
    if (bases.isNotEmpty) return bases;
    throw Exception(
      'URL du serveur non configurée. Ajoutez une URL ngrok ou IP dans kBackendFallbackBaseUrls '
      'ou saisissez-la dans l’app.',
    );
  }

  static Map<String, dynamic>? _tryDecodeJsonObject(String body) {
    final String s = _prepareJsonBody(body);
    if (s.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static Object? _tryDecodeJsonAny(String body) {
    final String s = _prepareJsonBody(body);
    if (s.isEmpty) return null;
    try {
      return jsonDecode(s);
    } catch (_) {}
    return null;
  }

  static const Duration _httpTimeout = Duration(seconds: 18);

  /// Vrai si la route liste notifications existe (ancien binaire sur le port → 404 « API route not found »).
  Future<bool> _probeNotificationsListRoute(String base, Map<String, String> headers) async {
    const paths = <String>[
      '/api/notifications',
      '/api/notifications-intervenant',
    ];
    for (final path in paths) {
      try {
        final Uri u = backendPathUri(
          base,
          path,
          <String, String>{'userId': 'health_probe@local', 'limit': '1'},
        );
        final http.Response res = await http.get(u, headers: headers).timeout(_httpTimeout);
        if (res.statusCode == 404) continue;
        final Object? decoded = _tryDecodeJsonAny(res.body);
        if (decoded == null) continue;
        if (res.statusCode == 503 && decoded is Map) {
          final String? m = decoded['message'] as String?;
          if (m != null && m.toLowerCase().contains('indisponible')) return true;
          continue;
        }
        if (res.statusCode >= 200 && res.statusCode < 300) {
          if (decoded is List) return true;
          if (decoded is Map && _responseSuccess(Map<String, dynamic>.from(decoded)['success'])) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  /// Évite les 404 HTML : confirme que c’est bien `server.js` (intervenant-backend), pas un autre outil sur le port.
  ///
  /// [requireNotificationsApi] : uniquement pour charger les notifications — exige la clé `notificationsApi`
  /// dans `/api/health` ou la clé `notifications` sur `GET /`. Les chantiers / affectations restent tolérants
  /// tant que `/api/health` renvoie `status: ok`.
  ///
  /// [requireProblemesVoirieApi] : si le health déclare explicitement `problemesVoirieApi: false`, on refuse tôt.
  /// Si la clé est absente (backend plus ancien), on ne bloque pas ici — l’app retentera `/api/problemes_voirie` au besoin.
  Future<void> _ensureIntervenantBackendReachable(
    String base, {
    bool requireNotificationsApi = false,
    bool requireProblemesVoirieApi = false,
  }) async {
    final Map<String, String> headers = {
      'Accept': 'application/json',
      ..._extraHeadersForBase(base),
    };

    late final http.Response healthRes;
    late final http.Response rootRes;
    try {
      healthRes = await http
          .get(Uri.parse('$base/api/health'), headers: headers)
          .timeout(_httpTimeout);
    } catch (e) {
      throw Exception('Connexion impossible vers $base (health). Erreur: $e');
    }
    try {
      rootRes = await http.get(Uri.parse('$base/'), headers: headers).timeout(_httpTimeout);
    } catch (_) {
      rootRes = http.Response('', 0);
    }

    final Map<String, dynamic>? hm = _tryDecodeJsonObject(healthRes.body);
    final Map<String, dynamic>? rm = _tryDecodeJsonObject(rootRes.body);

    final bool healthOk = healthRes.statusCode >= 200 &&
        healthRes.statusCode < 300 &&
        hm != null &&
        hm['status'] == 'ok';

    if (healthOk) {
      if (requireProblemesVoirieApi && hm['problemesVoirieApi'] != true) {
        throw Exception(
          'Le PC qui écoute sur $base n’exécute pas le bon backend (ou une vieille copie).\n'
          'Vérifiez sur le PC : dans un navigateur, ouvrez $base/api/health — la réponse JSON doit contenir '
          '"problemesVoirieApi": true.\n'
          'Sinon : fermez l’ancien Node (PowerShell : netstat -ano | findstr :$kBackendDefaultPort puis taskkill /PID … /F), '
          'allez dans le dossier backend de ce projet, npm start (port $kBackendDefaultPort, aligné avec ngrok http $kBackendDefaultPort), '
          'et dans l’app mettez la même racine (http://IP:$kBackendDefaultPort ou votre URL ngrok).',
        );
      }
      if (!requireNotificationsApi) {
        return;
      }
      if (hm['notificationsApi'] == true) {
        return;
      }
      final bool rootHasNotifHint = rootRes.statusCode >= 200 &&
          rootRes.statusCode < 300 &&
          rm != null &&
          rm['service'] == 'intervenant-backend' &&
          rm['notifications'] != null;
      if (rootHasNotifHint) {
        return;
      }
      if (await _probeNotificationsListRoute(base, headers)) {
        return;
      }
      final int port = Uri.tryParse(base)?.port ?? kBackendDefaultPort;
      throw Exception(
        'Sur $base, ce n’est pas le bon backend « intervenant » (souvent un ancien Node garde encore le port $port). '
        'Après npm start, le backend doit écouter sur le port $kBackendDefaultPort (voir backend/.env). '
        'Mettez la même racine dans l’app. Si ngrok : `ngrok http $kBackendDefaultPort` puis l’URL https affichée. '
        'Port occupé : netstat -ano | findstr :$kBackendDefaultPort puis taskkill /PID … /F.',
      );
    }

    if (rootRes.statusCode >= 200 &&
        rootRes.statusCode < 300 &&
        rm != null &&
        rm['service'] == 'intervenant-backend') {
      if (requireNotificationsApi && rm['notifications'] == null) {
        final int port = Uri.tryParse(base)?.port ?? kBackendDefaultPort;
        throw Exception(
          'Notifications : racine JSON sans clé « notifications » — backend trop ancien ou mauvais programme. '
          'netstat -ano | findstr :$port puis arrêtez l’ancien Node, relancez npm run dev.',
        );
      }
      return;
    }

    final Uri? pu = Uri.tryParse(base);
    final String host = pu?.host ?? base;
    final int port = pu?.port ?? kBackendDefaultPort;
    throw Exception(
      'Sur $base ce n’est pas le backend intervenant (/api/health attend du JSON avec "status":"ok").\n'
      'Le plus souvent : un AUTRE programme utilise déjà le port (page HTML).\n'
      'Vérifiez backend/.env (PORT), redémarrez avec npm run dev, puis dans l’app saisissez http://$host:$port.',
    );
  }

  Future<String?> register({
    required String name,
    required String nom,
    required String prenom,
    required String equipe,
    required String email,
    required String password,
  }) async {
    if (!await ensureBackendReachable()) {
      return 'Serveur injoignable. Vérifiez ngrok (npm run dev + ngrok http 3000) ou le Wi‑Fi.';
    }

    final Uri url = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        ..._extraHeadersForBase(baseUrl),
      },
      body: jsonEncode({
        'name': name,
        'nom': nom,
        'prenom': prenom,
        'equipe': equipe,
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return null;
    }
    return (body['message'] as String?) ?? 'Erreur inscription.';
  }

  Future<({AccountInfo? account, String? errorMessage})> login({
    required String email,
    required String password,
  }) async {
    if (!await ensureBackendReachable()) {
      return (
        account: null,
        errorMessage:
            'Serveur injoignable. Vérifiez ngrok ou l’IP locale (npm run dev), puis réessayez.',
      );
    }

    final Uri url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        ..._extraHeadersForBase(baseUrl),
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> user = (body['user'] as Map<String, dynamic>?) ?? {};
      final account = AccountInfo(
        name: (user['name'] as String? ?? 'Intervenant'),
        email: (user['email'] as String? ?? email),
        password: password,
        equipe: (user['equipe'] as String?)?.trim(),
      );
      return (account: account, errorMessage: null);
    }

    return (
      account: null,
      errorMessage: (body['message'] as String?) ?? 'Erreur connexion.',
    );
  }

  Future<List<InterventionAssignment>> fetchAssignments({String? teamLabel}) async {
    final Map<String, String> query = {};
    if (teamLabel != null && teamLabel.trim().isNotEmpty) {
      final String normalizedLabel = teamLabel.trim();
      query['team_label'] = normalizedLabel;

      final RegExp digitsPattern = RegExp(r'(\d+)');
      final Match? m = digitsPattern.firstMatch(normalizedLabel);
      if (m != null) {
        query['team_key'] = 'equipe_${m.group(1)}';
      }
    }
    query['limit'] = '200';

    const assignmentPaths = <String>[
      '/api/intervenant/assignments',
      '/api/assignments',
    ];

    String? lastError;
    final tried = <String>[];
    for (final base in _candidateBackendBasesForAssignments()) {
      try {
        await _ensureIntervenantBackendReachable(base);
      } catch (e) {
        lastError = _stripExceptionPrefix(e.toString());
        continue;
      }
      for (final path in assignmentPaths) {
        final String attempt = '$base$path';
        tried.add(attempt);
        try {
          final Uri url = Uri.parse(attempt).replace(queryParameters: query);
          final response = await http
              .get(
                url,
                headers: {
                  'Accept': 'application/json',
                  ..._extraHeadersForBase(base),
                },
              )
              .timeout(_httpTimeout);

          final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
          if (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              _responseSuccess(body['success'])) {
            final List<dynamic> rawItems = (body['items'] as List<dynamic>?) ?? const [];
            return rawItems
                .whereType<Map<String, dynamic>>()
                .map(InterventionAssignment.fromJson)
                .toList(growable: false);
          }
          lastError = (body['message'] as String?) ?? 'Réponse invalide (${response.statusCode}) $attempt';
        } catch (e) {
          lastError = _stripExceptionPrefix(e.toString());
        }
      }
    }

    throw Exception(
      '${lastError ?? 'Impossible de charger les affectations.'} '
      '(URLs testées: ${tried.join(', ')})',
    );
  }

  /// Met à jour le statut opérationnel d’un chantier (`assigné`, `en_cours`, `en_pause`, `terminé`).
  Future<InterventionAssignment> patchAssignmentStatus({
    required String assignmentId,
    required String status,
  }) async {
    final String id = assignmentId.trim();
    if (id.isEmpty) {
      throw Exception('Identifiant chantier manquant.');
    }
    String? lastError;
    final tried = <String>[];
    for (final base in _candidateBackendBasesForAssignments()) {
      try {
        await _ensureIntervenantBackendReachable(base);
      } catch (e) {
        lastError = _stripExceptionPrefix(e.toString());
        continue;
      }
      const suffixes = <String>[
        '/api/intervenant/assignments',
        '/api/assignments',
      ];
      for (final prefix in suffixes) {
        final String attempt = '$base$prefix/$id/status';
        tried.add(attempt);
        try {
          final Uri url = Uri.parse(attempt);
          final response = await http
              .patch(
                url,
                headers: _jsonHeaders(),
                body: jsonEncode(<String, String>{'status': status}),
              )
              .timeout(_httpTimeout);
          final Map<String, dynamic> body =
              _decodeJsonMap(response.body, statusCode: response.statusCode);
          if (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              _responseSuccess(body['success'])) {
            final Map<String, dynamic>? raw =
                body['item'] is Map<String, dynamic> ? body['item'] as Map<String, dynamic> : null;
            if (raw != null) {
              return InterventionAssignment.fromJson(raw);
            }
            throw Exception((body['message'] as String?) ?? 'Réponse sans détail chantier.');
          }
          lastError = (body['message'] as String?) ?? 'Réponse invalide (${response.statusCode}) $attempt';
        } catch (e) {
          lastError = _stripExceptionPrefix(e.toString());
        }
      }
    }
    throw Exception(
      '${lastError ?? 'Impossible de mettre à jour le statut.'} '
      '(URLs testées: ${tried.join(', ')})',
    );
  }

  /// Liste des problèmes de voirie (`GET /api/problemes-voirie`, Mongo `problemes_de_voirie`).
  /// [limit] plafonné côté API (5000) pour renvoyer tous les enregistrements de l’équipe.
  Future<List<ProblemeVoirie>> fetchProblemesVoirie({String? teamLabel, int limit = 5000}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final String base = baseUrl.trim();
    await _ensureIntervenantBackendReachable(base, requireProblemesVoirieApi: true);
    final Map<String, String> query = <String, String>{
      'limit': '${limit.clamp(1, 5000)}',
    };
    final String? label = teamLabel?.trim();
    if (label != null && label.isNotEmpty) {
      query['team_label'] = label;
      final RegExp digitsPattern = RegExp(r'(\d+)');
      final Match? m = digitsPattern.firstMatch(label);
      if (m != null) {
        query['team_key'] = 'equipe_${m.group(1)}';
      }
    }

    Future<List<ProblemeVoirie>> oneGet(String path, Map<String, String> qp) async {
      final Uri url = backendPathUri(base, path, qp);
      final http.Response response =
          await http.get(url, headers: _jsonHeaders()).timeout(_httpTimeout);
      final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          !_responseSuccess(body['success'])) {
        throw Exception((body['message'] as String?) ?? 'Impossible de charger les problèmes voirie.');
      }
      final List<dynamic> raw = (body['items'] as List<dynamic>?) ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ProblemeVoirie.fromJson)
          .toList(growable: false);
    }

    try {
      return await oneGet('/api/problemes-voirie', query);
    } catch (e) {
      final String msg = _stripExceptionPrefix(e.toString());
      if (msg.contains('API route not found') && msg.contains('problemes-voirie')) {
        try {
          return await oneGet('/api/problemes_voirie', query);
        } catch (_) {
          throw Exception(
            'Le serveur à l’adresse $base est une ancienne version : il n’expose pas GET /api/problemes-voirie. '
            'Sur le PC : ouvrez le dossier backend, faites git pull si besoin, puis redémarrez avec npm start '
            '(backend sur le port $kBackendDefaultPort, tunnel `ngrok http $kBackendDefaultPort`) et mettez la racine ngrok dans l’app.',
          );
        }
      }
      rethrow;
    }
  }

  /// Liste affichée dans l’onglet Notifications : même source Mongo que les chantiers (`problemes_de_voirie`).
  Future<List<AppNotification>> fetchNotificationsAsProblemesVoirie({String? teamLabel, int limit = 500}) async {
    final List<ProblemeVoirie> items = await fetchProblemesVoirie(teamLabel: teamLabel, limit: limit);
    return items.map(AppNotification.fromProblemeVoirie).toList(growable: false);
  }

  /// Met à jour le statut métier (« En cours », « Terminé », …).
  Future<ProblemeVoirie> patchProblemeVoirieStatus({
    required String id,
    required String status,
  }) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final String base = baseUrl.trim();
    await _ensureIntervenantBackendReachable(base, requireProblemesVoirieApi: true);
    final String sid = id.trim();

    Future<ProblemeVoirie> onePatch(String pathPrefix) async {
      final Uri url = backendPathUri(base, '$pathPrefix/$sid');
      final http.Response response = await http
          .patch(
            url,
            headers: _jsonHeaders(),
            body: jsonEncode(<String, String>{'status': status}),
          )
          .timeout(_httpTimeout);
      final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          !_responseSuccess(body['success'])) {
        throw Exception((body['message'] as String?) ?? 'Mise à jour impossible.');
      }
      final Map<String, dynamic>? raw =
          body['item'] is Map<String, dynamic> ? body['item'] as Map<String, dynamic> : null;
      if (raw == null) {
        throw Exception('Réponse sans détail problème.');
      }
      return ProblemeVoirie.fromJson(raw);
    }

    try {
      return await onePatch('/api/problemes-voirie');
    } catch (e) {
      final String msg = _stripExceptionPrefix(e.toString());
      if (msg.contains('API route not found') && msg.contains('problemes-voirie')) {
        return await onePatch('/api/problemes_voirie');
      }
      rethrow;
    }
  }

  static String _stripExceptionPrefix(String s) {
    return s.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Map<String, String> _jsonHeaders() {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ..._extraHeadersForBase(baseUrl),
    };
  }

  static List<AppNotification> _parseNotificationsBody(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> err = _decodeJsonMap(response.body, statusCode: response.statusCode);
      throw Exception(
        (err['message'] as String?) ??
            (err['error'] as String?) ??
            'Impossible de charger les notifications.',
      );
    }
    final Object? decoded = _tryDecodeJsonAny(response.body);
    if (decoded is List) {
      return <AppNotification>[
        for (final Object? e in decoded)
          if (e is Map) AppNotification.fromJson(Map<String, dynamic>.from(e)),
      ];
    }
    if (decoded is Map) {
      final Map<String, dynamic> body = Map<String, dynamic>.from(decoded);
      if (!_responseSuccess(body['success'])) {
        throw Exception((body['message'] as String?) ?? 'Impossible de charger les notifications.');
      }
      final List<dynamic> raw = (body['items'] as List<dynamic>?) ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(growable: false);
    }
    throw Exception('Réponse notifications invalide : JSON ni tableau ni objet attendu.');
  }

  /// Liste des notifications.
  ///
  /// Par défaut : `GET /api/notifications/:clé` (flux unifié : `notification_intervenant` filtré +
  /// alertes `status: active`). [userId] est en général l’email ; [secondaryIntervenantId] optionnel
  /// (ex. `interv_001`) est passé en query `?intervenantId=`.
  /// Retombée sur `GET /api/notifications` si l’endpoint unifié répond 404.
  Future<List<AppNotification>> fetchNotifications({
    String userId = '',
    String? secondaryIntervenantId,
  }) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) {
      throw Exception(missing);
    }
    final String base = baseUrl.trim();
    await _ensureIntervenantBackendReachable(base, requireNotificationsApi: true);
    final String primary = userId.trim();
    final String? sec = secondaryIntervenantId?.trim();
    final Map<String, String> qp = <String, String>{'limit': '200'};
    if (sec != null && sec.isNotEmpty && sec != primary) {
      qp['intervenantId'] = sec;
    }

    String? pathKey;
    if (primary.isNotEmpty) {
      pathKey = primary;
    } else if (sec != null && sec.isNotEmpty) {
      pathKey = sec;
    }

    if (pathKey != null) {
      final String enc = Uri.encodeComponent(pathKey);
      final Uri unifiedUrl = backendPathUri(base, '/api/notifications/$enc', qp);
      final http.Response unifiedRes =
          await http.get(unifiedUrl, headers: _jsonHeaders()).timeout(_httpTimeout);
      final bool unifiedLooksValid = unifiedRes.statusCode >= 200 &&
          unifiedRes.statusCode < 300 &&
          () {
            final Object? dec = _tryDecodeJsonAny(unifiedRes.body);
            if (dec is Map) {
              return _responseSuccess(Map<String, dynamic>.from(dec)['success']);
            }
            return dec is List;
          }();
      if (unifiedLooksValid) {
        return _parseNotificationsBody(unifiedRes);
      }
    }

    final String uid = primary.toLowerCase();
    final Map<String, String> qpLegacy = <String, String>{'limit': '200'};
    if (uid.isNotEmpty) qpLegacy['userId'] = uid;

    Uri url = backendPathUri(base, '/api/notifications', qpLegacy);
    http.Response response =
        await http.get(url, headers: _jsonHeaders()).timeout(_httpTimeout);
    if (response.statusCode == 404) {
      url = backendPathUri(base, '/api/notifications-intervenant', qpLegacy);
      response = await http.get(url, headers: _jsonHeaders()).timeout(_httpTimeout);
    }
    return _parseNotificationsBody(response);
  }

  /// Toutes les alertes MongoDB (`GET /api/alerts`) — sans filtre intervenant ; tri côté serveur (timestamp / dates).
  Future<List<AppNotification>> fetchAlerts({int limit = 200}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) {
      throw Exception(missing);
    }
    final String base = baseUrl.trim();
    await _ensureIntervenantBackendReachable(base, requireNotificationsApi: true);
    final Uri url = backendPathUri(
      base,
      '/api/alerts',
      <String, String>{'limit': '${limit.clamp(1, 500)}'},
    );
    final http.Response res =
        await http.get(url, headers: _jsonHeaders()).timeout(_httpTimeout);
    return _parseNotificationsBody(res);
  }

  Future<List<Map<String, dynamic>>> fetchChatItems({
    required String intervenantId,
    int limit = 500,
  }) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final String base = baseUrl.trim();
    final Uri url = backendPathUri(
      base,
      '/api/chat/intervenant',
      <String, String>{
        'intervenant_id': intervenantId.trim(),
        'limit': '${limit.clamp(1, 2000)}',
      },
    );
    final http.Response res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        ..._extraHeadersForBase(base),
      },
    ).timeout(_httpTimeout);
    final Map<String, dynamic> body = _decodeJsonMap(res.body, statusCode: res.statusCode);
    if (res.statusCode < 200 || res.statusCode >= 300 || !_responseSuccess(body['success'])) {
      throw Exception((body['message'] as String?) ?? 'Impossible de charger la conversation.');
    }
    final List<dynamic> raw = (body['items'] as List<dynamic>?) ?? const [];
    return raw.whereType<Map>().map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e)).toList(growable: false);
  }

  Future<int> fetchUnreadNotificationCount({String userId = ''}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) return 0;
    final String base = baseUrl.trim();
    try {
      await _ensureIntervenantBackendReachable(base, requireNotificationsApi: true);
    } catch (_) {
      return 0;
    }
    final String uid = userId.trim().toLowerCase();
    final Map<String, String> qp = <String, String>{};
    if (uid.isNotEmpty) qp['userId'] = uid;
    final Uri url = backendPathUri(base, '/api/notifications/unread-count', qp);
    try {
      final response = await http.get(url, headers: _jsonHeaders()).timeout(_httpTimeout);
      final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
      if (response.statusCode < 200 || response.statusCode >= 300 || !_responseSuccess(body['success'])) {
        return 0;
      }
      final dynamic n = body['unreadCount'];
      if (n is int) return n;
      if (n is num) return n.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationRead({String userId = '', required String notificationId}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final Uri url = backendPathUri(baseUrl.trim(), '/api/notifications/$notificationId/read');
    final Map<String, String> payload = <String, String>{};
    final String uid = userId.trim().toLowerCase();
    if (uid.isNotEmpty) payload['userId'] = uid;
    final response = await http
        .patch(url, headers: _jsonHeaders(), body: jsonEncode(payload))
        .timeout(_httpTimeout);
    final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300 || !_responseSuccess(body['success'])) {
      throw Exception((body['message'] as String?) ?? 'Marquage lu impossible.');
    }
  }

  Future<void> markAllNotificationsRead({String userId = ''}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final Uri url = backendPathUri(baseUrl.trim(), '/api/notifications/mark-all-read');
    final Map<String, String> payload = <String, String>{};
    final String uid = userId.trim().toLowerCase();
    if (uid.isNotEmpty) payload['userId'] = uid;
    final response = await http
        .post(url, headers: _jsonHeaders(), body: jsonEncode(payload))
        .timeout(_httpTimeout);
    final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300 || !_responseSuccess(body['success'])) {
      throw Exception((body['message'] as String?) ?? 'Action impossible.');
    }
  }

  Future<void> deleteNotification({required String userId, required String notificationId}) async {
    final String? missing = _missingBaseUrlOnPhoneMessage();
    if (missing != null) throw Exception(missing);
    final Uri url = backendPathUri(
      baseUrl.trim(),
      '/api/notifications/$notificationId',
      <String, String>{'userId': userId.trim().toLowerCase()},
    );
    final response = await http.delete(url, headers: _jsonHeaders()).timeout(_httpTimeout);
    final Map<String, dynamic> body = _decodeJsonMap(response.body, statusCode: response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300 || !_responseSuccess(body['success'])) {
      throw Exception((body['message'] as String?) ?? 'Suppression impossible.');
    }
  }
}
