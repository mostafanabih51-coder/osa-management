import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SchedulesScreen extends StatefulWidget { const SchedulesScreen({super.key}); @override State<SchedulesScreen> createState() => _SchedulesScreenState(); }
class _SchedulesScreenState extends State<SchedulesScreen> {
  List<dynamic> schedules = [], teachers = [], students = [];
  bool loading = true; String? error;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final a = await Future.wait([ApiService.get('schedules'), ApiService.get('teachers'), ApiService.get('students')]);
      if (mounted) setState(() { schedules = List<dynamic>.from(a[0]['data'] ?? a[0]); teachers = List<dynamic>.from(a[1]['data'] ?? a[1]); students = List<dynamic>.from(a[2]['data'] ?? a[2]); loading = false; error = null; });
    } catch (e) { if (mounted) setState(() { loading = false; error = e.toString(); }); }
  }
  Future<void> add() async {
    String type = 'private'; int? teacherId = teachers.isEmpty ? null : teachers.first['id']; int? studentId = students.isEmpty ? null : students.first['id'];
    final group = TextEditingController(), subject = TextEditingController(), start = TextEditingController(), end = TextEditingController(), zoom = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: const Text('إضافة جدول / حصة'),
      content: SingleChildScrollView(child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: type, items: const [DropdownMenuItem(value: 'private', child: Text('فردية')), DropdownMenuItem(value: 'group', child: Text('مجموعة'))], onChanged: (v) { if (v != null) setD(() => type = v); }, decoration: const InputDecoration(labelText: 'نوع الحصة')),
        DropdownButtonFormField<int>(value: teacherId, items: teachers.map((x) => DropdownMenuItem<int>(value: x['id'], child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => teacherId = v), decoration: const InputDecoration(labelText: 'المدرس')),
        if (type == 'private' && students.isNotEmpty) DropdownButtonFormField<int>(value: studentId, items: students.map((x) => DropdownMenuItem<int>(value: x['id'], child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => studentId = v), decoration: const InputDecoration(labelText: 'الطالب')),
        if (type == 'group') TextFormField(controller: group, decoration: const InputDecoration(labelText: 'اسم المجموعة'), validator: (v) => v!.trim().isEmpty ? 'اكتب اسم المجموعة' : null),
        TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'المادة'), validator: (v) => v!.trim().isEmpty ? 'اكتب المادة' : null),
        TextFormField(controller: start, decoration: const InputDecoration(labelText: 'البداية YYYY-MM-DD HH:MM'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: end, decoration: const InputDecoration(labelText: 'النهاية YYYY-MM-DD HH:MM'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: zoom, decoration: const InputDecoration(labelText: 'رابط Zoom (اختياري)')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); }, child: const Text('حفظ'))],
    )));
    if (ok != true) return;
    try { await ApiService.post('schedules', {'type': type, 'teacher_id': teacherId, 'student_id': type == 'private' ? studentId : null, 'group_name': type == 'group' ? group.text.trim() : null, 'subject': subject.text.trim(), 'starts_at': start.text.trim(), 'ends_at': end.text.trim(), 'zoom_url': zoom.text.trim().isEmpty ? null : zoom.text.trim()}); await load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('الجداول والحصص'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]), floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)), body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) : RefreshIndicator(onRefresh: load, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: schedules.length, itemBuilder: (_, i) { final x = schedules[i]; final t = x['teacher']; final s = x['student']; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.calendar_month)), title: Text('${x['subject'] ?? 'حصة'}'), subtitle: Text('${x['starts_at'] ?? ''}\nالمدرس: ${t is Map ? t['name'] ?? '' : 'غير محدد'}${s is Map ? '\nالطالب: ${s['name'] ?? ''}' : ''}${x['group_name'] != null ? '\nالمجموعة: ${x['group_name']}' : ''}'))); }));
}
