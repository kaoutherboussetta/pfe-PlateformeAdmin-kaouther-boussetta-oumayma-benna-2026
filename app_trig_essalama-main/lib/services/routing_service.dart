import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const String _baseDomain = 'https://router.project-osrm.org/route/v1';
  static const Distance _distance = Distance();

  /// Itinéraires OSRM + détours multiples si une seule route (alternatives locales possibles).
  static Future<List<Map<String, dynamic>>> getRoutesWithAlternatives(
    LatLng start,
    LatLng end, {
    List<LatLng>? waypoints,
    String profile = 'driving',
  }) async {
    final routes = await getRoutes(start, end, waypoints: waypoints, profile: profile);
    if (routes.length >= 2) return routes;
    if (routes.isEmpty) return routes;

    final mainPoints = List<LatLng>.from(routes.first['points'] as List);
    if (mainPoints.length < 2) return routes;

    final detourPoints = detourWaypointsAlongRoute(mainPoints);
    var merged = List<Map<String, dynamic>>.from(routes);
    for (final detourPoint in detourPoints) {
      final viaDetour = <LatLng>[...?waypoints, detourPoint];
      final detourRoutes = await getRoutes(
        start,
        end,
        waypoints: viaDetour,
        profile: profile,
      );
      merged = _mergeDistinctRoutes(merged, detourRoutes);
      if (merged.length >= 4) break;
    }
    return merged;
  }

  /// Génère des itinéraires de contournement autour de points problématiques (routes locales acceptées).
  static Future<List<Map<String, dynamic>>> getRoutesAvoidingHazards(
    LatLng start,
    LatLng end, {
    List<LatLng>? waypoints,
    required List<LatLng> hazards,
    List<LatLng>? referenceRoute,
    String profile = 'driving',
  }) async {
    final candidates = <Map<String, dynamic>>[];
    final ref = referenceRoute ?? const <LatLng>[];

    if (ref.length >= 2) {
      for (final detour in detourWaypointsAlongRoute(ref)) {
        final routes = await getRoutes(
          start,
          end,
          waypoints: [...?waypoints, detour],
          profile: profile,
        );
        candidates.addAll(routes);
      }
    }

    for (final hazard in hazards.take(24)) {
      for (final bypass in bypassWaypointsForHazard(hazard, ref)) {
        final routes = await getRoutes(
          start,
          end,
          waypoints: [...?waypoints, bypass],
          profile: profile,
        );
        candidates.addAll(routes);
      }
    }

    if (ref.length >= 2 && hazards.isNotEmpty) {
      final ordered = _orderedHazardsAlongRoute(hazards, ref);
      final chain = <LatLng>[];
      for (final hazard in ordered.take(6)) {
        final bypasses = bypassWaypointsForHazard(hazard, ref);
        if (bypasses.isNotEmpty) chain.add(bypasses.first);
      }
      for (var n = 1; n <= chain.length && n <= 4; n++) {
        final subChain = chain.take(n).toList();
        final routes = await getRoutes(
          start,
          end,
          waypoints: [...?waypoints, ...subChain],
          profile: profile,
        );
        candidates.addAll(routes);
      }
    }

    if (hazards.length >= 2) {
      final first = bypassWaypointsForHazard(hazards.first, ref);
      final second = bypassWaypointsForHazard(hazards[1], ref);
      if (first.isNotEmpty && second.isNotEmpty) {
        final routes = await getRoutes(
          start,
          end,
          waypoints: [...?waypoints, first.first, second.first],
          profile: profile,
        );
        candidates.addAll(routes);
      }
    }

    return _mergeDistinctRoutes(const [], candidates);
  }

  /// Points de détour le long d'un itinéraire (plusieurs distances et côtés).
  static List<LatLng> detourWaypointsAlongRoute(List<LatLng> mainPoints) {
    if (mainPoints.length < 2) return const [];

    final waypoints = <LatLng>[];
    const fractions = [0.2, 0.35, 0.5, 0.65, 0.8];
    const offsetsM = [500.0, 900.0, 1300.0, 1800.0, 2500.0];
    const sides = [90.0, -90.0];

    for (final frac in fractions) {
      final idx = (mainPoints.length * frac).round().clamp(1, mainPoints.length - 2);
      final mid = mainPoints[idx];
      final prev = mainPoints[idx - 1];
      final bearing = Geolocator.bearingBetween(
        prev.latitude,
        prev.longitude,
        mid.latitude,
        mid.longitude,
      );
      for (final offsetM in offsetsM) {
        for (final side in sides) {
          waypoints.add(_distance.offset(mid, offsetM, bearing + side));
        }
      }
    }
    return waypoints;
  }

  /// Contournement perpendiculaire autour d'un danger signalé sur l'itinéraire.
  static List<LatLng> bypassWaypointsForHazard(LatLng hazard, List<LatLng> route) {
    if (route.length < 2) {
      return [
        _distance.offset(hazard, 900, 0),
        _distance.offset(hazard, 900, 180),
      ];
    }

    var nearestIdx = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < route.length - 1; i++) {
      final mid = LatLng(
        (route[i].latitude + route[i + 1].latitude) / 2,
        (route[i].longitude + route[i + 1].longitude) / 2,
      );
      final d = Geolocator.distanceBetween(
        hazard.latitude,
        hazard.longitude,
        mid.latitude,
        mid.longitude,
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }

    final a = route[nearestIdx];
    final b = route[math.min(nearestIdx + 1, route.length - 1)];
    final bearing = Geolocator.bearingBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );

    const offsetsM = [700.0, 1100.0, 1600.0, 2200.0, 3000.0, 4200.0];
    return [
      for (final offsetM in offsetsM) ...[
        _distance.offset(hazard, offsetM, bearing + 90),
        _distance.offset(hazard, offsetM, bearing - 90),
      ],
    ];
  }

  static List<LatLng> _orderedHazardsAlongRoute(List<LatLng> hazards, List<LatLng> route) {
    if (route.length < 2) return hazards;
    final scored = <({LatLng point, int idx})>[];
    for (final hazard in hazards) {
      var nearestIdx = 0;
      var nearestDist = double.infinity;
      for (var i = 0; i < route.length - 1; i++) {
        final mid = LatLng(
          (route[i].latitude + route[i + 1].latitude) / 2,
          (route[i].longitude + route[i + 1].longitude) / 2,
        );
        final d = Geolocator.distanceBetween(
          hazard.latitude,
          hazard.longitude,
          mid.latitude,
          mid.longitude,
        );
        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }
      scored.add((point: hazard, idx: nearestIdx));
    }
    scored.sort((a, b) => a.idx.compareTo(b.idx));
    return scored.map((e) => e.point).toList();
  }

  static LatLng? _detourWaypoint(List<LatLng> mainPoints) {
    final points = detourWaypointsAlongRoute(mainPoints);
    return points.isEmpty ? null : points.first;
  }

  static List<Map<String, dynamic>> _mergeDistinctRoutes(
    List<Map<String, dynamic>> base,
    List<Map<String, dynamic>> extra,
  ) {
    final out = List<Map<String, dynamic>>.from(base);
    for (final route in extra) {
      if (!_isSimilarToAny(route, out)) {
        out.add(route);
      }
    }
    return out;
  }

  static bool isSimilarToExistingRoute(
    Map<String, dynamic> candidate,
    List<Map<String, dynamic>> existing,
  ) =>
      _isSimilarToAny(candidate, existing);

  static bool _isSimilarToAny(
    Map<String, dynamic> candidate,
    List<Map<String, dynamic>> existing,
  ) {
    final cDist = (candidate['distance'] as num).toDouble();
    final cPts = candidate['points'] as List<LatLng>;
    for (final r in existing) {
      final rDist = (r['distance'] as num).toDouble();
      if ((cDist - rDist).abs() / math.max(rDist, 1) < 0.08) {
        final rPts = r['points'] as List<LatLng>;
        if (_routesOverlapMeters(cPts, rPts) < 120) return true;
      }
    }
    return false;
  }

  static double _routesOverlapMeters(List<LatLng> a, List<LatLng> b) {
    if (a.isEmpty || b.isEmpty) return double.infinity;
    final samples = [0, a.length ~/ 4, a.length ~/ 2, (a.length * 3) ~/ 4, a.length - 1];
    var total = 0.0;
    for (final i in samples) {
      final p = a[i.clamp(0, a.length - 1)];
      var minD = double.infinity;
      for (final j in [0, b.length ~/ 2, b.length - 1]) {
        final q = b[j.clamp(0, b.length - 1)];
        final d = Geolocator.distanceBetween(
          p.latitude,
          p.longitude,
          q.latitude,
          q.longitude,
        );
        if (d < minD) minD = d;
      }
      total += minD;
    }
    return total / samples.length;
  }

  /// Calcule l'itinéraire et les alternatives (retourne une liste de trajets)
  static Future<List<Map<String, dynamic>>> getRoutes(
    LatLng start, 
    LatLng end, {
    List<LatLng>? waypoints,
    String profile = 'driving', // driving, cycling, walking
  }) async {
    // 🔗 Construire la chaîne des coordonnées (Start -> Waypoints -> End)
    String coordinateString = "${start.longitude},${start.latitude}";
    if (waypoints != null && waypoints.isNotEmpty) {
      coordinateString += ";" + waypoints.map((p) => "${p.longitude},${p.latitude}").join(";");
    }
    coordinateString += ";${end.longitude},${end.latitude}";

    final url = '$_baseDomain/$profile/$coordinateString?overview=full&geometries=polyline&alternatives=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return (data['routes'] as List).map((route) => {
            'points': _decodePolyline(route['geometry']),
            'duration': (route['duration'] as num).toDouble(),
            'distance': (route['distance'] as num).toDouble(),
            'safetyScore': 0.0, // Initialisé à 0, calculé plus tard par SafetyService
          }).toList();
        }
      }
    } catch (e) {
      print('Erreur OSRM: $e');
    }
    return [];
  }

  /// Helper pour récupérer un seul itinéraire (le plus rapide par défaut)
  static Future<Map<String, dynamic>?> getRoute(LatLng start, LatLng end) async {
    final routes = await getRoutes(start, end);
    if (routes.isNotEmpty) {
      return routes[0];
    }
    return null;
  }

  /// Décodeur de Polyline (Algorithme standard Google/OSRM)
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
