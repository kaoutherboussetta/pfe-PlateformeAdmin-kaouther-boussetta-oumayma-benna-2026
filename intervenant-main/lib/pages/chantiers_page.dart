import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/pages/chantier_detail_page.dart';
import 'package:intervenant/services/auth_api_service.dart';

String _formatShortDate(String isoOrText) {
  if (isoOrText.isEmpty) return '—';
  final DateTime? d = DateTime.tryParse(isoOrText);
  if (d != null) {
    final DateTime local = d.toLocal();
    try {
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(local);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(local);
    }
  }
  return isoOrText;
}

String _formatTodayFr() {
  final DateTime now = DateTime.now();
  try {
    return DateFormat.yMMMMEEEEd('fr_FR').format(now);
  } catch (_) {
    return DateFormat('EEEE d MMMM yyyy').format(now);
  }
}

enum _ProblemeStatutBucket { enAttente, enCours, termine, autre }

_ProblemeStatutBucket _problemeStatutBucket(String raw) {
  final String s = raw.toLowerCase().trim();
  if (s.contains('termin')) return _ProblemeStatutBucket.termine;
  if (s.contains('attente')) return _ProblemeStatutBucket.enAttente;
  if (s.contains('cours') || s.contains('progress')) return _ProblemeStatutBucket.enCours;
  return _ProblemeStatutBucket.autre;
}

class _ProblemesKpiData {
  const _ProblemesKpiData({
    required this.total,
    required this.enAttente,
    required this.enCours,
    required this.termines,
  });

  final int total;
  final int enAttente;
  final int enCours;
  final int termines;

  static _ProblemesKpiData fromProblemes(List<ProblemeVoirie> items) {
    int enAttente = 0;
    int enCours = 0;
    int termines = 0;
    for (final ProblemeVoirie p in items) {
      switch (_problemeStatutBucket(p.status)) {
        case _ProblemeStatutBucket.enAttente:
          enAttente++;
          break;
        case _ProblemeStatutBucket.enCours:
          enCours++;
          break;
        case _ProblemeStatutBucket.termine:
          termines++;
          break;
        case _ProblemeStatutBucket.autre:
          break;
      }
    }
    return _ProblemesKpiData(total: items.length, enAttente: enAttente, enCours: enCours, termines: termines);
  }
}

class ChantiersPage extends StatefulWidget {
  const ChantiersPage({
    this.teamLabel,
    this.intervenantName,
    this.intervenantTeam,
    this.notifBadgeCount = 0,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onOpenChat,
    this.onNavigateToProblemsTab,
    this.headerTitle = 'Chantiers',
    this.showKpiStrip = true,
    this.useBonjourGreeting = false,
    this.showProblemesPreviewInKpiSection = false,
    this.listProblemesVoirieAsChantierCards = false,
    super.key,
  });

  final String? teamLabel;
  final String? intervenantName;
  final String? intervenantTeam;
  final int notifBadgeCount;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenChat;
  final VoidCallback? onNavigateToProblemsTab;
  final String headerTitle;
  final bool showKpiStrip;
  final bool useBonjourGreeting;
  final bool showProblemesPreviewInKpiSection;
  final bool listProblemesVoirieAsChantierCards;

  @override
  State<ChantiersPage> createState() => _ChantiersPageState();
}

class _ChantiersPageState extends State<ChantiersPage> {
  List<ProblemeVoirie> _problemes = const [];
  bool _loadingProblemes = false;
  bool _syncOk = false;
  Object? _problemesError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool needProblemes = widget.showKpiStrip;
    setState(() {
      _loadingProblemes = needProblemes;
      _problemesError = null;
    });

    if (!needProblemes) {
      if (mounted) setState(() => _syncOk = true);
      return;
    }

    try {
      final List<ProblemeVoirie> list =
          await AuthApiService.instance.fetchProblemesVoirie(teamLabel: widget.teamLabel);
      if (!mounted) return;
      setState(() {
        _problemes = list;
        _loadingProblemes = false;
        _problemesError = null;
        _syncOk = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _problemes = const [];
        _loadingProblemes = false;
        _problemesError = e;
        _syncOk = false;
      });
    }
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayName = (widget.intervenantName?.trim().isNotEmpty ?? false)
        ? widget.intervenantName!.trim()
        : 'Intervenant';
    final String? equipe = widget.intervenantTeam?.trim();
    final String subtitle = equipe != null && equipe.isNotEmpty ? 'Équipe : $equipe' : 'Sans équipe renseignée';
    final String headerTitleEffective = widget.useBonjourGreeting && widget.headerTitle == 'Tableau de bord'
        ? 'Bonjour, $displayName'
        : widget.headerTitle;
    final String? dateLineAccueil = widget.showKpiStrip ? _formatTodayFr() : null;

