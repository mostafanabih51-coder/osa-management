import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/student_model.dart';

class StudentsProvider extends ChangeNotifier {
  final ApiClient api;
  StudentsProvider(this.api);
  List<StudentModel> students = [];
  bool loading = false;
  String? error;
  int page = 1;
  bool hasMore = false;
  String search = '';

  Future<void> load({String? query, bool append = false}) async {
    if (!append) { page = 1; students = []; }
    loading = true; error = null; notifyListeners();
    try {
      final q = <String, dynamic>{'page': page};
      final term = query ?? search;
      if (term.trim().isNotEmpty) q['search'] = term.trim();
      final response = await api.get(ApiEndpoints.students, query: q);
      final raw = response['data'] ?? response['students'] ?? response;
      List<dynamic> items = [];
      if (raw is List) items = raw;
      if (raw is Map && raw['data'] is List) items = raw['data'];
      final parsed = items.whereType<Map>().map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e))).toList();
      students = append ? [...students, ...parsed] : parsed;
      final meta = response['meta'] ?? (raw is Map ? raw['meta'] : null);
      if (meta is Map) {
        final current = int.tryParse(meta['current_page']?.toString() ?? '') ?? page;
        final last = int.tryParse(meta['last_page']?.toString() ?? '') ?? current;
        hasMore = current < last;
      } else { hasMore = parsed.length >= 15; }
    } on ApiException catch (e) { error = e.message; }
    catch (_) { error = 'تعذر تحميل الطلاب.'; }
    loading = false; notifyListeners();
  }

  Future<bool> save({int? id, required Map<String, dynamic> data}) async {
    try {
      if (id == null) await api.post(ApiEndpoints.students, body: data);
      else await api.put(ApiEndpoints.student(id), body: data);
      await load(query: search);
      return true;
    } on ApiException catch (e) { error = e.message; notifyListeners(); return false; }
  }

  Future<bool> remove(int id) async {
    try { await api.delete(ApiEndpoints.student(id)); await load(query: search); return true; }
    on ApiException catch (e) { error = e.message; notifyListeners(); return false; }
  }
}
