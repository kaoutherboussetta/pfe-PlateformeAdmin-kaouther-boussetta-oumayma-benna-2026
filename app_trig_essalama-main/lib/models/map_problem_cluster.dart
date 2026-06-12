import 'package:latlong2/latlong.dart';

import '../models/probleme_signale_map_item.dart';
import '../services/problemes_voirie_service.dart';

/// Regroupement de problèmes de voirie et/ou signalements au même GPS.
class MapProblemCluster {
  final LatLng location;
  final List<ProblemeVoirie> voirie;
  final List<ProblemeSignaleMapItem> signales;

  const MapProblemCluster({
    required this.location,
    this.voirie = const [],
    this.signales = const [],
  });

  int get totalCount => voirie.length + signales.length;

  bool get isGrouped => totalCount > 1;

  bool containsVoirieId(String id) => voirie.any((v) => v.id == id);

  bool containsSignaleId(String id) => signales.any((s) => s.id == id);

  bool matchesSelection({
    MapProblemCluster? selectedCluster,
    ProblemeVoirie? selectedVoirie,
    ProblemeSignaleMapItem? selectedSignale,
  }) {
    if (selectedCluster != null && identical(selectedCluster, this)) return true;
    if (selectedVoirie != null && containsVoirieId(selectedVoirie.id)) return true;
    if (selectedSignale != null && containsSignaleId(selectedSignale.id)) return true;
    return false;
  }

  ProblemeVoirie? get highestRiskVoirie {
    if (voirie.isEmpty) return null;
    return voirie.reduce((a, b) => a.riskScore >= b.riskScore ? a : b);
  }
}

class MapProblemClusterService {
  static String locationKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

  /// Fusionne voirie + signalements partageant les mêmes coordonnées (6 décimales).
  static List<MapProblemCluster> cluster({
    Iterable<ProblemeVoirie> voirie = const [],
    Iterable<ProblemeSignaleMapItem> signales = const [],
  }) {
    final locByKey = <String, LatLng>{};
    final voirieByKey = <String, List<ProblemeVoirie>>{};
    final signaleByKey = <String, List<ProblemeSignaleMapItem>>{};

    for (final item in voirie) {
      if (!ProblemesVoirieService.hasValidMapLocation(item)) continue;
      final key = locationKey(item.location);
      final bucket = voirieByKey.putIfAbsent(key, () => []);
      if (bucket.any((v) => v.id == item.id)) continue;
      locByKey[key] = item.location;
      bucket.add(item);
    }
    for (final item in signales) {
      if (item.id.isEmpty || !ProblemeVoirie.isPlausibleMapLocation(item.location)) {
        continue;
      }
      final key = locationKey(item.location);
      final bucket = signaleByKey.putIfAbsent(key, () => []);
      if (bucket.any((s) => s.id == item.id)) continue;
      locByKey[key] = item.location;
      bucket.add(item);
    }

    final keys = {...voirieByKey.keys, ...signaleByKey.keys};
    return keys
        .map(
          (key) => MapProblemCluster(
            location: locByKey[key]!,
            voirie: List.unmodifiable(voirieByKey[key] ?? const []),
            signales: List.unmodifiable(signaleByKey[key] ?? const []),
          ),
        )
        .toList();
  }
}
