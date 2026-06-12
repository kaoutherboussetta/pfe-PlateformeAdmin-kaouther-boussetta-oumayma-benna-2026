import 'package:flutter/material.dart';
import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/pages/chantier_detail_page.dart';
import 'package:intervenant/services/auth_api_service.dart';

/// Liste des problèmes de voirie (`problemes_de_voirie` via `/api/problemes-voirie`).
class ProblemesVoiriePage extends StatefulWidget {
  const ProblemesVoiriePage({
    this.teamLabel,
    this.notifBadgeCount = 0,
    this.onOpenNotifications,
    this.onOpenProfile,
    this.onOpenChat,
    super.key,
  });

  final String? teamLabel;
  final int notifBadgeCount;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenChat;

  @override
  State<ProblemesVoiriePage> createState() => _ProblemesVoiriePageState();
}

class _ProblemesVoiriePageState extends State<ProblemesVoiriePage> {
  List<ProblemeVoirie> _items = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<ProblemeVoirie> list =
          await AuthApiService.instance.fetchProblemesVoirie(teamLabel: widget.teamLabel);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Color _riskColor(double score) {
    if (score >= 70) return Colors.red.shade700;
    if (score >= 40) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text(
                'Problèmes voirie',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: widget.onOpenNotifications,
                  icon: _NotifBell(count: widget.notifBadgeCount),
                ),
                IconButton(
                  tooltip: 'Chat',
                  onPressed: widget.onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                IconButton(
                  tooltip: 'Profil',
                  onPressed: widget.onOpenProfile,
                  icon: const Icon(Icons.person_outline),
                ),
              ],
            ),
            if (_loading && _items.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_error != null && _items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text('$_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  ),
                ),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun problème pour votre équipe',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les champs assigned_team, equipe ou team du document doivent correspondre à votre équipe (ex. Equipe 5 / equipe_5).',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ProblemeVoirie p = _items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            onTap: () async {
                              final ProblemeVoirie? updated = await Navigator.of(context).push<ProblemeVoirie>(
                                MaterialPageRoute<ProblemeVoirie>(
                                  builder: (_) => ChantierDetailPage(probleme: p),
                                ),
                              );
                              if (!mounted || updated == null) return;
                              setState(() {
                                _items[index] = updated;
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: _riskColor(p.riskScore).withValues(alpha: 0.2),
                              foregroundColor: _riskColor(p.riskScore),
                              child: Text(
                                '${p.totalDefects}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                            title: Text(
                              ChantierDetailPage.problemTypeLabel(p.problemType),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Risque ${p.riskScore.toStringAsFixed(1)} · ${p.severity.isEmpty ? '—' : p.severity}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ChantierDetailPage.statusColor(p.status).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                p.status.isEmpty ? '—' : p.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ChantierDetailPage.statusColor(p.status),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotifBell extends StatelessWidget {
  const _NotifBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const double sz = 24;
    return SizedBox(
      width: sz,
      height: sz,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_outlined, size: sz),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: count > 9 ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
                decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99' : '$count',
                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
