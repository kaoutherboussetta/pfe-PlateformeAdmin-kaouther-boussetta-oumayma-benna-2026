import 'package:flutter/material.dart';

import '../models/traffic_jam_model.dart';

class TrafficJamMarker extends StatelessWidget {
  final TrafficJamModel jam;
  final VoidCallback onTap;

  const TrafficJamMarker({
    super.key,
    required this.jam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        jam.getLevelIcon(),
        color: jam.getLevelColor(),
        size: 34,
      ),
    );
  }
}
