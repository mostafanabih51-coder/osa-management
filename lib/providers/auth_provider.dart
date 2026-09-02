import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  final TokenStorage storage;
  AuthStatus status = AuthStatus.initial;
  UserModel? user;
  String? errorMessage;

  AuthProvider({required this.api, required this.storage});
  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    status = AuthStatus.loading; notifyListeners();
    try {
      final token = await storage.readToken();
      if (token == null || token.isEmpty) { status = AuthStatus.unauthenticated; notifyListeners(); return; }
      api.token = token;
      final cached = await storage.readUser();
      if (cached != null) user = UserModel.fromJson(jsonDecode(cached));
      try {
        final response = await api.get(ApiEndpoints.me);
        final raw = response['user'] ?? response['data']?['user'] ?? response['data'];
        if (raw is Map<String, dynamic>) {
          user = UserModel.fromJson(raw);
          await storage.saveUser(jsonEncode(user!.toJson()));
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401) { await logout(notify: false); status = AuthStatus.unauthenticated; notifyListeners(); return; }
      }
      status = AuthStatus.authenticated;
    } catch (_) { await logout(notify: false); status = AuthStatus.unauthenticated; }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    status = AuthStatus.loading; errorMessage = null; notifyListeners();
    try {
      final response = await api.post(ApiEndpoints.login, body: {'email': email.trim(), 'password': password});
      final token = (response['token'] ?? response['access_token'] ?? response['data']?['token'])?.toString();
      if (token == null || token.isEmpty) throw ApiException('لم يتم استلام رمز الدخول من الخادم.');
      api.token = token; await storage.saveToken(token);
      final raw = response['user'] ?? response['data']?['user'];
      if (raw is Map<String, dynamic>) { user = UserModel.fromJson(raw); await storage.saveUser(jsonEncode(user!.toJson())); }
      else {
        try {
          final me = await api.get(ApiEndpoints.me);
          final meRaw = me['user'] ?? me['data']?['user'] ?? me['data'];
          if (meRaw is Map<String, dynamic>) { user = UserModel.fromJson(meRaw); await storage.saveUser(jsonEncode(user!.toJson())); }
        } catch (_) {}
      }
      status = AuthStatus.authenticated; notifyListeners(); return true;
    } on ApiException catch (e) { errorMessage = e.message; }
    catch (_) { errorMessage = 'تعذر الاتصال بالخادم. تأكد من الإنترنت وحاول مرة أخرى.'; }
    status = AuthStatus.unauthenticated; notifyListeners(); return false;
  }

  Future<void> logout({bool notify = true}) async {
    try { if (api.token != null) await api.post(ApiEndpoints.logout); } catch (_) {}
    api.token = null; user = null; await storage.clear(); status = AuthStatus.unauthenticated;
    if (notify) notifyListeners();
  }
}
