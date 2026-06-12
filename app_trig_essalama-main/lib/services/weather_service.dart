import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  /// Récupère la météo actuelle à partir des coordonnées GPS (Open-Meteo API)
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['current_weather'];
      } else {
        throw Exception("Erreur lors de la récupération de la météo : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion météo : $e");
    }
  }
}
