import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/pages/chantiers_page.dart';
import 'package:intervenant/pages/chat_page.dart';
import 'package:intervenant/pages/notifications_page.dart';
import 'package:intervenant/pages/profile_page.dart';
import 'package:intervenant/services/auth_api_service.dart';
import 'package:intervenant/services/chat_badge_prefs.dart';
import 'package:intervenant/services/notification_alerts_badge_prefs.dart';

bool _chatTruthyFlag(Object? v) {
  if (v == true) return true;
  if (v is num && v != 0) return true;
  if (v is String) {
    final String s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

bool _chatSenderFieldEquals(Map<String, dynamic> map, String expected) {
  const List<String> keys = <String>['senderRole', 'sender_role', 'senderType', 'sender_type', 'role'];
  final String want = expected.trim().toLowerCase();
  for (final String key in keys) {
    final Object? v = map[key];
    if (v != null && v.toString().trim().toLowerCase() == want) return true;
  }
  return false;
}

bool _isAdminChatItem(Map<String, dynamic> map) {
  if (_chatTruthyFlag(map['from_admin']) || _chatTruthyFlag(map['fromAdmin'])) return true;
  if (_chatSenderFieldEquals(map, 'admin')) return true;
  final String authorKey = (map['author_key'] ?? map['authorKey'] ?? '').toString().toLowerCase();
  return authorKey.startsWith('e:admin@') || authorKey.contains(':admin@');
}

String _chatMessageKey(Map<String, dynamic> map) {
  final String id = (map['id'] ?? map['_id'] ?? '').toString().trim();
  if (id.isNotEmpty) return id;
  final String sender = (map['sender'] ?? map['senderRole'] ?? map['sender_role'] ?? '').toString();
  final String text = (map['text'] ?? map['message'] ?? '').toString();
  final String ts = (map['createdAt'] ?? map['created_at'] ?? map['updated_at'] ?? '').toString();
  return '$sender|$text|$ts';
}

class HomePage extends StatefulWidget {
  const HomePage({
    this.intervenantName = 'Intervenant',
    this.intervenantEmail = '',
    this.intervenantTeam,
    this.intervenantLegacyId,
    this.projectName,
    super.key,
  });

  final String intervenantName;
  final String intervenantEmail;
  final String? intervenantTeam;
  /// Identifiant terrain (ex. `interv_001`) pour le flux unifié si les signalements Mongo l’utilisent.
  final String? intervenantLegacyId;

  /// Conservé pour compatibilité (ne s’affiche plus dans l’UI).
  final String? projectName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _notifUnreadCount = 0;
  int _chatUnreadCount = 0;
  Timer? _chatBadgeTimer;

  @override
  void initState() {
    super.initState();
    _refreshNotifBadge();
    unawaited(_refreshChatBadge(markAllRead: false));
    _chatBadgeTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refreshChatBadge(markAllRead: _currentIndex == 2)),
    );
  }

  @override
  void dispose() {
    _chatBadgeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNotifBadge() async {
    try {
      final alerts = await AuthApiService.instance.fetchNotificationsAsProblemesVoirie(
        teamLabel: widget.intervenantTeam,
        limit: 500,
      );
      final int c = await NotificationAlertsBadgePrefs.unreadBadgeFromAlerts(alerts);
      if (mounted) setState(() => _notifUnreadCount = c);
    } catch (_) {
      if (mounted) setState(() => _notifUnreadCount = 0);
    }
  }

  Future<void> _openNotificationsTab() async {
    if (!mounted) return;
    setState(() => _currentIndex = 1);
    await _refreshNotifBadge();
  }

  String get _chatIntervenantId {
    final String email = widget.intervenantEmail.trim().toLowerCase();
    if (email.isNotEmpty) return email;
    final String normalizedName =
        widget.intervenantName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalizedName.isNotEmpty) return 'name_$normalizedName';
    return 'anonymous_intervenant';
  }

  Future<void> _refreshChatBadge({required bool markAllRead}) async {
    try {
      final List<Map<String, dynamic>> items = await AuthApiService.instance.fetchChatItems(
        intervenantId: _chatIntervenantId,
        limit: 1000,
      );
      final List<String> adminIds = items
          .where(_isAdminChatItem)
          .map(_chatMessageKey)
          .where((String e) => e.trim().isNotEmpty)
          .toList(growable: false);
      await ChatBadgePrefs.ensureBaselineIfNeeded(adminIds);
      if (markAllRead) {
        await ChatBadgePrefs.markAllOpened(adminIds);
      }
      final int count = await ChatBadgePrefs.unreadCount(adminIds);
      if (mounted) setState(() => _chatUnreadCount = markAllRead ? 0 : count);
    } catch (_) {
      if (mounted && markAllRead) setState(() => _chatUnreadCount = 0);
    }
  }

  Future<void> _onNavDestinationSelected(int index) async {
    final int prev = _currentIndex;
    if (!mounted) return;
    setState(() => _currentIndex = index);
    if (index == 1 || prev == 1) {
      await _refreshNotifBadge();
    }
    if (index == 2) {
      await _refreshChatBadge(markAllRead: true);
    } else if (prev == 2 || _chatUnreadCount == 0) {
      await _refreshChatBadge(markAllRead: false);
    }
  }

  void _onNotifUnreadChanged(int count) {
    if (_notifUnreadCount == count) return;
    setState(() => _notifUnreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final pages = <Widget>[
      ChantiersPage(
        teamLabel: widget.intervenantTeam,
        intervenantName: widget.intervenantName,
        intervenantTeam: widget.intervenantTeam,
        notifBadgeCount: _notifUnreadCount,
        headerTitle: l10n.chantiersHeader,
        showKpiStrip: true,
        useBonjourGreeting: false,
        showProblemesPreviewInKpiSection: false,
        listProblemesVoirieAsChantierCards: true,
        onOpenNotifications: () => unawaited(_openNotificationsTab()),
        onOpenProfile: () => setState(() => _currentIndex = 3),
        onOpenChat: () => setState(() => _currentIndex = 2),
      ),
      NotificationsPage(
        intervenantEmail: widget.intervenantEmail,
        intervenantLegacyId: widget.intervenantLegacyId,
        teamLabel: widget.intervenantTeam,
        onUnreadCountChanged: _onNotifUnreadChanged,
      ),
      ChatPage(
        intervenantName: widget.intervenantName,
        intervenantEmail: widget.intervenantEmail,
        teamLabel: widget.intervenantTeam,
        onUnreadCountChanged: (int count) {
          if (_chatUnreadCount != count && mounted) {
            setState(() => _chatUnreadCount = count);
          }
        },
      ),
      ProfilePage(
        name: widget.intervenantName,
        email: widget.intervenantEmail,
        team: widget.intervenantTeam,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => unawaited(_onNavDestinationSelected(index)),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.construction_outlined),
            selectedIcon: const Icon(Icons.construction),
            label: l10n.navChantiers,
          ),
          NavigationDestination(
            icon: _NotifNavIcon(count: _notifUnreadCount, selected: false),
            selectedIcon: _NotifNavIcon(count: _notifUnreadCount, selected: true),
            label: l10n.navNotif,
          ),
          NavigationDestination(
            icon: _ChatNavIcon(count: _chatUnreadCount, selected: false),
            selectedIcon: _ChatNavIcon(count: _chatUnreadCount, selected: true),
            label: l10n.navChat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

class _ChatNavIcon extends StatelessWidget {
  const _ChatNavIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24;
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
            size: iconSize,
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: count > 9 ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99' : '$count',
                  style: const TextStyle(fontSize: 8, color: Colors.white, height: 1, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotifNavIcon extends StatelessWidget {
  const _NotifNavIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const double iconSize = 24;
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            selected ? Icons.notifications_rounded : Icons.notifications_none_rounded,
            size: iconSize,
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: count > 9 ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99' : '$count',
                  style: const TextStyle(fontSize: 8, color: Colors.white, height: 1, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
