import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static const _defaultBase = 'https://admin.muteatalriyadiaat.com/api';
  final String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBase).replaceFirst(RegExp(r'/+$'), '');
  String? token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query.map((k,v) => MapEntry(k, v.toString())));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await http.get(_uri(path, query), headers: _headers).timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException('تعذر الاتصال بالخادم.');
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException('تعذر الاتصال بالخادم.');
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 20));
      return _decode(response);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException('تعذر الاتصال بالخادم.');
    }
  }

  Future<void> delete(String path) async {
    try {
      final response = await http.delete(_uri(path), headers: _headers).timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _decode(response);
      }
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on http.ClientException {
      throw ApiException('تعذر الاتصال بالخادم.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic data;
    try { data = jsonDecode(response.body); } catch (_) { data = null; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : data is Map && data['error'] != null
              ? data['error'].toString()
              : 'حدث خطأ أثناء الاتصال بالخادم (${response.statusCode})';
      throw ApiException(message, statusCode: response.statusCode);
    }
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }
}
