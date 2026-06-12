import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class SettingsList extends StatefulWidget {
  final AppStrings strings;
  final Function(String) onItemTap;
  final Function(bool) onDarkModeToggle;
  final bool initialDarkMode;

  const SettingsList({
    super.key,
    required this.strings,
    required this.onItemTap,
    required this.onDarkModeToggle,
    required this.initialDarkMode,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  late bool _darkModeEnabled;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = widget.initialDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final s = widget.strings;
    return Column(
      children: [
        _buildSection([
          _buildSettingsItem(
            icon: Icons.person_outline_rounded,
            title: s.settingsPersonalInfo,
            iconColor: Colors.blue[400]!,
            onTap: () => widget.onItemTap('personal'),
          ),
          _buildSettingsItem(
            icon: Icons.emergency_outlined,
            title: s.settingsEmergency,
            iconColor: Colors.red[400]!,
            onTap: () => widget.onItemTap('emergency'),
          ),
          _buildSettingsItem(
            icon: Icons.location_on_outlined,
            title: s.settingsLocation,
            iconColor: Colors.green[400]!,
            onTap: () => widget.onItemTap('location'),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection([
          _buildSettingsItem(
            icon: Icons.dark_mode_outlined,
            title: s.settingsDarkMode,
            iconColor: Colors.orange[400]!,
            trailing: Switch.adaptive(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                widget.onDarkModeToggle(value);
              },
              activeColor: AppTheme.iosBlue,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection([
          _buildSettingsItem(
            icon: Icons.language_rounded,
            title: s.settingsLanguage,
            iconColor: Colors.purple[400]!,
            onTap: () => widget.onItemTap('language'),
          ),
        ]),
        const SizedBox(height: 20),
        _buildSection([
          _buildSettingsItem(
            icon: Icons.help_outline_rounded,
            title: s.settingsHelp,
            iconColor: Colors.teal[400]!,
            onTap: () => widget.onItemTap('help'),
          ),
        ]),
      ],
    );
  }

  Widget _buildSection(List<Widget> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isEven) {
            return items[index ~/ 2];
          }
          return Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: isDark ? theme.dividerColor : Colors.grey[200],
          );
        }),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
