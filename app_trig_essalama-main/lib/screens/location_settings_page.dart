import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

const String _kLocationEnabled = 'location_settings_enabled';
const String _kEmergencySharing = 'location_settings_emergency_sharing';
const String _kAutoUpdate = 'location_settings_auto_update';
const String _kPrecision = 'location_settings_precision';
const String _kFrequency = 'location_settings_frequency';
const String _kHistory = 'location_settings_history';

class LocationSettingsPage extends StatefulWidget {
  const LocationSettingsPage({super.key});

  @override
  State<LocationSettingsPage> createState() => _LocationSettingsPageState();
}

class _LocationSettingsPageState extends State<LocationSettingsPage> with WidgetsBindingObserver {
  bool _isLocationEnabled = true;
  bool _isEmergencySharingEnabled = true;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _timeUpdateTimer;
  bool _isAutoUpdateEnabled = true;
  String _selectedPrecision = 'Élevée (GPS)';
  String _selectedUpdateFrequency = 'En temps réel';
  List<Map<String, dynamic>> _locationHistory = [];
  bool _loading = true;
  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  final List<String> _precisionOptions = [
    'Élevée (GPS)',
    'Moyenne (Réseau)',
    'Faible (Économie)',
  ];

  final List<String> _frequencyOptions = [
    'En temps réel',
    'Toutes les 30 secondes',
    'Toutes les minutes',
    'Toutes les 5 minutes',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSettings();
      await _loadPermissions();
      await _syncLocationServiceState();
    });
    _listenToLocationService();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _locationHistory.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _serviceStatusSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Récupère le timestamp (JSON peut renvoyer int ou double).
  static int? _parseTimestamp(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  /// Formate un horodatage en texte "temps réel" : À l'instant, Il y a X min, ou heure réelle.
  String _formatRealtime(int? timestampMs) {
    if (timestampMs == null) return 'À l\'instant';
    final then = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final diff = now.difference(then);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${then.day}/${then.month} ${then.hour.toString().padLeft(2, '0')}:${then.minute.toString().padLeft(2, '0')}';
  }

  void _listenToLocationService() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
      final isEnabled = status == ServiceStatus.enabled;
      if (mounted) {
        setState(() {
          _isLocationEnabled = isEnabled;
        });
        await _saveBool(_kLocationEnabled, isEnabled);
        _showSnackBar(
          isEnabled
              ? 'Localisation activée (téléphone)'
              : 'Localisation désactivée (téléphone)',
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissions();
      _syncLocationServiceState();
    }
  }

  Future<void> _syncLocationServiceState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() {
        _isLocationEnabled = serviceEnabled;
      });
      await _saveBool(_kLocationEnabled, serviceEnabled);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var precision = prefs.getString(_kPrecision) ?? _precisionOptions.first;
    var frequency = prefs.getString(_kFrequency) ?? _frequencyOptions.first;
    if (!_precisionOptions.contains(precision)) precision = _precisionOptions.first;
    if (!_frequencyOptions.contains(frequency)) frequency = _frequencyOptions.first;
    final historyJson = prefs.getString(_kHistory);
    List<Map<String, dynamic>> loaded;
    if (historyJson != null) {
      try {
        final list = jsonDecode(historyJson) as List<dynamic>?;
        loaded = list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      } catch (_) {
        loaded = _defaultHistory();
      }
    } else {
      loaded = _defaultHistory();
    }
    final filteredHistory = _filterOutStaticPositions(loaded);
    if (filteredHistory.length < loaded.length) {
      final prefsSave = await SharedPreferences.getInstance();
      await prefsSave.setString(_kHistory, jsonEncode(filteredHistory));
    }
    setState(() {
      _isLocationEnabled = prefs.getBool(_kLocationEnabled) ?? true;
      _isEmergencySharingEnabled = prefs.getBool(_kEmergencySharing) ?? true;
      _isAutoUpdateEnabled = prefs.getBool(_kAutoUpdate) ?? true;
      _selectedPrecision = precision;
      _selectedUpdateFrequency = frequency;
      _locationHistory = filteredHistory;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _defaultHistory() {
    return [];
  }

  /// Adresses statiques à ne plus afficher (anciennes données de démo).
  static const Set<String> _staticAddresses = {
    '123 Rue de Paris, 75001 Paris',
    'Gare de Lyon, 75012 Paris',
    'Aéroport CDG, 95700 Roissy',
  };

  /// Retire les positions statiques de l'historique (au chargement ou après lecture des prefs).
  List<Map<String, dynamic>> _filterOutStaticPositions(List<Map<String, dynamic>> history) {
    return history
        .where((e) => !_staticAddresses.contains(e['address'] as String?))
        .toList();
  }

  Future<void> _loadPermissions() async {
    final location = await perm.Permission.locationWhenInUse.status;
    final notification = await perm.Permission.notification.status;
    if (mounted) {
      setState(() {
        _locationPermissionGranted = location.isGranted;
        _notificationPermissionGranted = notification.isGranted;
      });
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, jsonEncode(_locationHistory));
  }

  Future<void> _setLocationEnabled(bool value) async {
    if (!value) {
      setState(() => _isLocationEnabled = false);
      await _saveBool(_kLocationEnabled, false);
      _showSnackBar('Localisation désactivée');
      return;
    }

    // 1) Vérifier / demander la permission de localisation
    var status = await perm.Permission.locationWhenInUse.status;
    if (!status.isGranted && !status.isLimited) {
      status = await perm.Permission.locationWhenInUse.request();
    }
    final granted = status.isGranted || status.isLimited;
    if (!granted) {
      _showSnackBar('Autorisez la localisation dans les réglages du téléphone.');
      return;
    }

    // 2) Vérifier si le service de localisation (GPS) est activé côté téléphone
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Localisation désactivée',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
          ),
          content: const Text(
            'La localisation est désactivée sur votre téléphone.\n\n'
            'Activez-la dans les paramètres pour utiliser les itinéraires sécurisés.',
            style: TextStyle(color: AppTheme.secondaryGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.secondaryGrey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ouvrir les paramètres', style: TextStyle(color: AppTheme.alertOrange)),
            ),
          ],
        ),
      );
      if (open == true) {
        await Geolocator.openLocationSettings();
      }
    }

    // On active quand même le flag côté app (préférence utilisateur)
    setState(() => _isLocationEnabled = true);
    await _saveBool(_kLocationEnabled, true);
    _showSnackBar('Localisation activée');
  }

  void _setEmergencySharing(bool value) {
    setState(() => _isEmergencySharingEnabled = value);
    _saveBool(_kEmergencySharing, value);
    _showSnackBar(value ? 'Partage d\'urgence activé' : 'Partage d\'urgence désactivé');
  }

  void _setAutoUpdate(bool value) {
    setState(() => _isAutoUpdateEnabled = value);
    _saveBool(_kAutoUpdate, value);
    _showSnackBar(value ? 'Mise à jour auto activée' : 'Mise à jour auto désactivée');
  }

  void _setPrecision(String? value) {
    if (value == null) return;
    setState(() => _selectedPrecision = value);
    _saveString(_kPrecision, value);
    _showSnackBar('Précision : $value');
  }

  void _setFrequency(String? value) {
    if (value == null) return;
    setState(() => _selectedUpdateFrequency = value);
    _saveString(_kFrequency, value);
    _showSnackBar('Fréquence : $value');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Localisation', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText, fontSize: 20, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.alertOrange),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Localisation',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.secondaryGrey),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carte de statut principal
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isLocationEnabled 
                          ? AppTheme.alertOrange.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLocationEnabled 
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                      color: _isLocationEnabled 
                          ? AppTheme.alertOrange
                          : AppTheme.secondaryGrey,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Localisation',
                          style: TextStyle(
                            color: AppTheme.secondaryGrey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _isLocationEnabled ? 'Activée' : 'Désactivée',
                          style: TextStyle(
                            color: _isLocationEnabled 
                                ? Colors.green 
                                : Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isLocationEnabled,
                    onChanged: (value) => _setLocationEnabled(value),
                    activeColor: AppTheme.alertOrange,
                  ),
                ],
              ),
            ),
            
            // Paramètres de localisation
            _buildSettingsSection('Paramètres', [
              _buildSwitchTile(
                icon: Icons.emergency_rounded,
                title: 'Partager en cas d\'urgence',
                subtitle: 'Envoie automatiquement votre position aux contacts d\'urgence',
                value: _isEmergencySharingEnabled,
                onChanged: _isLocationEnabled ? _setEmergencySharing : null,
              ),
              _buildSwitchTile(
                icon: Icons.autorenew_rounded,
                title: 'Mise à jour automatique',
                subtitle: 'Actualise votre position pendant les trajets',
                value: _isAutoUpdateEnabled,
                onChanged: _isLocationEnabled ? _setAutoUpdate : null,
              ),
            ]),
            
            // Précision de localisation
            _buildSettingsSection('Précision', [
              _buildDropdownTile(
                icon: Icons.satellite_alt_rounded,
                title: 'Niveau de précision',
                subtitle: _getPrecisionDescription(_selectedPrecision),
                value: _precisionOptions.contains(_selectedPrecision) ? _selectedPrecision : _precisionOptions.first,
                items: _precisionOptions,
                onChanged: _isLocationEnabled ? _setPrecision : null,
              ),
            ]),
            
            // Fréquence de mise à jour
            _buildSettingsSection('Mise à jour', [
              _buildDropdownTile(
                icon: Icons.timer_rounded,
                title: 'Fréquence',
                subtitle: 'À quelle fréquence votre position est actualisée',
                value: _frequencyOptions.contains(_selectedUpdateFrequency) ? _selectedUpdateFrequency : _frequencyOptions.first,
                items: _frequencyOptions,
                onChanged: _isLocationEnabled && _isAutoUpdateEnabled ? _setFrequency : null,
              ),
              _buildInfoTile(
                icon: Icons.battery_saver_rounded,
                title: 'Impact batterie',
                subtitle: _getBatteryImpact(),
                color: _getBatteryImpactColor(),
              ),
            ]),
            
            // Dernières positions (uniquement les positions ajoutées dynamiquement)
            if (_isLocationEnabled && _locationHistory.isNotEmpty) ...[
              _buildSettingsSection('Dernières positions', [
                ..._locationHistory.map((location) => _buildHistoryTile(location)),
              ]),
            ],
            
            // Autorisations (dynamiques selon l'état réel)
            _buildSettingsSection('Autorisations', [
              _buildPermissionTile(
                icon: Icons.location_on_rounded,
                title: 'Localisation',
                status: _locationPermissionGranted ? 'Autorisée' : 'Non autorisée',
                statusColor: _locationPermissionGranted ? Colors.green : Colors.orange,
                onTap: () async {
                  final status = await perm.Permission.locationWhenInUse.request();
                  await _loadPermissions();
                  if (mounted) _showSnackBar(status.isGranted ? 'Localisation autorisée' : 'Localisation refusée');
                },
              ),
              _buildPermissionTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                status: _notificationPermissionGranted ? 'Autorisées' : 'Non autorisées',
                statusColor: _notificationPermissionGranted ? Colors.green : Colors.orange,
                onTap: () async {
                  final status = await perm.Permission.notification.request();
                  await _loadPermissions();
                  if (mounted) _showSnackBar(status.isGranted ? 'Notifications autorisées' : 'Notifications refusées');
                },
              ),
              _buildPermissionTile(
                icon: Icons.network_cell_rounded,
                title: 'Données mobiles',
                status: 'Requis pour la carte',
                statusColor: AppTheme.secondaryGrey,
              ),
            ]),
            
            // Bouton pour vérifier la position
            if (_isLocationEnabled)
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCurrentLocationDialog(context);
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Vérifier ma position actuelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.alertOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.alertOrange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                  child,
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1.0,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.alertOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.alertOrange, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.alertOrange,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.alertOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.alertOrange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButton<String>(
                value: value,
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: onChanged == null ? Colors.grey : AppTheme.alertOrange,
                ),
                underline: const SizedBox(),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.secondaryGrey, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> location) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.history_rounded, color: AppTheme.secondaryGrey, size: 20),
      ),
      title: Text(
        location['address'],
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.alertOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              location['type'],
              style: TextStyle(color: AppTheme.alertOrange, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            location['type'] == 'Position actuelle'
                ? _formatRealtime(_parseTimestamp(location['timestamp']))
                : (location['time'] as String? ?? ''),
            style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getPrecisionDescription(String precision) {
    switch (precision) {
      case 'Élevée (GPS)':
        return 'Précision jusqu\'à 3 mètres, consommation batterie élevée';
      case 'Moyenne (Réseau)':
        return 'Précision jusqu\'à 50 mètres, consommation batterie modérée';
      case 'Faible (Économie)':
        return 'Précision jusqu\'à 500 mètres, économie de batterie';
      default:
        return '';
    }
  }

  String _getBatteryImpact() {
    if (!_isLocationEnabled) return 'Aucun impact (localisation désactivée)';
    
    if (_selectedPrecision.contains('Élevée') && _selectedUpdateFrequency == 'En temps réel') {
      return 'Élevé - Autonomie réduite';
    } else if (_selectedPrecision.contains('Moyenne') || _selectedUpdateFrequency.contains('30')) {
      return 'Modéré - Impact moyen';
    } else {
      return 'Faible - Optimisé pour la batterie';
    }
  }

  Color _getBatteryImpactColor() {
    if (!_isLocationEnabled) return AppTheme.secondaryGrey;
    
    if (_selectedPrecision.contains('Élevée') && _selectedUpdateFrequency == 'En temps réel') {
      return Colors.orange;
    } else if (_selectedPrecision.contains('Moyenne') || _selectedUpdateFrequency.contains('30')) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Localisation',
          style: TextStyle(color: AppTheme.whiteText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('📍', 'Activez la localisation pour les trajets'),
            _buildInfoRow('🆘', 'Position partagée aux contacts d\'urgence'),
            _buildInfoRow('🔋', 'La précision élevée consomme plus de batterie'),
            _buildInfoRow('🔄', 'Mise à jour automatique pendant les trajets'),
            _buildInfoRow('🔒', 'Données chiffrées et confidentielles'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris', style: TextStyle(color: AppTheme.alertOrange)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.secondaryGrey),
            ),
          ),
        ],
      ),
    );
  }

  /// Récupère une adresse à partir des coordonnées (géocodage inverse Nominatim).
  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Trig_Essalama/1.0'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final displayName = data?['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (_) {}
    return '${latitude.toStringAsFixed(5)}° N, ${longitude.toStringAsFixed(5)}° E';
  }

  void _showCurrentLocationDialog(BuildContext context) async {
    if (!_isLocationEnabled) {
      _showSnackBar('Activez la localisation pour vérifier votre position.');
      return;
    }
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Autorisez la localisation dans les paramètres.');
      return;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Activez le GPS dans les paramètres du téléphone.');
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.alertOrange),
            SizedBox(height: 16),
            Text('Récupération de votre position...', style: TextStyle(color: AppTheme.whiteText)),
          ],
        ),
      ),
    );

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
      if (mounted) _showSnackBar('Impossible de récupérer la position.');
      return;
    }
    if (position == null) return;

    final address = await _getAddressFromLatLng(position.latitude, position.longitude);
    if (!context.mounted) return;
    Navigator.of(context).pop();

    void updateHistoryEntry(String addr, String latLngStr) {
      if (!mounted) return;
      final ts = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        if (_locationHistory.isEmpty || _locationHistory.first['type'] != 'Position actuelle') {
          _locationHistory.insert(0, {
            'address': addr,
            'time': 'À l\'instant',
            'timestamp': ts,
            'type': 'Position actuelle',
            'latLng': latLngStr,
          });
        } else {
          _locationHistory[0] = {
            'address': addr,
            'time': 'À l\'instant',
            'timestamp': ts,
            'type': 'Position actuelle',
            'latLng': latLngStr,
          };
        }
      });
      _saveHistory();
    }

    final latLngStr = '${position.latitude.toStringAsFixed(5)}° N, ${position.longitude.toStringAsFixed(5)}° E';
    updateHistoryEntry(address, latLngStr);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => _CurrentPositionDialog(
        address: address,
        latLngStr: latLngStr,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.alertOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Dialog affichant la position actuelle.
class _CurrentPositionDialog extends StatelessWidget {
  final String address;
  final String latLngStr;

  const _CurrentPositionDialog({
    required this.address,
    required this.latLngStr,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text(
        'Position actuelle',
        style: TextStyle(color: AppTheme.whiteText),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.alertOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppTheme.alertOrange,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            latLngStr,
            style: const TextStyle(color: AppTheme.whiteText, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(color: AppTheme.secondaryGrey),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer', style: TextStyle(color: AppTheme.alertOrange)),
        ),
      ],
    );
  }
}