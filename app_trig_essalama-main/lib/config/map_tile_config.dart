import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

/// Configuration des tuiles cartographiques.
///
/// OpenStreetMap limite fortement le trafic : pas de mode rétina simulé,
/// User-Agent explicite, et erreurs de tuiles gérées silencieusement.
class MapTileConfig {
  MapTileConfig._();

  static const String packageName = 'com.trigressalama.app';
  static const String urlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String userAgent =
      'Trig_Essalama/1.0 ($packageName; Flutter; contact@trig_essalama.com)';

  static TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: packageName,
      // OSM ne fournit pas de tuiles @2x : la simulation multiplie les requêtes
      // et provoque des "Connection reset by peer".
      retinaMode: false,
      tileProvider: NetworkTileProvider(
        headers: {'User-Agent': userAgent},
      ),
      errorTileCallback: (tile, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Tuile carte indisponible (${tile.coordinates}): $error');
        }
      },
    );
  }
}
