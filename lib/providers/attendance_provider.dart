import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/attendance_model.dart';
import '../models/group_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiClient api;
  AttendanceProvider(this.api);

  List<AttendanceRecord> records = [];
  List<GroupModel> groups = [];
  bool loading = false;
  bool saving = false;
  String? error;
  DateTime selectedDate = DateTime.now();
  int? selectedGroupId;

  Future<void> loadGroups() async {
    try {
      final response = await api.get(ApiEndpoints.groups, query: {'page': 1, 'per_page': 100});
      final raw = response['data'] ?? response['groups'] ?? response;
      List<dynamic> items = [];
      if (raw is List) items = raw;
      if (raw is Map && raw['data'] is List) items = raw['data'];
      groups = items.whereType<Map>().map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.id > 0).toList();
      if (selectedGroupId == null && groups.isNotEmpty) selectedGroupId = groups.first.id;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadAttendance() async {
    if (selectedGroupId == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.get(ApiEndpoints.attendance, query: {
        'group_id': selectedGroupId,
        'date': _dateString,
      });
      final raw = response['data'] ?? response['attendance'] ?? response;
      List<dynamic> items = [];
      if (raw is List) items = raw;
      if (raw is Map && raw['data'] is List) items = raw['data'];
      records = items.whereType<Map>().map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e))).where((e) => e.studentId > 0).toList();
    } on ApiException catch (e) {
      error = e.message;
      records = [];
    } catch (_) {
      error = 'تعذر تحميل سجل الحضور.';
      records = [];
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> saveAttendance() async {
    if (selectedGroupId == null || records.isEmpty) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await api.post(ApiEndpoints.attendance, body: {
        'group_id': selectedGroupId,
        'date': _dateString,
        'records': records.map((r) => {
          'student_id': r.studentId,
          'status': r.status,
          if (r.note != null && r.note!.trim().isNotEmpty) 'note': r.note,
        }).toList(),
      });
      await loadAttendance();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'تعذر حفظ الحضور.';
      notifyListeners();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void setGroup(int? id) {
    selectedGroupId = id;
    records = [];
    notifyListeners();
    loadAttendance();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    records = [];
    notifyListeners();
    loadAttendance();
  }

  void setStatus(int studentId, String status) {
    final index = records.indexWhere((r) => r.studentId == studentId);
    if (index >= 0) records[index] = records[index].copyWith(status: status);
    notifyListeners();
  }

  String get _dateString => '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
}
