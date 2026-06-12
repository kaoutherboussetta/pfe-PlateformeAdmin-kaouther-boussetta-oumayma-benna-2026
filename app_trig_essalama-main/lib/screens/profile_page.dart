import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/context_l10n.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/security_status_card.dart';
import '../widgets/settings_list.dart';
import '../widgets/logout_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_theme.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import 'edit_profile_page.dart';
import 'personal_information_page.dart';
import 'emergency_contacts_page.dart';
import 'location_settings_page.dart';
import 'help_support_page.dart';
import 'alert_history_page.dart';
import '../widgets/language_bottom_sheet.dart';

class ProfilePage extends StatefulWidget {
  /// When true, shows the bottom nav bar (e.g. when opened as standalone route).
  /// When false, used as tab content inside HomePage which has its own nav.
  final bool showBottomBar;

  const ProfilePage({super.key, this.showBottomBar = true});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 3; // Profile tab is active

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/home', arguments: 1);
        break;
      case 2:
        Navigator.pushNamed(context, '/home', arguments: 2);
        break;
      case 3:
        break;
    }
  }

  void _navigateToSettings(String route) {
    switch (route) {
      case 'personal':
        // Ouvre la page Information personnelle (personal_information_page.dart)
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PersonalInformationPage()),
        );
        break;
      case 'edit_profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfilePage()),
        );
        break;
      case 'emergency':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmergencyContactsPage()),
        );
        break;
      case 'location':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LocationSettingsPage()),
        );
        break;
      case 'help':
        Navigator.pushNamed(context, '/help-support');
        break;
      case 'language':
        showAppLanguagePicker(context);
        break;
    }
  }

  void _onSOSPressed() {
    final s = context.read<LocaleProvider>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          s.sosTitle,
          style: const TextStyle(color: AppTheme.alertOrange),
        ),
        content: Text(
          s.sosBody,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel, style: const TextStyle(color: AppTheme.secondaryGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEmergencyConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertOrange,
              foregroundColor: AppTheme.whiteText,
            ),
            child: Text(s.sendSos),
          ),
        ],
      ),
    );
  }

  void _showEmergencyConfirmation() {
    final s = context.read<LocaleProvider>().strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.emergencyAlertSent),
        backgroundColor: AppTheme.alertOrange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onShareLocationPressed() {
    final s = context.read<LocaleProvider>().strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.sharingLocation),
        backgroundColor: AppTheme.alertOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onAlertHistoryPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final user = authProvider.currentUser ?? _fallbackUser(authProvider);
    final s = context.strings;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light ? AppTheme.lightGrey : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ProfileHeader(
                        user: user,
                        onEditPressed: () => _navigateToSettings('edit_profile'),
                        variant: 'default',
                      ),
                      const SizedBox(height: 32),
                      SettingsList(
                        strings: s,
                        initialDarkMode: themeProvider.isDarkMode,
                        onItemTap: _navigateToSettings,
                        onDarkModeToggle: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildStopServiceButton(),
                      const SizedBox(height: 16),
                      const LogoutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.showBottomBar)
              BottomNavBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onNavItemTapped,
                homeLabel: s.navHome,
                alertsLabel: s.navAlerts,
                mapLabel: s.navMap,
                profileLabel: s.navProfile,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopServiceButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: () {
          final s = context.read<LocaleProvider>().strings;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.serviceStopped),
              backgroundColor: AppTheme.softRed,
            ),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.softRed.withOpacity(0.08),
          foregroundColor: AppTheme.softRed,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              context.strings.stopService,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback user when not logged in (e.g. demo or after logout redirect).
  UserModel? _fallbackUser(AuthProvider authProvider) {
    if (authProvider.userEmail != null || authProvider.userFullName != null) {
      return UserModel(
        id: '1',
        fullName: authProvider.userFullName,
        email: authProvider.userEmail,
        alertsSent: 24,
        monitoredZones: 5,
        emergencyContactsCount: 8,
        securityLevel: 'High',
      );
    }
    return null;
  }
}
