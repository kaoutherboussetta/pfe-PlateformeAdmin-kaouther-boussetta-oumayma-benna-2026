import 'package:flutter/material.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_theme.dart';

class StatisticsCards extends StatelessWidget {
  final int alertsSent;
  final int monitoredZones;
  final int emergencyContacts;

  const StatisticsCards({
    super.key,
    required this.alertsSent,
    required this.monitoredZones,
    required this.emergencyContacts,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.warning_rounded,
            number: alertsSent,
            label: s.statAlertsSent,
            color: AppTheme.alertOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.map_rounded,
            number: monitoredZones,
            label: s.statMonitoredZones,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            number: emergencyContacts,
            label: s.statEmergencyContacts,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int number;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            number.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.secondaryGrey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
