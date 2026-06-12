import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SecurityStatusCard extends StatelessWidget {
  final String securityLevel; // 'High', 'Medium', 'Low'
  final VoidCallback onSOSPressed;
  final VoidCallback onShareLocationPressed;
  final VoidCallback onAlertHistoryPressed;

  const SecurityStatusCard({
    super.key,
    required this.securityLevel,
    required this.onSOSPressed,
    required this.onShareLocationPressed,
    required this.onAlertHistoryPressed,
  });

  Color _getStatusColor() {
    switch (securityLevel) {
      case 'High':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Security Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor().withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      securityLevel,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.warning_rounded,
                  label: 'SOS',
                  color: Colors.red,
                  onPressed: onSOSPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_location_rounded,
                  label: 'Share Location',
                  color: Colors.blue,
                  onPressed: onShareLocationPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  color: AppTheme.secondaryGrey,
                  onPressed: onAlertHistoryPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
