import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List schedules = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    try {
      final result = await ApiService.get('schedules');
      if (!mounted) return;
      setState(() {
        schedules = result['data'] ?? result['schedules'] ?? [];
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
      appBar: AppBar(title: const Text('الجداول والحصص')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: loadSchedules, child: const Text('إعادة المحاولة')),
                  ]),
                ))
              : schedules.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadSchedules,
                      child: ListView(children: const [
                        SizedBox(height: 220),
                        Center(child: Text('لا توجد حصص مسجلة حاليًا', style: TextStyle(fontSize: 18))),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: loadSchedules,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: schedules.length,
                        itemBuilder: (_, index) {
                          final item = schedules[index] as Map<String, dynamic>;
                          final teacher = item['teacher'];
                          final student = item['student'];
                          final teacherName = teacher is Map ? '${teacher['name'] ?? ''}' : '';
                          final studentName = student is Map ? '${student['name'] ?? ''}' : '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.video_camera_front)),
                              title: Text('${item['subject'] ?? 'حصة'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text([
                                if (item['starts_at'] != null) '${item['starts_at']}',
                                if (teacherName.isNotEmpty) 'المدرس: $teacherName',
                                if (studentName.isNotEmpty) 'الطالب: $studentName',
                              ].join('\n')),
                              isThreeLine: teacherName.isNotEmpty || studentName.isNotEmpty,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
