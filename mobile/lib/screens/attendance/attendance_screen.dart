import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> attendance = [], students = [], teachers = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final a = await Future.wait([
        ApiService.get('attendance'),
        ApiService.get('students'),
        ApiService.get('teachers'),
      ]);
      if (!mounted) return;
      setState(() {
        attendance = List<dynamic>.from(a[0]['data'] ?? a[0]);
        students = List<dynamic>.from(a[1]['data'] ?? a[1]);
        teachers = List<dynamic>.from(a[2]['data'] ?? a[2]);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  void msg(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> add() async {
    if (students.isEmpty) { msg('أضف طالبًا أولًا'); return; }
    int studentId = students.first['id'];
    int? teacherId = teachers.isEmpty ? null : teachers.first['id'];
    String status = 'present';
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final notes = TextEditingController();
    final key = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('تسجيل حضور'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: studentId,
                    items: students.map((x) => DropdownMenuItem<int>(
                      value: x['id'], child: Text('${x['name'] ?? ''}'),
                    )).toList(),
                    onChanged: (v) { if (v != null) setD(() => studentId = v); },
                    decoration: const InputDecoration(labelText: 'الطالب'),
                  ),
                  if (teachers.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: teacherId,
                      items: teachers.map((x) => DropdownMenuItem<int>(
                        value: x['id'], child: Text('${x['name'] ?? ''}'),
                      )).toList(),
                      onChanged: (v) => setD(() => teacherId = v),
                      decoration: const InputDecoration(labelText: 'المدرس'),
                    ),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'present', child: Text('حاضر')),
                      DropdownMenuItem(value: 'absent', child: Text('غائب')),
                      DropdownMenuItem(value: 'late', child: Text('متأخر')),
                      DropdownMenuItem(value: 'excused', child: Text('معتذر')),
                    ],
                    onChanged: (v) { if (v != null) setD(() => status = v); },
                    decoration: const InputDecoration(labelText: 'الحالة'),
                  ),
                  TextFormField(
                    controller: date,
                    decoration: const InputDecoration(labelText: 'التاريخ YYYY-MM-DD'),
                    validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      await ApiService.post('attendance', {
        'student_id': studentId,
        'teacher_id': teacherId,
        'date': date.text.trim(),
        'status': status,
        'notes': notes.text.trim(),
      });
      await load();
      msg('تم تسجيل الحضور');
    } catch (e) {
      msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحضور'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: attendance.length,
                    itemBuilder: (_, i) {
                      final x = attendance[i];
                      final s = x['student'];
                      final st = '${x['status'] ?? ''}';
                      final label = st == 'present'
                          ? 'حاضر'
                          : st == 'late'
                              ? 'متأخر'
                              : st == 'excused' ? 'معتذر' : 'غائب';
                      final studentName = s is Map ? '${s['name'] ?? 'طالب'}' : 'طالب';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(st == 'present' ? Icons.check : Icons.close)),
                          title: Text(studentName),
                          subtitle: Text('${x['date'] ?? ''}'),
                          trailing: Text(label),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
