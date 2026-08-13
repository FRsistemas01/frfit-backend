import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// El backend devuelve 402 cuando un usuario free llega al límite de una
/// feature gateada por Premium (chat, foto con IA, recetas guardadas).
class PremiumRequiredException implements Exception {
  const PremiumRequiredException(this.message);
  final String message;
}

/// Cliente HTTP fino sobre el backend Django. Maneja el token de auth y
/// crea/loguea automáticamente un usuario demo local la primera vez que se
/// abre la app, para poder probar el flujo completo sin pantalla de login.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  /// Restaura la sesión guardada, si existe. No crea usuarios automáticamente:
  /// el login/registro es una acción explícita del usuario.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token != null;
  }

  Future<String?> login(String username, String password) async {
    try {
      // 25s, no 8: en el plan free de Render el backend "duerme" sin uso y el
      // primer pedido después de eso puede tardar bastante en despertarlo.
      final res = await http
          .post(Uri.parse('${ApiConfig.baseUrl}/auth/login/'), body: {'username': username, 'password': password})
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200) {
        _token = jsonDecode(res.body)['token'];
        await _persistToken();
        return null;
      }
      return 'Usuario o contraseña incorrectos.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }

  Future<String?> register(String username, String password) async {
    try {
      final res = await http
          .post(Uri.parse('${ApiConfig.baseUrl}/auth/register/'), body: {'username': username, 'password': password})
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 201) {
        _token = jsonDecode(res.body)['token'];
        await _persistToken();
        return null;
      }
      final body = jsonDecode(res.body);
      return body['detail'] ?? 'No se pudo crear la cuenta.';
    } catch (_) {
      return 'No se pudo conectar con el servidor.';
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('onboarding_done');
  }

  Future<void> _persistToken() async {
    if (_token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
  }

  bool get isConnected => _token != null;

  Map<String, String> get _headers => {
        if (_token != null) 'Authorization': 'Token $_token',
      };

  Future<Map<String, dynamic>?> get(String path, {Map<String, String>? query}) async {
    if (_token == null) return null;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> getList(String path, {Map<String, String>? query}) async {
    final result = await _getRaw(path, query: query);
    return result is List ? result : null;
  }

  Future<dynamic> _getRaw(String path, {Map<String, String>? query}) async {
    if (_token == null) return null;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> _postRaw(String path, Map<String, dynamic> body) async {
    if (_token == null) return null;
    http.Response res;
    try {
      // Timeout largo: varios endpoints (recetas, coach, estimaciones) llaman
      // a un modelo de IA y pueden tardar bastante más que un CRUD normal.
      res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      return null;
    }
    if (res.statusCode == 402) {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'] as String? ?? 'Esta función es de Premium.';
      throw PremiumRequiredException(detail);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }

  Future<Map<String, dynamic>?> post(String path, Map<String, dynamic> body) async {
    final result = await _postRaw(path, body);
    return result is Map<String, dynamic> ? result : null;
  }

  /// Como [post] pero para endpoints que devuelven una lista en vez de un objeto
  /// (ej. guardar un plan de comidas crea varias comidas y las devuelve todas).
  Future<List<dynamic>?> postList(String path, Map<String, dynamic> body) async {
    final result = await _postRaw(path, body);
    return result is List ? result : null;
  }

  Future<Map<String, dynamic>?> patch(String path, Map<String, dynamic> body) async {
    if (_token == null) return null;
    try {
      final res = await http
          .patch(Uri.parse('${ApiConfig.baseUrl}$path'), headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> delete(String path) async {
    if (_token == null) return false;
    try {
      final res = await http.delete(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers).timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadPhoto(String path, File file) async {
    if (_token == null) return null;
    http.Response res;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$path'));
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('photo', file.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      return null;
    }
    if (res.statusCode == 402) {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'] as String? ?? 'Esta función es de Premium.';
      throw PremiumRequiredException(detail);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }
}
