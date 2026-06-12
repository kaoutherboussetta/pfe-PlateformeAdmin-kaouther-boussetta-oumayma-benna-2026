import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/language_bottom_sheet.dart';
import '../widgets/video_background.dart';

const String _kLocationPermissionAskedKey = 'location_permission_asked_once';

// Clés partagées avec LocationSettingsPage pour synchroniser les préférences
const String _kLocationEnabled = 'location_settings_enabled';
const String _kEmergencySharing = 'location_settings_emergency_sharing';
const String _kAutoUpdate = 'location_settings_auto_update';
const String _kPrecision = 'location_settings_precision';
const String _kFrequency = 'location_settings_frequency';

class CompleteOnboardingPage extends StatefulWidget {
  const CompleteOnboardingPage({super.key});

  @override
  State<CompleteOnboardingPage> createState() => _CompleteOnboardingPageState();
}

class _CompleteOnboardingPageState extends State<CompleteOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  // Couleurs
  static const Color _primaryColor = Color(0xFF0088CC);
  static const Color _secondaryColor = Color(0xFF25D366);
  static const Color _accentColor = Color(0xFFFF9500);
  static const Color _textSecondary = Color(0xFF8E8E93);
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    VideoBackground.preload();
    // Afficher automatiquement la demande de localisation à la première ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionDialogIfFirstTime();
    });
  }

  /// Vérifie la permission de localisation : demande si refusée, ouvre les paramètres si refus définitif.
  Future<LocationPermission> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
    }
    return permission;
  }

  /// Vérifie si le GPS est activé et ouvre les paramètres de localisation si besoin.
  Future<void> checkGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage == _totalPages - 1) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    HapticFeedback.lightImpact();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Demande l'autorisation de localisation une seule fois (au premier lancement après installation).
  Future<void> _showLocationPermissionDialogIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLocationPermissionAskedKey) == true) return;
    if (!mounted) return;

    final s = context.read<LocaleProvider>().strings;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.locationDialogTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            s.locationDialogBody,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final p = await SharedPreferences.getInstance();
                await p.setBool(_kLocationPermissionAskedKey, true);
                // L'utilisateur repousse la décision : on laisse la localisation
                // de l'app désactivée par défaut.
                await p.setBool(_kLocationEnabled, false);
              },
              child: Text(
                s.later,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Demande la permission (popup système : Autoriser / Refuser / Pendant l'utilisation)
                LocationPermission permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.deniedForever) {
                  await openAppSettings();
                }
                await checkGPS();
                final p = await SharedPreferences.getInstance();
                await p.setBool(_kLocationPermissionAskedKey, true);
                final granted = permission == LocationPermission.whileInUse ||
                    permission == LocationPermission.always;
                await p.setBool(_kLocationEnabled, granted);
                if (granted) {
                  await p.setBool(_kEmergencySharing, true);
                  await p.setBool(_kAutoUpdate, true);
                  await p.setString(_kPrecision, 'Élevée (GPS)');
                  await p.setString(_kFrequency, 'En temps réel');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s.allow,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, locale, _) {
        final s = locale.strings;
        return Scaffold(
      backgroundColor: _bgColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Stack(
        children: [
              // Fond avec léger dégradé
          Positioned.fill(
                child: Container(
      decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [const Color(0xFFF7F8FA), _bgColor],
                      stops: const [0.0, 0.8],
                    ),
          ),
        ),
      ),

              // Pages
              PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _totalPages,
                itemBuilder: (context, index) => _buildPage(index, s),
              ),

              // Header : indicateurs + bouton retour/skip
          Positioned(
                top: 20,
                left: 24,
                right: 24,
      child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      GestureDetector(
                        onTap: _previousPage,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: _textPrimary, size: 20),
                      )
                    else
                      const SizedBox(width: 20),
                    Row(
                      children: List.generate(_totalPages, (i) {
          return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 22 : 8,
                          height: 8,
            decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentPage
                                ? _getPageColor(i)
                                : _textSecondary.withValues(alpha:0.3),
            ),
          );
        }),
      ),
                    if (_currentPage < _totalPages - 1)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          s.skip,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 20),
                  ],
                ),
              ),

              // Bouton principal
              Positioned(
                bottom: 100,
                left: 40,
                right: 40,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? s.start
                        : s.continueLabel,
                                style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                                  color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),

              // Choix langue
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    onPressed: () => showAppLanguagePicker(context),
                    child: Text(
                      s.chooseLanguage,
                              style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
            ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  // Construction d'une page : logo, titre, phrase (même style qu'avant)
  Widget _buildPage(int index, AppStrings s) {
    final page = _getPageData(index, s);
    const double logoSize = 150;
    const double iconSize = 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (index == 0)
              Image.asset(
                "assets/images/logo_trig_essalama.png",
                height: logoSize,
                width: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.directions_car_rounded,
                  size: logoSize,
                  color: _getPageColor(0),
                ),
              )
            else
              Icon(
                page.icon,
                size: iconSize,
                color: _getPageColor(index),
              ),
            const SizedBox(width: 20),
            Flexible(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    page.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.2,
                      fontFamily: 'Roboto',
                    ),
                  ),
                        const SizedBox(height: 10),
                  Text(
                    page.subtitle,
                    style: TextStyle(
                            fontSize: 16,
                      color: _textSecondary,
                      height: 1.4,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Couleur des pages
  Color _getPageColor(int index) {
    switch (index) {
      case 0:
        return _primaryColor;
      case 1:
        return _accentColor;
      case 2:
        return _primaryColor;
      case 3:
        return _secondaryColor;
      default:
        return _primaryColor;
    }
  }

  // Données des pages
  _PageData _getPageData(int index, AppStrings s) {
    switch (index) {
      case 0:
        return _PageData(
          title: s.page0Title,
          subtitle: s.page0Subtitle,
        );
      case 1:
        return _PageData(
          title: s.page1Title,
          subtitle: s.page1Subtitle,
          icon: Icons.warning_amber_rounded,
        );
      case 2:
        return _PageData(
          title: s.page2Title,
          subtitle: s.page2Subtitle,
          icon: Icons.map_outlined,
        );
      case 3:
        return _PageData(
          title: s.page3Title,
          subtitle: s.page3Subtitle,
          icon: Icons.lock_outline,
        );
      default:
        return _PageData(title: '', subtitle: '');
    }
  }
}

class _PageData {
  final String title;
  final String subtitle;
  final IconData icon;

  _PageData({
    required this.title,
    required this.subtitle,
    this.icon = Icons.safety_check,
  });
}
