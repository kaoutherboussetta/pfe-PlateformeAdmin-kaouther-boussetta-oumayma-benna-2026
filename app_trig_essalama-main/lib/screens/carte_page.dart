// ignore_for_file: unused_local_variable, deprecated_member_use, unused_element

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../l10n/context_l10n.dart';
import '../l10n/search_constants.dart';
import '../providers/locale_provider.dart';
import '../services/nominatim_service.dart';
import '../services/routing_service.dart';
import 'search_location_page.dart';
import '../services/search_history_service.dart';
import '../services/safety_service.dart';
import '../services/problemes_voirie_service.dart';
import '../services/problemes_signales_map_service.dart';
import '../services/route_corridor_problems_service.dart';
import '../models/probleme_signale_map_item.dart';
import '../models/map_problem_cluster.dart';
import '../config/map_tile_config.dart';
import '../utils/route_hazard_utils.dart';
import '../services/traffic_service.dart';
import '../services/traffic_jam_service.dart';
import '../services/accident_report_service.dart';
import '../providers/auth_provider.dart';
import '../models/traffic_jam_model.dart';
import '../widgets/grouped_map_problem_marker.dart';
import '../widgets/traffic_jam_marker.dart';
import '../widgets/traffic_jam_details_sheet.dart';
import '../widgets/traffic_jam_report_sheet.dart';
import '../widgets/pulsating_location_indicator.dart';

/// Ligne de liste fusionnée (voirie + signalement) triée le long de l'itinéraire.
class _RouteProblemRow {
  final ProblemeVoirie? voirie;
  final ProblemeSignaleMapItem? signale;
  final int sortIndex;

  const _RouteProblemRow._(this.voirie, this.signale, this.sortIndex);

  factory _RouteProblemRow.voirie(ProblemeVoirie v, int sortIndex) =>
      _RouteProblemRow._(v, null, sortIndex);

  factory _RouteProblemRow.signale(ProblemeSignaleMapItem s, int sortIndex) =>
      _RouteProblemRow._(null, s, sortIndex);
}

class CartePage extends StatefulWidget {
  const CartePage({super.key});

  @override
  State<CartePage> createState() => _CartePageState();
}

