import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../services/traffic_service.dart';

class TrafficReportBottomSheet extends StatefulWidget {
  final LatLng userPosition;
  final Function(bool) onReportSent;

  const TrafficReportBottomSheet({
    super.key,
    required this.userPosition,
    required this.onReportSent,
  });

  static void show(BuildContext context, LatLng position, Function(bool) onReportSent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrafficReportBottomSheet(
        userPosition: position,
        onReportSent: onReportSent,
      ),
    );
  }

  @override
  State<TrafficReportBottomSheet> createState() => _TrafficReportBottomSheetState();
}

class _TrafficReportBottomSheetState extends State<TrafficReportBottomSheet> {
  int _congestionLevel = 50;
  String _cause = 'unknown';
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
    final s = context.stringsRead;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + keyboardPad + 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.traffic, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.mapReportTrafficJam,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      s.mapReportJamSubtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Niveau de congestion
          Text(
            s.mapJamLevelLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                s.mapJamLevelLow,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Expanded(
                child: Slider(
                  value: _congestionLevel.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 4,
                  activeColor: _getJamColor(_congestionLevel),
                  label: _getJamLabel(_congestionLevel, s),
                  onChanged: (val) => setState(() => _congestionLevel = val.toInt()),
                ),
              ),
              Text(
                s.mapJamLevelHigh,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Cause présumée
          Text(
            s.mapJamCauseLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChoiceChip('accident', s.mapReportAccident, Icons.car_crash_rounded),
              _buildChoiceChip('construction', s.mapReportLaneBlocked, Icons.construction),
              _buildChoiceChip('event', s.mapReportEvent, Icons.event),
              _buildChoiceChip('unknown', s.mapReportUnknown, Icons.help_outline),
            ],
          ),

          const SizedBox(height: 24),

          // Commentaire
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: s.mapReportJamCommentHint,
              hintStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 24),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA4335),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s.mapButtonReport,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String value, String label, IconData icon) {
    final isSelected = _cause == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _cause = value);
      },
      selectedColor: const Color(0xFFFF6B6B),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Color _getJamColor(int level) {
    if (level < 30) return Colors.green;
    if (level < 60) return Colors.orange;
    return Colors.red;
  }

  String _getJamLabel(int level, AppStrings s) {
    if (level < 30) return s.mapJamLevelFluid;
    if (level < 60) return s.mapJamLevelSlow;
    return s.mapJamLevelBlocked;
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await TrafficService.reportProblem(
        lat: widget.userPosition.latitude,
        lng: widget.userPosition.longitude,
        type: 'jam',
        congestionLevel: _congestionLevel,
        cause: _cause,
        description: _descController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReportSent(success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
