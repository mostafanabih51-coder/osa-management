import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List attendance = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    try {
      final result = await ApiService.get('attendance');
      if (!mounted) return;
      setState(() {
        attendance = result['data'] ?? result['attendance'] ?? [];
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحضور')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: loadAttendance, child: const Text('إعادة المحاولة')),
                  ]),
                ))
              : attendance.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadAttendance,
                      child: ListView(children: const [
                        SizedBox(height: 220),
                        Center(child: Text('لا توجد سجلات حضور حاليًا', style: TextStyle(fontSize: 18))),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: loadAttendance,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: attendance.length,
                        itemBuilder: (_, index) {
                          final item = attendance[index] as Map<String, dynamic>;
                          final status = '${item['status'] ?? ''}';
                          final present = status == 'present';
                          final late = status == 'late';
                          final excused = status == 'excused';
                          final student = item['student'];
                          final studentName = student is Map ? '${student['name'] ?? 'طالب'}' : 'طالب';
                          final label = present ? 'حاضر' : late ? 'متأخر' : excused ? 'معتذر' : 'غائب';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: present ? Colors.green : AppColors.red,
                                child: Icon(present ? Icons.check : Icons.close, color: Colors.white),
                              ),
                              title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['date'] ?? ''}'),
                              trailing: Text(label, style: TextStyle(color: present ? Colors.green : AppColors.red, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
