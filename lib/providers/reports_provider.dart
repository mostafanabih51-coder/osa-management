import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/report_model.dart';

class ReportsProvider extends ChangeNotifier {
  final ApiClient api;
  ReportsProvider(this.api);

  ReportSummary data = ReportSummary.empty;
  bool loading = false;
  String? error;
  String period = 'month';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      data = ReportSummary.fromJson(
        await api.get(
          ApiEndpoints.reports,
          query: {'period': period},
        ),
      );
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'تعذر تحميل بيانات التقارير.';
    }

    loading = false;
    notifyListeners();
  }

  Future<void> setPeriod(String value) async {
    if (period == value) return;
    period = value;
    await load();
  }
}
