import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../models/alert_model.dart';
import '../providers/alerts_feed_notifier.dart';
import '../services/alert_notifications_service.dart';
import '../services/alert_service.dart';
import '../widgets/alert_location_label.dart';
import '../widgets/alert_message_zone.dart';
import '../theme/app_theme.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with SingleTickerProviderStateMixin {
  List<AlertModel> _alerts = [];
  bool _initialLoading = true;
  String? _loadError;
  String _selectedFilterId = 'all';
  AlertsFeedNotifier? _feedNotifier;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _feedNotifier = context.read<AlertsFeedNotifier>();
      _feedNotifier!.addListener(_onFeedUpdated);
      final cached = _feedNotifier!.alerts;
      if (cached.isNotEmpty) {
        setState(() {
          _alerts = List.from(cached);
          _initialLoading = false;
          _loadError = null;
        });
      }
      _loadAlerts();
      _animationController.forward();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 20 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 20 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _feedNotifier?.removeListener(_onFeedUpdated);
    super.dispose();
  }

  void _onFeedUpdated() {
    if (!mounted) return;
    final feed = context.read<AlertsFeedNotifier>();
    final pending = feed.lastIncomingNewKeys;
    setState(() {
      _alerts = List.from(feed.alerts);
      _initialLoading = false;
      _loadError = null;
      final types = _distinctTypes();
      if (_selectedFilterId != 'all' && !types.contains(_selectedFilterId)) {
        _selectedFilterId = 'all';
      }
    });
    if (pending.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.alertListUpdatedNew),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAlerts({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _initialLoading = true;
        _loadError = null;
      });
    }
    try {
      final svc = context.read<AlertService>();
      final list = await svc.fetchAlerts();
      if (!mounted) return;
      final newKeys = await AlertNotificationsService.processNewAlerts(list);
      if (!mounted) return;
      context.read<AlertsFeedNotifier>().setAlerts(
            list,
            newStableKeys: newKeys,
            notify: false,
          );
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _initialLoading = false;
        _loadError = null;
        final types = _distinctTypes();
        if (_selectedFilterId != 'all' && !types.contains(_selectedFilterId)) {
          _selectedFilterId = 'all';
        }
      });
      if (newKeys.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.strings.alertListUpdatedNew),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        if (_alerts.isEmpty) {
          _loadError = e.toString();
        }
      });
      if (isRefresh && _alerts.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.stringsRead.mapNetworkError),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> _distinctTypes() {
    final set = <String>{};
    for (final a in _alerts) {
      final t = a.alertType.trim().isNotEmpty ? a.alertType.trim() : a.typeField.trim();
      if (t.isNotEmpty) set.add(t);
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<AlertModel> _filteredAlerts() {
    var filtered = _alerts;
    
    if (_selectedFilterId != 'all') {
      filtered = filtered.where((a) {
        final t = a.alertType.trim().isNotEmpty ? a.alertType.trim() : a.typeField.trim();
        return t == _selectedFilterId;
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = context.strings;
    final types = _distinctTypes();
    final filtered = _filteredAlerts();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF0F2F5),
      body: _initialLoading
          ? _loadingState(theme, s)
          : RefreshIndicator(
              onRefresh: () => _loadAlerts(isRefresh: true),
              color: AppTheme.alertOrange,
              child: CustomScrollView(
                key: const PageStorageKey<String>('alerts_scroll'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildEnterpriseAppBar(theme, isDark, s, filtered.length, _alerts.length),
                  _buildSearchAndFilterBar(theme, isDark, s, types),
                  if (_loadError != null && _alerts.isEmpty)
                    SliverFillRemaining(child: _errorState(theme, s))
                  else if (_alerts.isEmpty)
                    SliverFillRemaining(child: _emptyState(theme, s))
                  else if (filtered.isEmpty)
                    SliverFillRemaining(child: _emptyFilterState(theme, s))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _enterpriseAlertCard(filtered[index], theme, isDark, s);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _loadingState(ThemeData theme, AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.alertOrange, AppTheme.alertOrange.withValues(alpha: 0.75)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            s.loading,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseAppBar(ThemeData theme, bool isDark, AppStrings s, int filteredCount, int totalCount) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF0F2F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isScrolled ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.alertOrange, AppTheme.alertOrange.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alert Center',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF0B0E14),
                      const Color(0xFF1A1D27),
                    ]
                  : [
                      const Color(0xFFF0F2F5),
                      const Color(0xFFE4E7EB),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alerts',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                fontSize: 34,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitoring & Incidents',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.alertOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.alertOrange.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timeline, size: 14, color: AppTheme.alertOrange),
                                const SizedBox(width: 4),
                                Text(
                                  '${_alerts.length} total',
                                  style: TextStyle(
                                    color: AppTheme.alertOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 14, color: const Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  '$filteredCount active',
                                  style: TextStyle(
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme, bool isDark, AppStrings s, List<String> types) {
    if (types.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    const barHeight = 60.0;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterBarDelegate(
        extent: barHeight,
        filterStateKey: '${_selectedFilterId}_${types.length}_$isDark',
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0E14) : const Color(0xFFF0F2F5),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            itemCount: 1 + types.length,
            itemBuilder: (context, index) {
              final isSelected = index == 0 ? _selectedFilterId == 'all' : _selectedFilterId == types[index - 1];
              final label = index == 0 ? 'All' : types[index - 1];
              final typeId = index == 0 ? 'all' : types[index - 1];
              final count = index == 0
                  ? _alerts.length
                  : _alerts.where((a) {
                      final t = a.alertType.trim().isNotEmpty ? a.alertType.trim() : a.typeField.trim();
                      return t == typeId;
                    }).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _enterpriseFilterChip(
                  label: label,
                  count: count,
                  isSelected: isSelected,
                  isDark: isDark,
                  theme: theme,
                  onTap: () => setState(() => _selectedFilterId = typeId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _enterpriseFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.alertOrange
              : isDark
                  ? const Color(0xFF1A1D27)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _enterpriseAlertCard(
    AlertModel alert,
    ThemeData theme,
    bool isDark,
    AppStrings s,
  ) {
    final map = alert.toDisplayMap(s);
    
    final Map<String, dynamic> severityConfig = {
      'danger': {
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEF2F2),
        'icon': Icons.error_outline,
        'label': 'CRITICAL',
        'borderColor': const Color(0xFFFEE2E2),
      },
      'warning': {
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFFFBEB),
        'icon': Icons.warning_amber_outlined,
        'label': 'WARNING',
        'borderColor': const Color(0xFFFEF3C7),
      },
      'info': {
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFEFF6FF),
        'icon': Icons.info_outline,
        'label': 'INFO',
        'borderColor': const Color(0xFFDBEAFE),
      },
    };

    final config = severityConfig[map['level']] ?? severityConfig['info'];
    final isNew = context.read<AlertsFeedNotifier>().lastIncomingNewKeys.contains(
          AlertNotificationsService.stableKey(alert),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEnterpriseDetails(alert, theme, s),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D27) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNew 
                    ? config['color'].withValues(alpha: 0.3)
                    : theme.dividerColor.withValues(alpha: 0.08),
                width: isNew ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: config['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          config['icon'],
                          color: config['color'],
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: config['color'].withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    config['label'],
                                    style: TextStyle(
                                      color: config['color'],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  alert.relativeTime,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isNew) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              map['title']! as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            AlertMessageWithZone(
                              alert: alert,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13161F) : const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppTheme.alertOrange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AlertLocationLabel(
                          alert: alert,
                          loadingPlaceholder: '...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (alert.temperatureC != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.alertOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.thermostat, size: 12, color: AppTheme.alertOrange),
                              const SizedBox(width: 4),
                              Text(
                                '${alert.temperatureC!.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  color: AppTheme.alertOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnterpriseDetails(AlertModel alert, ThemeData theme, AppStrings s) {
    final isDark = theme.brightness == Brightness.dark;
    final map = alert.toDisplayMap(s);
    
    final Map<String, dynamic> severityConfig = {
      'danger': {
        'color': const Color(0xFFEF4444),
        'icon': Icons.error_outline,
      },
      'warning': {
        'color': const Color(0xFFF59E0B),
        'icon': Icons.warning_amber_outlined,
      },
      'info': {
        'color': const Color(0xFF3B82F6),
        'icon': Icons.info_outline,
      },
    };
    
    final config = severityConfig[map['level']] ?? severityConfig['info'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                    maxWidth: 500,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey[900]!.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: config['color'].withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header avec dégradé
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    config['color'].withValues(alpha: 0.15),
                                    config['color'].withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: config['color'].withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      config['icon'],
                                      color: config['color'],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          map['typeLabel']!.toString().toUpperCase(),
                                          style: TextStyle(
                                            color: config['color'],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          map['title']! as String,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                            color: isDark ? Colors.white : Colors.black,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badge de temps
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          alert.relativeTime,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Carte de description
                                    _buildDetailCard(
                                      title: 'DESCRIPTION',
                                      icon: Icons.description_outlined,
                                      children: [
                                        AlertMessageWithZone(
                                          alert: alert,
                                          maxLines: 20,
                                          style: TextStyle(
                                            height: 1.6,
                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                      isDark: isDark,
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Cartes de métriques
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricCard(
                                            label: 'Severity',
                                            value: map['level'].toString().toUpperCase(),
                                            icon: Icons.warning_rounded,
                                            color: config['color'],
                                            isDark: isDark,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildMetricCard(
                                            label: 'Priority',
                                            value: map['priority']! as String,
                                            icon: Icons.flag_rounded,
                                            color: config['color'],
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Carte de localisation
                                    _buildDetailCard(
                                      title: 'LOCATION & ENVIRONMENT',
                                      icon: Icons.location_on_outlined,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.location_city, size: 16, color: Colors.grey[500]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: AlertLocationLabel(
                                                alert: alert,
                                                loadingPlaceholder: 'Loading...',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (alert.temperatureC != null) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.thermostat, size: 16, color: Colors.grey[500]),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${alert.temperatureC!.toStringAsFixed(1)}°C',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                      isDark: isDark,
                                    ),
                                    
                                    if ((map['recommendation'] as String).isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      // Carte de recommandation
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF10B981).withValues(alpha: 0.1),
                                              const Color(0xFF10B981).withValues(alpha: 0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.lightbulb_outline,
                                                    color: Color(0xFF10B981),
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'RECOMMENDED ACTION',
                                                  style: TextStyle(
                                                    color: const Color(0xFF10B981),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              map['recommendation']! as String,
                                              style: TextStyle(
                                                height: 1.5,
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Carte des métadonnées
                                    _buildDetailCard(
                                      title: 'METADATA',
                                      icon: Icons.info_outline,
                                      children: [
                                        _buildMetadataRow(
                                          'Status',
                                          map['status']! as String,
                                          isDark,
                                        ),
                                        _buildMetadataRow(
                                          'Alert ID',
                                          alert.id ?? 'N/A',
                                          isDark,
                                        ),
                                        if (alert.createdAt != null)
                                          _buildMetadataRow(
                                            'Created',
                                            _formatDate(alert.createdAt!),
                                            isDark,
                                          ),
                                      ],
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Footer avec boutons
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    s.close,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Widget helper pour les cartes de détails
  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // Widget helper pour les cartes métriques
  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget helper pour les rangées de métadonnées
  Widget _buildMetadataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _errorState(ThemeData theme, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              s.mapNetworkError,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.alertOrange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _loadAlerts(),
              icon: const Icon(Icons.refresh),
              label: Text(s.alertRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.alertOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none, color: AppTheme.alertOrange, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              s.alertEmptyList,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFilterState(ThemeData theme, AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.alertOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_alt_off, color: AppTheme.alertOrange, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              s.alertEmptyForCategory,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double extent;
  final String filterStateKey;

  _FilterBarDelegate({
    required this.child,
    required this.extent,
    required this.filterStateKey,
  });

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    if (oldDelegate is! _FilterBarDelegate) return true;
    return oldDelegate.filterStateKey != filterStateKey || oldDelegate.extent != extent;
  }
}