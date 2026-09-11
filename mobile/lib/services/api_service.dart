import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static const _tokenKey = 'osa_auth_token';
  static String? token;

  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || savedToken.isEmpty) return false;

    token = savedToken;
    try {
      await get('user');
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/login'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(data, 'بيانات الدخول غير صحيحة'));
    }

    final newToken = data['token'];
    if (newToken is! String || newToken.isEmpty) {
      throw Exception('الخادم لم يُرجع رمز تسجيل دخول صالحًا');
    }

    token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    return data;
  }

  static Future<void> logout() async {
    try {
      if (token != null) {
        await http
            .post(
              Uri.parse('$apiBaseUrl/logout'),
              headers: _authHeaders(),
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Local session is still cleared even when the network is unavailable.
    } finally {
      await clearSession();
    }
  }

  static Future<void> clearSession() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    if (token == null || token!.isEmpty) {
      throw Exception('انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
    }

    final response = await http
        .get(
          Uri.parse('$apiBaseUrl/$endpoint'),
          headers: _authHeaders(),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decode(response);
    if (response.statusCode == 401) {
      await clearSession();
      throw Exception('انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(data, 'تعذر تحميل البيانات'));
    }

    return data;
  }

  static Map<String, String> _authHeaders() => {
        'Authorization': 'Bearer ${token ?? ''}',
        'Accept': 'application/json',
      };

  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _message(Map<String, dynamic> data, String fallback) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    return fallback;
  }
}
