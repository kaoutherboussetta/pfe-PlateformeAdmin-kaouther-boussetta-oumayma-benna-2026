import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alert_model.dart';
import 'api_client.dart';

class AlertService {
  final ApiClient api;

  AlertService(this.api);

  http.Client? _sseClient;
  StreamSubscription<List<int>>? _sseSub;
  Completer<void>? _sseAwaitDone;
  String _ssePending = '';
  bool _sseWanted = false;
  Future<void> Function(AlertModel? newAlert)? _sseOnInsert;

  void _completeSseWait(Completer<void> done) {
    if (!done.isCompleted) done.complete();
  }

  /// Écoute les insertions d’alertes côté serveur (SSE).
  void subscribeRealtimeAlerts(Future<void> Function(AlertModel? newAlert) onInsert) {
    _sseOnInsert = onInsert;
    _sseWanted = true;
    unawaited(_sseListenLoop());
  }

  Future<void> _sseListenLoop() async {
    while (_sseWanted) {
      if (api.auth.token == null) break;
      try {
        final (streamed, client) = await api.openSseStream('/alert/stream');
        _sseClient = client;
        _ssePending = '';
        final done = Completer<void>();
        _sseAwaitDone = done;
        _sseSub = streamed.stream.listen(
          (chunk) {
            _ssePending += utf8.decode(chunk);
            _drainSseLines();
          },
          // Connexion SSE : en cas d’erreur HTTP/parser, onError puis onDone peuvent
          // tous deux être invoqués — ne compléter qu’une fois.
          onError: (_) {
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
          cancelOnError: false,
        );
        await done.future;
        _sseAwaitDone = null;
        await _sseSub?.cancel();
        _sseSub = null;
        _sseClient?.close();
        _sseClient = null;
      } catch (_) {
        final c = _sseAwaitDone;
        _sseAwaitDone = null;
        if (c != null) _completeSseWait(c);
        _sseClient?.close();
        _sseClient = null;
      }
      if (!_sseWanted) break;
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  void _drainSseLines() {
    while (true) {
      final idx = _ssePending.indexOf('\n\n');
      if (idx < 0) break;
      final block = _ssePending.substring(0, idx);
      _ssePending = _ssePending.substring(idx + 2);
      for (final raw in block.split('\n')) {
        final line = raw.trimRight();
        if (line.isEmpty || line.startsWith(':')) continue;
        if (!line.startsWith('data:')) continue;
        final jsonStr = line.substring(5).trim();
        if (jsonStr.isEmpty) continue;
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is! Map) continue;
          final map = Map<String, dynamic>.from(decoded);
          final ev = map['event']?.toString();
          if (ev == 'insert' && _sseOnInsert != null) {
            // Si on a le document complet, on crée l'AlertModel directement
            if (map.containsKey('fullDocument') && map['fullDocument'] is Map) {
              try {
                final alert = AlertModel.fromJson(Map<String, dynamic>.from(map['fullDocument']));
                unawaited(_sseOnInsert!(alert));
              } catch (_) {
                unawaited(_sseOnInsert!(null));
              }
            } else {
              unawaited(_sseOnInsert!(null));
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Arrête le flux SSE (ex. à la sortie de [HomePage]).
  void unsubscribeRealtimeAlerts() {
    _sseWanted = false;
    _sseOnInsert = null;
    final c = _sseAwaitDone;
    _sseAwaitDone = null;
    if (c != null) _completeSseWait(c);
    final sub = _sseSub;
    _sseSub = null;
    if (sub != null) unawaited(sub.cancel());
    _sseClient?.close();
    _sseClient = null;
    _ssePending = '';
  }

  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await api.get('/alert').timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps a repondre (20s).');
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await api.get('/alert').timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AlertModel?> fetchAlertById(String id) async {
    try {
      final alerts = await fetchAlerts();
      for (final alert in alerts) {
        if (alert.id == id) return alert;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<AlertModel> _handleResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(_buildErrorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    final rows = _extractDataList(decoded);
    final output = <AlertModel>[];
    for (final row in rows) {
      if (row is! Map) continue;
      try {
        output.add(AlertModel.fromJson(Map<String, dynamic>.from(row)));
      } catch (_) {
        // Ligne invalide: on ignore pour garder le flux robuste.
      }
    }
    return output;
  }

  String _buildErrorMessage(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return 'Non autorise.';
      case 403:
        return 'Acces interdit.';
      case 404:
        return 'Route API /alert introuvable.';
      case 500:
        return 'Erreur interne du serveur.';
      default:
        return 'Erreur serveur (${response.statusCode}).';
    }
  }

  List<dynamic> _extractDataList(dynamic decoded) {
    if (decoded is List) return decoded;
    // jsonDecode renvoie Map<dynamic, dynamic>, pas Map<String, dynamic>.
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      const keys = ['alerts', 'data', 'results'];
      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }
      if (map['alert'] is Map) return [map['alert']];
      if (map.containsKey('_id') || map.containsKey('id') || map.containsKey('title')) {
        return [map];
      }
    }
    return const [];
  }
}
