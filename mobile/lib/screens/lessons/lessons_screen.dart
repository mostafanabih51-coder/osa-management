import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List lessons = [], teachers = [], students = [], supervisors = [], groups = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); load(); }

  List<dynamic> list(dynamic v) => v is List ? List<dynamic>.from(v) : (v is Map && v['data'] is List ? List<dynamic>.from(v['data']) : []);

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([ApiService.get('lessons'), ApiService.get('teachers'), ApiService.get('students'), ApiService.get('supervisors'), ApiService.get('groups')]);
      if (!mounted) return;
      setState(() { lessons = list(r[0]); teachers = list(r[1]); students = list(r[2]); supervisors = list(r[3]); groups = list(r[4]); loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> createGroup() async {
    final name = TextEditingController(), grade = TextEditingController(), subject = TextEditingController(), notes = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('إضافة مجموعة'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المجموعة'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
        TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'المادة')),
        TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); }, child: const Text('حفظ'))],
    ));
    if (ok != true) return;
    try { await ApiService.post('groups', {'name': name.text.trim(), 'grade': grade.text.trim(), 'subject': subject.text.trim(), 'notes': notes.text.trim()}); await load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء المجموعة'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> addLesson() async {
    if (teachers.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مدرسًا أولًا'))); return; }
    String type = 'private';
    int teacherId = teachers.first['id'] as int;
    int? studentId = students.isEmpty ? null : students.first['id'] as int;
    int? supervisorId = supervisors.isEmpty ? null : supervisors.first['id'] as int;
    int? groupId = groups.isEmpty ? null : groups.first['id'] as int;
    final subject = TextEditingController();
    final starts = TextEditingController(text: '${DateTime.now().toIso8601String().substring(0, 10)} 16:00');
    final ends = TextEditingController(text: '${DateTime.now().toIso8601String().substring(0, 10)} 17:00');
    final teacherRate = TextEditingController(text: '0');
    final supervisorRate = TextEditingController(text: '0');
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setD) => AlertDialog(
      title: const Text('إضافة حصة'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'نوع الحصة'), items: const [DropdownMenuItem(value: 'private', child: Text('خاصة')), DropdownMenuItem(value: 'group', child: Text('مجموعة'))], onChanged: (v) { if (v != null) setD(() => type = v); }),
        DropdownButtonFormField<int>(initialValue: teacherId, decoration: const InputDecoration(labelText: 'المدرس'), items: teachers.map((x) => DropdownMenuItem<int>(value: x['id'] as int, child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) { if (v != null) setD(() => teacherId = v); }),
        if (type == 'private' && students.isNotEmpty) DropdownButtonFormField<int>(initialValue: studentId, decoration: const InputDecoration(labelText: 'الطالب'), items: students.map((x) => DropdownMenuItem<int>(value: x['id'] as int, child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => studentId = v)),
        if (type == 'group' && groups.isNotEmpty) DropdownButtonFormField<int>(initialValue: groupId, decoration: const InputDecoration(labelText: 'المجموعة'), items: groups.map((x) => DropdownMenuItem<int>(value: x['id'] as int, child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => groupId = v)),
        if (type == 'group' && groups.isEmpty) Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () async { Navigator.pop(context); await createGroup(); await addLesson(); }, icon: const Icon(Icons.add), label: const Text('أنشئ مجموعة أولًا'))),
        if (supervisors.isNotEmpty) DropdownButtonFormField<int?>(initialValue: supervisorId, decoration: const InputDecoration(labelText: 'المشرف'), items: [const DropdownMenuItem<int?>(value: null, child: Text('بدون مشرف')), ...supervisors.map((x) => DropdownMenuItem<int?>(value: x['id'] as int, child: Text('${x['name'] ?? ''}')))], onChanged: (v) => setD(() => supervisorId = v)),
        TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'المادة'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل المادة' : null),
        TextFormField(controller: starts, decoration: const InputDecoration(labelText: 'البداية YYYY-MM-DD HH:MM'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: ends, decoration: const InputDecoration(labelText: 'النهاية YYYY-MM-DD HH:MM'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: teacherRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مستحق المدرس')),
        TextFormField(controller: supervisorRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'مستحق المشرف')),
      ])),),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate() && (type == 'private' ? studentId != null : groupId != null)) Navigator.pop(context, true); }, child: const Text('حفظ'))],
    )));
    if (ok != true) return;
    try {
      await ApiService.post('lessons', {'type': type, 'teacher_id': teacherId, 'supervisor_id': supervisorId, 'group_id': type == 'group' ? groupId : null, 'student_id': type == 'private' ? studentId : null, 'subject': subject.text.trim(), 'starts_at': starts.text.trim(), 'ends_at': ends.text.trim(), 'teacher_rate': double.tryParse(teacherRate.text) ?? 0, 'supervisor_rate': double.tryParse(supervisorRate.text) ?? 0, 'status': 'scheduled'});
      await load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الحصة')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدروس والحصص'), actions: [IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh)), IconButton(onPressed: createGroup, icon: const Icon(Icons.group_add))]),
      floatingActionButton: FloatingActionButton(onPressed: addLesson, child: const Icon(Icons.add)),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? _error() : lessons.isEmpty ? const Center(child: Text('لا توجد حصص مسجلة')) : RefreshIndicator(
        onRefresh: load,
        child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: lessons.length, itemBuilder: (_, i) {
          final x = lessons[i] as Map<String, dynamic>;
          final t = x['teacher']; final s = x['student']; final g = x['group'];
          final person = s is Map ? (s['name'] ?? '') : (g is Map ? 'مجموعة: ${g['name'] ?? ''}' : 'حصة');
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.menu_book)), title: Text('${x['subject'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${t is Map ? (t['name'] ?? '') : ''} • $person\n${x['starts_at'] ?? ''} → ${x['ends_at'] ?? ''}'), isThreeLine: true, trailing: Text('${x['teacher_due'] ?? 0}')));
        }),
      ),
    );
  }

  Widget _error() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 52), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))])));
}