    final _ProblemesKpiData kpiProblemes = _ProblemesKpiData.fromProblemes(_problemes);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header moderne avec effet de profondeur
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                    child: _ModernDashboardHeader(
                      title: headerTitleEffective,
                      subtitle: subtitle,
                      dateLine: dateLineAccueil,
                      syncOk: _syncOk,
                      loading: widget.showKpiStrip && _loadingProblemes,
                      notifBadgeCount: widget.notifBadgeCount,
                      onNotifications: widget.onOpenNotifications,
                      onProfile: widget.onOpenProfile,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showKpiStrip)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _ModernProblemesSection(
                    data: kpiProblemes,
                    loading: _loadingProblemes && _problemes.isEmpty,
                    error: _problemesError,
                    preview: _problemes.length > 5 ? _problemes.sublist(0, 5) : _problemes,
                    showPreviewList: widget.showProblemesPreviewInKpiSection,
                    onVoirTout: widget.showProblemesPreviewInKpiSection ? widget.onNavigateToProblemsTab : null,
                    onTapProbleme: (ProblemeVoirie p) async {
                      final ProblemeVoirie? updated = await Navigator.of(context).push<ProblemeVoirie>(
                        MaterialPageRoute<ProblemeVoirie>(
                          builder: (_) => ChantierDetailPage(probleme: p),
                        ),
                      );
                      if (!mounted || updated == null) return;
                      final int i = _problemes.indexWhere((ProblemeVoirie x) => x.id == updated.id);
                      if (i >= 0) {
                        final List<ProblemeVoirie> next = List<ProblemeVoirie>.from(_problemes);
                        next[i] = updated;
                        setState(() => _problemes = next);
                      }
                    },
                  ),
                ),
              ),
            if (widget.listProblemesVoirieAsChantierCards && widget.showKpiStrip)
              ..._problemesVoirieSlivers(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _problemesVoirieSlivers(ThemeData theme) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Liste des interventions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_problemes.length} chantier${_problemes.length > 1 ? 's' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (_loadingProblemes && _problemes.isEmpty && _problemesError == null)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des interventions...'),
                ],
              ),
            ),
          ),
        )
      else if (_problemesError != null && _problemes.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur de chargement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_problemesError',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      else if (_problemes.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune intervention en cours',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toutes les interventions sont terminées ou aucun problème n\'a été signalé pour votre équipe.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: _problemes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final ProblemeVoirie p = _problemes[index];
              return _ModernProblemeCard(
                probleme: p,
                onOpenDetail: () async {
                  final ProblemeVoirie? updated = await Navigator.of(context).push<ProblemeVoirie>(
                    MaterialPageRoute<ProblemeVoirie>(
                      builder: (_) => ChantierDetailPage(probleme: p),
                    ),
                  );
                  if (!mounted || updated == null) return;
                  final int i = _problemes.indexWhere((ProblemeVoirie x) => x.id == updated.id);
                  if (i >= 0) {
                    final List<ProblemeVoirie> next = List<ProblemeVoirie>.from(_problemes);
                    next[i] = updated;
                    setState(() => _problemes = next);
                  }
                },
                onChat: widget.onOpenChat,
              );
            },
          ),
        ),
    ];
  }
}

// ==================== MODERN HEADER ====================

class _ModernDashboardHeader extends StatelessWidget {
  const _ModernDashboardHeader({
    required this.title,
    required this.subtitle,
    this.dateLine,
    required this.syncOk,
    required this.loading,
    required this.notifBadgeCount,
    this.onNotifications,
    this.onProfile,
  });

