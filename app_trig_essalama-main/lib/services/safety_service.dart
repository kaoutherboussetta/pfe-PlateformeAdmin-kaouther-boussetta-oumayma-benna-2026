import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_strings.dart';

class SafetyService {
  // 🚨 Zones de danger simulées (Points noirs ou trafic intense en Tunisie)
  static final List<LatLng> dangerZones = [
    const LatLng(34.7406, 10.7603), // Sfax (Centre)
    const LatLng(36.8065, 10.1815), // Tunis (Avenue Habib Bourguiba)
    const LatLng(35.8256, 10.6369), // Sousse (Entrée ville)
    const LatLng(33.8819, 10.0982), // Gabès (Zone industrielle)
  ];

  /// Calcule un score de sécurité (0-100) basé sur des facteurs externes
  static Future<double> calculateSafetyScore(Map<String, dynamic> route) async {
    // Dans une version réelle, on analyserait les points de la route
    // Pour la démo, on utilise une logique basée sur l'heure et des données simulées
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 20;
    
    double score = 85.0; // Score de base
    if (isNight) score -= 15.0;
    
    // Simuler une variation basée sur la distance (plus c'est long, plus il y a de risques potentiels)
    final distance = route['distance'] as double? ?? 0.0;
    if (distance > 10000) score -= 5.0;
    
    return score.clamp(0, 100).toDouble();
  }

  /// Calcule un score de sécurité manuel (0-100)
  static double calculateManualSafetyScore({
    required int accidents,
    required int trafficIndex,
    required bool nightMode,
  }) {
    // Logique: 100 - (accidents * 5 + trafic * 2 + bonus nuit)
    double score = 100.0 - (accidents * 5.0) - (trafficIndex * 2.0);
    if (nightMode) score -= 10; // La nuit est plus risquée
    
    return score.clamp(0, 100).toDouble();
  }

  /// Prédit le risque d'accident en fonction de l'historique et de l'heure
  static String predictRisk(int accidents, int hour, AppStrings s) {
    if (accidents > 5 && (hour > 20 || hour < 6)) {
      return s.mapRiskHigh;
    } else if (accidents > 3 || hour > 17 && hour < 20) {
      return s.mapRiskModerate;
    }
    return s.mapRiskLow;
  }

  /// Vérifie si l'utilisateur est proche d'une zone de danger (300m)
  static List<LatLng> getNearbyDangers(LatLng userPos) {
    return dangerZones.where((zone) {
      double distance = Geolocator.distanceBetween(
        userPos.latitude, userPos.longitude,
        zone.latitude, zone.longitude
      );
      return distance < 300; // Alerte sous 300 mètres
    }).toList();
  }

  /// Filtre les routes pour ne garder que les plus sûres (Mode Sécurité)
  static List<Map<String, dynamic>> filterSafeRoutes(List<Map<String, dynamic>> routes) {
    // On simule un score de sécurité pour chaque route pour la démonstration
    // Route 0: Très sûre, Route 1: Normale, Route 2: Rapide mais moins sûre
    for (int i = 0; i < routes.length; i++) {
      if (i == 0) routes[i]['safetyScore'] = 95.0;
      if (i == 1) routes[i]['safetyScore'] = 75.0;
      if (i >= 2) routes[i]['safetyScore'] = 55.0;
    }
    return routes;
  }
}
