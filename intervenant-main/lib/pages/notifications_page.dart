import 'package:flutter/material.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/models/app_notification.dart';
import 'package:intervenant/services/auth_api_service.dart';
import 'package:intervenant/services/notification_alerts_badge_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

enum _NotifFilter { all, unread, dangerOnly }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.intervenantEmail,
    this.intervenantLegacyId,
    this.teamLabel,
    this.onUnreadCountChanged,
    super.key,
  });

  final String intervenantEmail;
  final String? intervenantLegacyId;
  /// Filtre serveur `team_label` / `team_key` (même logique que les chantiers).
  final String? teamLabel;
  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  List<AppNotification> _notifications = [];
  Set<String> _openedIds = <String>{};
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  _NotifFilter _filter = _NotifFilter.all;

  String get _userId => widget.intervenantEmail.trim().toLowerCase();

  bool _isNew(AppNotification n) {
    final String id = n.id.trim();
    return id.isNotEmpty && !_openedIds.contains(id);
  }

  int get _newCount => _notifications.where(_isNew).length;

  void _pushBadgeToParent() {
    widget.onUnreadCountChanged?.call(_newCount);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _humanizeLoadError(String raw) {
    if (raw.contains('API route not found') &&
        (raw.contains('/api/problemes-voirie') || raw.contains('/api/problemes_voirie'))) {
      return 'Le backend n’expose pas la liste des problèmes de voirie.\n'
          'Mettez à jour le serveur intervenant et vérifiez GET /api/problemes-voirie.';
    }
    return raw;
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<AppNotification> notifications =
          await AuthApiService.instance.fetchNotificationsAsProblemesVoirie(
        teamLabel: widget.teamLabel,
        limit: 500,
      );
      notifications.sort((AppNotification a, AppNotification b) => b.createdAt.compareTo(a.createdAt));
      await NotificationAlertsBadgePrefs.ensureBaselineIfNeeded(notifications);
      final Set<String> opened = await NotificationAlertsBadgePrefs.readOpenedIds();
      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _openedIds = opened;
        _isLoading = false;
        _error = null;
      });
      _pushBadgeToParent();
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = [];
        _error = _humanizeLoadError(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
        _isLoading = false;
      });
      widget.onUnreadCountChanged?.call(0);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await _loadNotifications();
    setState(() => _isRefreshing = false);
  }

  List<AppNotification> get _sortedNotifications {
    final list = List<AppNotification>.from(_notifications);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<AppNotification> get _visibleNotifications {
    final sorted = _sortedNotifications;
    switch (_filter) {
      case _NotifFilter.all:
        return sorted;
      case _NotifFilter.unread:
        return sorted.where(_isNew).toList();
      case _NotifFilter.dangerOnly:
        return sorted
            .where(
              (AppNotification n) =>
                  n.gravite == 'grave' ||
                  n.typeProbleme == 'danger' ||
                  n.gravite == 'high',
            )
            .toList();
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (!_isNew(notification)) return;

    await NotificationAlertsBadgePrefs.markAlertOpened(notification.id);
    if (!mounted) return;

      setState(() {
      final String id = notification.id.trim();
      if (id.isNotEmpty) _openedIds.add(id);
      final int index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
    }
    });
    _pushBadgeToParent();

    if (notification.isAlertFeed) {
      try {
        await AuthApiService.instance
            .markNotificationRead(userId: _userId, notificationId: notification.id);
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_newCount == 0) return;

    await NotificationAlertsBadgePrefs.markAllAlertsOpened(_notifications);
    if (!mounted) return;

    setState(() {
      for (final AppNotification n in _notifications) {
        final String id = n.id.trim();
        if (id.isNotEmpty) _openedIds.add(id);
      }
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    _pushBadgeToParent();

    final bool anyAlert = _notifications.any((AppNotification n) => n.isAlertFeed);
    if (anyAlert) {
      try {
        await AuthApiService.instance.markAllNotificationsRead(userId: _userId);
        if (mounted) {
          _showSnackBar('Toutes les notifications ont été marquées comme lues');
        }
      } catch (e) {
        debugPrint('Error marking all as read: $e');
      }
    } else if (mounted) {
      _showSnackBar('Toutes les notifications ont été marquées comme lues');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openMaps(NotificationPosition pos) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}',
    );
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showSnackBar('Impossible d’ouvrir la carte.');
    }
  }

  void _onNotificationTap(AppNotification notification) async {
    await _markAsRead(notification);
    if (!mounted) return;
    _showNotificationDetails(notification);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final visible = _visibleNotifications;
    final bool hasData = visible.isNotEmpty;

    if (_isLoading) {
      return _LoadingState();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _ModernAppBar(
              newCount: _newCount,
              onRefresh: _refresh,
              onMarkAllRead: _markAllAsRead,
              isRefreshing: _isRefreshing,
            ),
            SliverToBoxAdapter(
              child: _ModernFilterChips(
                currentFilter: _filter,
                newCount: _newCount,
                onFilterChanged: (filter) => setState(() => _filter = filter),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(child: _ErrorBanner(error: _error!)),
            if (!hasData)
              SliverFillRemaining(
                child: _EmptyState(filter: _filter),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ModernNotificationCard(
                    notification: visible[index],
                    isNew: _isNew(visible[index]),
                    onTap: () => _onNotificationTap(visible[index]),
                    index: index,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.viewPaddingOf(context).bottom + 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetailSheet(
        notification: notification,
        onOpenMaps: _openMaps,
      ),
    );
  }
}

// ==================== MODERN APP BAR ====================

class _ModernAppBar extends StatelessWidget {
  const _ModernAppBar({
    required this.newCount,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.isRefreshing,
  });

  final int newCount;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllRead;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String newLine = l10n.notificationsNewCountLine(newCount);

    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 100,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notificationsTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            if (newLine.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  newLine,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (newCount > 0)
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: l10n.notificationsMarkAllReadTooltip,
            onPressed: onMarkAllRead,
          ),
        IconButton(
          icon: AnimatedRotation(
            turns: isRefreshing ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: const Icon(Icons.refresh_rounded),
          ),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

// ==================== MODERN FILTER CHIPS ====================

class _ModernFilterChips extends StatelessWidget {
  const _ModernFilterChips({
    required this.currentFilter,
    required this.newCount,
    required this.onFilterChanged,
  });

  final _NotifFilter currentFilter;
  final int newCount;
  final ValueChanged<_NotifFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterChip(
              label: 'Toutes',
              isSelected: currentFilter == _NotifFilter.all,
              onSelected: () => onFilterChanged(_NotifFilter.all),
              icon: Icons.inbox_rounded,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Non lues',
              badge: newCount > 0 ? '$newCount' : null,
              isSelected: currentFilter == _NotifFilter.unread,
              onSelected: () => onFilterChanged(_NotifFilter.unread),
              icon: Icons.mark_email_unread_rounded,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Danger',
              isSelected: currentFilter == _NotifFilter.dangerOnly,
              onSelected: () => onFilterChanged(_NotifFilter.dangerOnly),
              icon: Icons.warning_amber_rounded,
              color: currentFilter == _NotifFilter.dangerOnly ? Colors.red : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.icon,
    this.badge,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData icon;
  final String? badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = color ?? theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
          child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? selectedColor : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? selectedColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedColor : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MODERN NOTIFICATION CARD ====================

class _ModernNotificationCard extends StatelessWidget {
  const _ModernNotificationCard({
    required this.notification,
    required this.isNew,
    required this.onTap,
    required this.index,
  });

  final AppNotification notification;
  final bool isNew;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accentColor = _getAccentColor(notification);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index % 10) * 30),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, opacity, _) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
              padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNew ? accentColor.withValues(alpha: 0.05) : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isNew ? accentColor.withValues(alpha: 0.3) : theme.colorScheme.outline.withValues(alpha: 0.1),
                      width: isNew ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (isNew)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      _NotificationIcon(notification: notification, isNew: isNew),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                    notification.title.isNotEmpty ? notification.title : 'Notification',
                                    style: TextStyle(
                                  fontSize: 15,
                                      fontWeight: isNew ? FontWeight.w700 : FontWeight.w600,
                                      color: isNew ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                                if (isNew)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 8,
                                    height: 8,
                                  decoration: BoxDecoration(
                                      color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: accentColor.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                      ),
                                    ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.message,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                                _NotificationBadge(
                                  text: notification.isAlertFeed ? 'Alerte' : 'Intervention',
                                  icon: notification.isAlertFeed ? Icons.warning_rounded : Icons.build_rounded,
                                  color: notification.isAlertFeed ? Colors.teal : Colors.purple,
                                ),
                            if (notification.typeProbleme.isNotEmpty)
                                  _NotificationBadge(
                                    text: _labelTypeProbleme(notification.typeProbleme),
                                    icon: Icons.category_rounded,
                                    color: Colors.blueGrey,
                              ),
                            if (notification.gravite.isNotEmpty)
                                  _NotificationBadge(
                                    text: _labelGravite(notification.gravite),
                                    icon: Icons.trending_up_rounded,
                                    color: _graviteColor(notification.gravite),
                                  ),
                                _TimeBadge(createdAt: notification.createdAt),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Color _getAccentColor(AppNotification n) {
    if (n.gravite == 'grave' || n.gravite == 'high') return const Color(0xFFE53935);
    if (n.typeProbleme == 'danger') return const Color(0xFFE53935);
    return const Color(0xFFEF6C00);
  }

  String _labelTypeProbleme(String tp) {
    switch (tp) {
      case 'nid_de_poule': return 'Nid de poule';
      case 'fissure': return 'Fissure';
      case 'danger': return 'Danger';
      case 'route_cassee': return 'Route cassée';
      default: return tp.replaceAll('_', ' ');
    }
  }

  String _labelGravite(String g) {
    switch (g) {
      case 'faible': case 'low': return 'Faible';
      case 'moyenne': case 'medium': return 'Moyenne';
      case 'grave': case 'high': return 'Grave';
      default: return g;
    }
  }

  Color _graviteColor(String g) {
    switch (g) {
      case 'faible': case 'low': return Colors.blueGrey;
      case 'moyenne': case 'medium': return Colors.orange;
      case 'grave': case 'high': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.notification,
    required this.isNew,
  });

  final AppNotification notification;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = _iconColor(notification);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: isNew ? 0.25 : 0.15),
            baseColor.withValues(alpha: isNew ? 0.15 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        _iconForType(notification),
        color: baseColor,
        size: 26,
      ),
    );
  }

  IconData _iconForType(AppNotification n) {
    if (n.isAlertFeed) return Icons.thermostat_rounded;
    switch (n.typeProbleme) {
      case 'nid_de_poule': return Icons.warning_amber_rounded;
      case 'fissure': return Icons.report_problem_rounded;
      case 'danger': return Icons.error_outline_rounded;
      case 'route_cassee': return Icons.remove_road_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _iconColor(AppNotification n) {
    if (n.isAlertFeed) return Colors.lightBlue.shade700;
    switch (n.typeProbleme) {
      case 'nid_de_poule': return Colors.amber.shade800;
      case 'fissure': return Colors.deepOrange.shade700;
      case 'danger': return const Color(0xFFE53935);
      case 'route_cassee': return Colors.brown.shade600;
      default: return Colors.blueGrey.shade600;
    }
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.createdAt});

  final DateTime createdAt;

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    if (diff.inDays == 1) return "Hier";
    if (diff.inDays < 7) return "Il y a ${diff.inDays} j";
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          _formatRelativeTime(createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ==================== DETAIL SHEET ====================

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
    required this.onOpenMaps,
  });

  final AppNotification notification;
  final void Function(NotificationPosition) onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                    backgroundColor: theme.colorScheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  notification.title.isNotEmpty ? notification.title : 'Notification',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                        const SizedBox(height: 8),
                        // En-tête avec icône
                        Row(
                      children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _getBaseColor(notification).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _getIcon(notification),
                                size: 32,
                                color: _getBaseColor(notification),
                              ),
                            ),
                            const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    _getTypeLabel(notification),
                                  style: TextStyle(
                                      fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                      color: _getBaseColor(notification),
                                  ),
                                ),
                                  const SizedBox(height: 4),
                                Text(
                                    _getGraviteLabel(notification),
                                  style: TextStyle(
                                      fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                      color: _graviteColor(notification.gravite),
                                  ),
                                ),
                                  const SizedBox(height: 4),
                                  _TimeBadge(createdAt: notification.createdAt),
                              ],
                              ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            notification.message,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                        if (notification.temperatureC != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightBlue.shade50,
                                  Colors.lightBlue.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.thermostat_rounded, size: 32, color: Colors.lightBlue.shade700),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Température mesurée', style: TextStyle(fontSize: 12)),
                    Text(
                                      '${notification.temperatureC!.toStringAsFixed(1)} °C',
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                    if (notification.hasPosition) ...[
                          const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                              onOpenMaps(notification.position!);
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Voir sur la carte'),
                        style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                            '${notification.position!.latitude.toStringAsFixed(6)}, ${notification.position!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                      ),
                    ],
                    if (notification.relatedId != null) ...[
                          const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                                Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Référence : ${notification.relatedId}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                        const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBaseColor(AppNotification n) {
    if (n.gravite == 'grave' || n.gravite == 'high') return const Color(0xFFE53935);
    return const Color(0xFFEF6C00);
  }

  IconData _getIcon(AppNotification n) {
    if (n.isAlertFeed) return Icons.thermostat_rounded;
    switch (n.typeProbleme) {
      case 'nid_de_poule': return Icons.warning_amber_rounded;
      case 'fissure': return Icons.report_problem_rounded;
      case 'danger': return Icons.error_outline_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  String _getTypeLabel(AppNotification n) {
    if (n.isAlertFeed) return 'Alerte température';
    return _labelTypeProbleme(n.typeProbleme);
  }

  String _labelTypeProbleme(String tp) {
    switch (tp) {
      case 'nid_de_poule': return 'Nid de poule';
      case 'fissure': return 'Fissure';
      case 'danger': return 'Danger signalé';
      case 'route_cassee': return 'Route cassée';
      default: return tp.replaceAll('_', ' ');
    }
  }

  String _getGraviteLabel(AppNotification n) {
    if (n.gravite.isEmpty) return '';
    switch (n.gravite) {
      case 'faible': case 'low': return '⚠️ Gravité faible';
      case 'moyenne': case 'medium': return '⚠️⚠️ Gravité moyenne';
      case 'grave': case 'high': return '⚠️⚠️⚠️ Gravité grave';
      default: return n.gravite;
    }
  }

  Color _graviteColor(String g) {
    switch (g) {
      case 'faible': case 'low': return Colors.blueGrey;
      case 'moyenne': case 'medium': return Colors.orange;
      case 'grave': case 'high': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }
}

// ==================== LOADING STATE ====================

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.notificationsLoading,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY STATE ====================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _NotifFilter filter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case _NotifFilter.unread:
        title = l10n.notificationsEmptyUnreadTitle;
        subtitle = l10n.notificationsEmptyUnreadSubtitle;
        icon = Icons.mark_email_read_rounded;
        break;
      case _NotifFilter.dangerOnly:
        title = l10n.notificationsEmptyDangerTitle;
        subtitle = l10n.notificationsEmptyDangerSubtitle;
        icon = Icons.verified_rounded;
        break;
      default:
        title = l10n.notificationsEmptyTitle;
        subtitle = l10n.notificationsEmptySubtitle;
        icon = Icons.notifications_none_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
                children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ==================== ERROR BANNER ====================

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                error,
                style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}