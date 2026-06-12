import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/services/auth_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Détail d’un enregistrement `problemes_de_voirie` (Atlas) - Version Professionnelle
class ChantierDetailPage extends StatelessWidget {
  const ChantierDetailPage({required this.probleme, super.key});

  final ProblemeVoirie probleme;

  static String problemTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'crack':
        return 'Fissure';
      case 'pothole':
        return 'Nid-de-poule';
      default:
        return type.isEmpty ? 'Type inconnu' : type;
    }
  }

  static Color statusColor(String status) {
    final String s = status.toLowerCase().trim();
    if (s.contains('cours') || s.contains('progress')) return const Color(0xFFEF6C00);
    if (s.contains('termin')) return const Color(0xFF2E7D32);
    if (s.contains('attente')) return const Color(0xFFC62828);
    return Colors.blueGrey;
  }

  static const String statutEnAttente = 'en attente';
  static const String statutEnCours = 'en cours';
  static const String statutTermine = 'terminé';

  static String _canonStatut(String raw) {
    final String s = raw.toLowerCase().trim().replaceAll('é', 'e');
    if (s.contains('attente')) return statutEnAttente;
    if (s.contains('termine')) return statutTermine;
    if (s.contains('cours')) return statutEnCours;
    return raw.trim().toLowerCase();
  }

  static String formatStatutAffichage(String status) {
    final String c = _canonStatut(status);
    switch (c) {
      case statutEnAttente:
        return 'En attente';
      case statutEnCours:
        return 'En cours';
      case statutTermine:
        return 'Terminé';
      default:
        return status.trim().isEmpty ? '—' : status.trim();
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final double? lat = probleme.mapsLatitude;
    final double? lng = probleme.mapsLongitude;
    final String addr = probleme.address.trim();
    final bool addrUsable =
        addr.isNotEmpty && addr != 'Adresse non renseignée' && addr != 'Adresse non disponible';

    final Uri uri;
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (addrUsable) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(addr)}',
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Localisation (adresse ou GPS) indisponible')),
        );
      }
      return;
    }
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir Maps')),
      );
    }
  }

  String _formatDate(String raw) {
    final DateTime? d = DateTime.tryParse(raw);
    if (d != null) {
      final DateTime local = d.toLocal();
      try {
        return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(local);
      } catch (_) {
        return DateFormat('dd/MM/yyyy HH:mm').format(local);
      }
    }
    return raw.isEmpty ? '—' : raw;
  }

  String _resolveTeam() {
    final String t = probleme.equipe.trim();
    if (t.isNotEmpty) return t;
    final String a = probleme.assignedTeam.trim();
    if (a.isNotEmpty) return a.replaceAll('_', ' ');
    return probleme.team.trim().isEmpty ? 'Non assignée' : probleme.team;
  }

  Future<void> _updateStatus(BuildContext context, String newStatusCanon) async {
    final String currentCanon = _canonStatut(probleme.status);
    if (currentCanon == newStatusCanon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut déjà : ${formatStatutAffichage(newStatusCanon)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final ProblemeVoirie updated = await AuthApiService.instance.patchProblemeVoirieStatus(
        id: probleme.id,
        status: newStatusCanon,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade300, size: 20),
              const SizedBox(width: 12),
              Text('Statut mis à jour : ${formatStatutAffichage(updated.status)}'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade800,
        ),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur : $e')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).chantierDetailTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: CustomScrollView(
        slivers: [
          // Header Hero Section
          SliverToBoxAdapter(
            child: _HeroHeader(probleme: probleme),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Contenu principal
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatusTimeline(probleme: probleme, onStatusChange: _updateStatus),
                const SizedBox(height: 16),
                _LocationCard(probleme: probleme, onOpenMaps: _openMaps),
                const SizedBox(height: 16),
                _TechnicalCard(probleme: probleme, formatDate: _formatDate),
                const SizedBox(height: 16),
                _DescriptionCard(probleme: probleme),
                const SizedBox(height: 16),
                _TeamCard(probleme: probleme, resolveTeam: _resolveTeam),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HERO HEADER ====================

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.probleme});

  final ProblemeVoirie probleme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color status = ChantierDetailPage.statusColor(probleme.status);
    final String typeLabel = ChantierDetailPage.problemTypeLabel(probleme.problemType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Intervention #${probleme.id.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: status,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: status.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(probleme.status),
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ChantierDetailPage.formatStatutAffichage(probleme.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Indicateurs clés
          Row(
            children: [
              _HeroMetric(
                value: '${probleme.totalDefects}',
                label: 'Défauts',
                icon: Icons.bug_report_rounded,
              ),
              const SizedBox(width: 16),
              _HeroMetric(
                value: probleme.riskScore.toStringAsFixed(0),
                label: 'Risque',
                icon: Icons.trending_up_rounded,
                suffix: '%',
              ),
              const SizedBox(width: 16),
              _HeroMetric(
                value: (probleme.confidence * 100).toStringAsFixed(0),
                label: 'Confiance IA',
                icon: Icons.psychology_rounded,
                suffix: '%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    final String s = status.toLowerCase();
    if (s.contains('cours')) return Icons.play_circle_rounded;
    if (s.contains('termin')) return Icons.check_circle_rounded;
    if (s.contains('attente')) return Icons.pause_circle_rounded;
    return Icons.help_outline_rounded;
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
    this.suffix = '',
  });

  final String value;
  final String label;
  final IconData icon;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== STATUS TIMELINE ====================

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({
    required this.probleme,
    required this.onStatusChange,
  });

  final ProblemeVoirie probleme;
  final Future<void> Function(BuildContext, String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String currentStatus = ChantierDetailPage._canonStatut(probleme.status);
    final List<Map<String, dynamic>> steps = [
      {'status': ChantierDetailPage.statutEnAttente, 'label': 'En attente', 'icon': Icons.pause_circle_outline},
      {'status': ChantierDetailPage.statutEnCours, 'label': 'En cours', 'icon': Icons.play_circle_outline},
      {'status': ChantierDetailPage.statutTermine, 'label': 'Terminé', 'icon': Icons.check_circle_outline},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avancement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(steps.length, (index) {
                final isCompleted = index <= currentIndex;
                final isActive = index == currentIndex;
                return Expanded(
                  child: _TimelineStep(
                    label: steps[index]['label'] as String,
                    icon: steps[index]['icon'] as IconData,
                    isCompleted: isCompleted,
                    isActive: isActive,
                    isLast: index == steps.length - 1,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Changer le statut',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'En attente',
                    icon: Icons.pause_circle_outline,
                    color: const Color(0xFFC62828),
                    onPressed: () => onStatusChange(context, ChantierDetailPage.statutEnAttente),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: 'En cours',
                    icon: Icons.play_circle_outline,
                    color: const Color(0xFFEF6C00),
                    onPressed: () => onStatusChange(context, ChantierDetailPage.statutEnCours),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: 'Terminé',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF2E7D32),
                    onPressed: () => onStatusChange(context, ChantierDetailPage.statutTermine),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color activeColor = isCompleted ? theme.colorScheme.primary : Colors.grey.shade300;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? activeColor : (isCompleted ? activeColor.withValues(alpha: 0.2) : Colors.grey.shade100),
                  border: isActive ? Border.all(color: activeColor, width: 2) : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive ? Colors.white : (isCompleted ? activeColor : Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? activeColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isCompleted ? activeColor : Colors.grey.shade200,
            ),
          ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// ==================== LOCATION CARD ====================

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.probleme,
    required this.onOpenMaps,
  });

  final ProblemeVoirie probleme;
  final Future<void> Function(BuildContext) onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? la = probleme.mapsLatitude;
    final double? lo = probleme.mapsLongitude;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFFC62828), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Localisation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(label: 'Adresse', value: probleme.address),
            if (la != null && lo != null && la.isFinite && lo.isFinite) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(label: 'Latitude', value: la.toStringAsFixed(6)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoRow(label: 'Longitude', value: lo.toStringAsFixed(6)),
                  ),
                ],
              ),
              if (probleme.location.accuracy != null) ...[
                const SizedBox(height: 12),
                _InfoRow(label: 'Précision GPS', value: '${probleme.location.accuracy} mètres'),
              ],
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => onOpenMaps(context),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Ouvrir dans Google Maps'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TECHNICAL CARD ====================

class _TechnicalCard extends StatelessWidget {
  const _TechnicalCard({
    required this.probleme,
    required this.formatDate,
  });

  final ProblemeVoirie probleme;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Caractéristiques techniques',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoGrid(
              items: [
                _InfoItem(
                  label: 'Type de problème',
                  value: ChantierDetailPage.problemTypeLabel(probleme.problemType),
                  icon: Icons.category_rounded,
                ),
                _InfoItem(
                  label: 'Gravité',
                  value: probleme.severity.isEmpty ? 'Non évaluée' : probleme.severity,
                  icon: Icons.warning_amber_rounded,
                  color: _getSeverityColor(probleme.severity),
                ),
                _InfoItem(
                  label: 'Score de risque',
                  value: '${probleme.riskScore.toStringAsFixed(0)} / 100',
                  icon: Icons.trending_up_rounded,
                ),
                _InfoItem(
                  label: 'Confiance IA',
                  value: '${(probleme.confidence * 100).toStringAsFixed(0)}%',
                  icon: Icons.psychology_rounded,
                ),
                _InfoItem(
                  label: 'Modèle IA',
                  value: probleme.aiModel.isEmpty ? 'Standard' : probleme.aiModel,
                  icon: Icons.model_training_rounded,
                ),
                _InfoItem(
                  label: 'Coût estimé',
                  value: probleme.coutEstime.isEmpty ? 'Non estimé' : probleme.coutEstime,
                  icon: Icons.attach_money_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Détecté le',
                    value: formatDate(probleme.dateDetection),
                    icon: Icons.calendar_today_rounded,
                    narrowLabel: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoRow(
                    label: 'Mise à jour',
                    value: formatDate(probleme.updatedAt),
                    icon: Icons.update_rounded,
                    narrowLabel: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    final String s = severity.toLowerCase();
    if (s.contains('élev') || s.contains('eleve') || s.contains('crit')) {
      return const Color(0xFFC62828);
    }
    if (s.contains('moy')) return const Color(0xFFEF6C00);
    if (s.contains('faib')) return const Color(0xFF2E7D32);
    return Colors.grey;
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final _InfoItem left = items[i];
      final _InfoItem? right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < items.length ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InfoGridItem(item: left)),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _InfoGridItem(item: right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _InfoGridItem extends StatelessWidget {
  const _InfoGridItem({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = item.color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

// ==================== DESCRIPTION CARD ====================

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.probleme});

  final ProblemeVoirie probleme;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String fr = probleme.descriptionFr.isNotEmpty ? probleme.descriptionFr : probleme.description;
    final String ar = probleme.descriptionAr;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_rounded, color: Color(0xFF2E7D32), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Français', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    fr.isEmpty ? 'Aucune description disponible' : fr,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            if (ar.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('العربية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      ar,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== TEAM CARD ====================

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.probleme,
    required this.resolveTeam,
  });

  final ProblemeVoirie probleme;
  final String Function() resolveTeam;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String team = resolveTeam();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  team.isNotEmpty ? team.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Équipe assignée',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.purple, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== INFO ROW ====================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.narrowLabel = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  /// Libellé plus court en demi-largeur (ligne à deux colonnes).
  final bool narrowLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double labelW = narrowLabel
        ? (icon != null ? 72.0 : 80.0)
        : (icon != null ? 110.0 : 120.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
        ],
        SizedBox(
          width: labelW,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}