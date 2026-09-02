import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient api;
  DashboardProvider(this.api);
  DashboardModel data = DashboardModel.empty();
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try { data = DashboardModel.fromJson(await api.get(ApiEndpoints.dashboard)); }
    on ApiException catch (e) { error = e.message; }
    catch (_) { error = 'تعذر تحميل بيانات لوحة التحكم.'; }
    loading = false; notifyListeners();
  }
}
