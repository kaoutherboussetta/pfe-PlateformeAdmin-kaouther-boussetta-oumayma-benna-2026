import 'package:flutter/material.dart';

import '../models/probleme_signale_map_item.dart';

/// Marqueur carte pour un document `problemes_signales` (MongoDB).
class ProblemeSignaleMarker extends StatelessWidget {
  final ProblemeSignaleMapItem item;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;

  const ProblemeSignaleMarker({
    super.key,
    required this.item,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 36.0 : 30.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(
            color: isSelected ? Colors.white : color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: isSelected ? 18 : 15),
      ),
    );
  }
}
