import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> groups = [], students = [], teachers = [], supervisors = [];
  List<String> subjects = [];
  bool loading = true;
  static const fallback = ['العربية','اللغة الإنجليزية','الرياضيات','العلوم','الدراسات الاجتماعية','Math','Science','English','Arabic','German','French','Spanish','Quran'];

  List<dynamic> list(dynamic v) {
    if (v is List) return List<dynamic>.from(v);
    if (v is Map) {
      final d = v['data'];
      if (d is List) return List<dynamic>.from(d);
      if (d is Map && d['data'] is List) return List<dynamic>.from(d['data']);
    }
    return [];
  }
  int id(dynamic v) => int.tryParse('${v['id']}') ?? 0;
  String sub(dynamic v) => v is Map ? '${v['subject'] ?? v['name'] ?? ''}' : '$v';
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    Object? error;
    try { final r = await ApiService.get('groups'); if (mounted) setState(() => groups = list(r)); } catch (e) { error = e; }
    try { final r = await ApiService.get('students'); if (mounted) setState(() => students = list(r)); } catch (_) {}
    try { final r = await ApiService.get('teachers'); if (mounted) setState(() => teachers = list(r)); } catch (_) {}
    try { final r = await ApiService.get('supervisors'); if (mounted) setState(() => supervisors = list(r)); } catch (_) {}
    try { final r = await ApiService.get('subjects'); final s = list(r).map(sub).where((x) => x.isNotEmpty).toSet().toList(); if (mounted) setState(() => subjects = s.isEmpty ? fallback : s); } catch (_) { if (mounted) setState(() => subjects = fallback); }
    if (mounted) { setState(() => loading = false); if (error != null) msg(error!); }
  }

  Future<void> form({Map<String, dynamic>? existing}) async {
    if (teachers.isEmpty) { msg(Exception('أضف مدرسًا أولًا.')); return; }
    if (students.isEmpty) { msg(Exception('أضف طالبًا أولًا.')); return; }
    final editing = existing != null;
    int? teacherId = editing ? id(existing!['teacher']) : id(teachers.first);
    if (!teachers.any((t) => id(t) == teacherId)) teacherId = id(teachers.first);
    int? supervisorId = editing ? id(existing!['supervisor']) : null;
    if (supervisorId == 0 || !supervisors.any((s) => id(s) == supervisorId)) supervisorId = null;
    String subject = editing ? '${existing!['subject'] ?? ''}' : (subjects.isEmpty ? fallback.first : subjects.first);
    final availableSubjects = subjects.isEmpty ? fallback : subjects;
    if (!availableSubjects.contains(subject)) subject = availableSubjects.first;
    final name = TextEditingController(text: editing ? '${existing!['name'] ?? ''}' : '');
    final rate = TextEditingController(text: editing ? '${existing!['teacher_rate'] ?? ''}' : '');
    final grade = TextEditingController(text: editing ? '${existing!['grade'] ?? ''}' : '');
    final notes = TextEditingController(text: editing ? '${existing!['notes'] ?? ''}' : '');
    final selected = <int>{};
    if (editing && existing!['students'] is List) {
      for (final s in existing!['students']) selected.add(id(s));
    }
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final studentTiles = students.map((s) {
            final sid = id(s);
            return CheckboxListTile(
              value: selected.contains(sid),
              title: Text('${s['name']}'),
              onChanged: (value) => setDialogState(() { if (value == true) selected.add(sid); else selected.remove(sid); }),
            );
          }).toList();
          return AlertDialog(
            title: Text(editing ? 'تعديل المجموعة' : 'إنشاء مجموعة'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(children: [
                    TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المجموعة *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                    TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
                    DropdownButtonFormField<int>(
                      value: teacherId,
                      decoration: const InputDecoration(labelText: 'المدرس *'),
                      items: teachers.map((t) => DropdownMenuItem(value: id(t), child: Text('${t['name']}'))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => teacherId = v); },
                    ),
                    DropdownButtonFormField<int?>(
                      value: supervisorId,
                      decoration: const InputDecoration(labelText: 'المشرف (اختياري)'),
                      items: [const DropdownMenuItem<int?>(value: null, child: Text('بدون مشرف')), ...supervisors.map((s) => DropdownMenuItem<int?>(value: id(s), child: Text('${s['name']}')))],
                      onChanged: (v) => setDialogState(() => supervisorId = v),
                    ),
                    DropdownButtonFormField<String>(
                      value: subject,
                      decoration: const InputDecoration(labelText: 'المادة *'),
                      items: availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => subject = v); },
                    ),
                    TextFormField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الحصة *'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل السعر' : null),
                    TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
                    const SizedBox(height: 8),
                    const Align(alignment: Alignment.centerRight, child: Text('طلاب المجموعة', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...studentTiles,
                  ]),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate() && selected.isNotEmpty) Navigator.pop(dialogContext, true);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      try {
        final payload = {
          'name': name.text.trim(),
          'grade': grade.text.trim().isEmpty ? null : grade.text.trim(),
          'subject': subject,
          'teacher_id': teacherId,
          'supervisor_id': supervisorId,
          'teacher_rate': double.parse(rate.text),
          'student_ids': selected.toList(),
          'status': 'active',
          'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        };
        if (editing) {
          await ApiService.put('groups/${id(existing)}', payload);
        } else {
          await ApiService.post('groups', payload);
        }
        await load();
      } catch (e) { msg(e); }
    }
    name.dispose(); rate.dispose(); grade.dispose(); notes.dispose();
  }

  Future<void> remove(dynamic group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المجموعة'), content: Text('حذف ${group['name'] ?? ''}؟'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف'))],
      ),
    );
    if (ok == true) {
      try { await ApiService.delete('groups/${id(group)}'); await load(); } catch (e) { msg(e); }
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجموعات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => form(), icon: const Icon(Icons.groups), label: const Text('إنشاء مجموعة')),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: load,
        child: groups.isEmpty ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا توجد مجموعات بعد.'))]) : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), itemCount: groups.length,
          itemBuilder: (context, index) {
            final g = Map<String, dynamic>.from(groups[index]);
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.groups)),
              title: Text('${g['name'] ?? ''}'),
              subtitle: Text('المدرس: ${g['teacher']?['name'] ?? ''}\nالمشرف: ${g['supervisor']?['name'] ?? 'بدون'}\nالمادة: ${g['subject'] ?? ''} • الطلاب: ${g['students_count'] ?? 0}'),
              isThreeLine: true,
              trailing: Wrap(children: [IconButton(onPressed: () => form(existing: g), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(g), icon: const Icon(Icons.delete))]),
            ));
          },
        ),
      ),
    );
  }
}
