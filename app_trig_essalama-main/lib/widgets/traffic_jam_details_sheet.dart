import 'package:flutter/material.dart';

import '../models/traffic_jam_model.dart';

class TrafficJamDetailsSheet extends StatelessWidget {
  final TrafficJamModel jam;

  const TrafficJamDetailsSheet({super.key, required this.jam});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: jam.getLevelColor().withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  jam.getLevelIcon(),
                  color: jam.getLevelColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jam.getLevelLabel(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: jam.getLevelColor(),
                      ),
                    ),
                    Text(
                      'Signale le ${_formatDate(jam.detectedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                'Congestion',
                '${jam.congestionLevel}%',
                jam.getLevelColor(),
                Icons.speed,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Vitesse moyenne',
                '${jam.averageSpeed.toInt()} km/h',
                jam.getLevelColor(),
                Icons.directions_car,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (jam.cause != 'unknown') ...[
            _buildInfoRow(Icons.info_outline, 'Cause', _getCauseLabel(jam.cause)),
            const SizedBox(height: 12),
          ],
          if (jam.description.isNotEmpty) ...[
            _buildInfoRow(Icons.description, 'Description', jam.description),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getCauseLabel(String cause) {
    switch (cause) {
      case 'accident':
        return 'Accident';
      case 'construction':
        return 'Travaux';
      case 'event':
        return 'Evenement';
      case 'peak_hour':
        return 'Heure de pointe';
      case 'weather':
        return 'Conditions meteo';
      default:
        return 'Cause inconnue';
    }
  }
}
