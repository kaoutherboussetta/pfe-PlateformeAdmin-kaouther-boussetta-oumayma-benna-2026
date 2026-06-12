import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/alerts_feed_notifier.dart';
import 'services/alert_notifications_service.dart';
import 'services/alert_service.dart';
import 'l10n/context_l10n.dart';
import 'providers/auth_provider.dart';
import 'connexion/login_page.dart';
import 'screens/alerts_page.dart';
import 'screens/carte_page.dart';
import 'pages/AccueilPage.dart';
import 'screens/profile_page.dart' as profile_screen;
import 'widgets/bottom_nav_bar.dart';

/// Rafraîchissement périodique des alertes depuis `/alert` tant que l’app est au premier plan
/// (complément du SSE `/alert/stream`, qui peut se couper selon le réseau ou l’OS).
const Duration _kAlertForegroundPollInterval = Duration(seconds: 30);

/// Sur l’onglet Alertes, requêtes plus fréquentes pour refléter vite les nouveaux documents MongoDB.
const Duration _kAlertTabPollInterval = Duration(seconds: 10);

class HomePage extends StatefulWidget {
  /// Index de l'onglet affiché au démarrage (0=Accueil, 1=Carte, 2=Alertes, 3=Profil).
  final int initialTabIndex;

  const HomePage({super.key, this.initialTabIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late int _selectedIndex;
  late Duration _alertPollInterval;
  /// Initialisé au niveau du champ (pas `late` dans [initState]) pour éviter
  /// [LateInitializationError] après hot reload ou tout rebuild avant initState.
  final List<Widget> _tabPages = [
    const AccueilPage(),
    const CartePage(),
    const AlertsPage(),
    const profile_screen.ProfilePage(showBottomBar: false),
  ];
  Timer? _alertPollTimer;
  AlertService? _alertService;

  void _syncAlertPollIntervalWithTab(int tabIndex) {
    _alertPollInterval =
        tabIndex == 2 ? _kAlertTabPollInterval : _kAlertForegroundPollInterval;
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 3);
    _syncAlertPollIntervalWithTab(_selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alertService = context.read<AlertService>();
      _alertService!.subscribeRealtimeAlerts((newAlert) async {
        if (!mounted) return;
        if (newAlert != null) {
          // Ajout incrémental sans recharger toute l'API
          context.read<AlertsFeedNotifier>().addAlert(newAlert);
        } else {
          // Fallback : rechargement complet
          await _pollAlertsForNotifications();
        }
      });
      _pollAlertsForNotifications();
      _startForegroundAlertPolling();
    });
  }

  void _startForegroundAlertPolling() {
    _alertPollTimer?.cancel();
    _alertPollTimer = Timer.periodic(
      _alertPollInterval,
      (_) => _pollAlertsForNotifications(),
    );
  }

  void _stopForegroundAlertPolling() {
    _alertPollTimer?.cancel();
    _alertPollTimer = null;
  }

  @override
  void dispose() {
    _alertService?.unsubscribeRealtimeAlerts();
    _alertPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _pollAlertsForNotifications();
        _startForegroundAlertPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopForegroundAlertPolling();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _pollAlertsForNotifications() async {
    if (!mounted) return;
    try {
      final svc = context.read<AlertService>();
      final list = await svc.fetchAlerts();
      if (!mounted) return;
      final newKeys = await AlertNotificationsService.processNewAlerts(list);
      if (!mounted) return;
      context.read<AlertsFeedNotifier>().setAlerts(
            list,
            newStableKeys: newKeys,
          );
    } catch (_) {}
  }

  void _onItemTapped(int index) {
    final prevInterval = _alertPollInterval;
    setState(() {
      _selectedIndex = index;
      _syncAlertPollIntervalWithTab(index);
    });
    if (_alertPollInterval != prevInterval) {
      _startForegroundAlertPolling();
    }
    if (index == 2) {
      // Efface les badges "Nouveau" quand on entre dans l'onglet Alertes
      context.read<AlertsFeedNotifier>().clearNewKeysFlag();
      unawaited(_pollAlertsForNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final hasUnreadAlerts =
        context.watch<AlertsFeedNotifier>().lastIncomingNewKeys.isNotEmpty;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true, // Important : permet au body de s'étendre sous la navbar
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          sizing: StackFit.expand,
          children: _tabPages,
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
          bottomAppBarTheme: const BottomAppBarThemeData(
            color: Colors.transparent,
            elevation: 0,
          ),
        ),
        child: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          homeLabel: s.navHome,
          mapLabel: s.navMap,
          alertsLabel: s.navAlerts,
          profileLabel: s.navProfile,
          showAlertsBadge: hasUnreadAlerts,
        ),
      ),
    );
  }
}