class _CartePageState extends State<CartePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  LatLng? _currentPosition;
  LatLng? _startPosition;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _routes = [];
  int _selectedRouteIndex = 0;
  double? _routeDuration;
  double? _routeDistance;
  bool _isNavigating = false;
  bool _showFlashOnStart = false;
  bool _showRoutePreview = false;
  bool _isFollowingUser = true;
  bool _hasCenteredOnUserGps = false;
  bool _isMinimized = false;
  String _selectedProfile = 'driving';
  StreamSubscription<Position>? _positionStream;

  List<LatLng> _waypoints = [];
  bool _safetyMode = true;
  double _currentSpeed = 0.0;
  double _safetyScore = 95.0;
  String _riskLevel = '';
  List<LatLng> _nearbyDangers = [];
  bool _isSpeeding = false;
  DateTime _lastRouteUpdate = DateTime.now();

  String _currentInstruction = "";
  String _currentStreet = "";
  String _nextInstruction = "";
  double _remainingDuration = 0.0;
  double _remainingDistance = 0.0;
  double _distanceToNextInstruction = 0.0;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  Timer? _navigationTimer;
  Timer? _trafficRefreshTimer;
  DateTime? _lastTrafficTelemetrySentAt;
  List<Polyline> _trafficPolylines = const [];
  List<TrafficZone> _trafficZones = [];
  List<TrafficJamModel> _trafficJams = [];
  bool _showTrafficJams = true;
  bool _loadingTrafficJams = false;
  List<AccidentReport> _accidentReports = [];
  bool _loadingAccidents = false;
  Timer? _accidentRefreshTimer;
  bool _accidentTrackingInitialized = false;
  bool _centerOnAccidentRequested = false;
  bool _openReportSheetRequested = false;

  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  String _lastSpokenInstruction = "";
  DateTime _lastSpeechTime = DateTime.now();
  DateTime _lastSpeedAlertTime = DateTime.now();
  DateTime _lastDangerAlertTime = DateTime.now();

  DateTime _lastInstructionTime = DateTime.now();
  int _instructionFrequency = 8;

  bool _argsProcessed = false;

  static const LatLng _defaultPosition = LatLng(33.8869, 9.5375);
  static const LatLng _tunisiaSouthWest = LatLng(30.23, 7.52);
  static const LatLng _tunisiaNorthEast = LatLng(37.54, 11.60);

  final List<Marker> _markers = [];
  List<ProblemeVoirie> _problemesVoirie = [];
  List<ProblemeVoirie> _problemesVoirieOnRoute = [];
  bool _loadingProblemesVoirie = false;
  List<ProblemeSignaleMapItem> _problemesSignales = [];
  List<ProblemeSignaleMapItem> _problemesSignalesOnRoute = [];
  bool _loadingProblemesSignales = false;
  bool _loadingRouteProblems = false;
  ProblemeVoirie? _selectedProbleme;
  bool _showProblemeDetails = false;
  ProblemeSignaleMapItem? _selectedSignale;
  bool _showSignaleDetails = false;
  MapProblemCluster? _selectedMapCluster;
  bool _showMapClusterDetails = false;

  String? _routeProblemsAlertShownForSignature;
  String? _routeProblemsAlertDismissedSignature;
  bool _alternativeRoutePromptOpen = false;
  static const double _kRouteProblemPenaltyMeters = 4000;
  static const double _kRouteProblemDistanceM = 220.0;
  static const int _kMaxCleanAlternativeRoutes = 3;
  static const double _kAltRouteSimplifySpacingM = 140.0;
  final Map<String, String> _geocodedProblemAddresses = {};
  List<int>? _routeProblemCounts;
  bool _scanningRouteAlternatives = false;
  bool _showRouteAlternatives = false;
  int? _recommendedAlternativeIndex;
  List<Map<String, dynamic>>? _savedRoutesBeforeCleanAlts;
  final Map<String, int> _routeProblemCountCache = {};
  List<ProblemeVoirie> _savedMainRouteVoirie = [];
  List<ProblemeSignaleMapItem> _savedMainRouteSignales = [];
  List<LatLng> _savedMainRoutePoints = [];
  bool _usingCleanRouteWithoutProblems = false;

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initLocationTracking();
      _loadProblemesVoirie();
      _loadProblemesSignales();
      _startTrafficRealtimeUpdates();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyTtsLocale();
    if (!_argsProcessed) {
      final Object? rawArgs = ModalRoute.of(context)?.settings.arguments;
      if (rawArgs is Map<String, dynamic>) {
        final args = rawArgs;
        if (args['showTrafficJams'] == true) {
          _showTrafficJams = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadTrafficJamsAroundUser();
          });
        }
        if (args['showAccidents'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadAccidents();
          });
        }
        if (args['centerOnAccident'] == true) {
          _centerOnAccidentRequested = true;
        }
        if (args['openReportSheet'] == true) {
          _openReportSheetRequested = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentPosition != null) {
              _reportTrafficJam();
            }
          });
        }
        if (args.containsKey('destination')) {
          final dest = args['destination'] as LatLng;
          final destName = args['destinationName'] as String?;
          final departure = args['departure'] as LatLng?;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (destName != null) {
                _searchController.text = destName;
              }
              _calculateRoute(
                dest,
                start: departure,
                promptAlternativeRoute: true,
              );
            }
          });
        }
      }
      _argsProcessed = true;
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _positionStream?.cancel();
    _navigationTimer?.cancel();
    _trafficRefreshTimer?.cancel();
    _accidentRefreshTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // TTS INITIALISATION
  // ============================================================================

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        setState(() => _isSpeaking = true);
      });

      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint("❌ Erreur TTS: $msg");
        setState(() => _isSpeaking = false);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _applyTtsLocale());
      debugPrint("✅ Moteur vocal initialisé");
    } catch (e) {
      debugPrint("❌ Erreur TTS: $e");
    }
  }

  Future<void> _applyTtsLocale() async {
    if (!mounted) return;
    try {
      final lang = context.read<LocaleProvider>().language;
      final code = switch (lang) {
        AppLanguage.fr => 'fr-FR',
        AppLanguage.en => 'en-US',
        AppLanguage.tnd => 'fr-FR',
      };
      await _flutterTts.setLanguage(code);
    } catch (e) {
      debugPrint("❌ Erreur TTS locale: $e");
    }
  }

  Future<void> _speakInstruction(String instruction, {bool force = false}) async {
    if (instruction.isEmpty) return;
    if (_isSpeaking && !force) {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final now = DateTime.now();
    if (!force && now.difference(_lastSpeechTime).inSeconds < 2) return;
    if (instruction == _lastSpokenInstruction && !force) return;
    debugPrint("🔊 [TTS] $instruction");
    _lastSpokenInstruction = instruction;
    _lastSpeechTime = now;
    try {
      await _flutterTts.speak(instruction);
    } catch (e) {
      debugPrint("❌ Erreur synthèse: $e");
    }
  }

  Future<void> _speakDangerAlert(String danger) async {
    final now = DateTime.now();
    if (now.difference(_lastDangerAlertTime).inSeconds < 10) return;
    _lastDangerAlertTime = now;
    if (_isSpeaking) {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _speakInstruction("⚠️ Attention, $danger", force: true);
  }

  Future<void> _speakSpeedAlert() async {
    final now = DateTime.now();
    if (now.difference(_lastSpeedAlertTime).inSeconds < 30) return;
    _lastSpeedAlertTime = now;
    if (!mounted) return;
    await _speakInstruction(context.stringsRead.mapTtsSlowDown, force: true);
  }

  // ============================================================================
  // LOCALISATION
  // ============================================================================

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showMessage(context.stringsRead.mapLocationDisabled);
      setState(() => _currentPosition = _defaultPosition);
      _initAccidentTracking();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentPosition = _defaultPosition);
        _initAccidentTracking();
        return;
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((Position position) {
      if (mounted) {
        final newSpeed = position.speed * 3.6;
        final currentHour = DateTime.now().hour;
        final LatLng userPos = LatLng(position.latitude, position.longitude);

        _updateInstructionFrequency(newSpeed);

        if (_isNavigating && newSpeed > 80 && !_isSpeaking) {
          _speakSpeedAlert();
        }

        setState(() {
          _currentPosition = userPos;
          _currentSpeed = newSpeed;
          _isSpeeding = newSpeed > 80;
          _nearbyDangers = SafetyService.getNearbyDangers(userPos);
          _riskLevel = SafetyService.predictRisk(
            2,
            currentHour,
            context.stringsRead,
          );
          _safetyScore = SafetyService.calculateManualSafetyScore(
            accidents: 2,
            trafficIndex: 3,
            nightMode: currentHour > 20 || currentHour < 6,
          );
          if (_nearbyDangers.isNotEmpty && _isNavigating) {
            _speakDangerAlert(context.stringsRead.mapTtsDangerNearby);
          }
          _updateMarkers();
          _updateRemainingDistance();
        });
        _maybeSendTrafficTelemetry(userPos, newSpeed);

        if (_isFollowingUser && _isMapReady) {
          _centerMapOnUser();
        }
      }
    });

    try {
      Position? firstPos = await Geolocator.getLastKnownPosition();
      firstPos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (!mounted || firstPos == null) return;
      final position = firstPos;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentSpeed = position.speed * 3.6;
        _nearbyDangers = SafetyService.getNearbyDangers(_currentPosition!);
        _updateMarkers();
      });
      _maybeOpenRequestedReportSheet();
      if (_showTrafficJams) {
        _loadTrafficJamsAroundUser();
      }
      _initAccidentTracking();
      _tryCenterMapOnUser(zoom: 15.0);
    } catch (e) {
      debugPrint("Erreur position initiale: $e");
      if (mounted) {
        _showMessage(context.stringsRead.mapPositionError);
        setState(() {
          _currentPosition ??= _defaultPosition;
          _updateMarkers();
        });
      }
    }
  }

  void _updateInstructionFrequency(double speed) {
    if (speed > 80) {
      _instructionFrequency = 10;
    } else if (speed > 50) {
      _instructionFrequency = 6;
    } else {
      _instructionFrequency = 4;
    }
  }

  void _maybeSendTrafficTelemetry(LatLng pos, double speedKmh) {
    final now = DateTime.now();
    if (_lastTrafficTelemetrySentAt != null &&
        now.difference(_lastTrafficTelemetrySentAt!).inSeconds < 15) {
      return;
    }
    _lastTrafficTelemetrySentAt = now;
    TrafficService.sendTelemetry(
      lat: pos.latitude,
      lng: pos.longitude,
      speedKmh: speedKmh,
      timestamp: now,
    );
  }

  // ============================================================================
  // TRAFIC ET ACCIDENTS
  // ============================================================================

  void _startTrafficRealtimeUpdates() {
    _trafficRefreshTimer?.cancel();
    _fetchTrafficZones();
    _trafficRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchTrafficZones();
    });
  }

  Future<void> _fetchTrafficZones() async {
    final zones = await TrafficService.getTrafficZones();
    if (!mounted) return;
    setState(() {
      _trafficZones = zones;
      _trafficPolylines = zones
          .where((z) => z.points.length >= 2)
          .map(
            (z) => Polyline(
              points: z.points,
              color: _getTrafficColor(z.status),
              strokeWidth: 5,
            ),
          )
          .toList();
      _updateMarkers();
    });
    if (_showTrafficJams) {
      _loadTrafficJamsAroundUser();
    }
  }

  Color _getTrafficColor(String status) {
    switch (status.toLowerCase()) {
      case 'jam':
      case 'embouteillage':
        return Colors.red;
      case 'slow':
      case 'lent':
      case 'traffic_slow':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Future<void> _loadTrafficJamsAroundUser() async {
    final base = _currentPosition;
    if (base == null) return;
    setState(() => _loadingTrafficJams = true);
    final jams = await TrafficJamService.getTrafficJams(
      lat: base.latitude,
      lng: base.longitude,
      radius: 10000,
      limit: 200,
    );
    if (!mounted) return;
    setState(() {
      _trafficJams = jams;
      _loadingTrafficJams = false;
      _updateMarkers();
    });
  }

  Future<void> _loadAccidents() async {
    final base = _currentPosition;
    if (base == null) return;
    setState(() => _loadingAccidents = true);
    try {
      final accidents = await AccidentReportService.getAccidents(
        lat: base.latitude,
        lng: base.longitude,
        radius: 20000,
      );
      if (!mounted) return;
      setState(() {
        _accidentReports = accidents;
        _loadingAccidents = false;
        _updateMarkers();
      });
      if (_centerOnAccidentRequested && _accidentReports.isNotEmpty) {
        _centerOnAccidentRequested = false;
        final first = _accidentReports.first;
        _mapController.move(LatLng(first.latitude, first.longitude), 16.5);
      }
    } catch (e) {
      debugPrint('Erreur chargement accidents: $e');
      if (mounted) {
        setState(() => _loadingAccidents = false);
      }
    }
  }

  void _initAccidentTracking() {
    if (_accidentTrackingInitialized) return;
    _accidentTrackingInitialized = true;
    _loadAccidents();
    _accidentRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted && _currentPosition != null) {
        _loadAccidents();
      }
    });
  }

  void _reportTrafficJam() {
    if (_currentPosition == null) {
      _showMessage('Position non disponible');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrafficJamReportSheet(
        position: _currentPosition!,
        onReported: (success) {
          if (success && mounted) {
            _showMessage('Embouteillage signalé avec succès');
            _loadTrafficJamsAroundUser();
          }
        },
      ),
    );
  }

  void _maybeOpenRequestedReportSheet() {
    if (!_openReportSheetRequested || _currentPosition == null) return;
    _openReportSheetRequested = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reportTrafficJam();
    });
  }

  // ============================================================================
  // ROUTING ET NAVIGATION
  // ============================================================================

  double _adjustDuration(double duration, String profile) {
    switch (profile) {
      case 'bus':
        return duration * 1.4;
      case 'moto':
        return duration * 0.85;
      case 'cycling':
        return duration * 2.5;
      case 'walking':
        return duration * 5.0;
      default:
        return duration;
    }
  }

  Future<void> _calculateRoute(
    LatLng destination, {
    LatLng? start,
    String? profile,
    bool promptAlternativeRoute = false,
  }) async {
    try {
      final routeProfile = profile ?? _selectedProfile;
      final isDefaultStart = start == null;
      final startPoint = start ?? _currentPosition;
      final osrmProfile = (routeProfile == 'moto' || routeProfile == 'bus')
          ? 'driving'
          : routeProfile;

      if (startPoint == null) {
        _showMessage(context.stringsRead.mapCurrentPositionMissing);
        return;
      }

      _resetAlternativeRoutePromptState();

      final s = context.stringsRead;
      _showMessage(
        isDefaultStart ? s.mapCalculatingRouteSecure : s.mapCalculatingRoute,
      );

      final routes = await RoutingService.getRoutesWithAlternatives(
        startPoint,
        destination,
        waypoints: _waypoints,
        profile: osrmProfile,
      );

      if (routes.isEmpty) {
        _showMessage(context.stringsRead.mapNoRouteFound);
        return;
      }

      if (mounted) {
        final adjustedRoutes = routes.map((r) {
          return {
            ...r,
            'duration': _adjustDuration(r['duration'], routeProfile),
          };
        }).toList();

        final processedRoutes = _safetyMode
            ? SafetyService.filterSafeRoutes(adjustedRoutes)
            : adjustedRoutes;

        setState(() {
          _selectedProfile = routeProfile;
          _routes = processedRoutes;
          _selectedRouteIndex = 0;
          _showRouteAlternatives = false;
          _routePoints = processedRoutes[0]['points'];
          _routeDuration = processedRoutes[0]['duration'];
          _routeDistance = processedRoutes[0]['distance'];
          _safetyScore = processedRoutes[0]['safetyScore'] ?? 95.0;
          _startPosition = start;
          _destination = destination;
          _showRoutePreview = true;
          _isNavigating = false;
          _isMinimized = false;
          _updateMarkers();
        });

        if (mounted && _routePoints.length >= 2) {
          await _loadProblemesAlongRoute(
            navigationMode: false,
            triggerAlternativePrompt: !promptAlternativeRoute,
          );
          unawaited(_loadProblemesAroundDestination());
          if (_problemesVoirie.isEmpty) unawaited(_loadProblemesVoirie());
          if (_problemesSignales.isEmpty) unawaited(_loadProblemesSignales());

          if (promptAlternativeRoute && mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              await _showAlternativeRouteDialogAfterSearch();
              final problemCount =
                  _problemesVoirieOnRoute.length + _problemesSignalesOnRoute.length;
              final shouldAutoSearchFallback =
                  !_showRouteAlternatives &&
                  problemCount > 0 &&
                  !_isRouteAlertDismissedForCurrentRoute();
              if (shouldAutoSearchFallback) {
                unawaited(_searchAndDisplayCleanRoutes());
              }
            }
          }
        }

        if (_routes.isNotEmpty) {
          final mainPoints = List<LatLng>.from(processedRoutes[0]['points'] as List);
          final bounds = LatLngBounds.fromPoints(mainPoints);
          if (bounds.northWest.latitude == bounds.southEast.latitude &&
              bounds.northWest.longitude == bounds.southEast.longitude) {
            _mapController.move(bounds.center, 15.0);
          } else {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(70),
                maxZoom: 17.0,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur calcul itinéraire: $e");
      _showMessage(context.stringsRead.mapNetworkError);
    }
  }

  void _startNavigation() {
    final s = context.stringsRead;
    _showMessage(s.mapNavigationStarted);
    _speakInstruction(s.mapNavigationStartedVoice);

    setState(() {
      _isNavigating = true;
      _showFlashOnStart = true;
      _showRoutePreview = false;
      _isFollowingUser = true;
      _isMinimized = false;
      _remainingDistance = _routeDistance ?? 0;
      _remainingDuration = _routeDuration ?? 0;
      _lastSpokenInstruction = "";
      _lastInstructionTime = DateTime.now();
    });

    _updateMarkers();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showFlashOnStart = false);
        _updateMarkers();
      }
    });

    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 18.0);
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isNavigating) {
        unawaited(_loadProblemesForNavigation());
      }
    });
    if (_problemesVoirie.isEmpty) unawaited(_loadProblemesVoirie());
    if (_problemesSignales.isEmpty) unawaited(_loadProblemesSignales());

    _startNavigationTracking();
  }

  void _startNavigationTracking() {
    _navigationTimer?.cancel();
    int currentStepIndex = 0;

    _navigationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isNavigating || _currentPosition == null || _routePoints.isEmpty) {
        timer.cancel();
        return;
      }

      double minDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < _routePoints.length; i++) {
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _routePoints[i].latitude,
          _routePoints[i].longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      if (minDistance > 50) {
        _showMessage(context.stringsRead.mapDeviationRecalcul);
        if (_destination != null) {
          _calculateRoute(_destination!, promptAlternativeRoute: false);
        }
        timer.cancel();
        return;
      }

      double distanceToDestination = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );

      if (distanceToDestination < 50) {
        _showArrivalSummary();
        _cancelNavigation();
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (nearestIndex > currentStepIndex + 3 ||
          now.difference(_lastInstructionTime).inSeconds >=
              _instructionFrequency) {
        currentStepIndex = nearestIndex;
        _generateNavigationInstruction(nearestIndex);
        _lastInstructionTime = now;
      }

      _checkNearbyHazards();
    });
  }

  void _generateNavigationInstruction(int currentIndex) {
    if (_routePoints.isEmpty || currentIndex >= _routePoints.length - 1) return;

    List<Map<String, dynamic>> upcomingTurns = _analyzeUpcomingTurns(currentIndex);

    if (upcomingTurns.isNotEmpty) {
      var nextTurn = upcomingTurns.first;
      String action = nextTurn['action'];
      String direction = nextTurn['direction'];
      double distance = nextTurn['distance'];

      String instructionText = "$action $direction dans ${distance.round()} mètres";

      setState(() {
        _currentInstruction = instructionText;
        _distanceToNextInstruction = upcomingTurns.length > 1
            ? upcomingTurns[1]['distance']
            : 0;
      });

      if (distance < 100 && (action.contains("Tournez") || action.contains("demi-tour"))) {
        _vibrateForInstruction();
        _speakInstruction(instructionText);
      } else if (distance < 300 && distance > 100) {
        _speakInstruction(
          "Préparez-vous à $action $direction dans ${distance.round()} mètres",
        );
      }
    } else {
      String instructionText = "Continuez tout droit";
      setState(() {
        _currentInstruction = instructionText;
      });
      if (_currentInstruction != instructionText) {
        _speakInstruction(instructionText);
      }
    }
  }

  List<Map<String, dynamic>> _analyzeUpcomingTurns(int currentIndex) {
    List<Map<String, dynamic>> turns = [];
    int maxLookAhead = min(currentIndex + 100, _routePoints.length - 1);
    double lastBearing = _calculateBearing(
      _routePoints[currentIndex],
      _routePoints[min(currentIndex + 5, _routePoints.length - 1)],
    );
    double accumulatedDistance = 0;
    int lastTurnIndex = currentIndex;

    for (int i = currentIndex + 5; i < maxLookAhead; i += 5) {
      LatLng point1 = _routePoints[i];
      LatLng point2 = _routePoints[min(i + 5, _routePoints.length - 1)];
      double currentBearing = _calculateBearing(point1, point2);
      double bearingChange = (currentBearing - lastBearing).abs();
      if (bearingChange > 180) bearingChange = 360 - bearingChange;
      double segmentDistance = Geolocator.distanceBetween(
        _routePoints[lastTurnIndex].latitude,
        _routePoints[lastTurnIndex].longitude,
        point1.latitude,
        point1.longitude,
      );
      accumulatedDistance += segmentDistance;

      if (bearingChange > 30 && accumulatedDistance > 20) {
        String action = _getAdvancedNavigationAction(bearingChange);
        String direction = _getDirectionFromBearing(currentBearing);
        turns.add({
          'index': i,
          'action': action,
          'direction': direction,
          'distance': accumulatedDistance,
          'bearingChange': bearingChange,
          'streetName': null,
        });
        lastBearing = currentBearing;
        lastTurnIndex = i;
        accumulatedDistance = 0;
        if (turns.length >= 3) break;
      }
    }
    return turns;
  }

  String _getAdvancedNavigationAction(double bearingChange) {
    if (bearingChange < 30) return "Continuez légèrement à";
    if (bearingChange < 60) return "Tournez doucement à";
    if (bearingChange < 120) return "Tournez à";
    if (bearingChange < 150) return "Tournez franchement à";
    if (bearingChange < 180) return "Faites demi-tour";
    return "Prenez le virage à";
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double dLon = (end.longitude - start.longitude) * (pi / 180);
    double x = sin(dLon) * cos(lat2);
    double y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(x, y) * (180 / pi);
    return (bearing + 360) % 360;
  }

  String _getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return "Nord";
    if (bearing >= 22.5 && bearing < 67.5) return "Nord-Est";
    if (bearing >= 67.5 && bearing < 112.5) return "Est";
    if (bearing >= 112.5 && bearing < 157.5) return "Sud-Est";
    if (bearing >= 157.5 && bearing < 202.5) return "Sud";
    if (bearing >= 202.5 && bearing < 247.5) return "Sud-Ouest";
    if (bearing >= 247.5 && bearing < 292.5) return "Ouest";
    return "Nord-Ouest";
  }

  void _vibrateForInstruction() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint("Vibration non supportée");
    }
  }

  void _checkNearbyHazards() {
    if (_currentPosition == null) return;
    bool hasHazard = _nearbyDangers.any((danger) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        danger.latitude,
        danger.longitude,
      );
      return distance < 200;
    });
    if (hasHazard && !_isSpeaking) {
      final s = context.stringsRead;
      setState(() {
        _currentInstruction = s.mapHazardInstruction;
      });
      _speakDangerAlert(s.mapTtsDangerNearbySlow);
    }
  }

  void _showArrivalSummary() {
    final s = context.stringsRead;
    _speakInstruction(s.mapTtsArrived, force: true);
    _showDialog(
      context,
      s.mapArrivedTitle,
      "${s.mapTotalDistanceLabel} ${_formatDistance(_routeDistance ?? 0)}\n"
      "${s.mapArrivedDurationLine} ${_formatDuration(_routeDuration ?? 0)}",
      () {},
    );
  }

  void _updateRemainingDistance() {
    if (_currentPosition == null || _destination == null || _routePoints.isEmpty) return;

    double minDistance = double.infinity;
    int nearestIndex = 0;
    for (int i = 0; i < _routePoints.length; i++) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _routePoints[i].latitude,
        _routePoints[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    _remainingDistance = 0;
    for (int i = nearestIndex; i < _routePoints.length - 1; i++) {
      _remainingDistance += Geolocator.distanceBetween(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
    }

    if (_currentSpeed > 0) {
      _remainingDuration = (_remainingDistance / 1000) / (_currentSpeed / 60) * 60;
    } else {
      double progress = 1 - (_remainingDistance / (_routeDistance ?? 1));
      _remainingDuration = (_routeDuration ?? 0) * (1 - progress);
    }
    setState(() {});
  }

  double _calculateProgress() {
    if (_routeDistance == null || _routeDistance == 0) return 0;
    double distanceTraveled = (_routeDistance! - _remainingDistance);
    return (distanceTraveled / _routeDistance!).clamp(0.0, 1.0);
  }

  void _cancelNavigation() {
    _navigationTimer?.cancel();
    _flutterTts.stop();

    setState(() {
      _isNavigating = false;
      _showFlashOnStart = false;
      _showRoutePreview = false;
      _isFollowingUser = false;
      _isMinimized = false;
      _routePoints = [];
      _routes = [];
      _waypoints = [];
      _destination = null;
      _problemesVoirieOnRoute = [];
      _problemesSignalesOnRoute = [];
      _loadingRouteProblems = false;
      _selectedSignale = null;
      _showSignaleDetails = false;
      _selectedProbleme = null;
      _showProblemeDetails = false;
      _selectedMapCluster = null;
      _showMapClusterDetails = false;
      _currentInstruction = "";
      _currentStreet = "";
      _nextInstruction = "";
      _remainingDuration = 0;
      _remainingDistance = 0;
      _distanceToNextInstruction = 0;
      _navigationSteps = [];
      _currentStepIndex = 0;
      _routeProblemsAlertShownForSignature = null;
      _resetAlternativeRoutePromptState();
    });

    _updateMarkers();
    _showMessage(context.stringsRead.mapGuidanceStopped);

    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 14.0);
    }
  }

  // ============================================================================
  // PROBLÈMES SUR L'ITINÉRAIRE
  // ============================================================================

  /// Charge voirie (En cours / En attente) + signalements MongoDB le long de l'itinéraire.
  Future<void> _loadProblemesForNavigation() async {
    if (_routePoints.length >= 2) {
      await _loadProblemesAlongRoute(navigationMode: true);
      return;
    }
    final anchor = _currentPosition ?? _destination;
    if (anchor == null) return;
    final bounds = boundsWithPaddingMeters([anchor], paddingMeters: 4000);
    try {
      final voirie = await ProblemesVoirieService.getProblemesInBounds(
        bounds,
        limit: 500,
        activeOnly: true,
      );
      final signales = await ProblemesSignalesMapService.fetchInBounds(
        bounds,
        limit: 500,
        sinceDays: 90,
      );
      if (!mounted) return;
      setState(() {
        _problemesVoirieOnRoute = voirie;
        _problemesSignalesOnRoute = _filterValidSignales(signales);
      });
      _updateMarkers();
    } catch (e) {
      debugPrint('Erreur chargement problemes navigation: $e');
    }
  }

  List<ProblemeSignaleMapItem> _filterValidSignales(List<ProblemeSignaleMapItem> items) =>
      items
          .where(
            (e) =>
                e.id.isNotEmpty &&
                (e.location.latitude.abs() > 1e-6 || e.location.longitude.abs() > 1e-6),
          )
          .toList();

  List<ProblemeVoirie> _mergeVoirieById(Iterable<ProblemeVoirie> items) {
    final byId = <String, ProblemeVoirie>{};
    for (final p in items) {
      if (p.id.isNotEmpty) byId[p.id] = p;
    }
    return byId.values.toList();
  }

  List<ProblemeSignaleMapItem> _mergeSignalesById(Iterable<ProblemeSignaleMapItem> items) {
    final byId = <String, ProblemeSignaleMapItem>{};
    for (final s in items) {
      if (s.id.isNotEmpty) byId[s.id] = s;
    }
    return byId.values.toList();
  }

  bool get _hasDestinationSearchContext =>
      _destination != null || _showRoutePreview || _isNavigating;

  List<ProblemeVoirie> _voirieForMapDisplay() {
    if (!_hasDestinationSearchContext) return _problemesVoirie;
    return _mergeVoirieById([..._problemesVoirie, ..._problemesVoirieOnRoute]);
  }

  List<ProblemeSignaleMapItem> _signalesForMapDisplay() {
    if (!_hasDestinationSearchContext) return _problemesSignales;
    return _mergeSignalesById([..._problemesSignales, ..._problemesSignalesOnRoute]);
  }

  Future<void> _loadProblemesAroundDestination() async {
    if (_destination == null && _routePoints.length < 2) return;

    final points = <LatLng>[];
    if (_destination != null) points.add(_destination!);
    if (_currentPosition != null) points.add(_currentPosition!);
    if (_routePoints.length >= 2) points.addAll(_routePoints);
    if (points.isEmpty) return;

    final bounds = boundsWithPaddingMeters(points, paddingMeters: 5000);
    try {
      final voirieRaw = await ProblemesVoirieService.getProblemesInBounds(
        bounds,
        limit: 500,
        activeOnly: true,
      );
      final signalesRaw = await ProblemesSignalesMapService.fetchInBounds(
        bounds,
        limit: 500,
        sinceDays: 90,
      );
      if (!mounted) return;
      setState(() {
        _problemesVoirie = _mergeVoirieById([
          ..._problemesVoirie,
          ...ProblemesVoirieService.filterForMapDisplay(voirieRaw),
        ]);
        _problemesSignales = _mergeSignalesById([
          ..._problemesSignales,
          ..._filterValidSignales(signalesRaw),
        ]);
      });
      _updateMarkers();
    } catch (e) {
      debugPrint('Erreur chargement problemes autour destination: $e');
    }
  }

  List<ProblemeVoirie> _filterVoirieNearRoute(
    Iterable<ProblemeVoirie> items,
    List<LatLng> route,
    double thresholdM,
  ) =>
      ProblemesVoirieService.filterForMapDisplay(
        items.where((e) => minDistanceToRouteMeters(e.location, route) <= thresholdM),
      );

  Future<List<ProblemeVoirie>> _voiriePoolForRouteScan() async {
    if (_problemesVoirie.isNotEmpty) return _problemesVoirie;
    final loaded = await ProblemesVoirieService.getAllForMap();
    if (mounted && loaded.isNotEmpty) {
      setState(() => _problemesVoirie = loaded);
      _updateMarkers();
    }
    return loaded;
  }

  Future<void> _applyRouteProblemsResult({
    required List<LatLng> route,
    required List<ProblemeVoirie> corridorVoirie,
    required List<ProblemeSignaleMapItem> corridorSignales,
    required double thresholdM,
    required bool navigationMode,
    bool triggerAlternativePrompt = true,
  }) async {
    final bounds = boundsWithPaddingMeters(
      route,
      paddingMeters: navigationMode ? 2000.0 : 750.0,
    );

    final voiriePool = await _voiriePoolForRouteScan();
    final localVoirie = _filterVoirieNearRoute(voiriePool, route, thresholdM);
    final bboxVoirie = _filterVoirieNearRoute(
      await ProblemesVoirieService.getProblemesInBounds(bounds, limit: 500),
      route,
      thresholdM,
    );
    final voirie = _mergeVoirieById([
      ...corridorVoirie,
      ...localVoirie,
      ...bboxVoirie,
    ]);

    final bboxSignales = _filterValidSignales(
      await ProblemesSignalesMapService.fetchInBounds(
        bounds,
        limit: 500,
        sinceDays: 90,
      ),
    ).where((e) => minDistanceToRouteMeters(e.location, route) <= thresholdM);
    final signales = _mergeSignalesById([
      ...corridorSignales,
      ...bboxSignales,
    ]);

    if (!mounted) return;
    setState(() {
      _problemesVoirieOnRoute = voirie;
      _problemesSignalesOnRoute = signales;
      _loadingRouteProblems = false;
    });
    _updateMarkers();
    _prefetchRouteProblemAddresses();
    debugPrint(
      'Problèmes sur itinéraire: ${voirie.length} voirie, ${signales.length} signalements',
    );
    if (!navigationMode && triggerAlternativePrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_onRouteProblemsScanned());
      });
    }
  }

  /// Charge voirie + signalements MongoDB le long de l'itinéraire (corridor ou bbox).
  Future<void> _loadProblemesAlongRoute({
    bool navigationMode = false,
    bool triggerAlternativePrompt = true,
  }) async {
    final route = List<LatLng>.from(_routePoints);
    if (route.length < 2) {
      if (!mounted) return;
      setState(() {
        _problemesVoirieOnRoute = [];
        _problemesSignalesOnRoute = [];
        _loadingRouteProblems = false;
      });
      _updateMarkers();
      return;
    }

    if (mounted) setState(() => _loadingRouteProblems = true);

    // Même seuil que le comptage (_countTotalProblemsOnRoute) pour éviter
    // d'afficher des problèmes sur un itinéraire jugé « sans problème ».
    const bufferM = _kRouteProblemDistanceM;
    const routeThresholdM = _kRouteProblemDistanceM;

    var corridorVoirie = <ProblemeVoirie>[];
    var corridorSignales = <ProblemeSignaleMapItem>[];

    try {
      final scan = await RouteCorridorProblemsService.scan(
        route,
        bufferMeters: bufferM,
        sinceDays: 90,
        details: true,
      );
      if (scan != null) {
        corridorVoirie = ProblemesVoirieService.filterForMapDisplay(scan.voirie);
        corridorSignales = _filterValidSignales(scan.signales);
      }
    } catch (e) {
      debugPrint("Erreur corridor serveur: $e");
    }

    try {
      await _applyRouteProblemsResult(
        route: route,
        corridorVoirie: corridorVoirie,
        corridorSignales: corridorSignales,
        thresholdM: routeThresholdM,
        navigationMode: navigationMode,
        triggerAlternativePrompt: triggerAlternativePrompt,
      );
    } catch (e) {
      debugPrint("Erreur chargement problemes sur itineraire: $e");
      if (mounted) setState(() => _loadingRouteProblems = false);
    }
  }

  void _resetAlternativeRoutePromptState() {
    _routeProblemCounts = null;
    _scanningRouteAlternatives = false;
    _showRouteAlternatives = false;
    _recommendedAlternativeIndex = null;
    _routeProblemsAlertShownForSignature = null;
    _routeProblemsAlertDismissedSignature = null;
    _alternativeRoutePromptOpen = false;
    _savedRoutesBeforeCleanAlts = null;
    _savedMainRouteVoirie = [];
    _savedMainRouteSignales = [];
    _savedMainRoutePoints = [];
  }

  void _snapshotMainRouteProblems() {
    _savedMainRouteVoirie = List<ProblemeVoirie>.from(_problemesVoirieOnRoute);
    _savedMainRouteSignales = List<ProblemeSignaleMapItem>.from(_problemesSignalesOnRoute);
    _savedMainRoutePoints = List<LatLng>.from(_routePoints);
    for (final v in _savedMainRouteVoirie) {
      unawaited(_displayAddressForVoirie(v));
    }
    for (final s in _savedMainRouteSignales) {
      unawaited(_problemAddressAt(s.location));
    }
  }

  String get _destinationSearchLabel => _searchController.text.trim();

  String _normalizeAddressLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[^\w\s,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _addressesReferToSamePlace(String a, String b) {
    final na = _normalizeAddressLabel(a);
    final nb = _normalizeAddressLabel(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;

    final tokensA = na.split(RegExp(r'[,\s]+')).where((t) => t.length > 2).toSet();
    final tokensB = nb.split(RegExp(r'[,\s]+')).where((t) => t.length > 2).toSet();
    if (tokensA.isEmpty || tokensB.isEmpty) return false;
    final overlap = tokensA.intersection(tokensB).length;
    return overlap >= 2 || overlap >= tokensA.length - 1;
  }

  bool _problemNearDestination(LatLng location, {double radiusM = 450}) {
    if (_destination == null) return false;
    return Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          _destination!.latitude,
          _destination!.longitude,
        ) <=
        radiusM;
  }

  List<ProblemeVoirie> _routeVoirieForDisplay() {
    if (_showRouteAlternatives && _savedMainRouteVoirie.isNotEmpty) {
      return _savedMainRouteVoirie;
    }
    return _problemesVoirieOnRoute;
  }

  List<ProblemeVoirie> _voirieSharingDestinationAddress() {
    final destLabel = _destinationSearchLabel;
    return _routeVoirieForDisplay().where((v) {
      if (_problemNearDestination(v.location)) return true;
      final addr = _cachedVoirieAddressLabel(v);
      if (addr != null && destLabel.isNotEmpty && _addressesReferToSamePlace(addr, destLabel)) {
        return true;
      }
      return false;
    }).toList();
  }

  String? _cachedVoirieAddressLabel(ProblemeVoirie v) {
    if (v.mongoAddress != null && v.mongoAddress!.trim().isNotEmpty) {
      return v.mongoAddress!.trim();
    }
    return _geocodedProblemAddresses[_voirieAddressCacheKey(v)];
  }

  String _voirieAddressCacheKey(ProblemeVoirie v) =>
      v.id.isNotEmpty ? 'voirie:${v.id}' : _geocodeCacheKey(v.location);

  Future<String> _displayAddressForVoirie(ProblemeVoirie v) async {
    final key = _voirieAddressCacheKey(v);
    if (v.mongoAddress != null && v.mongoAddress!.trim().isNotEmpty) {
      final label = v.mongoAddress!.trim();
      _geocodedProblemAddresses[key] = label;
      return label;
    }
    final cached = _geocodedProblemAddresses[key];
    if (cached != null) return cached;
    final addr = await NominatimService.reverseGeocode(v.location);
    final label = (addr != null && addr.trim().isNotEmpty)
        ? addr.trim()
        : '${v.location.latitude.toStringAsFixed(5)}, ${v.location.longitude.toStringAsFixed(5)}';
    _geocodedProblemAddresses[key] = label;
    return label;
  }

  List<LatLng> _collectDestinationAddressAvoidanceHazards() {
    final hazards = <LatLng>[];
    final seen = <String>{};

    void add(LatLng p) {
      final key = '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) hazards.add(p);
    }

    for (final v in _voirieSharingDestinationAddress()) {
      add(v.location);
    }
    if (_destination != null) {
      add(_destination!);
    }
    return hazards;
  }

  int _countDestinationAddressVoirieOnRoute(List<LatLng> route) {
    if (route.length < 2) return 0;
    const thresholdM = _kRouteProblemDistanceM;
    final destLabel = _destinationSearchLabel;
    final seen = <String>{};
    var total = 0;

    for (final v in _problemesVoirie) {
      if (v.id.isNotEmpty && !seen.add(v.id)) continue;
      final nearRoute = minDistanceToRouteMeters(v.location, route) <= thresholdM;
      if (!nearRoute) continue;
      final addr = _cachedVoirieAddressLabel(v);
      final sameDest = _problemNearDestination(v.location) ||
          (addr != null &&
              destLabel.isNotEmpty &&
              _addressesReferToSamePlace(addr, destLabel));
      if (sameDest) total++;
    }
    return total;
  }

  void _pruneRoutesToCleanOnly(List<int> cleanIndexes) {
    if (cleanIndexes.isEmpty || _routes.isEmpty) return;
    final limited = cleanIndexes.length > _kMaxCleanAlternativeRoutes
        ? cleanIndexes.sublist(0, _kMaxCleanAlternativeRoutes)
        : cleanIndexes;
    final pruned = <Map<String, dynamic>>[];
    final prunedCounts = <int>[];
    final sourceIndexes = <int>[];
    final oldCounts = _routeProblemCounts;
    for (final i in limited) {
      if (i < 0 || i >= _routes.length || !_isValidRouteMap(_routes[i])) continue;
      pruned.add(Map<String, dynamic>.from(_routes[i]));
      sourceIndexes.add(i);
      if (oldCounts != null && i < oldCounts.length) {
        prunedCounts.add(oldCounts[i]);
      } else {
        prunedCounts.add(-1);
      }
    }
    if (pruned.isEmpty) return;
    final prevSelected = _selectedRouteIndex;
    var newSelected = sourceIndexes.indexOf(prevSelected);
    if (newSelected < 0) newSelected = 0;

    setState(() {
      _routes = pruned;
      _routeProblemCounts = prunedCounts;
      _selectedRouteIndex = newSelected.clamp(0, pruned.length - 1);
      _recommendedAlternativeIndex = _pickBestRouteIndexFromCounts(
        prunedCounts.every((c) => c >= 0)
            ? prunedCounts
            : List.filled(pruned.length, 0),
      );
      _routePoints = List<LatLng>.from(_routes[_selectedRouteIndex]['points'] as List);
      _routeDuration = (_routes[_selectedRouteIndex]['duration'] as num).toDouble();
      _routeDistance = (_routes[_selectedRouteIndex]['distance'] as num).toDouble();
      _safetyScore =
          (_routes[_selectedRouteIndex]['safetyScore'] as num?)?.toDouble() ?? 95.0;
    });
    unawaited(_loadProblemesAlongRoute());
  }

  void _applyMainRouteOnly() {
    if (_routes.isEmpty || !_isValidRouteMap(_routes[0])) return;
    _selectedRouteIndex = 0;
    _routePoints = List<LatLng>.from(_routes[0]['points'] as List);
    _routeDuration = (_routes[0]['duration'] as num).toDouble();
    _routeDistance = (_routes[0]['distance'] as num).toDouble();
    _safetyScore = (_routes[0]['safetyScore'] as num?)?.toDouble() ?? 95.0;
  }

  Future<void> _loadProblemesVoirie() async {
    if (!mounted) return;
    setState(() => _loadingProblemesVoirie = true);
    try {
      final problemes = await ProblemesVoirieService.getAllForMap();
      if (!mounted) return;
      setState(() {
        _problemesVoirie = problemes;
        _loadingProblemesVoirie = false;
      });
      _updateMarkers();
      debugPrint('Problemes voirie affichés sur la carte: ${problemes.length}');
    } catch (e) {
      if (mounted) setState(() => _loadingProblemesVoirie = false);
      debugPrint("Erreur chargement problemes voirie: $e");
    }
  }

  Future<void> _loadProblemesSignales() async {
    if (!mounted) return;
    setState(() => _loadingProblemesSignales = true);
    try {
      final signalements = await ProblemesSignalesMapService.fetchAll();
      if (!mounted) return;
      setState(() {
        _problemesSignales = _filterValidSignales(signalements);
        _loadingProblemesSignales = false;
      });
      _updateMarkers();
      debugPrint('Signalements MongoDB affichés sur la carte: ${_problemesSignales.length}');
    } catch (e) {
      if (mounted) setState(() => _loadingProblemesSignales = false);
      debugPrint('Erreur chargement problemes signales: $e');
    }
  }

  Future<void> _loadAllMapProblems() async {
    await Future.wait([
      _loadProblemesVoirie(),
      _loadProblemesSignales(),
    ]);
  }

  List<_RouteProblemRow> _mergedRouteProblemsOrdered() {
    final useSnapshot = _showRouteAlternatives && _savedMainRoutePoints.length >= 2;
    final route = useSnapshot ? _savedMainRoutePoints : _routePoints;
    if (route.length < 2) return [];
    final voirie = useSnapshot ? _savedMainRouteVoirie : _problemesVoirieOnRoute;
    final signales = useSnapshot ? _savedMainRouteSignales : _problemesSignalesOnRoute;
    final out = <_RouteProblemRow>[];
    for (final v in voirie) {
      out.add(_RouteProblemRow.voirie(v, _nearestRouteVertexIndex(v.location, route)));
    }
    for (final s in signales) {
      out.add(_RouteProblemRow.signale(s, _nearestRouteVertexIndex(s.location, route)));
    }
    out.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return out;
  }

  int _nearestRouteVertexIndex(LatLng p, List<LatLng> route) {
    if (route.isEmpty) return 0;
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < route.length; i++) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        route[i].latitude,
        route[i].longitude,
      );
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  String _routeProblemsSignature() {
    final d = _destination;
    if (d == null || _routes.isEmpty) return '';
    final wp = _waypoints
        .map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
        .join(';');
    final dist0 = (_routes[0]['distance'] as num).toString();
    return '${d.latitude}_${d.longitude}_${wp}_${_selectedProfile}_$dist0';
  }

  bool _isRouteAlertDismissedForCurrentRoute() {
    final sig = _routeProblemsSignature();
    return sig.isNotEmpty && sig == _routeProblemsAlertDismissedSignature;
  }

  void _rememberRouteAlertDismissed() {
    final sig = _routeProblemsSignature();
    if (sig.isNotEmpty) {
      _routeProblemsAlertDismissedSignature = sig;
    }
  }

  /// Comptage local rapide (données déjà en mémoire, sans requête réseau).
  int _countProblemsOnRouteLocal(List<LatLng> route) {
    if (route.length < 2) return 0;
    const thresholdM = _kRouteProblemDistanceM;
    final seenV = <String>{};
    final seenS = <String>{};
    var total = 0;

    for (final v in _problemesVoirieOnRoute) {
      if (v.id.isNotEmpty && !seenV.add(v.id)) continue;
      if (minDistanceToRouteMeters(v.location, route) <= thresholdM) total++;
    }
    for (final v in _problemesVoirie) {
      if (v.id.isNotEmpty && !seenV.add(v.id)) continue;
      if (minDistanceToRouteMeters(v.location, route) <= thresholdM) total++;
    }
    for (final s in _problemesSignalesOnRoute) {
      if (s.id.isNotEmpty && !seenS.add(s.id)) continue;
      if (minDistanceToRouteMeters(s.location, route) <= thresholdM) total++;
    }
    for (final s in _problemesSignales) {
      if (s.id.isNotEmpty && !seenS.add(s.id)) continue;
      if (minDistanceToRouteMeters(s.location, route) <= thresholdM) total++;
    }
    return total;
  }

  List<int> _localProblemCountsForRoutes({int maxRoutes = 6}) {
    final limit = _routes.length < maxRoutes ? _routes.length : maxRoutes;
    return List.generate(limit, (i) {
      final pts = List<LatLng>.from(_routes[i]['points'] as List);
      return _countProblemsOnRouteLocal(pts);
    });
  }

  Future<int> _countTotalProblemsOnRoute(List<LatLng> route) async {
    if (route.length < 2) return 0;

    final cacheKey = _generateRouteCacheKey(route);
    if (_routeProblemCountCache.containsKey(cacheKey)) {
      return _routeProblemCountCache[cacheKey]!;
    }

    try {
      final scan = await RouteCorridorProblemsService.scan(
        route,
        bufferMeters: _kRouteProblemDistanceM,
        sinceDays: 90,
        details: false,
      );
      final count = scan?.totalCount ?? 0;
      _routeProblemCountCache[cacheKey] = count;
      return count;
    } catch (_) {
      final count = await _countTotalProblemsOnRouteBboxFallback(route);
      _routeProblemCountCache[cacheKey] = count;
      return count;
    }
  }

  String _generateRouteCacheKey(List<LatLng> route) {
    final step = max(1, route.length ~/ 10);
    final sampled = <String>[];
    for (var i = 0; i < route.length; i += step) {
      sampled.add(
        '${route[i].latitude.toStringAsFixed(4)},${route[i].longitude.toStringAsFixed(4)}',
      );
    }
    return sampled.join('|');
  }

  Future<int> _countTotalProblemsOnRouteBboxFallback(List<LatLng> route) async {
    final bounds = boundsWithPaddingMeters(route, paddingMeters: 750);
    const thresholdM = _kRouteProblemDistanceM;
    try {
      final rawVoirie = await ProblemesVoirieService.getProblemesInBounds(
        bounds,
        limit: 500,
      );
      final rawSignales = await ProblemesSignalesMapService.fetchInBounds(
        bounds,
        limit: 500,
        sinceDays: 90,
      );
      final nv = rawVoirie
          .where((e) => minDistanceToRouteMeters(e.location, route) <= thresholdM)
          .length;
      final ns = rawSignales
          .where((e) => minDistanceToRouteMeters(e.location, route) <= thresholdM)
          .length;
      return nv + ns;
    } catch (_) {
      return 0;
    }
  }

  int _pickBestRouteIndexFromCounts(List<int> problemCounts) {
    if (problemCounts.isEmpty || _routes.isEmpty) return 0;

    final routeCount = _routes.length;
    final n = problemCounts.length < routeCount ? problemCounts.length : routeCount;
    if (n <= 0) return 0;

    final zeroProblemIndexes = <int>[];
    for (var i = 0; i < n; i++) {
      if (problemCounts[i] == 0) zeroProblemIndexes.add(i);
    }
    if (zeroProblemIndexes.isNotEmpty) {
      zeroProblemIndexes.sort((a, b) {
        final distA = (_routes[a]['distance'] as num).toDouble();
        final distB = (_routes[b]['distance'] as num).toDouble();
        return distA.compareTo(distB);
      });
      return zeroProblemIndexes.first;
    }

    var best = 0;
    var bestScore = _routeQualityScore(
      (_routes[0]['distance'] as num).toDouble(),
      problemCounts[0],
    );
    for (var i = 1; i < n; i++) {
      final dist = (_routes[i]['distance'] as num).toDouble();
      final sc = _routeQualityScore(dist, problemCounts[i]);
      if (sc < bestScore) {
        bestScore = sc;
        best = i;
      } else if (sc == bestScore) {
        final bestDist = (_routes[best]['distance'] as num).toDouble();
        if (problemCounts[i] < problemCounts[best] ||
            (problemCounts[i] == problemCounts[best] && dist < bestDist)) {
          best = i;
        }
      }
    }
    return best;
  }

  int? _indexOfFirstZeroProblemRoute() {
    final counts = _routeProblemCounts;
    if (counts == null || counts.isEmpty || _routes.isEmpty) return null;
    return _indexOfFirstZeroProblemRouteFromCounts(counts);
  }

  Future<void> _ensureRouteProblemCounts() async {
    if (_routes.isEmpty) return;
    if (_routeProblemCounts != null && _routeProblemCounts!.length == _routes.length) {
      if (_routeProblemCounts!.every((c) => c >= 0)) return;
    }

    final counts = <int>[];
    for (var i = 0; i < _routes.length; i++) {
      final pts = List<LatLng>.from(_routes[i]['points'] as List);
      counts.add(await _countTotalProblemsOnRoute(pts));
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _routeProblemCounts = counts;
      if (_routes.isNotEmpty) {
        _recommendedAlternativeIndex = _pickBestRouteIndexFromCounts(counts);
      }
    });
  }

  int? _pickShortestZeroProblemIndex(List<int> counts) {
    if (_routes.isEmpty || counts.isEmpty) return null;
    final zeros = <int>[];
    for (var i = 0; i < counts.length && i < _routes.length; i++) {
      if (counts[i] == 0) zeros.add(i);
    }
    if (zeros.isEmpty) return null;
    zeros.sort((a, b) {
      final distA = (_routes[a]['distance'] as num).toDouble();
      final distB = (_routes[b]['distance'] as num).toDouble();
      return distA.compareTo(distB);
    });
    return zeros.first;
  }

  Future<List<int>> _countAllRoutesProblems() async {
    final counts = <int>[];
    for (var i = 0; i < _routes.length; i++) {
      final pts = List<LatLng>.from(_routes[i]['points'] as List);
      counts.add(await _countTotalProblemsOnRoute(pts));
    }
    return counts;
  }

  Future<List<int>> _countAllRoutesProblemsDynamic() async {
    if (_routes.isEmpty) return [];

    final counts = <int>[];
    var current = 0;

    for (final route in _routes) {
      final pts = List<LatLng>.from(route['points'] as List);

      if (mounted && _routes.length > 1) {
        setState(() {
          _scanningRouteAlternatives = true;
        });
      }

      final problemCount = await _countTotalProblemsOnRoute(pts);
      counts.add(problemCount);
      current++;

      debugPrint('Route $current/${_routes.length}: $problemCount problèmes');

      if (!mounted) return [];
    }

    return counts;
  }

  List<LatLng> _collectHazardsForAvoidance() {
    final hazards = <LatLng>[];
    final seen = <String>{};

    void add(LatLng p) {
      final key = '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) hazards.add(p);
    }

    for (final v in _problemesVoirieOnRoute) {
      add(v.location);
    }
    for (final s in _problemesSignalesOnRoute) {
      add(s.location);
    }

    final ref = _routePoints.length >= 2
        ? _routePoints
        : (_routes.isNotEmpty
            ? List<LatLng>.from(_routes.first['points'] as List)
            : const <LatLng>[]);

    final refs = <List<LatLng>>[];
    if (ref.length >= 2) refs.add(ref);
    for (final route in _routes) {
      final pts = List<LatLng>.from(route['points'] as List);
      if (pts.length >= 2) refs.add(pts);
    }

    for (final polyline in refs) {
      for (final v in _problemesVoirie) {
        if (minDistanceToRouteMeters(v.location, polyline) <= _kRouteProblemDistanceM) {
          add(v.location);
        }
      }
      for (final s in _problemesSignales) {
        if (minDistanceToRouteMeters(s.location, polyline) <= _kRouteProblemDistanceM) {
          add(s.location);
        }
      }
    }

    return hazards;
  }

  List<LatLng> _collectExtendedHazardsForAvoidance() {
    final hazards = <LatLng>[];
    final seen = <String>{};

    void add(LatLng p) {
      final key = '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) hazards.add(p);
    }

    for (final v in _problemesVoirieOnRoute) {
      add(v.location);
    }
    for (final s in _problemesSignalesOnRoute) {
      add(s.location);
    }

    for (final v in _problemesVoirie) {
      final ref = _savedMainRoutePoints.length >= 2 ? _savedMainRoutePoints : _routePoints;
      if (minDistanceToRouteMeters(v.location, ref) <= 500) {
        add(v.location);
      }
    }
    for (final s in _problemesSignales) {
      final ref = _savedMainRoutePoints.length >= 2 ? _savedMainRoutePoints : _routePoints;
      if (minDistanceToRouteMeters(s.location, ref) <= 500) {
        add(s.location);
      }
    }

    return hazards;
  }

  List<LatLng> _referenceRouteForCleanSearch() {
    if (_savedMainRoutePoints.length >= 2) {
      return List<LatLng>.from(_savedMainRoutePoints);
    }
    if (_routePoints.length >= 2) {
      return List<LatLng>.from(_routePoints);
    }
    if (_routes.isNotEmpty) {
      return List<LatLng>.from(_routes.first['points'] as List);
    }
    return const [];
  }

  List<LatLng> _collectAllHazardsForCleanSearch(List<LatLng> referenceRoute) {
    final hazards = <LatLng>[];
    final seen = <String>{};

    void add(LatLng p) {
      final key = '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) hazards.add(p);
    }

    for (final p in _collectDestinationAddressAvoidanceHazards()) {
      add(p);
    }

    for (final v in _problemesVoirieOnRoute) {
      add(v.location);
    }
    for (final s in _problemesSignalesOnRoute) {
      add(s.location);
    }
    for (final v in _savedMainRouteVoirie) {
      add(v.location);
    }
    for (final s in _savedMainRouteSignales) {
      add(s.location);
    }

    if (referenceRoute.length >= 2) {
      for (final v in _problemesVoirie) {
        if (minDistanceToRouteMeters(v.location, referenceRoute) <= 500) {
          add(v.location);
        }
      }
      for (final s in _problemesSignales) {
        if (minDistanceToRouteMeters(s.location, referenceRoute) <= 500) {
          add(s.location);
        }
      }
    }

    return hazards;
  }

  Future<List<Map<String, dynamic>>> _pickVerifiedCleanRoutesFromPool() async {
    final mainRoute = _savedRoutesBeforeCleanAlts?.isNotEmpty == true
        ? _savedRoutesBeforeCleanAlts!.first
        : null;
    final clean = <Map<String, dynamic>>[];

    for (final route in _routes) {
      if (mainRoute != null &&
          RoutingService.isSimilarToExistingRoute(route, [mainRoute])) {
        continue;
      }

      final routePoints = List<LatLng>.from(route['points'] as List);
      if (routePoints.length < 2) continue;

      final problemCount = await _countTotalProblemsOnRoute(routePoints);
      if (problemCount != 0) continue;

      final adjusted = {
        ...route,
        'duration': _adjustDuration(route['duration'], _selectedProfile),
        'safetyScore': 100.0,
      };
      if (!_isRouteAlreadyInList(adjusted, clean)) {
        clean.add(adjusted);
      }
      if (!mounted) return [];
    }

    clean.sort((a, b) {
      final distA = (a['distance'] as num).toDouble();
      final distB = (b['distance'] as num).toDouble();
      return distA.compareTo(distB);
    });

    if (clean.length > _kMaxCleanAlternativeRoutes) {
      return clean.sublist(0, _kMaxCleanAlternativeRoutes);
    }
    return clean;
  }

  bool _isValidRouteMap(dynamic value) {
    if (value is! Map) return false;
    final pts = value['points'];
    return pts is List && pts.length >= 2;
  }

  List<Map<String, dynamic>> _validatedRouteMaps(Iterable<dynamic> candidates) {
    final out = <Map<String, dynamic>>[];
    for (final c in candidates) {
      if (!_isValidRouteMap(c)) continue;
      out.add(Map<String, dynamic>.from(c as Map));
    }
    return out;
  }

  void _applyAlternativeRoutesToMap(
    List<Map<String, dynamic>> routes, {
    required List<int> problemCounts,
    required bool allClean,
  }) {
    final validRoutes = _validatedRouteMaps(routes);
    if (validRoutes.isEmpty || !mounted) {
      debugPrint(
        'applyAlternativeRoutesToMap: aucun itinéraire valide '
        '(reçu ${routes.length}, valides 0)',
      );
      return;
    }
    final counts = problemCounts.length == validRoutes.length
        ? problemCounts
        : problemCounts.take(validRoutes.length).toList();

    setState(() {
      _routes = validRoutes;
      _routeProblemCounts = counts;
      _showRouteAlternatives = true;
      _selectedRouteIndex = 0;
      _recommendedAlternativeIndex = 0;
      _routePoints = List<LatLng>.from(validRoutes[0]['points'] as List);
      _routeDuration = (validRoutes[0]['duration'] as num).toDouble();
      _routeDistance = (validRoutes[0]['distance'] as num).toDouble();
      _safetyScore = (validRoutes[0]['safetyScore'] as num?)?.toDouble() ??
          _safetyScoreFromProblemCount(counts.first);
      if (allClean) {
        _problemesVoirieOnRoute = [];
        _problemesSignalesOnRoute = [];
      }
      _rememberRouteAlertDismissed();
      _scanningRouteAlternatives = false;
      _loadingRouteProblems = false;
    });

    _updateMarkers();
    _fitRoutesOnMap(padding: 70);

    if (!allClean) {
      unawaited(_loadProblemesAlongRoute(triggerAlternativePrompt: false));
    }
  }

  double _safetyScoreFromProblemCount(int count) {
    if (count <= 0) return 100.0;
    return (100 - count * 2.5).clamp(35.0, 99.0);
  }

  Future<List<({Map<String, dynamic> routeMap, int count, int destConflict})>>
      _collectRankedAlternativeRoutes({
    required List<LatLng> referenceRoute,
    required List<LatLng> hazards,
  }) async {
    final start = _startPosition ?? _currentPosition;
    if (_destination == null || start == null) return [];

    final mainRoute = _savedRoutesBeforeCleanAlts?.isNotEmpty == true
        ? _savedRoutesBeforeCleanAlts!.first
        : null;
    final ranked = <({Map<String, dynamic> routeMap, int count, int destConflict})>[];
    final dedupeList = <Map<String, dynamic>>[];

    Future<void> addCandidate(
      Map<String, dynamic> route, {
      int? cachedProblemCount,
    }) async {
      if (!_isValidRouteMap(route)) return;
      if (mainRoute != null &&
          RoutingService.isSimilarToExistingRoute(route, [mainRoute])) {
        return;
      }
      if (_isRouteAlreadyInList(route, dedupeList)) return;

      final pts = List<LatLng>.from(route['points'] as List);
      if (pts.length < 2) return;

      dedupeList.add(route);
      final count =
          cachedProblemCount ?? await _countTotalProblemsOnRoute(pts);
      final destConflict = _countDestinationAddressVoirieOnRoute(pts);
      if (!mounted) return;

      ranked.add((
        routeMap: {
          ...route,
          'duration': _adjustDuration(route['duration'], _selectedProfile),
          'safetyScore': _safetyScoreFromProblemCount(count),
        },
        count: count,
        destConflict: destConflict,
      ));
    }

    for (var i = 0; i < _routes.length; i++) {
      if (!_isValidRouteMap(_routes[i])) continue;
      final cached = _routeProblemCounts != null && i < _routeProblemCounts!.length
          ? _routeProblemCounts![i]
          : null;
      await addCandidate(
        Map<String, dynamic>.from(_routes[i]),
        cachedProblemCount: cached,
      );
      if (!mounted) return [];
    }

    if (referenceRoute.length >= 2 && hazards.isNotEmpty) {
      final generated = await RoutingService.getRoutesAvoidingHazards(
        start,
        _destination!,
        waypoints: _waypoints,
        hazards: hazards,
        referenceRoute: referenceRoute,
        profile: _osrmProfileForSelected(),
      );
      for (final route in generated) {
        await addCandidate(route);
        if (!mounted) return [];
      }
    }

    if (ranked.length < _kMaxCleanAlternativeRoutes) {
      final osrmAlternatives = await RoutingService.getRoutesWithAlternatives(
        start,
        _destination!,
        waypoints: _waypoints,
        profile: _osrmProfileForSelected(),
      );
      for (final route in osrmAlternatives) {
        await addCandidate(route);
        if (!mounted) return [];
      }
    }

    ranked.sort((a, b) {
      final destCmp = a.destConflict.compareTo(b.destConflict);
      if (destCmp != 0) return destCmp;
      final cmp = a.count.compareTo(b.count);
      if (cmp != 0) return cmp;
      return (a.routeMap['distance'] as num).compareTo(b.routeMap['distance'] as num);
    });

    return ranked;
  }

  List<({Map<String, dynamic> routeMap, int count, int destConflict})> _pickBestRankedAlternatives(
    List<({Map<String, dynamic> routeMap, int count, int destConflict})> ranked,
    int mainProblemCount,
  ) {
    if (ranked.isEmpty) return const [];
    const minAlternatives = 2;

    final mainDestConflict = _countDestinationAddressVoirieOnRoute(
      _referenceRouteForCleanSearch(),
    );

    List<({Map<String, dynamic> routeMap, int count, int destConflict})> ensureMinCount(
      List<({Map<String, dynamic> routeMap, int count, int destConflict})> base,
    ) {
      if (base.length >= minAlternatives) return base;
      final out = <({Map<String, dynamic> routeMap, int count, int destConflict})>[
        ...base,
      ];
      for (final candidate in ranked) {
        if (out.length >= _kMaxCleanAlternativeRoutes) break;
        final exists = out.any(
          (e) =>
              e.count == candidate.count &&
              e.destConflict == candidate.destConflict &&
              (e.routeMap['distance'] as num) == (candidate.routeMap['distance'] as num),
        );
        if (!exists) out.add(candidate);
      }
      return out;
    }

    var picked = ranked
        .where((r) => r.count == 0 && r.destConflict == 0)
        .take(_kMaxCleanAlternativeRoutes)
        .toList();
    if (picked.isNotEmpty) return ensureMinCount(picked);

    picked = ranked
        .where((r) => r.destConflict < mainDestConflict)
        .take(_kMaxCleanAlternativeRoutes)
        .toList();
    if (picked.isNotEmpty) return ensureMinCount(picked);

    picked = ranked
        .where((r) => r.count < mainProblemCount)
        .take(_kMaxCleanAlternativeRoutes)
        .toList();
    if (picked.isNotEmpty) return ensureMinCount(picked);

    return ensureMinCount(ranked.take(_kMaxCleanAlternativeRoutes).toList());
  }

  void _applyCleanRoutesToMap(List<Map<String, dynamic>> cleanRoutes) {
    _applyAlternativeRoutesToMap(
      cleanRoutes,
      problemCounts: List.filled(cleanRoutes.length, 0),
      allClean: true,
    );
  }

  List<Polyline> _buildRoutePolylinePair(
    List<LatLng> pts, {
    required Color color,
    required double baseWidth,
    required double opacity,
    bool isSelected = false,
  }) {
    return [
      Polyline(
        points: pts,
        color: Colors.white,
        strokeWidth: baseWidth + 3,
        strokeCap: StrokeCap.round,
      ),
      Polyline(
        points: pts,
        color: color.withOpacity(opacity),
        strokeWidth: baseWidth,
        strokeCap: StrokeCap.round,
        borderStrokeWidth: isSelected ? 1.5 : 0,
        borderColor: Colors.white.withOpacity(0.9),
      ),
    ];
  }

  Future<int?> _searchCleanAlternativeRouteIndex() async {
    if (_routes.isEmpty) return null;

    await _ensureRouteProblemCounts();
    if (!mounted || _routes.isEmpty) return null;

    var counts = _routeProblemCounts ?? await _countAllRoutesProblems();
    var cleanIdx = _pickShortestZeroProblemIndex(counts);
    if (cleanIdx != null) return cleanIdx;

    for (var attempt = 0; attempt < 6; attempt++) {
      await _appendAvoidanceRoutes(_collectHazardsForAvoidance());
      if (!mounted || _routes.isEmpty) return null;

      counts = await _countAllRoutesProblems();
      if (!mounted) return null;

      setState(() {
        _routeProblemCounts = counts;
        _recommendedAlternativeIndex = _pickShortestZeroProblemIndex(counts);
      });

      cleanIdx = _pickShortestZeroProblemIndex(counts);
      if (cleanIdx != null) return cleanIdx;
    }

    return null;
  }

  List<int> _cleanRouteIndexesFromCounts(List<int> counts) {
    if (_routes.isEmpty || counts.isEmpty) return const [];
    final clean = <int>[];
    for (var i = 0; i < counts.length && i < _routes.length; i++) {
      if (counts[i] == 0) clean.add(i);
    }
    clean.sort((a, b) {
      final distA = (_routes[a]['distance'] as num).toDouble();
      final distB = (_routes[b]['distance'] as num).toDouble();
      return distA.compareTo(distB);
    });
    if (clean.length > _kMaxCleanAlternativeRoutes) {
      return clean.sublist(0, _kMaxCleanAlternativeRoutes);
    }
    return clean;
  }

  /// Alias conservé pour compatibilité (hot reload / anciennes références).
  List<int> _findCleanAlternativeRouteIndexes(List<int> counts) {
    final clean = _cleanRouteIndexesFromCounts(counts);
    if (clean.isNotEmpty) return clean;
    return _bestSaferAlternativeRouteIndexes(counts);
  }

  /// Itinéraires alternatifs plus sûrs (moins de problèmes que le trajet principal).
  List<int> _bestSaferAlternativeRouteIndexes(List<int> counts) {
    if (_routes.isEmpty || counts.isEmpty) return const [];
    final n = counts.length < _routes.length ? counts.length : _routes.length;
    if (n <= 0) return const [];

    final mainCount = counts[0];
    final ranked = List.generate(n, (i) => i)
      ..sort((a, b) {
        final cmp = counts[a].compareTo(counts[b]);
        if (cmp != 0) return cmp;
        return (_routes[a]['distance'] as num).compareTo(_routes[b]['distance'] as num);
      });

    final picked = <int>[];
    for (final i in ranked) {
      if (picked.length >= _kMaxCleanAlternativeRoutes) break;
      if (counts[i] < mainCount) picked.add(i);
    }

    if (picked.isEmpty) {
      for (var i = 1; i < n && picked.length < _kMaxCleanAlternativeRoutes; i++) {
        picked.add(i);
      }
    }

    if (picked.isEmpty && n > 1) {
      picked.add(ranked.first);
      for (final i in ranked) {
        if (picked.length >= _kMaxCleanAlternativeRoutes) break;
        if (!picked.contains(i)) picked.add(i);
      }
    }

    return picked;
  }

  List<int> _visibleAlternativeRouteIndexes() {
    if (_routes.isEmpty) return const [];
    if (_showRouteAlternatives) {
      return List.generate(_routes.length.clamp(0, _kMaxCleanAlternativeRoutes), (i) => i);
    }
    if (_routes.length <= 1) return const [];
    return List.generate(_routes.length.clamp(0, 3), (i) => i);
  }

  List<LatLng> _displayPointsForRoute(int index) {
    if (index < 0 || index >= _routes.length) return const [];
    final route = _routes[index];
    if (!_isValidRouteMap(route)) return const [];
    final pts = List<LatLng>.from(route['points'] as List);
    if (pts.length < 2) return pts;
    return simplifyPolyline(pts, minSpacingMeters: _kAltRouteSimplifySpacingM);
  }

  String _geocodeCacheKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';

  Future<String> _problemAddressAt(LatLng p) async {
    final key = _geocodeCacheKey(p);
    final cached = _geocodedProblemAddresses[key];
    if (cached != null) return cached;
    final addr = await NominatimService.reverseGeocode(p);
    final label = (addr != null && addr.trim().isNotEmpty)
        ? addr.trim()
        : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    _geocodedProblemAddresses[key] = label;
    return label;
  }

  void _prefetchRouteProblemAddresses() {
    for (final row in _mergedRouteProblemsOrdered()) {
      if (row.voirie != null) {
        unawaited(_displayAddressForVoirie(row.voirie!).then((addr) {
          if (!mounted) return;
          setState(() => _geocodedProblemAddresses[_voirieAddressCacheKey(row.voirie!)] = addr);
        }));
        continue;
      }
      final loc = row.signale?.location;
      if (loc == null) continue;
      final key = _geocodeCacheKey(loc);
      if (_geocodedProblemAddresses.containsKey(key)) continue;
      unawaited(_problemAddressAt(loc).then((addr) {
        if (!mounted) return;
        setState(() => _geocodedProblemAddresses[key] = addr);
      }));
    }
  }

  String _osrmProfileForSelected() {
    return (_selectedProfile == 'moto' || _selectedProfile == 'bus')
        ? 'driving'
        : _selectedProfile;
  }

  Future<void> _appendAvoidanceRoutes(List<LatLng> hazards) async {
    if (_destination == null || _routes.isEmpty) return;
    final start = _startPosition ?? _currentPosition;
    if (start == null) return;

    final referenceRoute = List<LatLng>.from(_routes[0]['points'] as List);

    final allExtra = <Map<String, dynamic>>[];

    for (var i = 0; i < hazards.length && i < 15; i += 3) {
      final subset = hazards.skip(i).take(5).toList();
      if (subset.isEmpty) continue;

      final extra = await RoutingService.getRoutesAvoidingHazards(
        start,
        _destination!,
        waypoints: _waypoints,
        hazards: subset,
        referenceRoute: referenceRoute,
        profile: _osrmProfileForSelected(),
      );

      if (extra.isNotEmpty) {
        allExtra.addAll(extra);
      }

      if (!mounted) return;
    }

    if (allExtra.isEmpty) return;

    final adjusted = allExtra.map((r) {
      return {
        ...r,
        'duration': _adjustDuration(r['duration'], _selectedProfile),
      };
    }).toList();

    final processed = _safetyMode ? SafetyService.filterSafeRoutes(adjusted) : adjusted;
    if (processed.isEmpty) return;

    final merged = <Map<String, dynamic>>[];
    for (final route in [..._routes, ...processed]) {
      if (!RoutingService.isSimilarToExistingRoute(route, merged)) {
        merged.add(route);
      }
    }

    if (merged.length > _routes.length) {
      setState(() {
        _routes = merged;
        _updateMarkers();
      });
    }
  }

  double _routeQualityScore(double distanceMeters, int problemCount) =>
      distanceMeters + problemCount * _kRouteProblemPenaltyMeters;

  Future<void> _applySelectedRouteIndex(int index) async {
    if (index < 0 || index >= _routes.length) return;
    final rawPts = List<LatLng>.from(_routes[index]['points'] as List);
    final problemCount = await _countTotalProblemsOnRoute(rawPts);
    if (!mounted) return;
    final allAlternativesClean =
        _showRouteAlternatives && (_routeProblemCounts?.every((c) => c == 0) ?? false);
    if (allAlternativesClean && problemCount > 0) {
      _showMessage(
        'Cet itinéraire comporte $problemCount problème${problemCount > 1 ? 's' : ''} de voirie ou signalement. Seuls les itinéraires sans problème sont proposés.',
      );
      return;
    }

    setState(() {
      _selectedRouteIndex = index;
      _routePoints = List<LatLng>.from(_routes[index]['points'] as List);
      _routeDuration = (_routes[index]['duration'] as num).toDouble();
      _routeDistance = (_routes[index]['distance'] as num).toDouble();
      _safetyScore = (_routes[index]['safetyScore'] as num?)?.toDouble() ?? 95.0;
      _updateMarkers();
    });
    await _loadProblemesAlongRoute();
    _fitRoutesOnMap(padding: 70);
  }

  void _fitRoutesOnMap({double padding = 70}) {
    if (!_isMapReady || _routes.isEmpty) return;
    final List<LatLng> allPoints;
    if (_showRouteAlternatives) {
      final visible = _visibleAlternativeRouteIndexes();
      if (visible.isNotEmpty) {
        allPoints = visible.expand(_displayPointsForRoute).toList();
      } else {
        final idx = _selectedRouteIndex.clamp(0, _routes.length - 1);
        allPoints = _displayPointsForRoute(idx);
      }
    } else {
      final idx = _selectedRouteIndex.clamp(0, _routes.length - 1);
      allPoints = List<LatLng>.from(_routes[idx]['points'] as List);
    }
    if (allPoints.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(allPoints);
    if (bounds.northWest.latitude == bounds.southEast.latitude &&
        bounds.northWest.longitude == bounds.southEast.longitude) {
      _mapController.move(bounds.center, 15.0);
      return;
    }
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.all(padding),
          maxZoom: 17.0,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onRouteProblemsScanned({bool forceOnDestinationSearch = false}) async {
    if (!mounted) return;
    if (!_showRoutePreview && !_isNavigating) return;
    if (_showRouteAlternatives) return;
    if (_alternativeRoutePromptOpen) return;
    if (_routePoints.length < 2) return;

    final sig = _routeProblemsSignature();
    if (sig.isEmpty) return;

    if (_isRouteAlertDismissedForCurrentRoute()) return;

    if (!forceOnDestinationSearch && _routeProblemsAlertShownForSignature == sig) {
      return;
    }

    var problemCount =
        _problemesVoirieOnRoute.length + _problemesSignalesOnRoute.length;
    if (problemCount == 0 || forceOnDestinationSearch) {
      problemCount = await _countTotalProblemsOnRoute(_routePoints);
      if (!mounted) return;
    }

    if (!forceOnDestinationSearch && problemCount == 0 && _routes.length < 2) {
      return;
    }

    // Recherche destination : afficher la fenêtre tout de suite, scanner après « Oui ».
    if (forceOnDestinationSearch) {
      _routeProblemsAlertShownForSignature = null;
      await _showAlternativeRoutePromptDialog(problemCount);
      return;
    }

    if (_routes.length < 2) {
      await _ensureExtraAlternativeRoute();
      if (!mounted) return;
    }

    setState(() => _scanningRouteAlternatives = true);

    final counts = <int>[];
    for (var i = 0; i < _routes.length; i++) {
      final pts = List<LatLng>.from(_routes[i]['points'] as List);
      counts.add(await _countTotalProblemsOnRoute(pts));
      if (!mounted) return;
    }

    if (!mounted || _routes.isEmpty) return;

    setState(() {
      _scanningRouteAlternatives = false;
      _routeProblemCounts = counts;
    });

    if (!counts.any((c) => c == 0)) {
      await _appendAvoidanceRoutes(_collectHazardsForAvoidance());
      if (!mounted || _routes.isEmpty) return;
      final extraCounts = <int>[...counts];
      for (var i = counts.length; i < _routes.length; i++) {
        final pts = List<LatLng>.from(_routes[i]['points'] as List);
        extraCounts.add(await _countTotalProblemsOnRoute(pts));
        if (!mounted) return;
      }
      if (!mounted) return;
      setState(() => _routeProblemCounts = extraCounts);
    }

    await _showAlternativeRoutePromptDialog(problemCount);
  }

  Future<void> _showAlternativeRoutePromptDialog(int problemCount) async {
    if (!mounted || _alternativeRoutePromptOpen) return;

    final sig = _routeProblemsSignature();
    if (sig.isEmpty) return;
    if (_routeProblemsAlertShownForSignature == sig) return;

    _alternativeRoutePromptOpen = true;
    _routeProblemsAlertShownForSignature = sig;
    final l10n = context.stringsRead;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.mapRouteProblemsAlertTitle),
        content: Text(
          problemCount > 0
              ? '${l10n.mapRouteProblemsContainsIssues(problemCount)}\n\n${l10n.mapRouteProblemsWantAlt}'
              : l10n.mapRouteProblemsWantAlt,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              _rememberRouteAlertDismissed();
              Navigator.pop(dialogContext);
            },
            child: Text(
              l10n.mapRouteProblemsAlertNo,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(_onAlternativeRouteAccepted());
            },
            child: Text(
              l10n.mapRouteProblemsAlertYes,
              style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _alternativeRoutePromptOpen = false);
    } else {
      _alternativeRoutePromptOpen = false;
    }
  }

  Future<void> _showAlternativeRouteDialogAfterSearch() async {
    if (!mounted) return;
    if (!_showRoutePreview && !_isNavigating) return;
    if (_showRouteAlternatives) return;
    if (_alternativeRoutePromptOpen) return;
    if (_routePoints.length < 2) return;

    final sig = _routeProblemsSignature();
    if (sig.isEmpty) return;

    if (_isRouteAlertDismissedForCurrentRoute()) return;

    final problemCount =
        _problemesVoirieOnRoute.length + _problemesSignalesOnRoute.length;

    debugPrint('Problèmes détectés sur l\'itinéraire: $problemCount');
    debugPrint(
      'Voirie: ${_problemesVoirieOnRoute.length}, Signalements: ${_problemesSignalesOnRoute.length}',
    );

    await _showSearchAlternativeRouteDialog(problemCount);
  }

  Future<void> _showSearchAlternativeRouteDialog(int problemCount) async {
    if (!mounted || _alternativeRoutePromptOpen) return;

    final sig = _routeProblemsSignature();
    if (sig.isEmpty) return;
    if (_routeProblemsAlertShownForSignature == sig) return;

    _alternativeRoutePromptOpen = true;
    _routeProblemsAlertShownForSignature = sig;
    final l10n = context.stringsRead;

    final destConflicts = _voirieSharingDestinationAddress();
    final String dialogMessage;
    if (problemCount > 0) {
      dialogMessage =
          '⚠️ ${l10n.mapRouteProblemsContainsIssues(problemCount)}\n\n'
          '${l10n.mapRouteProblemsWantAlt}\n\n'
          '${destConflicts.length >= 2 ? '📍 ${destConflicts.length} problèmes de voirie sont à la même adresse '
              'que votre destination « $_destinationSearchLabel ».\n'
              'Un itinéraire alternatif passera par d\'autres adresses.\n\n'
              : ''}'
          '💡 L\'itinéraire alternatif évitera les adresses problématiques.';
    } else {
      dialogMessage =
          '🔍 ${l10n.mapRouteProblemsWantAlt}\n\n'
          '💡 Un itinéraire alternatif encore plus sécurisé peut être proposé.\n'
          'Voulez-vous rechercher un itinéraire sans aucun problème de voirie ?';
    }

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              problemCount > 0 ? Icons.warning_amber_rounded : Icons.security_rounded,
              color: problemCount > 0 ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                problemCount > 0 ? l10n.mapRouteProblemsAlertTitle : 'Itinéraire plus sécurisé',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          dialogMessage,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              _rememberRouteAlertDismissed();
              Navigator.pop(dialogContext);
            },
            child: Text(
              l10n.mapRouteProblemsAlertNo,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(_searchAndDisplayCleanRoutes());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.mapRouteProblemsAlertYes,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _alternativeRoutePromptOpen = false);
    } else {
      _alternativeRoutePromptOpen = false;
    }
  }

  /// Réutilise les itinéraires OSRM déjà chargés si l'un est plus sûr que l'initial.
  Future<bool> _tryQuickAlternativeFromExistingRoutes() async {
    if (_routes.length < 2) return false;

    await _ensureRouteProblemCounts();
    if (!mounted) return false;

    final counts = _routeProblemCounts;
    if (counts == null || counts.isEmpty) return false;

    final mainCount = counts[0];
    var indexes = _cleanRouteIndexesFromCounts(counts);
    if (indexes.isEmpty) {
      indexes = _bestSaferAlternativeRouteIndexes(counts);
      if (indexes.isEmpty || counts[indexes.first] >= mainCount) {
        return false;
      }
    }

    final routes = <Map<String, dynamic>>[];
    final routeCounts = <int>[];
    for (final i in indexes.take(_kMaxCleanAlternativeRoutes)) {
      if (i < 0 || i >= _routes.length || !_isValidRouteMap(_routes[i])) continue;
      routes.add({
        ..._routes[i],
        'duration': _adjustDuration(_routes[i]['duration'], _selectedProfile),
        'safetyScore': _safetyScoreFromProblemCount(counts[i]),
      });
      routeCounts.add(counts[i]);
    }
    if (routes.isEmpty) return false;
    if (routes.length < 2) {
      // Continue vers la recherche complète pour essayer d'afficher 2-3 alternatives.
      return false;
    }

    final allClean = routeCounts.every((c) => c == 0);
    _applyAlternativeRoutesToMap(
      routes,
      problemCounts: routeCounts,
      allClean: allClean,
    );
    _showMessage(
      allClean
          ? (routes.length == 1
              ? '✅ Itinéraire alternatif sans problème affiché sur la carte !'
              : '✅ ${routes.length} itinéraires alternatifs sans problème disponibles !')
          : '✅ Itinéraire alternatif plus sûr affiché sur la carte.',
    );
    return true;
  }

  Future<void> _searchAndDisplayCleanRoutes() async {
    if (!mounted || (!_showRoutePreview && !_isNavigating)) return;

    setState(() => _scanningRouteAlternatives = true);

    _showMessage('🔍 Recherche d\'itinéraires alternatifs plus sûrs...');

    try {
      _savedRoutesBeforeCleanAlts ??= List<Map<String, dynamic>>.from(_routes);
      _snapshotMainRouteProblems();
      final referenceRoute = _referenceRouteForCleanSearch();

      if (_routes.length < 2) {
        await _ensureExtraAlternativeRoute();
      }
      if (await _tryQuickAlternativeFromExistingRoutes()) return;

      final allHazards = _collectAllHazardsForCleanSearch(referenceRoute);
      var mainProblemCount =
          _savedMainRouteVoirie.length + _savedMainRouteSignales.length;
      if (mainProblemCount == 0 && referenceRoute.length >= 2) {
        mainProblemCount = await _countTotalProblemsOnRoute(referenceRoute);
      }
      if (!mounted) return;

      debugPrint(
        'Recherche alternative: $mainProblemCount problèmes sur l\'itinéraire initial, '
        '${allHazards.length} zones à éviter',
      );

      var ranked = await _collectRankedAlternativeRoutes(
        referenceRoute: referenceRoute,
        hazards: allHazards,
      );

      if (ranked.isEmpty || ranked.every((r) => r.count >= mainProblemCount)) {
        _showMessage('🔄 Recherche élargie d\'itinéraires alternatifs...');

        if (_routes.length < 2) {
          await _ensureExtraAlternativeRoute();
        }
        if (allHazards.isNotEmpty) {
          await _appendAvoidanceRoutes(allHazards);
        }
        if (!mounted) return;

        final extendedHazards = _collectExtendedHazardsForAvoidance();
        if (extendedHazards.isNotEmpty) {
          await _appendAvoidanceRoutes(extendedHazards);
        }
        if (!mounted) return;

        ranked = await _collectRankedAlternativeRoutes(
          referenceRoute: referenceRoute,
          hazards: [...allHazards, ...extendedHazards],
        );
      }

      if (!mounted) return;

      final picked = _pickBestRankedAlternatives(ranked, mainProblemCount);
      if (picked.isEmpty) {
        _showMessage(
          '❌ Aucun itinéraire alternatif trouvé. L\'itinéraire initial reste affiché.',
        );
        return;
      }

      final routes = <Map<String, dynamic>>[];
      final counts = <int>[];
      final mainRouteMap =
          _savedRoutesBeforeCleanAlts?.isNotEmpty == true
              ? _savedRoutesBeforeCleanAlts!.first
              : {
                  'points': List<LatLng>.from(referenceRoute),
                  'distance': _routeDistance ?? 0.0,
                  'duration': _routeDuration ?? 0.0,
                  'safetyScore': _safetyScore,
                };
      for (final pick in picked.take(_kMaxCleanAlternativeRoutes)) {
        if (!_isValidRouteMap(pick.routeMap)) continue;
        if (RoutingService.isSimilarToExistingRoute(pick.routeMap, [mainRouteMap])) {
          continue;
        }
        routes.add(Map<String, dynamic>.from(pick.routeMap));
        counts.add(pick.count);
      }
      if (routes.length < 2 && _destination != null) {
        final start = _startPosition ?? _currentPosition;
        if (start != null && referenceRoute.length >= 2) {
          final detours = RoutingService.detourWaypointsAlongRoute(referenceRoute);
          for (final detour in detours.take(8)) {
            if (routes.length >= _kMaxCleanAlternativeRoutes) break;
            final generated = await RoutingService.getRoutes(
              start,
              _destination!,
              waypoints: [..._waypoints, detour],
              profile: _osrmProfileForSelected(),
            );
            if (!mounted) return;
            for (final candidate in generated) {
              if (routes.length >= _kMaxCleanAlternativeRoutes) break;
              if (!_isValidRouteMap(candidate)) continue;
              if (RoutingService.isSimilarToExistingRoute(candidate, [mainRouteMap])) continue;
              if (_isRouteAlreadyInList(candidate, routes)) continue;
              final pts = List<LatLng>.from(candidate['points'] as List);
              final c = await _countTotalProblemsOnRoute(pts);
              if (!mounted) return;
              routes.add({
                ...candidate,
                'duration': _adjustDuration(candidate['duration'], _selectedProfile),
                'safetyScore': _safetyScoreFromProblemCount(c),
              });
              counts.add(c);
            }
          }
        }
      }
      if (routes.length < 2) {
        // Dernier fallback: compléter avec les routes déjà chargées pour toujours afficher 2-3 cartes.
        for (final route in _routes) {
          if (routes.length >= _kMaxCleanAlternativeRoutes) break;
          if (!_isValidRouteMap(route)) continue;
          if (RoutingService.isSimilarToExistingRoute(route, [mainRouteMap])) continue;
          if (_isRouteAlreadyInList(route, routes)) continue;
          final pts = List<LatLng>.from(route['points'] as List);
          final c = await _countTotalProblemsOnRoute(pts);
          if (!mounted) return;
          routes.add({
            ...route,
            'duration': _adjustDuration(route['duration'], _selectedProfile),
            'safetyScore': _safetyScoreFromProblemCount(c),
          });
          counts.add(c);
        }
      }
      if (routes.isEmpty) {
        _showMessage(
          '❌ Aucun itinéraire alternatif valide trouvé. L\'itinéraire initial reste affiché.',
        );
        return;
      }
      if (routes.length < 2) {
        _showMessage(
          '❌ Impossible de trouver 2 itinéraires alternatifs différents pour cette destination.',
        );
        return;
      }
      final allClean = counts.every((c) => c == 0);
      final bestPick = picked.first;
      final avoidsDest = picked.every((e) => e.destConflict == 0);
      final destConflicts = _voirieSharingDestinationAddress();
      final mainDestConflict = _countDestinationAddressVoirieOnRoute(referenceRoute);

      _applyAlternativeRoutesToMap(
        routes,
        problemCounts: counts,
        allClean: allClean,
      );

      if (allClean && avoidsDest) {
        _showMessage(
          routes.length == 1
              ? '✅ Itinéraire alternatif affiché via une autre adresse, sans problème de voirie !'
              : '✅ ${routes.length} itinéraires alternatifs sans problème disponibles !',
        );
      } else if (destConflicts.length >= 2 &&
          bestPick.destConflict < mainDestConflict) {
        _showMessage(
          '✅ Itinéraire alternatif affiché en contournant l\'adresse « $_destinationSearchLabel » '
          '(${bestPick.destConflict} problème${bestPick.destConflict > 1 ? 's' : ''} '
          'vs $mainDestConflict sur l\'initial).',
        );
      } else if (allClean) {
        _showMessage(
          routes.length == 1
              ? '✅ Itinéraire alternatif SANS problème affiché sur la carte !'
              : '✅ ${routes.length} itinéraires alternatifs SANS problème disponibles !',
        );
      } else {
        final saved = mainProblemCount - counts.first;
        _showMessage(
          saved > 0
              ? '✅ Itinéraire alternatif affiché (${counts.first} problème${counts.first > 1 ? 's' : ''} vs $mainProblemCount sur l\'initial).'
              : '✅ Itinéraire alternatif plus sûr affiché sur la carte.',
        );
      }
    } catch (e, st) {
      debugPrint('Erreur recherche routes propres: $e\n$st');
      _showMessage('❌ Erreur lors de la recherche: $e');
      if (_savedRoutesBeforeCleanAlts != null &&
          _savedRoutesBeforeCleanAlts!.isNotEmpty &&
          _validatedRouteMaps(_savedRoutesBeforeCleanAlts!).isNotEmpty) {
        setState(() {
          _routes = List<Map<String, dynamic>>.from(_savedRoutesBeforeCleanAlts!);
          _showRouteAlternatives = false;
        });
        _applyMainRouteOnly();
        _updateMarkers();
      }
    } finally {
      if (mounted) {
        setState(() => _scanningRouteAlternatives = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _generateCleanRoutesAvoidingHazards(
    List<LatLng> hazards, {
    List<LatLng>? referenceRoute,
  }) async {
    final start = _startPosition ?? _currentPosition;
    if (_destination == null || start == null) return [];

    final ref = referenceRoute ??
        (_savedMainRoutePoints.length >= 2
            ? _savedMainRoutePoints
            : _routePoints);
    final allCleanRoutes = <Map<String, dynamic>>[];

    if (hazards.isEmpty && ref.length >= 2) {
      final detourRoutes = await RoutingService.getRoutesAvoidingHazards(
        start,
        _destination!,
        waypoints: _waypoints,
        hazards: const [],
        referenceRoute: ref,
        profile: _osrmProfileForSelected(),
      );
      for (final route in detourRoutes) {
        final routePoints = List<LatLng>.from(route['points'] as List);
        final mainRoute = _savedRoutesBeforeCleanAlts?.isNotEmpty == true
            ? _savedRoutesBeforeCleanAlts!.first
            : null;
        if (mainRoute != null &&
            RoutingService.isSimilarToExistingRoute(route, [mainRoute])) {
          continue;
        }
        final problemCount = await _countTotalProblemsOnRoute(routePoints);
        if (problemCount == 0 && !_isRouteAlreadyInList(route, allCleanRoutes)) {
          allCleanRoutes.add({
            ...route,
            'duration': _adjustDuration(route['duration'], _selectedProfile),
            'safetyScore': 100.0,
          });
        }
        if (!mounted) return [];
      }
    }

    for (var step = 0; step < hazards.length; step += 3) {
      final hazardSubset = hazards.skip(step).take(6).toList();
      if (hazardSubset.isEmpty) continue;

      try {
        final routes = await RoutingService.getRoutesAvoidingHazards(
          start,
          _destination!,
          waypoints: _waypoints,
          hazards: hazardSubset,
          referenceRoute: ref,
          profile: _osrmProfileForSelected(),
        );

        for (final route in routes) {
          final routePoints = List<LatLng>.from(route['points'] as List);
          final problemCount = await _countTotalProblemsOnRoute(routePoints);
          final mainRoute = _savedRoutesBeforeCleanAlts?.isNotEmpty == true
              ? _savedRoutesBeforeCleanAlts!.first
              : null;
          if (mainRoute != null &&
              RoutingService.isSimilarToExistingRoute(route, [mainRoute])) {
            continue;
          }

          if (problemCount == 0 && !_isRouteAlreadyInList(route, allCleanRoutes)) {
            allCleanRoutes.add({
              ...route,
              'duration': _adjustDuration(route['duration'], _selectedProfile),
              'safetyScore': 100.0,
            });
          }
        }
      } catch (e) {
        debugPrint('Erreur génération route: $e');
      }

      if (!mounted) return [];
    }

    allCleanRoutes.sort((a, b) {
      final distA = (a['distance'] as num).toDouble();
      final distB = (b['distance'] as num).toDouble();
      return distA.compareTo(distB);
    });

    if (allCleanRoutes.length > _kMaxCleanAlternativeRoutes) {
      return allCleanRoutes.sublist(0, _kMaxCleanAlternativeRoutes);
    }

    return allCleanRoutes;
  }

  bool _isRouteAlreadyInList(
    Map<String, dynamic> route,
    List<Map<String, dynamic>> list,
  ) {
    if (RoutingService.isSimilarToExistingRoute(route, list)) return true;

    final routePoints = List<LatLng>.from(route['points'] as List);
    if (routePoints.length < 5) return false;

    for (final existing in list) {
      final existingPoints = List<LatLng>.from(existing['points'] as List);
      if (existingPoints.length < 5) continue;

      final startDist = Geolocator.distanceBetween(
        routePoints.first.latitude,
        routePoints.first.longitude,
        existingPoints.first.latitude,
        existingPoints.first.longitude,
      );
      final endDist = Geolocator.distanceBetween(
        routePoints.last.latitude,
        routePoints.last.longitude,
        existingPoints.last.latitude,
        existingPoints.last.longitude,
      );

      if (startDist < 50 && endDist < 50) return true;
    }

    return false;
  }

  Future<void> _onAlternativeRouteAccepted() async {
    await _searchAndDisplayCleanRoutes();
  }

  Future<void> _tryApplyCleanAlternatives() async {
    if (!mounted || (!_showRoutePreview && !_isNavigating) || _showRouteAlternatives) return;

    var counts = _routeProblemCounts ?? await _countAllRoutesProblems();
    var cleanIndexes = _cleanRouteIndexesFromCounts(counts);

    if (cleanIndexes.isEmpty) {
      final cleanIdx = await _searchCleanAlternativeRouteIndex();
      if (!mounted) return;
      counts = _routeProblemCounts ?? counts;
      cleanIndexes = _cleanRouteIndexesFromCounts(counts);
      if (cleanIdx != null && !cleanIndexes.contains(cleanIdx)) {
        cleanIndexes = [cleanIdx, ...cleanIndexes];
        if (cleanIndexes.length > _kMaxCleanAlternativeRoutes) {
          cleanIndexes = cleanIndexes.sublist(0, _kMaxCleanAlternativeRoutes);
        }
      }
    }

    if (cleanIndexes.isNotEmpty) {
      await _applyCleanAlternativeRoutes(cleanIndexes: cleanIndexes);
    }
  }

  Future<void> _ensureExtraAlternativeRoute() async {
    if (_routes.length >= 2 || _destination == null) return;
    final start = _startPosition ?? _currentPosition;
    if (start == null) return;

    final osrmProfile = (_selectedProfile == 'moto' || _selectedProfile == 'bus')
        ? 'driving'
        : _selectedProfile;

    final extra = await RoutingService.getRoutesWithAlternatives(
      start,
      _destination!,
      waypoints: _waypoints,
      profile: osrmProfile,
    );
    if (!mounted || extra.length < 2) return;

    final processed = _safetyMode ? SafetyService.filterSafeRoutes(extra) : extra;
    if (processed.length < 2) return;

    setState(() {
      _routes = processed;
      _updateMarkers();
    });
  }

  Future<void> _applyCleanAlternativeRoutes({
    List<int>? cleanIndexes,
    bool requireZeroProblems = true,
  }) async {
    if (!mounted) return;

    setState(() {
      _showRouteAlternatives = true;
      _scanningRouteAlternatives = true;
      _rememberRouteAlertDismissed();
    });

    try {
      if (_routes.length < 2) {
        await _ensureExtraAlternativeRoute();
      }
      if (!mounted || _routes.isEmpty) return;

      await _ensureRouteProblemCounts();
      if (!mounted) return;

      var counts = _routeProblemCounts ?? await _countAllRoutesProblems();
      var indexes = cleanIndexes ?? _cleanRouteIndexesFromCounts(counts);

      if (indexes.isEmpty) {
        final cleanIdx = await _searchCleanAlternativeRouteIndex();
        if (!mounted || _routes.isEmpty) return;
        counts = _routeProblemCounts ?? counts;
        indexes = _cleanRouteIndexesFromCounts(counts);
        if (cleanIdx != null && !indexes.contains(cleanIdx)) {
          indexes = [cleanIdx, ...indexes];
          if (indexes.length > _kMaxCleanAlternativeRoutes) {
            indexes = indexes.sublist(0, _kMaxCleanAlternativeRoutes);
          }
        }
      }

      if (indexes.isEmpty) {
        indexes = _bestSaferAlternativeRouteIndexes(counts);
        requireZeroProblems = false;
      }

      if (indexes.isEmpty) {
        setState(() => _showRouteAlternatives = false);
        return;
      }

      _savedRoutesBeforeCleanAlts ??= List<Map<String, dynamic>>.from(_routes);
      _snapshotMainRouteProblems();

      if (requireZeroProblems) {
        for (final idx in List<int>.from(indexes)) {
          final verifyCount = await _countTotalProblemsOnRoute(
            List<LatLng>.from(_routes[idx]['points'] as List),
          );
          if (verifyCount > 0) {
            indexes.remove(idx);
          }
          if (!mounted) return;
        }
      }

      if (indexes.isEmpty) {
        indexes = _bestSaferAlternativeRouteIndexes(counts);
      }

      if (indexes.isEmpty) {
        setState(() => _showRouteAlternatives = false);
        return;
      }

      if (indexes.length > _kMaxCleanAlternativeRoutes) {
        indexes = indexes.sublist(0, _kMaxCleanAlternativeRoutes);
      }

      _pruneRoutesToCleanOnly(indexes);
      _updateMarkers();
      _fitRoutesOnMap(padding: 70);

      if (mounted) {
        final n = _routes.length;
        final allClean = _routeProblemCounts?.every((c) => c == 0) ?? false;
        _showMessage(
          allClean
              ? (n <= 1
                  ? 'Itinéraire sans problème de voirie ni signalement affiché.'
                  : '$n itinéraires sans problème affichés. Choisissez celui qui vous convient.')
              : (n <= 1
                  ? 'Itinéraire alternatif plus sûr affiché sur la carte.'
                  : '$n itinéraires alternatifs affichés (du plus sûr au moins sûr).'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scanningRouteAlternatives = false);
      }
    }
  }

  void _restoreMainRoute() {
    final saved = _savedRoutesBeforeCleanAlts;
    if (saved == null || saved.isEmpty) {
      setState(() {
        _showRouteAlternatives = false;
        _applyMainRouteOnly();
      });
    } else {
      setState(() {
        _routes = List<Map<String, dynamic>>.from(saved);
        _showRouteAlternatives = false;
        _selectedRouteIndex = 0;
        _applyMainRouteOnly();
        _problemesVoirieOnRoute = List<ProblemeVoirie>.from(_savedMainRouteVoirie);
        _problemesSignalesOnRoute = List<ProblemeSignaleMapItem>.from(_savedMainRouteSignales);
        _routeProblemCounts = null;
        _recommendedAlternativeIndex = null;
      });
    }
    _savedRoutesBeforeCleanAlts = null;
    _updateMarkers();
    _fitRoutesOnMap();
    if (_routePoints.length >= 2) {
      unawaited(_loadProblemesAlongRoute());
    }
  }

  int? _indexOfFirstZeroProblemRouteFromCounts(List<int> counts) {
    return _pickShortestZeroProblemIndex(counts);
  }

  void _declineAlternativeRoute() {
    _rememberRouteAlertDismissed();
    _restoreMainRoute();
  }

  // ============================================================================
  // MARQUEURS ET AFFICHAGE
  // ============================================================================

  void _updateMarkers() {
    _markers.clear();

    if (_currentPosition != null) {
      final markerSize = _isNavigating ? 88.0 : 60.0;
      _markers.add(
        Marker(
          point: _currentPosition!,
          width: markerSize,
          height: markerSize,
          alignment: Alignment.center,
          child: _buildUserMarker(),
        ),
      );
    }

    final routeStart = _routePoints.isNotEmpty ? _routePoints.first : null;
    final routeEnd = _routePoints.length >= 2 ? _routePoints.last : null;
    final showRouteEndpoints = _hasVisibleRoute();

    if (_startPosition != null &&
        (!showRouteEndpoints ||
            routeStart == null ||
            !_pointsNear(_startPosition!, routeStart))) {
      _markers.add(
        Marker(
          point: _startPosition!,
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: _buildPin(
            color: const Color(0xFF4285F4),
            icon: Icons.person_pin_circle,
          ),
        ),
      );
    }

    if (_destination != null &&
        (!showRouteEndpoints ||
            routeEnd == null ||
            !_pointsNear(_destination!, routeEnd))) {
      _markers.add(
        Marker(
          point: _destination!,
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: _buildPin(color: const Color(0xFFEA4335), icon: Icons.place),
        ),
      );
    }

    _addRouteLineEndpointMarkers();

    for (var wp in _waypoints) {
      _markers.add(
        Marker(
          point: wp,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: _buildPin(
            color: Colors.orange,
            icon: Icons.add_location_alt,
            size: 20,
          ),
        ),
      );
    }

    for (var danger in _nearbyDangers) {
      _markers.add(
        Marker(
          point: danger,
          width: 50,
          height: 50,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 30,
            ),
          ),
        ),
      );
    }

    final voirieForMap = _voirieForMapDisplay();
    final signalesForMap = _signalesForMapDisplay();
    final problemClusters = MapProblemClusterService.cluster(
      voirie: voirieForMap,
      signales: signalesForMap,
    );
    for (final cluster in problemClusters) {
      final markerSize = cluster.totalCount > 1 ? 34.0 : 28.0;
      _markers.add(
        Marker(
          point: cluster.location,
          width: markerSize,
          height: markerSize,
          alignment: Alignment.center,
          child: GroupedMapProblemMarker(
            icon: _clusterMarkerIcon(cluster),
            color: _clusterMarkerColor(cluster),
            count: cluster.totalCount,
            isSelected: cluster.matchesSelection(
              selectedCluster: _selectedMapCluster,
              selectedVoirie: _selectedProbleme,
              selectedSignale: _selectedSignale,
            ),
            onTap: () => _onMapClusterTap(cluster),
          ),
        ),
      );
    }

    if (_showTrafficJams && _trafficJams.isNotEmpty) {
      for (final jam in _trafficJams) {
        _markers.add(
          Marker(
            point: LatLng(jam.latitude, jam.longitude),
            width: 52,
            height: 52,
            child: TrafficJamMarker(
              jam: jam,
              onTap: () => _showTrafficJamDetails(jam),
            ),
          ),
        );
      }
    }

    for (final accident in _accidentReports) {
      _markers.add(
        Marker(
          point: LatLng(accident.latitude, accident.longitude),
          width: 60,
          height: 60,
          child: _buildAccidentMarker(accident),
        ),
      );
    }
  }

  Widget _buildPin({
    required Color color,
    required IconData icon,
    double size = 26,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.location_on, color: color, size: 48),
        Positioned(
          top: 6,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: size * 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    if (_showFlashOnStart) {
      return AnimatedLocationMarker(
        isFlashing: true,
        onAnimationComplete: () {
          if (mounted) {
            setState(() => _showFlashOnStart = false);
            _updateMarkers();
          }
        },
      );
    }

    if (_isNavigating) {
      return const PulsingNavigationIndicator(isActive: true, size: 48);
    }

    return const PulsatingLocationIndicator(
      radius: 18,
      color: Color(0xFF4285F4),
    );
  }

  Widget _buildAccidentMarker(AccidentReport accident) {
    final isConfirmed = accident.isConfirmed;
    final severity = accident.reportCount;

    return GestureDetector(
      onTap: () => _showAccidentDetails(accident),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (isConfirmed)
                Container(
                  width: 50 * _pulseController.value,
                  height: 50 * _pulseController.value,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.4 * (1 - _pulseController.value)),
                    shape: BoxShape.circle,
                  ),
                ),
              Icon(
                Icons.car_crash,
                color: Colors.red,
                size: isConfirmed ? 34 : 30,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              if (isConfirmed)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 11),
                  ),
                ),
              if (severity > 1)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$severity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showTrafficJamDetails(TrafficJamModel jam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrafficJamDetailsSheet(jam: jam),
    );
  }

  void _showAccidentDetails(AccidentReport accident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.car_crash, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accident',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Signalé ${_getTimeAgo(accident.createdAt)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (accident.isConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CONFIRMÉ',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${accident.reportCount} signalement${accident.reportCount > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (accident.reportCount >= 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Vérifié',
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Expire ${_getTimeUntilExpiry(accident.expiresAt)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(
                        LatLng(accident.latitude, accident.longitude),
                        17.0,
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Voir sur la carte'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _confirmAccident(accident);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAccident(AccidentReport accident) async {
    if (_currentPosition == null) return;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      accident.latitude,
      accident.longitude,
    );
    if (distance > 500) {
      _showMessage('Vous êtes trop loin (${distance.round()}m) pour confirmer cet accident.');
      return;
    }
    try {
      final result = await AccidentReportService.reportAccident(
        latitude: accident.latitude,
        longitude: accident.longitude,
        userId: context.read<AuthProvider>().currentUser?.id,
      );
      _showMessage((result['message'] ?? 'Accident confirmé !').toString());
      await _loadAccidents();
    } catch (e) {
      _showMessage('Erreur: $e');
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  String _getTimeUntilExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 'bientôt';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inMinutes < 1) return 'dans quelques secondes';
    if (diff.inMinutes < 60) return 'dans ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'dans ${diff.inHours} h';
    return 'dans ${diff.inDays} j';
  }

  // ============================================================================
  // TYPES DE PROBLÈMES
  // ============================================================================

  IconData _iconForSignaleType(String type) {
    switch (type) {
      case 'accident':
        return Icons.car_crash_rounded;
      case 'embouteillage':
        return Icons.traffic_rounded;
      case 'police':
        return Icons.local_police_rounded;
      case 'route_fermee':
        return Icons.block_rounded;
      case 'mauvais_temps':
        return Icons.thunderstorm_rounded;
      case 'probleme_carte':
        return Icons.map_outlined;
      case 'nid_de_poule':
        return Icons.circle_outlined;
      case 'travaux':
        return Icons.construction_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _colorForSignaleType(String type) {
    switch (type) {
      case 'accident':
      case 'embouteillage':
      case 'route_fermee':
        return const Color(0xFFEA4335);
      case 'police':
        return const Color(0xFF1A1A1A);
      case 'mauvais_temps':
        return const Color(0xFF334155);
      case 'probleme_carte':
        return const Color(0xFF7C3AED);
      case 'nid_de_poule':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _labelSignaleTypeFr(String type) {
    switch (type) {
      case 'police':
        return 'Police';
      case 'route_fermee':
        return 'Route fermée';
      case 'travaux':
        return 'Travaux';
      case 'nid_de_poule':
        return 'Nid-de-poule';
      case 'embouteillage':
        return 'Embouteillage';
      case 'accident':
        return 'Accident';
      case 'mauvais_temps':
        return 'Mauvais temps';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  Color _getProblemeColor(ProblemeVoirie probleme) {
    if (probleme.problemType == 'pothole') return Colors.red;
    if (probleme.riskScore > 40) return Colors.orange;
    return Colors.green;
  }

  Color _getProblemeRiskColor(double risk) {
    if (risk > 50) return Colors.red;
    if (risk > 30) return Colors.orange;
    return Colors.green;
  }

  Color _getProblemeSeverityColor(String severity) {
    switch (severity) {
      case 'Élevée':
        return Colors.red;
      case 'Moyenne':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getProblemePriorityColor(String? priority) {
    switch (priority) {
      case 'P1':
        return Colors.red;
      case 'P2':
        return Colors.orange;
      case 'P3':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getProblemeStatusColor(String status) {
    switch (status) {
      case 'En cours':
        return Colors.blue;
      case 'Résolu':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatProblemeDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  IconData _clusterMarkerIcon(MapProblemCluster cluster) {
    final topVoirie = cluster.highestRiskVoirie;
    if (topVoirie != null) {
      switch (topVoirie.problemType) {
        case 'pothole':
          return Icons.blur_circular_rounded;
        case 'crack':
          return Icons.view_week_rounded;
        default:
          return Icons.warning_amber_rounded;
      }
    }
    if (cluster.signales.isNotEmpty) {
      return _iconForSignaleType(cluster.signales.first.type);
    }
    return Icons.warning_amber_rounded;
  }

  Color _clusterMarkerColor(MapProblemCluster cluster) {
    final topVoirie = cluster.highestRiskVoirie;
    if (topVoirie != null) return _getProblemeColor(topVoirie);
    if (cluster.signales.isNotEmpty) {
      return _colorForSignaleType(cluster.signales.first.type);
    }
    return Colors.orange;
  }

  void _onMapClusterTap(MapProblemCluster cluster) {
    _mapController.move(cluster.location, 17.0);
    if (cluster.totalCount == 1) {
      if (cluster.voirie.isNotEmpty) {
        _openVoirieDetail(cluster.voirie.first);
      } else if (cluster.signales.isNotEmpty) {
        _openSignaleDetail(cluster.signales.first);
      }
      return;
    }
    setState(() {
      _selectedMapCluster = cluster;
      _showMapClusterDetails = true;
      _showProblemeDetails = false;
      _showSignaleDetails = false;
      _selectedProbleme = null;
      _selectedSignale = null;
    });
  }

  void _openVoirieDetail(ProblemeVoirie probleme) {
    setState(() {
      _selectedProbleme = probleme;
      _showProblemeDetails = true;
      _showSignaleDetails = false;
      _showMapClusterDetails = false;
      _selectedSignale = null;
      _selectedMapCluster = null;
    });
  }

  void _openSignaleDetail(ProblemeSignaleMapItem item) {
    setState(() {
      _selectedSignale = item;
      _showSignaleDetails = true;
      _showProblemeDetails = false;
      _showMapClusterDetails = false;
      _selectedProbleme = null;
      _selectedMapCluster = null;
    });
  }

  Color _getRouteColor(int index) {
    if (_showRouteAlternatives) {
      // Couleurs fixes pour les alternatives: 1 vert, 2 bleu, 3 orange.
      const alternativePalette = [
        Color(0xFF0F9D8A), // alternatif 1
        Color(0xFF1565C0), // alternatif 2
        Color(0xFFE65100), // alternatif 3
      ];
      return alternativePalette[index % alternativePalette.length];
    }

    const palette = [
      Color(0xFF0F9D8A),
      Color(0xFF1565C0),
      Color(0xFFE65100),
      Color(0xFF7B1FA2),
      Color(0xFFC62828),
    ];
    if (!_safetyMode) {
      const altPalette = [
        Color(0xFF2E7D32),
        Color(0xFF1565C0),
        Color(0xFFE65100),
        Color(0xFF6A1B9A),
      ];
      return altPalette[index % altPalette.length];
    }
    return palette[index % palette.length];
  }

  // ============================================================================
  // ACTIONS UI
  // ============================================================================

  void _zoomToTunisia() {
    if (!_isMapReady || _hasCenteredOnUserGps) return;
    final bounds = LatLngBounds.fromPoints([_tunisiaSouthWest, _tunisiaNorthEast]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20)),
    );
  }

  void _centerMapOnUser({double? zoom}) {
    if (!_isMapReady || _currentPosition == null) return;
    final zoomLevel = zoom ?? (_isNavigating ? 17.0 : 16.0);
    try {
      _mapController.move(_currentPosition!, zoomLevel);
    } catch (_) {}
  }

  void _tryCenterMapOnUser({double zoom = 15.0}) {
    if (!_isFollowingUser || _currentPosition == null) return;
    _centerMapOnUser(zoom: zoom);
    _hasCenteredOnUserGps = true;
  }

  void _goToMyLocation() {
    if (_currentPosition == null) return;
    setState(() => _isFollowingUser = true);
    _tryCenterMapOnUser(zoom: 15.0);
  }

  void _openSearchPage(bool isFrom) async {
    final s = context.stringsRead;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SearchLocationPage(
          hintText: s.mapSearchQuery,
          initialQuery: _searchController.text,
          historyType: 'destination',
        ),
      ),
    );

    if (result != null && mounted) {
      final lat = result['lat'];
      final lon = result['lon'];
      final name = result['display_name'];
      if (lat != null && lon != null) {
        final target = LatLng(lat, lon);
        setState(() {
          _searchController.text = name;
          _destination = target;
          _isNavigating = false;
          _routePoints = [];
          _problemesVoirieOnRoute = [];
          _problemesSignalesOnRoute = [];
          _routeProblemsAlertShownForSignature = null;
          _selectedSignale = null;
          _showSignaleDetails = false;
        });
        _mapController.move(target, 15.0);
        unawaited(_loadProblemesAroundDestination());
        if (_problemesVoirie.isEmpty) unawaited(_loadProblemesVoirie());
        if (_problemesSignales.isEmpty) unawaited(_loadProblemesSignales());
        _updateMarkers();
        await _calculateRoute(target, promptAlternativeRoute: true);
      }
    }
  }

  void _openDirectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NavigationDirectionSheet(
        onStartNavigation: (dest, {start, profile}) => _calculateRoute(
          dest,
          start: start,
          profile: profile,
          promptAlternativeRoute: true,
        ),
        currentProfile: _selectedProfile,
        duration: _routeDuration,
        distance: _routeDistance,
        isNavigating: _isNavigating,
        waypoints: _waypoints,
        onWaypointsChanged: (newWaypoints) {
          setState(() {
            _waypoints = newWaypoints;
            _updateMarkers();
          });
          if (_destination != null) _calculateRoute(_destination!);
        },
      ),
    );
  }

  void _openAddWaypointSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _AddWaypointSheet(
        onWaypointAdded: (point, name) {
          setState(() {
            _waypoints.add(point);
          });
          _showMessage('$name ${context.stringsRead.mapWaypointAdded}');
          if (_destination != null) {
            _calculateRoute(_destination!);
          }
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  void _showReportBottomSheet() {
    final s = context.stringsRead;
    const sheetBg = Color(0xFF2C2C2E);
    const circleBg = Color(0xFF3A3A3C);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: const BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.mapReportTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 26),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildReportItem(s.mapReportTrafficJam, Icons.traffic, const Color(0xFFFF6B6B), circleBg,
                        onTap: () {
                      Navigator.pop(context);
                      _reportTrafficJam();
                    }),
                    _buildReportItem(s.mapReportPolice, Icons.local_police_rounded, const Color(0xFF4285F4), circleBg),
                    _buildReportItem(s.mapReportAccident, Icons.car_crash_rounded, const Color(0xFFEA4335), circleBg),
                    _buildReportItem(s.mapReportDanger, Icons.warning_amber_rounded, const Color(0xFFFFC107), circleBg),
                    _buildReportItem(s.mapReportRoadClosed, Icons.block, const Color(0xFFEF5350), circleBg),
                    _buildReportItem(s.mapReportBadWeather, Icons.thunderstorm, const Color(0xFF78909C), circleBg),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportItem(
    String label,
    IconData icon,
    Color iconColor,
    Color circleBg, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.pop(context);
        _showMessage("${context.stringsRead.mapReportSent} $label");
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    double latVal, lonVal;
    final name = suggestion['display_name'] ?? "";
    try {
      final lat = suggestion['lat'];
      final lon = suggestion['lon'];
      latVal = (lat is String) ? double.parse(lat) : (lat as num).toDouble();
      lonVal = (lon is String) ? double.parse(lon) : (lon as num).toDouble();
      if (latVal.isNaN || lonVal.isNaN || latVal.isInfinite || lonVal.isInfinite) {
        throw Exception("Coordonnées invalides");
      }
      SearchHistoryService.addSearch(suggestion, 'destination');
    } catch (e) {
      _showMessage(context.stringsRead.mapInvalidCoordinates);
      return;
    }
    final target = LatLng(latVal, lonVal);
    setState(() {
      _suggestions = [];
      _searchController.text = name;
      _destination = target;
      _startPosition = null;
      FocusScope.of(context).unfocus();
    });
    _mapController.move(target, 15.0);
    unawaited(_loadProblemesAroundDestination());
    if (_problemesVoirie.isEmpty) unawaited(_loadProblemesVoirie());
    if (_problemesSignales.isEmpty) unawaited(_loadProblemesSignales());
    _calculateRoute(target, promptAlternativeRoute: true);
    _updateMarkers();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDialog(BuildContext ctx, String title, String message, VoidCallback onConfirm) {
    final s = ctx.stringsRead;
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.no, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(s.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _focusRouteProblemRow(_RouteProblemRow row) {
    if (row.voirie != null) {
      final p = row.voirie!;
      setState(() {
        _selectedProbleme = p;
        _showProblemeDetails = true;
        _showSignaleDetails = false;
        _selectedSignale = null;
      });
      _mapController.move(p.location, 17.0);
      return;
    }
    if (row.signale != null) {
      final s = row.signale!;
      setState(() {
        _selectedSignale = s;
        _showSignaleDetails = true;
        _showProblemeDetails = false;
        _selectedProbleme = null;
      });
      _mapController.move(s.location, 17.0);
    }
  }

  // ============================================================================
  // FORMATAGE
  // ============================================================================

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return "${hours}h ${minutes}min";
    } else {
      return "${minutes}min";
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  String _getArrivalTime() {
    if (_routeDuration == null) return '--:--';
    final arrival = DateTime.now().add(Duration(seconds: _routeDuration!.round()));
    return '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // BUILD PRINCIPAL - DESIGN MODERNE ET PROFESSIONNEL
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // =========================================================================
          // 1. CARTE FLUTTER MAP
          // =========================================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _defaultPosition,
              initialZoom: 15.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
                if (_currentPosition != null) {
                  _tryCenterMapOnUser(zoom: 15.0);
                } else {
                  _zoomToTunisia();
                }
              },
              onTap: (_, __) {
                if (_showRoutePreview || _isNavigating) {
                  setState(() => _isMinimized = true);
                }
              },
              onLongPress: (_, point) {
                setState(() {
                  _waypoints.add(point);
                  _showMessage(context.stringsRead.mapWaypointAdded);
                });
                if (_destination != null) {
                  _calculateRoute(_destination!);
                }
              },
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _isFollowingUser) {
                  setState(() => _isFollowingUser = false);
                }
              },
            ),
            children: [
              MapTileConfig.buildTileLayer(),
              if (_trafficPolylines.isNotEmpty)
                PolylineLayer(polylines: _trafficPolylines),
              if ((_isNavigating || _showRoutePreview) && _routes.isNotEmpty)
                _buildRouteLayer(),
              MarkerLayer(markers: _markers),
            ],
          ),

          NavigationStartFlashOverlay(visible: _showFlashOnStart),

          // =========================================================================
          // 2. BARRE DE RECHERCHE MODERNE (GLASSMORPHISM)
          // =========================================================================
          if (!_isNavigating)
            Positioned(
              top: topPadding + 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernSearchBar(theme, isDark),
                  if (_loadingProblemesVoirie ||
                      _loadingProblemesSignales ||
                      _problemesVoirie.isNotEmpty ||
                      _problemesSignales.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildVoirieCountChip(theme, isDark),
                    ),
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildModernSuggestionsList(theme, isDark),
                    ),
                ],
              ),
            ),

          // =========================================================================
          // 3. OVERLAY DE NAVIGATION ACTIVE
          // =========================================================================
          if (_isNavigating) _buildModernNavigationOverlay(theme, isDark),

          // =========================================================================
          // 4. INDICATEUR DE VITESSE MINIMALISTE
          // =========================================================================
          if ((_isNavigating || _isSpeeding || _nearbyDangers.isNotEmpty) && !_isNavigating)
            Positioned(
              top: topPadding + 80,
              left: 16,
              child: _buildMinimalSpeedCard(theme),
            ),

          // =========================================================================
          // 5. BOUTONS FLOTTANTS MODERNES (FAB)
          // =========================================================================
          Positioned(
            bottom: (_showRoutePreview || _isNavigating) ? 140 : 24,
            right: 16,
            child: _buildModernFABColumn(theme),
          ),

          // =========================================================================
          // 6. PANEL INFÉRIEUR - ROUTE OU NAVIGATION
          // =========================================================================
          if (_showRoutePreview && _routeDuration != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isMinimized
                    ? _buildMinimalRouteCard(theme, isDark)
                    : _buildModernRoutePanel(theme, isDark),
              ),
            ),

          if (_isNavigating && _routeDuration != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isMinimized
                    ? _buildMinimalNavigationCard(theme, isDark)
                    : _buildModernNavigationPanel(theme, isDark),
              ),
            ),

          // =========================================================================
          // 7. FEUILLES DE DÉTAILS (PROBLÈMES)
          // =========================================================================
          if (_showProblemeDetails && _selectedProbleme != null)
            _buildModernProblemSheet(_selectedProbleme!),
          if (_showSignaleDetails && _selectedSignale != null)
            _buildModernSignaleSheet(_selectedSignale!),
          if (_showMapClusterDetails && _selectedMapCluster != null)
            _buildMapClusterSheet(_selectedMapCluster!),

        ],
      ),
    );
  }

  // ============================================================================
  // COMPOSANTS UI MODERNES
  // ============================================================================

  Widget _buildVoirieCountChip(ThemeData theme, bool isDark) {
    final voirieCount = _problemesVoirie.length;
    final signaleCount = _problemesSignales.length;
    final loading = _loadingProblemesVoirie || _loadingProblemesSignales;
    final label = loading
        ? 'Chargement des problèmes…'
        : '$voirieCount voirie · $signaleCount signalement${signaleCount > 1 ? 's' : ''}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : _loadAllMapProblems,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900]!.withOpacity(0.92) : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Icon(Icons.report_problem_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(ThemeData theme, bool isDark) {
    final l10n = context.stringsRead;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900]!.withOpacity(0.92) : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => _openSearchPage(false),
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.search_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _searchController.text.isEmpty ? l10n.mapWhereTo : _searchController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _searchController.text.isEmpty ? Colors.grey[500] : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_searchController.text.isNotEmpty)
                    Text(
                      l10n.mapDestination,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: _clearSearch,
                icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[500]),
              ),
            Container(width: 1, height: 24, color: Colors.grey[300]),
            const SizedBox(width: 8),
            Icon(Icons.mic_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _destination = null;
      _isNavigating = false;
      _showRoutePreview = false;
      _routePoints = [];
      _problemesVoirieOnRoute = [];
      _problemesSignalesOnRoute = [];
      _loadingRouteProblems = false;
      _routeProblemsAlertShownForSignature = null;
      _updateMarkers();
    });
  }

  Widget _buildModernSuggestionsList(ThemeData theme, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(
            color: theme.dividerColor,
            height: 0,
            indent: 56,
          ),
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 20),
              ),
              title: Text(
                suggestion['display_name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                suggestion['class'] ?? '',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
              onTap: () => _selectSuggestion(suggestion),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernFABColumn(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isNavigating || _showRoutePreview)
          _buildModernFAB(
            icon: Icons.close_rounded,
            onPressed: _cancelNavigation,
            backgroundColor: Colors.red,
          ),
        if (_isNavigating || _showRoutePreview) const SizedBox(height: 12),
        _buildModernFAB(
          icon: Icons.my_location_rounded,
          onPressed: _goToMyLocation,
          backgroundColor: theme.colorScheme.surface,
          iconColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildModernFAB(
          icon: Icons.alt_route_rounded,
          onPressed: () {
            if (_showRoutePreview || _isNavigating) {
              unawaited(_searchAndDisplayCleanRoutes());
            } else {
              _openDirectionSheet(context);
            }
          },
          backgroundColor: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildModernFAB({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildMinimalSpeedCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: _isSpeeding ? Colors.red : Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_currentSpeed.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isSpeeding ? Colors.red : theme.colorScheme.onSurface,
            ),
          ),
          const Text(' km/h', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModernNavigationOverlay(ThemeData theme, bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = context.stringsRead;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildTurnIcon(size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentInstruction.isNotEmpty ? _currentInstruction : l10n.mapPrepareToStart,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _currentStreet.isNotEmpty ? _currentStreet : l10n.mapFollowRoute,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF0F9D8A)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_remainingDuration),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F9D8A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIcon({double size = 28}) {
    IconData iconData;
    final instr = _currentInstruction;
    if (instr.contains('droite') || instr.contains('right')) {
      iconData = Icons.turn_right;
    } else if (instr.contains('gauche') || instr.contains('left')) {
      iconData = Icons.turn_left;
    } else if (instr.contains('Continuez') || instr.contains('Continue')) {
      iconData = Icons.arrow_forward;
    } else if (instr.contains('demi-tour') || instr.contains('U-turn')) {
      iconData = Icons.u_turn_left;
    } else {
      iconData = Icons.navigation;
    }
    return Icon(iconData, color: const Color(0xFF1A73E8), size: size);
  }

  Widget _buildMiniTurnIcon() => _buildTurnIcon(size: 16);

  Widget _buildModernRoutePanel(ThemeData theme, bool isDark) {
    final l10n = context.stringsRead;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final maxPanelHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      key: const ValueKey('route_panel'),
      constraints: BoxConstraints(maxHeight: maxPanelHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
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
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchController.text.isNotEmpty ? _searchController.text : l10n.mapDestinationHint,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.mapYourCurrentLocation,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => setState(() => _showRoutePreview = false),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          _buildTransportModeTabs(theme),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.end,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    _formatDuration(_routeDuration!),
                                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      l10n.mapFastestRoute,
                                      style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${l10n.mapArrivalAt} ${_getArrivalTime()}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.straighten, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDistance(_routeDistance!),
                                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_safetyMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D8A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_rounded, color: Color(0xFF0F9D8A), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${_safetyScore.toStringAsFixed(0)}%',
                                  style: const TextStyle(color: Color(0xFF0F9D8A), fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_scanningRouteAlternatives)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Analyse des itinéraires en cours…',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_showRouteAlternatives &&
                      !_scanningRouteAlternatives &&
                      _routePoints.length >= 2 &&
                      (_problemesVoirieOnRoute.isNotEmpty ||
                          _problemesSignalesOnRoute.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => unawaited(_searchAndDisplayCleanRoutes()),
                          icon: const Icon(Icons.alt_route_rounded, size: 18),
                          label: const Text('Afficher un itinéraire alternatif plus sûr'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A73E8),
                            side: const BorderSide(color: Color(0xFF1A73E8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_routes.length > 1) _buildAlternativeRoutesList(theme),
                  if (_routePoints.length >= 2) _buildModernRouteProblemsSection(theme, isDark),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 20),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildGradientButton(
                    onPressed: _startNavigation,
                    icon: Icons.navigation_rounded,
                    label: l10n.mapStart,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A8A50), Color(0xFF0F9D8A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _openAddWaypointSheet,
                    icon: const Icon(Icons.add_location_alt, size: 24),
                    color: theme.colorScheme.primary,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportModeTabs(ThemeData theme) {
    final modes = <({IconData icon, String label, String profile})>[
      (icon: Icons.directions_car_rounded, label: 'Voiture', profile: 'driving'),
      (icon: Icons.motorcycle_rounded, label: 'Moto', profile: 'moto'),
      (icon: Icons.directions_bus_rounded, label: 'Bus', profile: 'bus'),
      (icon: Icons.directions_walk_rounded, label: 'Marche', profile: 'walking'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = _selectedProfile == mode.profile;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_destination != null) {
                  _calculateRoute(_destination!, profile: mode.profile);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode.icon,
                      color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlternativeRoutesList(ThemeData theme) {
    final l10n = context.stringsRead;
    final visibleIndexes = _visibleAlternativeRouteIndexes();
    final counts = _routeProblemCounts;
    final isSaferMode = _showRouteAlternatives;

    final allZero = counts != null && counts.isNotEmpty && counts.every((c) => c == 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  !isSaferMode
                      ? (visibleIndexes.length <= 1
                          ? 'Itinéraire alternatif'
                          : 'Itinéraires alternatifs')
                      : allZero
                          ? (visibleIndexes.length <= 1
                              ? 'Itinéraire alternatif sans problème'
                              : 'Itinéraires sans problème (${visibleIndexes.length})')
                          : (visibleIndexes.length <= 1
                              ? 'Itinéraire alternatif plus sûr'
                              : 'Itinéraires alternatifs (${visibleIndexes.length})'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
              ),
              if (_savedRoutesBeforeCleanAlts != null)
                TextButton(
                  onPressed: _restoreMainRoute,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Itinéraire initial', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleIndexes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _scanningRouteAlternatives
                    ? 'Recherche d\'un itinéraire sans problème de voirie ni signalement…'
                    : isSaferMode
                        ? 'Aucun itinéraire alternatif sans problème disponible pour le moment.'
                        : 'Aucun itinéraire alternatif disponible pour le moment.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            )
          else
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleIndexes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, listIndex) {
                  final index = visibleIndexes[listIndex];
                final isSelected = _selectedRouteIndex == index;
                final duration = _routes[index]['duration'] as double;
                final distance = _routes[index]['distance'] as double;
                final problemCount = counts != null && index < counts.length
                    ? counts[index]
                    : null;

                return GestureDetector(
                  onTap: () => _onAlternativeRouteSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getRouteColor(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            Text(
                              problemCount == 0
                                  ? isSaferMode
                                      ? '${_formatDistance(distance)} · 0 problème'
                                      : _formatDistance(distance)
                                  : _formatDistance(distance),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSaferMode && problemCount == 0
                                    ? Colors.green[700]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        if (index == _recommendedAlternativeIndex)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.star_rounded, size: 14, color: Colors.amber[700]),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAlternativeRouteSelected(int index) async {
    await _applySelectedRouteIndex(index);
  }

  String _labelVoirieProblemType(ProblemeVoirie p) {
    switch (p.problemType) {
      case 'pothole':
        return 'Nid-de-poule';
      case 'crack':
        return 'Fissure';
      default:
        return p.problemType.replaceAll('_', ' ');
    }
  }

  Map<String, List<_RouteProblemRow>> _groupRouteProblemsByAddress(List<_RouteProblemRow> rows) {
    final groups = <String, List<_RouteProblemRow>>{};
    for (final row in rows) {
      final String key;
      if (row.voirie != null) {
        key = _cachedVoirieAddressLabel(row.voirie!) ?? 'Chargement de l\'adresse…';
      } else {
        final loc = row.signale!.location;
        key = _geocodedProblemAddresses[_geocodeCacheKey(loc)] ?? 'Signalement citoyen';
      }
      groups.putIfAbsent(key, () => []).add(row);
    }
    return groups;
  }

  Widget _buildModernRouteProblemsSection(ThemeData theme, bool isDark) {
    final l10n = context.stringsRead;
    final rows = _mergedRouteProblemsOrdered();
    if (_showRouteAlternatives && rows.isEmpty) return const SizedBox.shrink();
    final destConflicts = _voirieSharingDestinationAddress();
    final grouped = _groupRouteProblemsByAddress(rows);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _showRouteAlternatives
                      ? 'Problèmes sur l\'itinéraire initial (par adresse)'
                      : l10n.mapRouteProblemsTitle,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange[800]),
                ),
              ),
            ],
          ),
          if (_showRouteAlternatives) ...[
            const SizedBox(height: 4),
            Text(
              'Adresses MongoDB des problèmes de voirie sur l\'itinéraire initial.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
          if (destConflicts.length >= 2 && !_showRouteAlternatives) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${destConflicts.length} problème${destConflicts.length > 1 ? 's' : ''} de voirie '
                    'à la même adresse que votre destination.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange[900],
                    ),
                  ),
                  if (_destinationSearchLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Destination : $_destinationSearchLabel',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Recherchez un itinéraire alternatif passant par d\'autres adresses.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (_loadingRouteProblems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange[700]),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analyse des problèmes sur l\'itinéraire…',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.mapRouteProblemsEmpty,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            )
          else ...[
            Text(
              l10n.mapRouteProblemsCount(rows.length),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              _showRouteAlternatives
                  ? '${_savedMainRouteVoirie.length} voirie · ${_savedMainRouteSignales.length} signalement${_savedMainRouteSignales.length > 1 ? 's' : ''}'
                  : '${_problemesVoirieOnRoute.length} voirie · ${_problemesSignalesOnRoute.length} signalement${_problemesSignalesOnRoute.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            ...grouped.entries.expand((entry) {
              final address = entry.key;
              final items = entry.value;
              return [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (items.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${items.length}',
                            style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                          ),
                        ),
                    ],
                  ),
                ),
                ...List.generate(items.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 6, left: 8),
                    child: _buildRouteProblemListTile(items[index], theme, isDark),
                  );
                }),
              ];
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteProblemListTile(_RouteProblemRow row, ThemeData theme, bool isDark) {
    final isVoirie = row.voirie != null;
    final icon = isVoirie
        ? (row.voirie!.problemType == 'pothole' ? Icons.blur_circular_rounded : Icons.view_week_rounded)
        : _iconForSignaleType(row.signale!.type);
    final color = isVoirie ? _getProblemeColor(row.voirie!) : _colorForSignaleType(row.signale!.type);
    final title = isVoirie
        ? _labelVoirieProblemType(row.voirie!)
        : _labelSignaleTypeFr(row.signale!.type);
    final loc = row.voirie?.location ?? row.signale?.location;
    final cachedAddr = row.voirie != null
        ? _cachedVoirieAddressLabel(row.voirie!)
        : (loc != null ? _geocodedProblemAddresses[_geocodeCacheKey(loc)] : null);
    final subtitle = isVoirie
        ? 'Voirie · ${row.voirie!.severity} · ${row.voirie!.status}'
        : 'Signalement citoyen';
    final addressLabel = row.voirie?.mongoAddress != null &&
            row.voirie!.mongoAddress!.trim().isNotEmpty
        ? row.voirie!.mongoAddress!.trim()
        : cachedAddr;

    return Material(
      color: isDark ? Colors.grey[900]!.withOpacity(0.35) : color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _focusRouteProblemRow(row),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (addressLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        isVoirie ? 'Adresse : $addressLabel' : addressLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (loc != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Chargement de l\'adresse…',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteLayer() {
    final visibleAlts = _visibleAlternativeRouteIndexes();
    final showAllColors = _showRouteAlternatives && visibleAlts.isNotEmpty;

    final polylines = <Polyline>[];

    if (_showRouteAlternatives && _savedMainRoutePoints.length >= 2) {
      final mainPts = simplifyPolyline(
        _savedMainRoutePoints,
        minSpacingMeters: _kAltRouteSimplifySpacingM,
      );
      if (mainPts.length >= 2) {
        polylines.addAll(
          _buildRoutePolylinePair(
            mainPts,
            color: const Color(0xFF7B1FA2),
            baseWidth: 5,
            opacity: 0.45,
          ),
        );
      }
    }

    final routeIndices = showAllColors
        ? visibleAlts
        : [_selectedRouteIndex.clamp(0, _routes.length - 1)];

    for (final i in routeIndices) {
      if (i < 0 || i >= _routes.length || !_isValidRouteMap(_routes[i])) continue;
      final pts = (_showRouteAlternatives || showAllColors)
          ? _displayPointsForRoute(i)
          : List<LatLng>.from(_routes[i]['points'] as List);
      if (pts.length < 2) continue;
      final isSelected = i == _selectedRouteIndex;
      final color = _getRouteColor(i);
      final baseWidth = isSelected ? 8.0 : 5.0;
      final opacity = showAllColors ? (isSelected ? 1.0 : 0.7) : (isSelected ? 1.0 : 0.35);

      polylines.addAll(
        _buildRoutePolylinePair(
          pts,
          color: color,
          baseWidth: baseWidth,
          opacity: opacity,
          isSelected: isSelected,
        ),
      );
    }

    return PolylineLayer(polylines: polylines);
  }

  bool _hasVisibleRoute() =>
      _routePoints.length >= 2 && (_showRoutePreview || _isNavigating);

  bool _pointsNear(LatLng a, LatLng b, {double meters = 20}) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude) < meters;

  Widget _buildRouteLineEndpoint({required bool isStart, required Color routeColor}) {
    final endpointColor = isStart ? const Color(0xFF1A8A50) : const Color(0xFFEA4335);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: endpointColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: routeColor.withOpacity(0.45),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            isStart ? Icons.trip_origin : Icons.flag_rounded,
            size: 11,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: endpointColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isStart ? 'Départ' : 'Arrivée',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _addRouteLineEndpointMarkers() {
    if (!_hasVisibleRoute()) return;

    final routeColor = _getRouteColor(_selectedRouteIndex);
    final start = _routePoints.first;
    final end = _routePoints.last;

    _markers.add(
      Marker(
        point: start,
        width: 56,
        height: 56,
        alignment: Alignment.bottomCenter,
        child: _buildRouteLineEndpoint(isStart: true, routeColor: routeColor),
      ),
    );
    _markers.add(
      Marker(
        point: end,
        width: 56,
        height: 56,
        alignment: Alignment.bottomCenter,
        child: _buildRouteLineEndpoint(isStart: false, routeColor: routeColor),
      ),
    );
  }

  Widget _buildMinimalRouteCard(ThemeData theme, bool isDark) {
    final l10n = context.stringsRead;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        key: const ValueKey('min_route'),
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getModeIcon(_selectedProfile), color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(_routeDuration!),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${l10n.mapArrivalAt} ${_getArrivalTime()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            _buildGradientButton(
              onPressed: _startNavigation,
              icon: Icons.navigation_rounded,
              label: l10n.mapStart,
              width: 90,
              height: 40,
              fontSize: 13,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A8A50), Color(0xFF0F9D8A)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(String profile) {
    switch (profile) {
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'moto':
        return Icons.motorcycle_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  Widget _buildModernNavigationPanel(ThemeData theme, bool isDark) {
    final l10n = context.stringsRead;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final progress = _calculateProgress();

    return Container(
      key: const ValueKey('nav_panel'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            color: theme.colorScheme.primary,
            minHeight: 3,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _buildTurnIcon(size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentInstruction.isNotEmpty ? _currentInstruction : l10n.mapPrepareToStart,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentStreet.isNotEmpty ? _currentStreet : l10n.mapFollowRoute,
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.access_time_rounded,
                        value: _formatDuration(_remainingDuration),
                        label: l10n.mapRemainingTime,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.straighten_rounded,
                        value: _formatDistance(_remainingDistance),
                        label: l10n.mapRemainingDistance,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.speed_rounded,
                        value: '${_currentSpeed.toStringAsFixed(0)}',
                        label: 'km/h',
                        color: _isSpeeding ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToMyLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Centrer'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cancelNavigation,
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(l10n.mapQuit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMinimalNavigationCard(ThemeData theme, bool isDark) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final progress = _calculateProgress();

    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        key: const ValueKey('min_nav'),
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
                  _buildMiniTurnIcon(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(_remainingDuration),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currentInstruction.isNotEmpty ? _currentInstruction : 'En route',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _cancelNavigation,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Quitter', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
    double width = double.infinity,
    double height = 48,
    double fontSize = 15,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: fontSize + 2),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapClusterSheet(MapProblemCluster cluster) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
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
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cluster.totalCount} problème${cluster.totalCount > 1 ? 's' : ''} à cet emplacement',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cluster.location.latitude.toStringAsFixed(5)}, ${cluster.location.longitude.toStringAsFixed(5)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _showMapClusterDetails = false;
                        _selectedMapCluster = null;
                      }),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
                  itemCount: cluster.voirie.length + cluster.signales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index < cluster.voirie.length) {
                      return _buildClusterVoirieCard(cluster.voirie[index], theme);
                    }
                    return _buildClusterSignaleCard(
                      cluster.signales[index - cluster.voirie.length],
                      theme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClusterVoirieCard(ProblemeVoirie v, ThemeData theme) {
    final label = v.problemType == 'pothole' ? 'Nid-de-poule' : 'Fissure';
    final color = _getProblemeColor(v);

    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openVoirieDetail(v),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      v.problemType == 'pothole'
                          ? Icons.blur_circular_rounded
                          : Icons.view_week_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          'Voirie · Détecté le ${_formatProblemeDate(v.dateDetection)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProblemeStatusColor(v.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      v.status,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildProblemStat(
                      label: 'Risque',
                      value: '${v.riskScore.toStringAsFixed(0)}%',
                      color: _getProblemeRiskColor(v.riskScore),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildProblemStat(
                      label: 'Sévérité',
                      value: v.severity,
                      color: _getProblemeSeverityColor(v.severity),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildProblemStat(
                      label: 'Priorité',
                      value: v.maintenancePriority ?? 'N/A',
                      color: _getProblemePriorityColor(v.maintenancePriority),
                    ),
                  ),
                ],
              ),
              if (v.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  v.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClusterSignaleCard(ProblemeSignaleMapItem s, ThemeData theme) {
    final color = _colorForSignaleType(s.type);
    final when = s.createdAt != null
        ? '${s.createdAt!.day}/${s.createdAt!.month}/${s.createdAt!.year} à ${s.createdAt!.hour.toString().padLeft(2, '0')}:${s.createdAt!.minute.toString().padLeft(2, '0')}'
        : null;

    return Material(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSignaleDetail(s),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(_iconForSignaleType(s.type), color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labelSignaleTypeFr(s.type),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          when != null ? 'Signalement citoyen · $when' : 'Signalement citoyen',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (s.meta.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: s.meta.entries.take(4).map((e) {
                    return Chip(
                      label: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernProblemSheet(ProblemeVoirie probleme) {
    final theme = Theme.of(context);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
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
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getProblemeColor(probleme).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            probleme.problemType == 'pothole' ? Icons.circle_outlined : Icons.timeline,
                            color: _getProblemeColor(probleme),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                probleme.problemType == 'pothole' ? 'Nid-de-poule' : 'Fissure',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Détecté le ${_formatProblemeDate(probleme.dateDetection)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showProblemeDetails = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProblemStat(
                            label: 'Risque',
                            value: '${probleme.riskScore.toStringAsFixed(0)}%',
                            color: _getProblemeRiskColor(probleme.riskScore),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProblemStat(
                            label: 'Sévérité',
                            value: probleme.severity,
                            color: _getProblemeSeverityColor(probleme.severity),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProblemStat(
                            label: 'Priorité',
                            value: probleme.maintenancePriority ?? 'N/A',
                            color: _getProblemePriorityColor(probleme.maintenancePriority),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 6),
                          Text(probleme.description, style: const TextStyle(fontSize: 14)),
                          if (probleme.diagnostic != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Diagnostic',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 6),
                            Text(probleme.diagnostic!, style: const TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getProblemeStatusColor(probleme.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            probleme.status,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            _mapController.move(probleme.location, 18.0);
                            setState(() => _showProblemeDetails = false);
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: const Text('Y aller'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemStat({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildModernSignaleSheet(ProblemeSignaleMapItem item) {
    final theme = Theme.of(context);
    final when = item.createdAt != null
        ? '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year} à ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
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
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _colorForSignaleType(item.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _iconForSignaleType(item.type),
                            color: _colorForSignaleType(item.type),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labelSignaleTypeFr(item.type),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (when.isNotEmpty)
                                Text(
                                  when,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _showSignaleDetails = false;
                            _selectedSignale = null;
                          }),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.location.latitude.toStringAsFixed(5)}, ${item.location.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _mapController.move(item.location, 18.0);
                              setState(() {
                                _showSignaleDetails = false;
                                _selectedSignale = null;
                              });
                            },
                            child: const Text('Voir'),
                          ),
                        ],
                      ),
                    ),
                    if (item.meta.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.meta.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADD WAYPOINT SHEET
// ============================================================================

class _AddWaypointSheet extends StatefulWidget {
  final Function(LatLng, String) onWaypointAdded;

  const _AddWaypointSheet({required this.onWaypointAdded});

  @override
  State<_AddWaypointSheet> createState() => _AddWaypointSheetState();
}

class _AddWaypointSheetState extends State<_AddWaypointSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        setState(() => _isSearching = true);
        final results = await NominatimService.getSuggestions(query);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } else {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = double.parse(suggestion['lat'].toString());
    final lon = double.parse(suggestion['lon'].toString());
    final name = suggestion['display_name']?.toString() ?? '';
    widget.onWaypointAdded(LatLng(lat, lon), name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final s = context.stringsRead;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_location_alt, color: Color(0xFF1A73E8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.mapAddWaypointHint,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                        _onSearchChanged(value);
                      },
                      decoration: InputDecoration(
                        hintText: s.mapSearchQuery,
                        border: InputBorder.none,
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      autofocus: true,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _suggestions = [];
                          _isSearching = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey.withOpacity(0.15)),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFFEA4335)),
                    ),
                    title: Text(
                      (suggestion['display_name'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      (suggestion['class'] ?? '').toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          if (_suggestions.isEmpty && _searchController.text.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(s.mapSearchNoResults, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}

// ============================================================================
// NAVIGATION DIRECTION SHEET
// ============================================================================

class _NavigationDirectionSheet extends StatefulWidget {
  final Function(LatLng, {LatLng? start, String? profile}) onStartNavigation;
  final String currentProfile;
  final double? duration;
  final double? distance;
  final bool isNavigating;
  final List<LatLng> waypoints;
  final Function(List<LatLng>) onWaypointsChanged;

  const _NavigationDirectionSheet({
    required this.onStartNavigation,
    required this.currentProfile,
    this.duration,
    this.distance,
    this.isNavigating = false,
    required this.waypoints,
    required this.onWaypointsChanged,
  });

  @override
  State<_NavigationDirectionSheet> createState() => _NavigationDirectionSheetState();
}

class _NavigationDirectionSheetState extends State<_NavigationDirectionSheet> {
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  late String _selectedProfile;
  LatLng? _selectedStart;
  LatLng? _selectedEnd;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.currentProfile;
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fromController.text = context.stringsRead.mapYourCurrentLocation;
    });
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.getHistory('destination');
    if (mounted) {
      setState(() => _history = history);
    }
  }

  void _openSearchPage(bool isFrom) async {
    final s = context.stringsRead;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SearchLocationPage(
          hintText: isFrom ? s.mapHintFrom : s.mapHintTo,
          initialQuery: isFrom ? fromController.text : toController.text,
          historyType: isFrom ? 'departure' : 'destination',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isFrom) {
          if (result['name'] == kSearchCurrentLocationName) {
            _selectedStart = null;
            fromController.text = s.mapYourCurrentLocation;
          } else {
            _selectedStart = LatLng(result['lat'], result['lon']);
            fromController.text = result['display_name'];
          }
        } else {
          _selectedEnd = LatLng(result['lat'], result['lon']);
          toController.text = result['display_name'];
        }
      });
      _loadHistory();
      if (_selectedEnd != null) {
        widget.onStartNavigation(_selectedEnd!, start: _selectedStart);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
    final s = context.stringsRead;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + keyboardPad + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
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
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(s.mapPlanRouteTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle)),
                  Container(width: 2, height: 30, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(vertical: 4)),
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.red[400], shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildInputField(controller: fromController, hint: s.mapStartPointHint, onTap: () => _openSearchPage(true), theme: theme, isDark: isDark),
                    const SizedBox(height: 8),
                    if (widget.waypoints.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ...widget.waypoints.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text("${s.mapWaypointLabel} ${entry.key + 1}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  final newList = List<LatLng>.from(widget.waypoints);
                                  newList.removeAt(entry.key);
                                  widget.onWaypointsChanged(newList);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 4),
                    ],
                    _buildInputField(controller: toController, hint: s.mapDestinationHint, onTap: () => _openSearchPage(false), theme: theme, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(s.mapRecents, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            ..._history.take(3).map((item) => _buildRecentItem(item['display_name'] ?? '', item)).toList(),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _selectedEnd == null
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onStartNavigation(_selectedEnd!, start: _selectedStart);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: _selectedEnd == null
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0F9D8A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _selectedEnd == null ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedEnd == null
                    ? []
                    : [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation_rounded, color: _selectedEnd == null ? Colors.grey[500] : Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(s.mapNavigationStart, style: TextStyle(color: _selectedEnd == null ? Colors.grey[500] : Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          controller.text.isEmpty ? hint : controller.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: controller.text.isEmpty ? Colors.grey[400] : theme.colorScheme.onSurface,
            fontWeight: controller.text.isEmpty ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(String title, Map<String, dynamic> item) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        try {
          final lat = item['lat'];
          final lon = item['lon'];
          double latVal = (lat is String) ? double.parse(lat) : (lat as num).toDouble();
          double lonVal = (lon is String) ? double.parse(lon) : (lon as num).toDouble();
          setState(() {
            _selectedEnd = LatLng(latVal, lonVal);
            toController.text = title;
          });
          await SearchHistoryService.addSearch(item, 'destination');
          _loadHistory();
        } catch (e) {
          _loadHistory();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}