  final String title;
  final String subtitle;
  final String? dateLine;
  final bool syncOk;
  final bool loading;
  final int notifBadgeCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isLight ? Colors.white : theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isLight ? Colors.white70 : theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _ModernActionButtons(
              notifBadgeCount: notifBadgeCount,
              onNotifications: onNotifications,
              onProfile: onProfile,
            ),
          ],
        ),
        if (dateLine != null && dateLine!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: isLight ? Colors.white70 : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                dateLine!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isLight ? Colors.white70 : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                loading
                    ? Icons.sync_rounded
                    : (syncOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded),
                size: 14,
                color: isLight ? Colors.white70 : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                loading
                    ? 'Synchronisation...'
                    : (syncOk ? 'Connecté' : 'Hors ligne'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isLight ? Colors.white70 : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernActionButtons extends StatelessWidget {
  const _ModernActionButtons({
    required this.notifBadgeCount,
    this.onNotifications,
    this.onProfile,
  });

  final int notifBadgeCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    
    return Row(
      children: [
        _ActionButton(
          icon: Icons.notifications_none_rounded,
          badgeCount: notifBadgeCount,
          onTap: onNotifications,
          color: isLight ? Colors.white : theme.colorScheme.onPrimary,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.person_outline_rounded,
          onTap: onProfile,
          color: isLight ? Colors.white : theme.colorScheme.onPrimary,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    this.badgeCount = 0,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 24),
            onPressed: onTap,
            color: color,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== MODERN KPI SECTION ====================

class _ModernProblemesSection extends StatelessWidget {
  const _ModernProblemesSection({
    required this.data,
    required this.loading,
    required this.preview,
    this.showPreviewList = true,
    this.error,
    this.onVoirTout,
    this.onTapProbleme,
  });

  final _ProblemesKpiData data;
  final bool loading;
  final Object? error;
  final List<ProblemeVoirie> preview;
  final bool showPreviewList;
  final VoidCallback? onVoirTout;
  final void Function(ProblemeVoirie p)? onTapProbleme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Problèmes de voirie détectés par IA',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onVoirTout != null)
              TextButton(
                onPressed: onVoirTout,
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (loading)
          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          _ErrorCard(error: error, theme: theme)
        else ...[
          // KPI Cards Modern
          Row(
            children: [
              Expanded(
                child: _ModernKpiCard(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Total',
                  value: data.total,
                  color: theme.colorScheme.primary,
                  gradient: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernKpiCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'En attente',
                  value: data.enAttente,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModernKpiCard(
                  icon: Icons.play_circle_rounded,
                  label: 'En cours',
                  value: data.enCours,
                  color: const Color(0xFFEF6C00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernKpiCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Terminés',
                  value: data.termines,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          if (showPreviewList && preview.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Interventions récentes',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...preview.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ModernPreviewTile(probleme: p, onTap: onTapProbleme),
            )),
          ],
        ],
      ],
    );
  }
}

class _ModernKpiCard extends StatelessWidget {
  const _ModernKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.gradient = false,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              )
            : null,
        color: gradient ? null : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: gradient ? Colors.white : color,
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: gradient ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: gradient ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernPreviewTile extends StatelessWidget {
  const _ModernPreviewTile({
    required this.probleme,
    this.onTap,
  });

  final ProblemeVoirie probleme;
  final void Function(ProblemeVoirie p)? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color statusColor = ChantierDetailPage.statusColor(probleme.status);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap != null ? () => onTap!(probleme) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${probleme.totalDefects}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ChantierDetailPage.problemTypeLabel(probleme.problemType),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            probleme.address.isNotEmpty ? probleme.address : 'Adresse non renseignée',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  probleme.status.isEmpty ? '—' : probleme.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MODERN PROBLEM CARD ====================

class _ModernProblemeCard extends StatelessWidget {
  const _ModernProblemeCard({
    required this.probleme,
    required this.onOpenDetail,
    this.onChat,
  });

  final ProblemeVoirie probleme;
  final Future<void> Function() onOpenDetail;
  final VoidCallback? onChat;

  String _teamLine() {
    final String e = probleme.equipe.trim();
    if (e.isNotEmpty) return e;
    final String a = probleme.assignedTeam.trim();
    if (a.isNotEmpty) return a.replaceAll('_', ' ');
    return probleme.team.trim().isEmpty ? 'Équipe non assignée' : probleme.team;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color severityColor = _getSeverityColor(probleme.severity);
    final Color statusColor = ChantierDetailPage.statusColor(probleme.status);
    final String title = ChantierDetailPage.problemTypeLabel(probleme.problemType);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onOpenDetail(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            probleme.status.isEmpty ? 'Statut inconnu' : probleme.status,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Risk score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRiskColor(probleme.riskScore),
                          _getRiskColor(probleme.riskScore).withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Risque ${probleme.riskScore.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      probleme.address.isNotEmpty ? probleme.address : 'Localisation non renseignée',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModernInfoChip(
                    icon: Icons.warning_amber_rounded,
                    label: probleme.severity.isNotEmpty ? probleme.severity : 'Gravité inconnue',
                    color: severityColor,
                  ),
                  _ModernInfoChip(
                    icon: Icons.psychology_rounded,
                    label: 'Précision IA ${(probleme.confidence * 100).toStringAsFixed(0)}%',
                    color: theme.colorScheme.primary,
                  ),
                  _ModernInfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Détecté le ${_formatShortDate(probleme.dateDetection)}',
                    color: theme.colorScheme.secondary,
                  ),
                  _ModernInfoChip(
                    icon: Icons.group_rounded,
                    label: _teamLine(),
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Actions buttons
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenDetail(),
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (onChat != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Contacter'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernInfoChip extends StatelessWidget {
  const _ModernInfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color finalColor = color ?? theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: finalColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: finalColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: finalColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: finalColor),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.error,
    required this.theme,
  });

  final Object? error;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Erreur de chargement',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getSeverityColor(String severity) {
  final String s = severity.toLowerCase();
  if (s.contains('élev') || s.contains('eleve') || s.contains('crit') || s.contains('haut')) {
    return const Color(0xFFC62828);
  }
  if (s.contains('moy')) return const Color(0xFFEF6C00);
  if (s.contains('faib') || s.contains('bas')) return const Color(0xFF2E7D32);
  return const Color(0xFF546E7A);
}

Color _getRiskScore(double score) {
  if (score >= 70) return const Color(0xFFC62828);
  if (score >= 40) return const Color(0xFFEF6C00);
  return const Color(0xFF2E7D32);
}

Color _getRiskColor(double score) {
  return _getRiskScore(score);
}