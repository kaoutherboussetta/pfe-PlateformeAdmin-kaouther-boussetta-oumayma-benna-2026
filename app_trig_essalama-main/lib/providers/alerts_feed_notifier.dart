import 'package:flutter/foundation.dart';

import '../models/alert_model.dart';
import '../services/alert_notifications_service.dart';

/// Dernière liste d’alertes partagée entre le polling ([HomePage]) et l’écran [AlertsPage].
class AlertsFeedNotifier extends ChangeNotifier {
  List<AlertModel> _alerts = [];
  Set<String> _lastIncomingNewKeys = {};

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  /// Clés stables des alertes considérées comme nouvelles lors du dernier [setAlerts] notifié.
  Set<String> get lastIncomingNewKeys => Set.unmodifiable(_lastIncomingNewKeys);

  void setAlerts(
    List<AlertModel> list, {
    Set<String> newStableKeys = const {},
    bool notify = true,
  }) {
    _alerts = List.from(list);
    _lastIncomingNewKeys = Set.from(newStableKeys);
    if (notify) notifyListeners();
  }

  /// Ajoute une seule alerte à la liste (temps réel) en évitant les doublons.
  void addAlert(AlertModel alert, {bool markAsNew = true}) {
    // Vérification doublon par ID
    if (_alerts.any((a) => a.id == alert.id)) return;

    final newList = [alert, ..._alerts];
    // Tri par date décroissante (plus récent en haut)
    newList.sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    _alerts = newList;
    if (markAsNew) {
      final key = AlertNotificationsService.stableKey(alert);
      _lastIncomingNewKeys.add(key);
    }
    notifyListeners();
  }

  void clearNewKeysFlag() {
    _lastIncomingNewKeys = {};
    notifyListeners();
  }
}
