import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_navigator.dart';
import '../firebase_options.dart';
import '../models/alert_model.dart';
import '../providers/alerts_feed_notifier.dart';
import 'api_client.dart';

/// Handler en arrière-plan (doit être une fonction de premier niveau).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  if (kDebugMode) {
    debugPrint('FCM background: ${message.notification?.title}');
  }
}

class FcmService {
  FcmService._();

  static String? _lastSentToken;
  static bool _refreshListenerAttached = false;
  static AlertsFeedNotifier? _notifier;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialise le service avec le [notifier] pour les mises à jour UI en temps réel.
  static void setNotifier(AlertsFeedNotifier notifier) {
    _notifier = notifier;
  }

  /// Navigation depuis le payload `data` (alerte, etc.).
  static void handleMessageForNavigation(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'alert') return;
    final alertId = data['alertId'];
    if (alertId == null || alertId.isEmpty) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    
    // On navigue vers le détail ou on change d'onglet
    nav.pushNamed('/alert', arguments: alertId);
  }

  static Future<void> setupForegroundHandlers() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (Firebase.apps.isEmpty) return;

    // Initialisation des notifications locales pour le foreground
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Optionnel : gérer le clic sur la notification locale
      },
    );

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM Foreground: ${message.notification?.title}');
      }
      
      // 1. Afficher la notification système (Android impose ça en foreground)
      _showLocalNotification(message);

      // 2. Mettre à jour la liste des alertes si le document complet est présent
      _processAlertFromMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Notification cliquée (arrière-plan) — data: ${message.data}');
      }
      handleMessageForNavigation(message);
    });
  }

  static void _processAlertFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'alert') return;
    
    final fullDocStr = data['fullDocument'];
    if (fullDocStr != null && fullDocStr.isNotEmpty) {
      try {
        final doc = jsonDecode(fullDocStr);
        final alert = AlertModel.fromJson(Map<String, dynamic>.from(doc));
        _notifier?.addAlert(alert);
      } catch (e) {
        if (kDebugMode) debugPrint('FCM detail parse error: $e');
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    final title = notification?.title ?? data['title'] ?? 'Alerte';
    final body = notification?.body ?? data['body'] ?? '';
    final priority = data['priority']?.toString().toLowerCase() ?? 'normal';

    final androidDetails = AndroidNotificationDetails(
      'alerts_channel',
      'Alertes de Sécurité',
      channelDescription: 'Notifications pour les dangers et alertes météo',
      importance: Importance.max,
      priority: Priority.high,
      // Utilise le son spécifié (urgent ou default)
      sound: RawResourceAndroidNotificationSound(priority.contains('high') ? 'urgent' : 'default'),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// À appeler après le premier frame (navigator prêt), si l’app a été lancée depuis une notif.
  static Future<void> consumeInitialMessageIfAny() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (Firebase.apps.isEmpty) return;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial == null) return;
    handleMessageForNavigation(initial);
  }

  static void _attachTokenRefresh(ApiClient api) {
    if (_refreshListenerAttached) return;
    _refreshListenerAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final res = await api.put('/user/fcm-token', {'fcmToken': newToken});
        if (res.statusCode == 200) {
          _lastSentToken = newToken;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('FCM onTokenRefresh: $e');
      }
    });
  }

  static Future<void> registerTokenIfNeeded(ApiClient api) async {
    if (kIsWeb || !Platform.isAndroid || Firebase.apps.isEmpty) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
      final status = await Permission.notification.request();
      if (!status.isGranted) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty || token == _lastSentToken) {
        if (token != null) _attachTokenRefresh(api);
        return;
      }

      final res = await api.put('/user/fcm-token', {'fcmToken': token});
      if (res.statusCode == 200) {
        _lastSentToken = token;
      }
      _attachTokenRefresh(api);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM registerTokenIfNeeded: $e');
    }
  }
}
