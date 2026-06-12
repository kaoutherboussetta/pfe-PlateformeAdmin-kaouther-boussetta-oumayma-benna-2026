import 'package:flutter/material.dart';

/// Marqueur compact avec badge de comptage pour plusieurs problèmes au même endroit.
class GroupedMapProblemMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;
  final bool isSelected;

  const GroupedMapProblemMarker({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
    this.isSelected = false,
  });

  static const double _size = 22;
  static const double _selectedSize = 26;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? _selectedSize : _size;
    final iconSize = isSelected ? 12.0 : 10.0;
    final showBadge = count > 1;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (showBadge ? 6 : 0),
        height: size + (showBadge ? 6 : 0),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
