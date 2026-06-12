import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _keyDeparture = 'recent_searches_departure';
  static const String _keyDestination = 'recent_searches_destination';
  static const String _savedPlacesKey = 'saved_places_json';
  static const int _maxHistorySize = 20;

  static String _keyForType(String type) =>
      type == 'departure' ? _keyDeparture : _keyDestination;

  /// Récupère l'historique selon le type (départ / destination).
  static Future<List<Map<String, dynamic>>> getHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForType(type);
    final String? jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ajoute une recherche (max [_maxHistorySize], sans doublon).
  static Future<void> addSearch(Map<String, dynamic> search, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForType(type);
    final List<Map<String, dynamic>> history = await getHistory(type);

    history.removeWhere(
      (item) =>
          item['display_name'] == search['display_name'] ||
          _sameCoords(item, search),
    );

    history.insert(0, search);

    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    await prefs.setString(key, jsonEncode(history));
  }

  static bool _sameCoords(Map<String, dynamic> a, Map<String, dynamic> b) {
    final la = a['lat'];
    final lo = a['lon'];
    final lb = b['lat'];
    final ob = b['lon'];
    if (la == null || lo == null || lb == null || ob == null) return false;
    return _numEquals(la, lb) && _numEquals(lo, ob);
  }

  static bool _numEquals(dynamic a, dynamic b) {
    final da = a is num ? a.toDouble() : double.tryParse('$a');
    final db = b is num ? b.toDouble() : double.tryParse('$b');
    if (da == null || db == null) return false;
    return (da - db).abs() < 1e-6;
  }

  /// Supprime une entrée de l'historique.
  static Future<void> removeSearch(Map<String, dynamic> search, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForType(type);
    final history = await getHistory(type);
    history.removeWhere(
      (item) =>
          item['display_name'] == search['display_name'] ||
          _sameCoords(item, search),
    );
    await prefs.setString(key, jsonEncode(history));
  }

  /// Vide l'historique selon le type.
  static Future<void> clearHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForType(type));
  }

  /// Lieux enregistrés (depuis une suggestion Nominatim).
  static Future<List<Map<String, dynamic>>> getSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_savedPlacesKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlace(Map<String, dynamic> place) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedPlaces();
    list.removeWhere(
      (e) =>
          e['display_name'] == place['display_name'] ||
          _sameCoords(e, place),
    );
    list.insert(0, Map<String, dynamic>.from(place));
    const maxSaved = 30;
    if (list.length > maxSaved) {
      list.removeRange(maxSaved, list.length);
    }
    await prefs.setString(_savedPlacesKey, jsonEncode(list));
  }
}
