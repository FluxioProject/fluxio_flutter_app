import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:tcc_flutter_mobile/global/global_variables.dart';
import 'package:tcc_flutter_mobile/pages/first_screens/login.dart';
import 'package:tcc_flutter_mobile/widgets/show_message.dart';

class Session {
  Map<String, String> headers = {};
  final http.Client _client = http.Client();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final String url = 'https://us-central1-tcc2026-7d3c4.cloudfunctions.net/api';

  Session() {
    _setApiKey();
  }

  void _setApiKey() {
    headers['x-api-key'] = 'ycevqNVkJRs5vSImbfCe6zpI8LBthNd4';
  }

  Future<void> loadCookie() async {
    try {
      String? savedCookie = await secureStorage.read(key: 'cookie');
      if (savedCookie != null) {
        headers['cookie'] = savedCookie;
      }
    } catch (e) {
      // tratativa de erro para BAD_DECRYPT (erro de decriptação do cookie, provavelmente corrompido)
      final errorStr = e.toString();
      if (errorStr.contains('BAD_DECRYPT')) {
        await secureStorage.delete(key: 'cookie'); // mais seguro que deleteAll
        headers.remove('cookie');
      }
    }
  }

  Future<void> saveCookie(String cookie) async {
    await secureStorage.write(key: 'cookie', value: cookie);
  }

  void updateCookie(http.Response response) {
    if (response.body == 'Token inválido') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      String cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
      headers['cookie'] = cookie;
      saveCookie(cookie); // Salvar o cookie no shared_preferences
    }
  }

  Future<Map<String, dynamic>> patchObj(
    String endpoint,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    await loadCookie();

    try {
      final response = await _client.patch(
        Uri.parse('$url/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...headers,
        },
        body: jsonEncode(data),
      );

      await _handleTokenErrorIfNeeded(context, response.body);

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic>) {
        return jsonResponse;
      } else {
        throw Exception('Resposta não é um objeto JSON válido.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getObj(String endpoint, BuildContext context) async {
    await loadCookie();

    try {
      final uri = Uri.parse('$url/$endpoint');

      final response = await _client.get(uri, headers: headers);

      await _handleTokenErrorIfNeeded(context, response.body);

      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        } else {
          return response.body;
        }
      } catch (e) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> get(String endpoint, {Map<String, String>? query}) async {
    await loadCookie();

    try {
      final uri = Uri.parse('$url/$endpoint').replace(queryParameters: query);

      final response = await _client.get(uri, headers: headers);
      updateCookie(response);

      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('message')) {
          return jsonResponse['message'].toString();
        } else {
          return response.body;
        }
      } catch (e) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> delete(String endpoint, {Map<String, dynamic>? data}) async {
    await loadCookie();

    try {
      final response = await _client.delete(
        Uri.parse('$url/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...headers,
        },
        body: data != null ? jsonEncode(data) : null,
      );
      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('message')) {
          return jsonResponse['message'].toString();
        } else {
          return response.body;
        }
      } catch (e) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await loadCookie();

    final response = await _client.post(
      Uri.parse('$url/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers,
      },
      body: jsonEncode(data),
    );
    updateCookie(response);

    final body = response.body.trim();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is String) {
          throw Exception(decoded);
        }
        if (decoded is Map && decoded['message'] != null) {
          throw Exception(decoded['message'].toString());
        }
      } catch (_) {
        throw Exception(body.isEmpty ? 'Erro inesperado' : body);
      }
    }

    if (body.isEmpty) return {};

    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': body};
    }
  }

  Future<Map<String, dynamic>> postObj(
    String endpoint,
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    await loadCookie();

    final response = await _client.post(
      Uri.parse('$url/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers,
      },
      body: jsonEncode(data),
    );

    updateCookie(response);
    await _handleTokenErrorIfNeeded(context, response.body);

    // ERRO vindo do backend
    if (response.statusCode >= 400) {
      throw Exception(response.body);
    }

    // Tenta converter JSON
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception('Resposta inválida do servidor.');
      }
    } catch (_) {
      throw Exception(response.body);
    }
  }

  Future<String> patch(String endpoint, Map<String, dynamic> data) async {
    await loadCookie();

    try {
      final response = await _client.patch(
        Uri.parse('$url/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...headers,
        },
        body: jsonEncode(data),
      );

      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('message')) {
          return jsonResponse['message'].toString();
        } else {
          return response.body;
        }
      } catch (e) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> put(String endpoint, Map<String, dynamic> data) async {
    await loadCookie();

    try {
      final response = await _client.put(
        Uri.parse('$url/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...headers,
        },
        body: jsonEncode(data),
      );
      try {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('message')) {
          return jsonResponse['message'].toString();
        } else {
          return response.body;
        }
      } catch (e) {
        return response.body;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleTokenErrorIfNeeded(
    BuildContext context,
    String responseBody,
  ) async {
    if (responseBody.contains('Token inválido')) {
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => LoginScreen()),
      // );
      showMessage(context, "sessionend", true);
    }
  }
}
