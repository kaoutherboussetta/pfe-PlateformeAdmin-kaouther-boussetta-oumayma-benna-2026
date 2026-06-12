import 'package:flutter/material.dart';

import '../services/problemes_voirie_service.dart';

/// Marqueur problème de voirie : icônes fissure / nid-de-poule / voie bloquée
/// avec la même taille de glyphe et des cercles de même diamètre.
class ProblemeVoirieMarker extends StatelessWidget {
  final ProblemeVoirie probleme;
  final VoidCallback onTap;
  final bool isSelected;

  const ProblemeVoirieMarker({
    super.key,
    required this.probleme,
    required this.onTap,
    this.isSelected = false,
  });

  static const Color _voieBloqueeColor = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    final double box = isSelected ? 30 : 26;
    final double cell = isSelected ? 14 : 12;
    const double gap = 2;
    final double iconSize = isSelected ? 9 : 7;
    final double spot = cell * 2 + gap;
    final bool inProgress = _isInProgressStatus(probleme.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: box,
        height: box,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (probleme.severity == 'Élevée' || probleme.riskScore > 50)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Container(
                    width: spot * value,
                    height: spot * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColor().withValues(
                        alpha: 0.3 - (value - 0.8) * 0.8,
                      ),
                    ),
                  );
                },
              ),
            if (inProgress)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundIconCell(
                    diameter: cell,
                    icon: Icons.construction,
                    iconColor: _voieBloqueeColor,
                    background: Colors.white,
                    borderColor: _voieBloqueeColor,
                    iconSize: iconSize,
                  ),
                  SizedBox(width: gap),
                  _roundIconCell(
                    diameter: cell,
                    icon: _getProblemTypeIcon(),
                    iconColor: _getColor(),
                    background: Colors.white,
                    borderColor: _getColor(),
                    iconSize: iconSize,
                  ),
                ],
              )
            else
              _roundIconCell(
                diameter: spot,
                icon: _getProblemTypeIcon(),
                iconColor: Colors.white,
                background: _getColor(),
                borderColor: Colors.white,
                borderWidth: isSelected ? 2 : 1.5,
                iconSize: iconSize,
              ),
            Positioned(
              top: -1,
              right: -1,
              child: _roundPriorityBadge(
                diameter: cell * 0.85,
                iconSize: iconSize * 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconCell({
    required double diameter,
    required IconData icon,
    required Color iconColor,
    required Color background,
    required Color borderColor,
    required double iconSize,
    double borderWidth = 1.5,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }

  Widget _roundPriorityBadge({
    required double diameter,
    required double iconSize,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        _getPriorityText(),
        style: TextStyle(
          color: Colors.white,
          fontSize: iconSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (probleme.problemType) {
      case 'pothole':
        return const Color(0xFFEA4335);
      case 'crack':
        return probleme.riskScore > 40
            ? const Color(0xFFFBBC05)
            : const Color(0xFF34A853);
      default:
        return Colors.grey;
    }
  }

  IconData _getProblemTypeIcon() {
    switch (probleme.problemType) {
      case 'pothole':
        return Icons.blur_circular_rounded;
      case 'crack':
        return Icons.view_week_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getPriorityColor() {
    switch (probleme.maintenancePriority) {
      case 'P1':
        return Colors.red;
      case 'P2':
        return Colors.orange;
      case 'P3':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText() {
    switch (probleme.maintenancePriority) {
      case 'P1':
        return '!';
      case 'P2':
        return '⚠';
      case 'P3':
        return '✓';
      default:
        return '•';
    }
  }

  bool _isInProgressStatus(String status) {
    return status.trim().toLowerCase() == 'en cours';
  }
}
