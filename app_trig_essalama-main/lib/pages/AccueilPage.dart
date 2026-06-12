import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/auth_provider.dart';
import '../providers/alerts_feed_notifier.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../l10n/context_l10n.dart';
import '../services/nominatim_service.dart';
import '../services/weather_service.dart';
import '../services/search_history_service.dart';
import '../services/traffic_service.dart';
import '../models/traffic_jam_model.dart';
import '../services/traffic_jam_service.dart';
import '../services/accident_report_service.dart';
import '../services/probleme_signale_service.dart';
import '../services/risque_service.dart';
import '../services/problemes_signales_map_service.dart';
import '../models/probleme_signale_map_item.dart';
import '../utils/route_hazard_utils.dart';
import '../services/feedback_prompt_service.dart';
import '../widgets/traffic_jam_details_sheet.dart';
import '../widgets/feedback_dialog.dart';


class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double _destinationRiskRadiusM = 8000;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showAllRecommendedRoutes = false;
  
  // Variables météo dynamiques
  final Map<String, dynamic> _weatherData = {
    'city': 'Chargement...',
    'temperature': '--',
    'condition': 'Inconnu',
    'icon': Icons.cloud,
    'color': Colors.grey,
    'humidity': 0,
    'wind': 0,
    'feelsLike': 0,
  };
  bool _isLoadingWeather = true;
  List<AlertModel> _homeAlerts = [];
  bool _loadingHomeAlerts = true;
  AlertsFeedNotifier? _alertsFeedNotifier;
  List<TrafficJamModel> _trafficJams = [];
  bool _loadingTrafficJams = false;
  
  // ==================== VARIABLE RECHERCHE DYNAMIQUE ====================
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  
  // Suggestions et Historique
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _recentSearches = [];
  List<Map<String, dynamic>> _popularPlaces = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  
  // Résultat de recherche et Alerte
  bool _showSearchAlert = false;
  Map<String, dynamic>? _searchResult;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
    
    // Listeners pour la recherche dynamique
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChange);
    
    // Charger les données initiales
    _loadRecentSearches();
    _loadPopularPlaces();
    _loadWeather();       // 🚀 Charger météo réelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrafficJams();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alertsFeedNotifier = context.read<AlertsFeedNotifier>();
      _alertsFeedNotifier!.addListener(_onHomeAlertsFeed);
      final cached = _alertsFeedNotifier!.alerts;
      if (cached.isNotEmpty) {
        setState(() {
          _homeAlerts = List.from(cached);
          _loadingHomeAlerts = false;
        });
      }
      _loadHomeAlerts();
    });

    // Ajouter l'observateur pour détecter le retour au premier plan
    WidgetsBinding.instance.addObserver(this);

    // 🔔 Afficher l'alerte d'avis au lancement (max une fois / 7 jours)
    _showFeedbackWithDelay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔔 Afficher le feedback quand l'app revient du background (max une fois / 7 jours)
    if (state == AppLifecycleState.resumed) {
      _showFeedbackWithDelay();
    }
  }

  void _showFeedbackWithDelay() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final shouldShow = await FeedbackPromptService.shouldShowAndMarkIfEligible(auth);
      if (!mounted || !shouldShow) return;
      FeedbackDialog.show(context);
    });
  }


  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChange);
    _animationController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _alertsFeedNotifier?.removeListener(_onHomeAlertsFeed);
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void _onHomeAlertsFeed() {
    if (!mounted) return;
    final feed = context.read<AlertsFeedNotifier>();
    setState(() {
      _homeAlerts = List.from(feed.alerts);
      _loadingHomeAlerts = false;
    });
  }

  Future<void> _loadHomeAlerts() async {
    if (!mounted) return;
    setState(() => _loadingHomeAlerts = true);
    try {
      final svc = context.read<AlertService>();
      final list = await svc.fetchAlerts();
      if (!mounted) return;
      context.read<AlertsFeedNotifier>().setAlerts(list, notify: false);
      setState(() {
        _homeAlerts = List.from(list);
        _loadingHomeAlerts = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingHomeAlerts = false);
      }
    }
  }

  Color _accentForAlert(AlertModel a) {
    final p = a.priority.toLowerCase();
    final st = a.status.toLowerCase();
    if (p.contains('high') ||
        p.contains('danger') ||
        p.contains('crit') ||
        st.contains('danger')) {
      return const Color(0xFFEF4444);
    }
    if (p.contains('med') ||
        p.contains('warn') ||
        p.contains('moyen') ||
        st.contains('warn')) {
      return const Color(0xFFF97316);
    }
    return const Color(0xFF6366F1);
  }

  // ==================== GESTION DE LA RECHERCHE ====================
  
  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _showSuggestions = true;
          // Si le texte est vide, on montrera l'historique/populaire (géré dans le build)
          // Sinon on garde les suggestions actuelles
        });
      }
    } else {
      // Petit délai pour permettre le clic sur une suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }
  
  void _onSearchChanged() {
    final query = _searchController.text;
    
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _showSuggestions = _searchFocusNode.hasFocus;
          _isSearching = false;
        });
      }
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (mounted) {
      setState(() {
        _isSearching = true;
        _showSuggestions = true;
      });
    }
    
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.length > 1) {
        final results = await _searchLocation(query);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _suggestions = [];
            _isSearching = false;
          });
        }
      }
    });
  }
  
  Future<List<Map<String, dynamic>>> _searchLocation(String query) async {
    try {
      final results = await NominatimService.searchLocation(query);
      return results.take(7).toList();
    } catch (e) {
      print('Erreur recherche: $e');
      return [];
    }
  }
  
  Future<void> _loadRecentSearches() async {
    final searches = await SearchHistoryService.getHistory('destination');
    if (mounted) {
      setState(() => _recentSearches = searches.take(5).toList());
    }
  }
  
  Future<void> _loadPopularPlaces() async {
    // Places populaires en Tunisie
    _popularPlaces = [
      {'name': 'Tunis Centre', 'display_name': 'Avenue Habib Bourguiba, Tunis', 'lat': 36.8003, 'lon': 10.1795, 'icon': Icons.location_city},
      {'name': 'La Marsa', 'display_name': 'La Marsa, Tunis', 'lat': 36.8825, 'lon': 10.3236, 'icon': Icons.beach_access},
      {'name': 'Sousse Corniche', 'display_name': 'Sousse, Tunisie', 'lat': 35.8256, 'lon': 10.6367, 'icon': Icons.beach_access},
      {'name': 'Aéroport Carthage', 'display_name': 'Aéroport Tunis-Carthage (TUN)', 'lat': 36.8510, 'lon': 10.2272, 'icon': Icons.local_airport},
    ];
    if (mounted) setState(() {});
  }
  
  void _selectSuggestion(Map<String, dynamic> suggestion) async {
    final alertSvc = context.read<AlertService>();
    final risqueSvc = context.read<RisqueService>();
    try {
      final lat = suggestion['lat'];
      final lon = suggestion['lon'];
      final double latVal = (lat is String) ? double.parse(lat) : (lat as num).toDouble();
      final double lonVal = (lon is String) ? double.parse(lon) : (lon as num).toDouble();

      final historySuggestion = Map<String, dynamic>.from(suggestion);
      historySuggestion.remove('icon');

      await SearchHistoryService.addSearch(historySuggestion, 'destination');
      await _loadRecentSearches();

      if (mounted) {
        setState(() {
          _searchController.text = suggestion['display_name'] ?? suggestion['name'] ?? '';
          _searchResult = {
            'name': suggestion['display_name']?.split(',').first ?? suggestion['name'] ?? 'Lieu',
            'location': suggestion['display_name'] ?? 'Emplacement',
            'latitude': latVal,
            'longitude': lonVal,
            'isLoading': true,
            'icon': Icons.travel_explore_rounded,
            'statusColor': const Color(0xFF64748B),
            'status': 'Analyse en cours',
            'safetyScore': 0,
            'description':
                'Vérification météo et interrogation de la base (alertes, risques cartographiés, embouteillages, signalements citoyens)…',
            'riskRows': <Map<String, String>>[],
          };
          _showSearchAlert = true;
          _showSuggestions = false;
          _suggestions = [];
        });
      }

      _searchFocusNode.unfocus();

      await _loadDestinationRisks(
        latVal: latVal,
        lonVal: lonVal,
        suggestion: suggestion,
        alertSvc: alertSvc,
        risqueSvc: risqueSvc,
      );
    } catch (e) {
      debugPrint('Erreur selection: $e');
    }
  }

  List<AlertModel> _filterAlertsNear(
    double latVal,
    double lonVal,
    List<AlertModel> alerts,
    String displayHintLower,
  ) {
    final out = <AlertModel>[];
    final parts = displayHintLower
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.length > 2)
        .toList();
    for (final a in alerts) {
      final la = a.latitude;
      final lo = a.longitude;
      if (la != null && lo != null) {
        final d = Geolocator.distanceBetween(latVal, lonVal, la, lo);
        if (d <= _destinationRiskRadiusM) {
          out.add(a);
        }
        continue;
      }
      final named = (a.locationNamed ?? '').toLowerCase();
      if (named.isEmpty || parts.isEmpty) continue;
      for (final p in parts) {
        if (p.length > 3 && (named.contains(p) || p.contains(named))) {
          out.add(a);
          break;
        }
      }
    }
    return out;
  }

  String _frProblemeSignale(String type) {
    switch (type) {
      case 'police':
        return 'Contrôle / police';
      case 'voie_bloquee':
        return 'Voie bloquée';
      case 'route_fermee':
        return 'Route fermée';
      case 'danger':
        return 'Danger signalé';
      case 'travaux':
        return 'Travaux';
      case 'vehicule_arrete':
        return 'Véhicule arrêté';
      case 'nid_de_poule':
        return 'Nid-de-poule';
      case 'fissure_chaussee':
        return 'Fissure chaussée';
      case 'objet':
        return 'Obstacle sur la route';
      case 'embouteillage':
        return 'Embouteillage (signalement)';
      case 'accident':
        return 'Accident (signalement)';
      case 'mauvais_temps':
        return 'Mauvais temps (signalement)';
      case 'probleme_carte':
        return 'Problème carte / GPS';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _risqueDocSummary(Map<String, dynamic> r) {
    final t = r['type'] ?? r['categorie'] ?? r['title'] ?? r['nature'] ?? r['name'];
    final d = r['description'] ?? r['details'] ?? r['message'];
    final head = (t ?? 'Indicateur de risque').toString().trim();
    if (d == null || d.toString().trim().isEmpty) return head;
    final tail = d.toString().trim();
    if (tail.length > 100) return '$head — ${tail.substring(0, 100)}…';
    return '$head — $tail';
  }

  Future<void> _loadDestinationRisks({
    required double latVal,
    required double lonVal,
    required Map<String, dynamic> suggestion,
    required AlertService alertSvc,
    required RisqueService risqueSvc,
  }) async {
    Map<String, dynamic>? weatherRaw;
    try {
      weatherRaw = await WeatherService.getWeather(latVal, lonVal);
    } catch (_) {}

    List<TrafficJamModel> jams = [];
    try {
      jams = await TrafficJamService.getTrafficJams(
        lat: latVal,
        lng: lonVal,
        radius: _destinationRiskRadiusM.round(),
        limit: 60,
      );
    } catch (_) {}

    List<AlertModel> allAlerts = [];
    try {
      allAlerts = await alertSvc.fetchAlerts();
    } catch (_) {}

    List<Map<String, dynamic>> risques = [];
    try {
      risques = await risqueSvc.fetchRisquesNear(
        latitude: latVal,
        longitude: lonVal,
        radiusMeters: _destinationRiskRadiusM.round(),
        limit: 500,
      );
    } catch (_) {}

    List<ProblemeSignaleMapItem> rawProblemes = [];
    try {
      final b = geoBoundsAroundPoint(latVal, lonVal, 7000);
      rawProblemes = await ProblemesSignalesMapService.fetchInBounds(b, limit: 120, sinceDays: 21);
    } catch (_) {}

    if (!mounted) return;

    final hint = (suggestion['display_name'] ?? suggestion['name'] ?? '').toString().toLowerCase();
    final nearbyAlerts = _filterAlertsNear(latVal, lonVal, allAlerts, hint);

    final problemes = rawProblemes.where((p) {
      if (p.id.isEmpty) return false;
      return Geolocator.distanceBetween(
            latVal,
            lonVal,
            p.location.latitude,
            p.location.longitude,
          ) <=
          _destinationRiskRadiusM;
    }).toList();

    final wc = (weatherRaw?['weathercode'] as num?)?.toInt() ?? 0;
    final tempLabel = '${weatherRaw?['temperature'] ?? '--'}';
    final condition = _mapWeatherCode(wc);
    final weatherBody = '$tempLabel°C — $condition';

    final riskRows = <Map<String, String>>[
      {'title': 'Météo (zone)', 'body': weatherBody},
    ];

    for (final a in nearbyAlerts.take(6)) {
      final msg = a.message.trim();
      final short = msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
      riskRows.add({
        'title': 'Alerte (${a.alertType.isNotEmpty ? a.alertType : a.typeField})',
        'body': '${a.title}. ${short.isNotEmpty ? short : a.recommendation}'.trim(),
      });
    }

    for (final j in jams.take(5)) {
      riskRows.add({
        'title': 'Trafic / embouteillage',
        'body':
            '${j.getLevelLabel()} — congestion ${j.congestionLevel}%${j.description.trim().isNotEmpty ? ' — ${j.description.trim()}' : ''}',
      });
    }

    for (final r in risques.take(6)) {
      riskRows.add({'title': 'Risque (base données)', 'body': _risqueDocSummary(r)});
    }

    for (final p in problemes.take(6)) {
      riskRows.add({
        'title': 'Signalement citoyen',
        'body': _frProblemeSignale(p.type),
      });
    }

    final hour = DateTime.now().hour;
    final isNight = hour > 20 || hour < 6;
    double score = 95;
    score -= nearbyAlerts.length * 7;
    for (final j in jams) {
      switch (j.level) {
        case 'severe':
        case 'blocked':
          score -= 14;
          break;
        case 'heavy':
          score -= 10;
          break;
        case 'moderate':
          score -= 6;
          break;
        default:
          score -= 3;
      }
    }
    score -= risques.length * 5;
    score -= problemes.length * 4;
    if (wc >= 61) score -= 8;
    if (wc >= 95) score -= 14;
    if (isNight) score -= 5;

    final intScore = score.round().clamp(35, 100);

    String status = 'Sécurisé';
    Color statusColor = const Color(0xFF22C55E);
    IconData icon = Icons.verified_user_rounded;

    if (intScore < 60) {
      status = 'Risque élevé';
      statusColor = const Color(0xFFEF4444);
      icon = Icons.warning_rounded;
    } else if (intScore < 80) {
      status = 'Attention recommandée';
      statusColor = const Color(0xFFF97316);
      icon = Icons.warning_amber_rounded;
    }

    final hasDbSignals =
        nearbyAlerts.isNotEmpty || jams.isNotEmpty || risques.isNotEmpty || problemes.isNotEmpty;
    final hasWeatherStress = wc >= 61 || wc == 56 || wc == 57;
    final description = !hasDbSignals && !hasWeatherStress
        ? 'Aucun risque identifié dans la base à proximité (~${_destinationRiskRadiusM ~/ 1000} km). '
            'Restez attentif en circulation.'
        : [
            if (nearbyAlerts.isNotEmpty) '${nearbyAlerts.length} alerte(s) liée(s) à la zone.',
            if (jams.isNotEmpty) '${jams.length} embouteillage(s) actif(s) à proximité.',
            if (risques.isNotEmpty) '${risques.length} entrée(s) « risques » en base à proximité.',
            if (problemes.isNotEmpty) '${problemes.length} signalement(s) citoyen(s) récent(s).',
            if (hasWeatherStress) 'Conditions météo pouvant impacter la conduite.',
          ].join(' ');

    setState(() {
      _searchResult = {
        'name': suggestion['display_name']?.split(',').first ?? suggestion['name'] ?? 'Lieu',
        'location': suggestion['display_name'] ?? 'Emplacement',
        'latitude': latVal,
        'longitude': lonVal,
        'isLoading': false,
        'safetyScore': intScore,
        'status': status,
        'statusColor': statusColor,
        'icon': icon,
        'description': description,
        'riskRows': riskRows,
      };
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _suggestions = [];
        _showSuggestions = _searchFocusNode.hasFocus;
        _showSearchAlert = false;
        _searchResult = null;
      });
    }
  }


  /// Obtenir la position GPS actuelle avec gestion des permissions
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Le service GPS est désactivé.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Les permissions de localisation sont refusées.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Les permissions de localisation sont définitivement refusées.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Fonction principale pour charger la ville et la météo
  Future<void> _loadWeather() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final position = await _getCurrentLocation();

      // 🔹 Nom du lieu via NominatimService
      final city = await NominatimService.getPlaceName(
        position.latitude,
        position.longitude,
      );

      // 🔹 Données météo via WeatherService
      final weather = await WeatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _weatherData['city'] = city;
          _weatherData['temperature'] = weather['temperature'] ?? '--';
          _weatherData['wind'] = weather['windspeed'] ?? 0;
          _weatherData['feelsLike'] = weather['temperature'] ?? '--';
          _weatherData['humidity'] = 60; // Valeur par défaut si non fournie

          _weatherData['condition'] = _mapWeatherCode(weather['weathercode'] ?? 0);
          _weatherData['icon'] = _getWeatherIcon(weather['weathercode'] ?? 0);
          _weatherData['color'] = _getWeatherColor(weather['weathercode'] ?? 0);

          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur météo globale: $e");
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _weatherData['city'] = "Erreur localisation";
        });
      }
    }
  }

  Future<void> _loadTrafficJams() async {
    if (_loadingTrafficJams) return;
    if (!mounted) return;

    setState(() => _loadingTrafficJams = true);
    try {
      final position = await _getCurrentLocation();
      final jams = await TrafficJamService.getTrafficJams(
        lat: position.latitude,
        lng: position.longitude,
        radius: 10000,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _trafficJams = jams;
        _loadingTrafficJams = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement embouteillages: $e');
      if (mounted) {
        setState(() => _loadingTrafficJams = false);
      }
    }
  }

  void _showTrafficJamDetails(TrafficJamModel jam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrafficJamDetailsSheet(jam: jam),
    );
  }

  /// Mappage des codes météo Open-Meteo
  String _mapWeatherCode(int code) {
    if (code == 0) return "Ensoleillé";
    if (code <= 3) return "Nuageux";
    if (code <= 67) return "Pluvieux";
    if (code <= 77) return "Neige";
    return "Variable";
  }

  /// Icônes dynamiques
  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 67) return Icons.water_drop_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    return Icons.cloud_rounded;
  }

  /// Couleurs dynamiques
  Color _getWeatherColor(int code) {
    if (code == 0) return Colors.orange;
    if (code <= 3) return Colors.blueGrey;
    if (code <= 67) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        String userName = auth.userFullName ?? "Citoyen";
        
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: Stack(
              children: [
                _buildBody(userName),
                if (_showSearchAlert) _buildSearchAlert(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAlert() {
    if (_searchResult == null) return const SizedBox.shrink();

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: -1, end: 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, value * 100),
            child: Opacity(
              opacity: 1 + value,
              child: child,
            ),
          );
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _searchResult!['statusColor'].withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _searchResult!['statusColor'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _searchResult!['icon'],
                        color: _searchResult!['statusColor'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _searchResult!['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _searchResult!['location'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSearchAlert = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                if (_searchResult!['isLoading'] == true) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchResult!['description'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_searchResult!['statusColor'] as Color).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, color: _searchResult!['statusColor'] as Color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                              children: [
                                const TextSpan(
                                  text: 'Niveau de sécurité : ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: _searchResult!['status'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _searchResult!['statusColor'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (((_searchResult!['safetyScore'] as num?)?.toInt() ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Score de sécurité',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (_searchResult!['safetyScore'] as num) / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(_searchResult!['statusColor'] as Color),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_searchResult!['safetyScore']}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: _searchResult!['statusColor'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchResult!['description'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final raw = _searchResult!['riskRows'];
                      final rows = <Map<String, String>>[];
                      if (raw is List) {
                        for (final e in raw) {
                          if (e is Map) {
                            rows.add(Map<String, String>.from(
                              e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
                            ));
                          }
                        }
                      }
                      if (rows.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          const Text(
                            'Détail (météo, alertes, trafic, risques, signalements)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: rows.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final r = rows[i];
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r['body'] ?? '',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home', arguments: {
                              'index': 1,
                              'destination': LatLng(_searchResult!['latitude'], _searchResult!['longitude']),
                              'destinationName': _searchResult!['name'],
                            });
                            setState(() => _showSearchAlert = false);
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Voir sur carte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _searchResult!['statusColor'] as Color,
                            side: BorderSide(color: _searchResult!['statusColor'] as Color),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home', arguments: {
                              'index': 1,
                              'destination': LatLng(_searchResult!['latitude'], _searchResult!['longitude']),
                              'destinationName': _searchResult!['name'],
                            });
                            setState(() => _showSearchAlert = false);
                          },
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Itinéraire'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _searchResult!['statusColor'] as Color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 60,
      leading: IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 20, height: 2.5, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 4),
            Container(width: 12, height: 2.5, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10))),
          ],
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
        },
      ),
      actions: const [SizedBox(width: 16)],
    );
  }

  Widget _buildProfileImage(String? imageSource, String userName) {
    if (imageSource == null || imageSource.isEmpty) {
      return _buildInitialsFallback(userName);
    }

    try {
      if (imageSource.startsWith('http')) {
        return Image.network(
          imageSource,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(userName),
        );
      } else if (imageSource.startsWith('data:')) {
        final base64String = imageSource.contains(',') ? imageSource.split(',').last : imageSource;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(userName),
        );
      } else {
        final bytes = base64Decode(imageSource);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(userName),
        );
      }
    } catch (e) {
      return _buildInitialsFallback(userName);
    }
  }

  Widget _buildInitialsFallback(String userName) {
    final initials = userName.isNotEmpty 
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : "?";
    
    return Container(
      color: const Color(0xFF6366F1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBody(String userName) {
    final s = context.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          
          // Animation guard
          _fadeAnimation.status == AnimationStatus.forward || _fadeAnimation.status == AnimationStatus.completed || _fadeAnimation.status == AnimationStatus.reverse || _fadeAnimation.status == AnimationStatus.dismissed
          ? FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: const Text(
                "Découvrez\nvotre route idéale !",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ) : const SizedBox(height: 80), // Fallback if animation not ready
          const SizedBox(height: 28),
          
          _buildSearchBar(),
          const SizedBox(height: 32),
          
          // NOUVEAU: Widget météo à la place de "Trajet recommandé"
          _buildWeatherCard(),
          const SizedBox(height: 32),
          
          _buildSectionHeader(s.nearbyAlertsTitle, s.seeAll, onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacementNamed(context, '/home', arguments: 2);
          }),
          const SizedBox(height: 16),
          _buildAlertsList(),
          const SizedBox(height: 32),
          
          _buildSectionHeader("Signaler un problème", ""),
          const SizedBox(height: 16),
          _buildReportGrid(),
          const SizedBox(height: 32),
          
          _buildSecurityStats(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSecurityStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "État global des routes",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SecurityStatMinimal(
              label: "Sécurisé",
              color: const Color(0xFF22C55E),
              percentage: 60,
            ),
            _SecurityStatMinimal(
              label: "Risque",
              color: const Color(0xFFF97316),
              percentage: 25,
            ),
            _SecurityStatMinimal(
              label: "Danger",
              color: const Color(0xFFEF4444),
              percentage: 15,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _searchLocation(value).then((results) {
                        if (results.isNotEmpty && mounted) {
                          _selectSuggestion(results.first);
                        }
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: "Où voulez-vous aller ?",
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Color(0xFF94A3B8)),
                  onPressed: _clearSearch,
                ),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade200,
              ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: Color(0xFF94A3B8), size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Recherche vocale bientôt disponible"))
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        
        // Panneau de suggestions
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 12),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Suggestions de recherche
                    if (_suggestions.isNotEmpty) ...[
                      _buildSuggestionHeader("Suggestions"),
                      ..._suggestions.map((s) => _buildSuggestionTile(s)).toList(),
                      if (_recentSearches.isNotEmpty) const Divider(height: 1),
                    ],
                    
                    // Recherches récentes
                    if (_recentSearches.isNotEmpty && _suggestions.isEmpty) ...[
                      _buildSuggestionHeader("Recherches récentes", showClear: true, onClear: () async {
                        await SearchHistoryService.clearHistory('destination');
                        await _loadRecentSearches();
                      }),
                      ..._recentSearches.map((s) => _buildRecentTile(s)).toList(),
                      const Divider(height: 1),
                    ],
                    
                    // Lieux populaires
                    if (_suggestions.isEmpty && _recentSearches.isEmpty) ...[
                      _buildSuggestionHeader("Lieux populaires"),
                      ..._popularPlaces.map((p) => _buildPopularTile(p)).toList(),
                    ],
                    
                    // Indicateur de chargement
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionHeader(String title, {bool showClear = false, VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          if (showClear && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Text(
                "Effacer tout",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 18),
      ),
      title: Text(
        suggestion['display_name'] ?? suggestion['name'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  Widget _buildRecentTile(Map<String, dynamic> search) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.history_rounded, color: Color(0xFF94A3B8), size: 18),
      ),
      title: Text(
        search['display_name'] ?? search['name'] ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () => _selectSuggestion(search),
    );
  }

  Widget _buildPopularTile(Map<String, dynamic> place) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(place['icon'], color: const Color(0xFF10B981), size: 18),
      ),
      title: Text(
        place['name'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        place['display_name'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      ),
      onTap: () => _selectSuggestion(place),
    );
  }


  // NOUVEAU: Widget météo avec animation
  Widget _buildWeatherCard() {
    final Color weatherColor = _weatherData['color'];

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              weatherColor.withValues(alpha: 0.15),
              weatherColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _loadWeather(); // Actualiser au clic sur la carte
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: weatherColor, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _weatherData['city'],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: weatherColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _loadWeather();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: weatherColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoadingWeather 
                                ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: weatherColor))
                                : Icon(Icons.update_rounded, size: 14, color: weatherColor),
                              const SizedBox(width: 4),
                              Text(
                                _isLoadingWeather ? "Chargement..." : "Mis à jour",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: weatherColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_weatherData['temperature']}",
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const Text(
                                "°C",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ressenti ${_weatherData['feelsLike']}°C",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: weatherColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _weatherData['icon'],
                          color: weatherColor,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherStat(Icons.water_drop_rounded, "Humidité", "${_weatherData['humidity']}%"),
                      Container(width: 1, height: 30, color: Colors.grey.shade200),
                      _buildWeatherStat(Icons.air_rounded, "Vent", "${_weatherData['wind']} km/h"),
                      Container(width: 1, height: 30, color: Colors.grey.shade200),
                      _buildWeatherStat(Icons.thermostat_rounded, "Condition", _weatherData['condition']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: weatherColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: weatherColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getWeatherAdvice(_weatherData['condition'], _weatherData['temperature'] is num ? _weatherData['temperature'] : 20),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: weatherColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  String _getWeatherAdvice(String condition, num temperature) {
    if (condition == "Ensoleillé" && temperature > 30) {
      return "🌞 Forte chaleur aujourd'hui - Hydratez-vous et évitez les trajets en plein soleil";
    } else if (condition == "Ensoleillé") {
      return "☀️ Belle journée - Conditions idéales pour vos déplacements";
    } else if (condition == "Pluvieux") {
      return "🌧️ Risque de pluie - Prudence sur les routes glissantes";
    } else if (condition == "Nuageux") {
      return "☁️ Temps couvert - Bonne visibilité pour vos trajets";
    } else if (condition == "Orageux") {
      return "⚡ Orages possibles - Évitez les zones inondables";
    }
    return "✅ Conditions météo favorables pour vos déplacements";
  }


  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        if (action.isNotEmpty)
          GestureDetector(
            onTap: onTap ?? () {
              HapticFeedback.lightImpact();
            },
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertsList() {
    final s = context.strings;
    if (_loadingHomeAlerts && _homeAlerts.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 12),
              Text(
                s.nearbyAlertsTitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }
    if (_homeAlerts.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            s.alertEmptyList,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
      );
    }
    final slice = _homeAlerts.length > 12 ? _homeAlerts.sublist(0, 12) : _homeAlerts;
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: slice.length,
        itemBuilder: (context, index) {
          final alert = slice[index];
          final map = alert.toDisplayMap(s);
          final color = _accentForAlert(alert);
          final loc = map['location'] ?? '';
          final typeLabel = map['typeLabel'] ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AlertCardMinimal(
              title: map['title'] ?? s.alertUntitled,
              location: loc.isNotEmpty ? loc : s.nearYou,
              distance: alert.relativeTime,
              severity: typeLabel.length > 14 ? '${typeLabel.substring(0, 14)}…' : typeLabel,
              color: color,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushReplacementNamed(context, '/home', arguments: 2);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        _ReportButtonMinimal(
          icon: Icons.car_crash_rounded,
          label: "🚗 Accident",
          color: const Color(0xFFEF4444),
          onTap: _showAccidentConfirmSheet,
        ),
        _ReportButtonMinimal(
          icon: Icons.traffic_rounded, 
          label: "Embouteillage", 
          color: const Color(0xFFEA4335),
          onTap: _showTrafficJamConfirmSheet,
        ),
        _ReportButtonMinimal(
          icon: Icons.error_outline_rounded,
          label: "Danger",
          color: const Color(0xFFF97316),
          onTap: _showDangerSelectionSheet,
        ),
        _ReportButtonMinimal(
          icon: Icons.local_police_rounded,
          label: "Police",
          color: Colors.black,
          onTap: () => _confirmAndReportGeneric('police'),
        ),
        _ReportButtonMinimal(
          icon: Icons.block_rounded,
          label: "Route fermée",
          color: const Color(0xFFDC2626),
          onTap: () => _confirmAndReportGeneric('route_fermee'),
        ),
        _ReportButtonMinimal(
          icon: Icons.thunderstorm_rounded,
          label: "Mauvais temps",
          color: const Color(0xFF334155),
          onTap: () => _confirmAndReportGeneric('mauvais_temps'),
        ),
        _ReportButtonMinimal(
          icon: Icons.map_outlined,
          label: "Problème carte",
          color: const Color(0xFF7C3AED),
          onTap: () => _confirmAndReportGeneric('probleme_carte'),
        ),
      ],
    );
  }

  Color _foregroundOnAccent(Color accent) {
    return accent.computeLuminance() > 0.5 ? const Color(0xFF0F172A) : Colors.white;
  }

  Widget _buildDangerTypeTile({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Color sheetSurface,
    required Color textPrimary,
    required Color borderLight,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: sheetSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : borderLight,
                    width: isSelected ? 2.2 : 1.2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: Icon(icon, color: color, size: 24)),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: color,
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: _foregroundOnAccent(color),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showWhiteReportBottomSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    String confirmLabel = 'Signaler',
  }) async {
    const sheetBg = Colors.white;
    const sheetSurface = Color(0xFFF8FAFC);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: sheetSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: Icon(icon, color: accentColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close, color: textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: borderLight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                foregroundColor: textSecondary,
                                backgroundColor: sheetSurface,
                              ),
                              child: const Text(
                                "Annuler",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: _foregroundOnAccent(accentColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                confirmLabel,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return confirmed == true;
  }

  ({String title, String subtitle, IconData icon, Color accent}) _reportUiForType(String type) {
    switch (type) {
      case 'police':
        return (
          title: 'Signaler la police',
          subtitle: 'Indiquez la présence des forces de l\'ordre à cet endroit.',
          icon: Icons.local_police_rounded,
          accent: const Color(0xFF0F172A),
        );
      case 'route_fermee':
        return (
          title: 'Route fermée',
          subtitle: 'Informez les autres usagers d\'une fermeture de voie.',
          icon: Icons.block_rounded,
          accent: const Color(0xFFDC2626),
        );
      case 'voie_bloquee':
        return (
          title: 'Voie bloquée',
          subtitle: 'Signalez un obstacle empêchant la circulation.',
          icon: Icons.construction_rounded,
          accent: const Color(0xFFEA580C),
        );
      case 'fissure_chaussee':
        return (
          title: 'Fissure de chaussée',
          subtitle: 'Alertez sur une dégradation de la chaussée.',
          icon: Icons.view_week_rounded,
          accent: const Color(0xFF64748B),
        );
      case 'nid_de_poule':
        return (
          title: 'Nid-de-poule',
          subtitle: 'Signalez un trou ou une bosse sur la route.',
          icon: Icons.blur_circular_rounded,
          accent: const Color(0xFFFB923C),
        );
      case 'mauvais_temps':
        return (
          title: 'Mauvais temps',
          subtitle: 'Partagez des conditions météo difficiles sur la route.',
          icon: Icons.thunderstorm_rounded,
          accent: const Color(0xFF334155),
        );
      case 'probleme_carte':
        return (
          title: 'Problème carte',
          subtitle: 'Signalez une erreur de carte ou d\'affichage.',
          icon: Icons.map_outlined,
          accent: const Color(0xFF7C3AED),
        );
      case 'danger':
        return (
          title: 'Danger',
          subtitle: 'Alertez sur un danger immédiat pour la circulation.',
          icon: Icons.warning_amber_rounded,
          accent: const Color(0xFFF59E0B),
        );
      case 'travaux':
        return (
          title: 'Travaux',
          subtitle: 'Indiquez des travaux routiers en cours.',
          icon: Icons.construction_rounded,
          accent: const Color(0xFFF97316),
        );
      case 'vehicule_arrete':
        return (
          title: 'Véhicule arrêté',
          subtitle: 'Signalez un véhicule arrêté ou en panne sur la voie.',
          icon: Icons.car_repair_rounded,
          accent: const Color(0xFF60A5FA),
        );
      case 'objet':
        return (
          title: 'Objet sur la route',
          subtitle: 'Prévenez la présence d\'un objet sur la chaussée.',
          icon: Icons.category_outlined,
          accent: const Color(0xFF94A3B8),
        );
      default:
        return (
          title: 'Signalement',
          subtitle: 'Confirmez l\'envoi de ce signalement.',
          icon: Icons.flag_rounded,
          accent: const Color(0xFF64748B),
        );
    }
  }

  Future<void> _confirmAndReportGeneric(String type) async {
    final ui = _reportUiForType(type);
    final ok = await _showWhiteReportBottomSheet(
      title: ui.title,
      subtitle: ui.subtitle,
      icon: ui.icon,
      accentColor: ui.accent,
    );
    if (!ok || !mounted) return;
    HapticFeedback.mediumImpact();
    await _reportGeneric(type);
  }

  Future<void> _showAccidentConfirmSheet() async {
    final ok = await _showWhiteReportBottomSheet(
      title: 'Signaler un accident',
      subtitle: 'Prévenez les autres conducteurs et facilitez l\'intervention.',
      icon: Icons.car_crash_rounded,
      accentColor: const Color(0xFFDC2626),
    );
    if (!ok || !mounted) return;
    HapticFeedback.mediumImpact();
    await _reportAccident();
  }

  Future<void> _reportAccident() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError("Le GPS est desactive. Veuillez l'activer.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError("Permission de localisation refusee.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationError("Permission de localisation refusee definitivement.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Envoi du signalement..."),
          ],
        ),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userId = context.read<AuthProvider>().currentUser?.id;
      final result = await AccidentReportService.reportAccident(
        latitude: position.latitude,
        longitude: position.longitude,
        userId: userId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final int count = (result['reportCount'] as num? ?? 1).toInt();
      final bool confirmedAccident = (result['confirmed'] ?? false) as bool;
      String message;
      if (confirmedAccident) {
        message = "Accident confirme par $count personnes.";
      } else if (count > 1) {
        message = "Accident signale par $count personnes.";
      } else {
        message = "Accident signale. En attente de confirmation.";
      }
      _showSnackBar(message);

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Erreur: $e");
    }
  }

  Future<void> _reportGeneric(String type) async {
    final service = context.read<ProblemeSignaleService>();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError("Le GPS est desactive. Veuillez l'activer.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError("Permission de localisation refusee.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showLocationError("Permission de localisation refusee definitivement.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Envoi du signalement..."),
          ],
        ),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final ok = await service.submit(
        type: type,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context);
      if (ok) {
        _showSnackBar("Signalement enregistre.");
      } else {
        _showSnackBar("Echec du signalement. Reessayez plus tard.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Erreur: $e");
    }
  }

  Future<void> _showDangerSelectionSheet() async {
    const options = [
      (
        id: 'danger',
        label: 'Danger',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFF59E0B),
      ),
      (
        id: 'travaux',
        label: 'Travaux',
        icon: Icons.construction_rounded,
        color: Color(0xFFF97316),
      ),
      (
        id: 'vehicule_arrete',
        label: 'Véhicule arrêté',
        icon: Icons.car_repair_rounded,
        color: Color(0xFF60A5FA),
      ),
      (
        id: 'nid_de_poule',
        label: 'Nid-de-poule',
        icon: Icons.blur_circular_rounded,
        color: Color(0xFFF59E0B),
      ),
      (
        id: 'fissure_chaussee',
        label: 'Fissure de chaussée',
        icon: Icons.view_week_rounded,
        color: Color(0xFF94A3B8),
      ),
      (
        id: 'objet',
        label: 'Objet',
        icon: Icons.category_outlined,
        color: Color(0xFF94A3B8),
      ),
    ];

    String selectedId = options.first.id;
    const sheetBg = Colors.white;
    const sheetSurface = Color(0xFFF8FAFC);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderLight = Color(0xFFE2E8F0);

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedOption = options.firstWhere((o) => o.id == selectedId);
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Signaler un danger",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choisissez le type de danger, puis confirmez.",
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const crossAxisCount = 3;
                          const spacing = 10.0;
                          const itemHeight = 112.0;
                          final itemWidth = (constraints.maxWidth -
                                  spacing * (crossAxisCount - 1)) /
                              crossAxisCount;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (var index = 0; index < options.length; index++)
                                SizedBox(
                                  width: itemWidth,
                                  height: itemHeight,
                                  child: _buildDangerTypeTile(
                                    label: options[index].label,
                                    icon: options[index].icon,
                                    color: options[index].color,
                                    isSelected: selectedId == options[index].id,
                                    sheetSurface: sheetSurface,
                                    textPrimary: textPrimary,
                                    borderLight: borderLight,
                                    onTap: () => setModalState(
                                      () => selectedId = options[index].id,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: borderLight),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  foregroundColor: textSecondary,
                                  backgroundColor: sheetSurface,
                                ),
                                child: const Text(
                                  "Annuler",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, selectedId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedOption.color,
                                  foregroundColor: _foregroundOnAccent(selectedOption.color),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Signaler",
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;
    HapticFeedback.mediumImpact();
    await _reportGeneric(selected);
  }

  Future<void> _showTrafficJamConfirmSheet() async {
    final ok = await _showWhiteReportBottomSheet(
      title: 'Signaler un embouteillage',
      subtitle: 'Aidez les autres conducteurs sur la route.',
      icon: Icons.traffic_rounded,
      accentColor: const Color(0xFFEA4335),
    );
    if (!ok || !mounted) return;
    HapticFeedback.mediumImpact();
    await _reportTrafficJamFromHome();
  }

  Future<void> _reportTrafficJamFromHome() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationError("Le GPS est desactive. Veuillez l'activer.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationError("Permission de localisation refusee.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showLocationError("Permission de localisation refusee definitivement.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Envoi du signalement..."),
          ],
        ),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final ok = await TrafficJamService.reportTrafficJam(
        latitude: position.latitude,
        longitude: position.longitude,
        congestionLevel: 50,
        cause: 'unknown',
      );

      if (!mounted) return;
      Navigator.pop(context);
      if (ok) {
        _showSnackBar("Embouteillage signale avec succes.");
      } else {
        _showSnackBar("Echec du signalement d'embouteillage.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Erreur: $e");
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

}

class _AlertCardMinimal extends StatelessWidget {
  final String title;
  final String location;
  final String distance;
  final String severity;
  final Color color;
  final VoidCallback? onTap;

  const _AlertCardMinimal({
    required this.title,
    required this.location,
    required this.distance,
    required this.severity,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.warning_rounded, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    distance,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      severity,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportButtonMinimal extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ReportButtonMinimal({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityStatMinimal extends StatelessWidget {
  final String label;
  final Color color;
  final int percentage;

  const _SecurityStatMinimal({
    required this.label,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: percentage / 100),
      duration: const Duration(milliseconds: 1000),
      builder: (context, double value, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: value,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  "${(value * 100).toInt()}%",
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        );
      },
    );
  }
}