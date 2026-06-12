import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Bordure géographique (degrés décimaux).
typedef GeoBounds = ({double minLat, double maxLat, double minLng, double maxLng});

/// Distance minimale (m) du point [p] à la polyligne [route] (segments droits).
double minDistanceToRouteMeters(LatLng p, List<LatLng> route) {
  if (route.isEmpty) return double.infinity;
  if (route.length == 1) {
    return Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      route.first.latitude,
      route.first.longitude,
    );
  }
  double best = double.infinity;
  for (int i = 0; i < route.length - 1; i++) {
    final d = _distancePointToSegmentMeters(p, route[i], route[i + 1]);
    if (d < best) best = d;
  }
  return best;
}

double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  double best = Geolocator.distanceBetween(
    p.latitude,
    p.longitude,
    a.latitude,
    a.longitude,
  );
  final dEnd = Geolocator.distanceBetween(
    p.latitude,
    p.longitude,
    b.latitude,
    b.longitude,
  );
  if (dEnd < best) best = dEnd;
  const steps = 16;
  for (int s = 1; s < steps; s++) {
    final t = s / steps;
    final lat = a.latitude + (b.latitude - a.latitude) * t;
    final lng = a.longitude + (b.longitude - a.longitude) * t;
    final d = Geolocator.distanceBetween(p.latitude, p.longitude, lat, lng);
    if (d < best) best = d;
  }
  return best;
}

/// Boîte englobante approximative autour d’un point (marge en mètres, repère local).
GeoBounds geoBoundsAroundPoint(double lat, double lng, double radiusMeters) {
  final latRad = lat * math.pi / 180;
  final dLat = radiusMeters / 110574.0;
  final dLng = radiusMeters / (111320.0 * math.max(0.2, math.cos(latRad)));
  return (
    minLat: lat - dLat,
    maxLat: lat + dLat,
    minLng: lng - dLng,
    maxLng: lng + dLng,
  );
}

/// Étend les bornes d’une liste de points avec une marge en mètres (approx. locale).
GeoBounds boundsWithPaddingMeters(Iterable<LatLng> points, {double paddingMeters = 280}) {
  double minLat = 90;
  double maxLat = -90;
  double minLng = 180;
  double maxLng = -180;
  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  final centerLat = (minLat + maxLat) / 2;
  final latRad = centerLat * math.pi / 180;
  final dLat = paddingMeters / 110574.0;
  final dLng = paddingMeters / (111320.0 * math.max(0.2, math.cos(latRad)));
  return (
    minLat: minLat - dLat,
    maxLat: maxLat + dLat,
    minLng: minLng - dLng,
    maxLng: maxLng + dLng,
  );
}

/// Réduit les points OSRM pour un tracé plus lisible (moins d’embranchements visuels).
List<LatLng> simplifyPolyline(
  List<LatLng> route, {
  double minSpacingMeters = 80,
}) {
  if (route.length <= 2) return List<LatLng>.from(route);

  final out = <LatLng>[route.first];
  for (var i = 1; i < route.length - 1; i++) {
    final d = Geolocator.distanceBetween(
      route[i].latitude,
      route[i].longitude,
      out.last.latitude,
      out.last.longitude,
    );
    if (d >= minSpacingMeters) out.add(route[i]);
  }
  final last = route.last;
  if (out.last.latitude != last.latitude || out.last.longitude != last.longitude) {
    out.add(last);
  }
  return out;
}
