import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String homeLabel;
  final String mapLabel;
  final String alertsLabel;
  final String profileLabel;
  final bool showAlertsBadge;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.homeLabel,
    required this.mapLabel,
    required this.alertsLabel,
    required this.profileLabel,
    this.showAlertsBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _NavItem(
                      label: homeLabel,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      isSelected: selectedIndex == 0,
                      onTap: () => onItemTapped(0),
                      isDark: isDark,
                    ),
                    _NavItem(
                      label: mapLabel,
                      icon: Icons.map_outlined,
                      selectedIcon: Icons.map_rounded,
                      isSelected: selectedIndex == 1,
                      onTap: () => onItemTapped(1),
                      isDark: isDark,
                    ),
                    _NavItem(
                      label: alertsLabel,
                      icon: Icons.notifications_none_rounded,
                      selectedIcon: Icons.notifications_rounded,
                      isSelected: selectedIndex == 2,
                      onTap: () => onItemTapped(2),
                      isDark: isDark,
                      showBadge: showAlertsBadge && selectedIndex != 2,
                    ),
                    _NavItem(
                      label: profileLabel,
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      isSelected: selectedIndex == 3,
                      onTap: () => onItemTapped(3),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool showBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : AppTheme.primaryBlack;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.38);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.alertOrange.withValues(alpha: 0.12),
          highlightColor: AppTheme.alertOrange.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? selectedIcon : icon,
                      size: 22,
                      color: isSelected ? AppTheme.alertOrange : inactiveColor,
                    ),
                    if (showBadge)
                      Positioned(
                        top: -2,
                        right: -5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.softRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.12),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
