import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> students = [];
  List<String> subjects = [];
  bool loading = true;
  static const fallback = ['العربية','اللغة الإنجليزية','الرياضيات','العلوم','الدراسات الاجتماعية','Math','Science','English','Arabic','German','French','Spanish','Quran'];

  List<dynamic> list(dynamic v) {
    if (v is List) return List<dynamic>.from(v);
    if (v is Map) {
      final x = v['data'];
      if (x is List) return List<dynamic>.from(x);
      if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']);
    }
    return [];
  }
  int id(dynamic v) => int.tryParse('${v['id']}') ?? 0;
  String subjectName(dynamic v) => v is Map ? '${v['subject'] ?? v['name'] ?? ''}' : '$v';
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    Object? error;
    try { final r = await ApiService.get('students'); if (mounted) setState(() => students = list(r)); } catch (e) { error = e; }
    try {
      final r = await ApiService.get('subjects');
      final s = list(r).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList();
      if (mounted) setState(() => subjects = s.isEmpty ? fallback : s);
    } catch (_) { if (mounted) setState(() => subjects = fallback); }
    if (mounted) { setState(() => loading = false); if (error != null) msg(error!); }
  }

  Future<void> editForm({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    final parent = TextEditingController(text: '${existing?['parent_name'] ?? ''}');
    final grade = TextEditingController(text: '${existing?['grade'] ?? ''}');
    final selected = <String>{...list(existing?['subjects']).map(subjectName)};
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final subjectTiles = subjects.map((s) => CheckboxListTile(
            dense: true,
            value: selected.contains(s),
            title: Text(s),
            onChanged: (value) => setDialogState(() { if (value == true) { selected.add(s); } else { selected.remove(s); } }),
          )).toList();
          return AlertDialog(
            title: Text(existing == null ? 'إضافة طالب' : 'تعديل بيانات الطالب'),
            content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
                TextFormField(controller: parent, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
                TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
                const SizedBox(height: 10),
                const Text('المواد المشترك بها', style: TextStyle(fontWeight: FontWeight.bold)),
                ...subjectTiles,
              ]),
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ')),
            ],
          );
        },
      ),
    );
    if (saved == true) {
      try {
        final body = {'name': name.text.trim(), 'phone': phone.text.trim(), 'parent_name': parent.text.trim(), 'grade': grade.text.trim(), 'status': 'active', 'subjects': selected.toList()};
        if (existing == null) { await ApiService.post('students', body); } else { await ApiService.put('students/${id(existing)}', body); }
        await load();
      } catch (e) { msg(e); }
    }
    name.dispose(); phone.dispose(); parent.dispose(); grade.dispose();
  }

  Future<void> details(int studentId) async {
    try {
      final response = await ApiService.get('students/$studentId');
      final data = Map<String, dynamic>.from(response is Map && response['data'] is Map ? response['data'] : response);
      if (!mounted) return;
      final lines = <Widget>[];
      final sections = {'المواد': data['subjects'], 'المدرسون': data['teachers'], 'المجموعات': data['groups'], 'الحصص': data['lessons'], 'الاشتراكات': data['subscriptions'], 'المدفوعات': data['payments']};
      for (final entry in sections.entries) {
        final values = list(entry.value);
        lines.add(Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)));
        if (values.isEmpty) lines.add(const Text('لا يوجد', style: TextStyle(color: Colors.grey)));
        for (final value in values) lines.add(Text('• ${value is Map ? (value['name'] ?? value['subject'] ?? value['amount'] ?? '') : value}'));
        lines.add(const SizedBox(height: 8));
      }
      await showDialog(context: context, builder: (dialogContext) => AlertDialog(title: Text('${data['name'] ?? 'الطالب'}'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines))), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))]));
    } catch (e) { msg(e); }
  }

  Future<void> remove(Map<String, dynamic> student) async {
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('حذف الطالب'), content: Text('حذف ${student['name'] ?? ''}؟'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف'))]));
    if (ok == true) { try { await ApiService.delete('students/${id(student)}'); await load(); } catch (e) { msg(e); } }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => editForm(), backgroundColor: AppColors.red, icon: const Icon(Icons.person_add), label: const Text('إضافة طالب')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: students.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد طلاب بعد.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final s = Map<String, dynamic>.from(students[index]);
                        return Card(
                          child: ListTile(
                            onTap: () => details(id(s)),
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text('${s['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s['phone'] ?? ''}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'details') details(id(s));
                                if (v == 'edit') editForm(existing: s);
                                if (v == 'delete') remove(s);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'details', child: Text('التفاصيل')),
                                PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
