import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _tokenKey = 'osa_auth_token';
  static String? token;
  static VoidCallback? onUnauthorized;

  static Future<bool> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_tokenKey);
    if (t == null || t.isEmpty) {
      token = null;
      return false;
    }
    token = t;
    try {
      await get('user');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await clearSession();
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(const Duration(seconds: 20));
    final d = _decode(r);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(r.statusCode, _message(d, 'بيانات الدخول غير صحيحة'));
    }
    final t = d['token'];
    if (t is! String || t.isEmpty) {
      throw const ApiException(500, 'الخادم لم يُرجع رمز تسجيل دخول صالحًا');
    }
    token = t;
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, t);
    return d;
  }

  static Future<void> logout() async {
    try {
      if (token != null) {
        await http.post(Uri.parse('$apiBaseUrl/logout'), headers: _authHeaders()).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
    } finally {
      await clearSession();
    }
  }

  static Future<void> clearSession() async {
    token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    _requireToken();
    final r = await http.get(Uri.parse('$apiBaseUrl/$endpoint'), headers: _authHeaders()).timeout(const Duration(seconds: 20));
    return _handle(r, 'تعذر تحميل البيانات');
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    _requireToken();
    final r = await http.post(
      Uri.parse('$apiBaseUrl/$endpoint'),
      headers: {..._authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return _handle(r, 'تعذر حفظ البيانات');
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    _requireToken();
    final r = await http.put(
      Uri.parse('$apiBaseUrl/$endpoint'),
      headers: {..._authHeaders(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return _handle(r, 'تعذر تحديث البيانات');
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    _requireToken();
    final r = await http.delete(
      Uri.parse('$apiBaseUrl/$endpoint'),
      headers: _authHeaders(),
    ).timeout(const Duration(seconds: 20));
    return _handle(r, 'تعذر حذف البيانات');
  }

  static void _requireToken() {
    if (token == null || token!.isEmpty) {
      onUnauthorized?.call();
      throw const ApiException(401, 'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
    }
  }

  static Map<String, String> _authHeaders() => {
    'Authorization': 'Bearer ${token ?? ''}',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> _handle(http.Response r, String fallback) async {
    final d = _decode(r);
    if (r.statusCode == 401) {
      await clearSession();
      onUnauthorized?.call();
      throw const ApiException(401, 'انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      var m = _message(d, fallback);
      final errors = d['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final f = errors.values.first;
        if (f is List && f.isNotEmpty) m = '${f.first}';
      }
      throw ApiException(r.statusCode, m);
    }
    return d;
  }

  static Map<String, dynamic> _decode(http.Response r) {
    if (r.body.isEmpty) return {};
    try {
      final d = jsonDecode(r.body);
      return d is Map<String, dynamic> ? d : {'data': d};
    } catch (_) {
      return {};
    }
  }

  static String _message(Map<String, dynamic> d, String f) {
    final m = d['message'];
    return m is String && m.isNotEmpty ? m : f;
  }
}
