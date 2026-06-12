import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/traffic_jam_service.dart';

class TrafficJamReportSheet extends StatefulWidget {
  final LatLng position;
  final Function(bool success) onReported;

  const TrafficJamReportSheet({
    super.key,
    required this.position,
    required this.onReported,
  });

  @override
  State<TrafficJamReportSheet> createState() => _TrafficJamReportSheetState();
}

class _TrafficJamReportSheetState extends State<TrafficJamReportSheet> {
  int _congestionLevel = 50;
  String _cause = 'unknown';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, Map<String, dynamic>> _causes = {
    'accident': {
      'label': 'Accident',
      'icon': Icons.car_crash,
      'color': Colors.red,
    },
    'construction': {
      'label': 'Travaux',
      'icon': Icons.construction,
      'color': Colors.orange,
    },
    'peak_hour': {
      'label': 'Heure de pointe',
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    'weather': {'label': 'Meteo', 'icon': Icons.cloud, 'color': Colors.cyan},
    'event': {
      'label': 'Evenement',
      'icon': Icons.celebration,
      'color': Colors.purple,
    },
    'unknown': {'label': 'Autre', 'icon': Icons.help, 'color': Colors.grey},
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    final success = await TrafficJamService.reportTrafficJam(
      latitude: widget.position.latitude,
      longitude: widget.position.longitude,
      congestionLevel: _congestionLevel,
      averageSpeed: _getEstimatedSpeed(),
      cause: _cause,
      description: _descriptionController.text.trim(),
      radius: 100,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onReported(success);
    Navigator.pop(context);
  }

  double _getEstimatedSpeed() {
    if (_congestionLevel >= 80) return 5;
    if (_congestionLevel >= 60) return 15;
    if (_congestionLevel >= 40) return 30;
    if (_congestionLevel >= 20) return 50;
    return 70;
  }

  Color _getLevelColor() {
    if (_congestionLevel >= 80) return Colors.red;
    if (_congestionLevel >= 60) return Colors.deepOrange;
    if (_congestionLevel >= 40) return Colors.orange;
    if (_congestionLevel >= 20) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getLevelLabel() {
    if (_congestionLevel >= 80) return 'Bloque / Tres severe';
    if (_congestionLevel >= 60) return 'Bouchon severe';
    if (_congestionLevel >= 40) return 'Circulation dense';
    if (_congestionLevel >= 20) return 'Circulation moderee';
    return 'Circulation fluide';
  }

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.traffic, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Signaler un embouteillage',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Niveau de congestion',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _congestionLevel.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: _getLevelColor(),
                  label: _getLevelLabel(),
                  onChanged: (value) {
                    setState(() => _congestionLevel = value.round());
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getLevelColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getLevelColor()),
                ),
                child: Text(
                  '$_congestionLevel%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getLevelColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getLevelLabel(),
            style: TextStyle(fontSize: 12, color: _getLevelColor()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cause (optionnel)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _causes.keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final key = _causes.keys.elementAt(index);
                final cause = _causes[key]!;
                final isSelected = _cause == key;
                return FilterChip(
                  label: Text(cause['label'] as String),
                  avatar: Icon(cause['icon'] as IconData, size: 18),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _cause = key),
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: (cause['color'] as Color).withValues(alpha: 0.2),
                  checkmarkColor: cause['color'] as Color,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description (optionnel)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ex: Accident sur la voie de gauche...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Signaler'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
