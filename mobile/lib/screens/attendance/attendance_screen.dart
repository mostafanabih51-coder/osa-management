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
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحضور')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : attendance.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد سجلات حضور حاليًا',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadAttendance,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attendance.length,
                    itemBuilder: (_, index) {
                      final item = attendance[index];
                      final present =
                          item['status'] == 'present' ||
                          item['present'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                present ? Colors.green : AppColors.red,
                            child: Icon(
                              present ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${item['student_name'] ?? item['student'] ?? 'طالب'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${item['date'] ?? ''}',
                          ),
                          trailing: Text(
                            present ? 'حاضر' : 'غائب',
                            style: TextStyle(
                              color: present ? Colors.green : AppColors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
