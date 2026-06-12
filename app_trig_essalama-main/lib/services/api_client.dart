import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ApiClient {
  final String baseUrl;
  final AuthProvider auth;

  ApiClient({required this.baseUrl, required this.auth});

  Map<String, String> _headers() {
    return apiJsonHeaders(token: auth.token);
  }

  /// Intercepte les réponses pour gérer les erreurs globales (ex: 401)
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Si le token est expiré ou invalide, on déconnecte l'utilisateur
      auth.logout();
    }
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }

  /// Ouvre un flux SSE (GET long). L’appelant doit fermer [http.Client] à la fin.
  Future<(http.StreamedResponse response, http.Client client)> openSseStream(
    String endpoint,
  ) async {
    final client = http.Client();
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.Request('GET', uri);
    request.headers.addAll({
      if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });
    final streamed = await client.send(request);
    if (streamed.statusCode == 401) {
      client.close();
      auth.logout();
      throw Exception('Non autorise');
    }
    if (streamed.statusCode != 200) {
      client.close();
      throw Exception('Flux SSE (${streamed.statusCode})');
    }
    return (streamed, client);
  }

  Future<http.Response> post(String endpoint, dynamic body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(String endpoint, dynamic body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers(),
    );
    return _handleResponse(response);
  }
}
