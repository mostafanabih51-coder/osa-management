import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? loadError;
  static const fallbackSubjects = <String>[
    'العربية','اللغة الإنجليزية','الرياضيات','العلوم','الدراسات الاجتماعية',
    'Math','Science','English','Arabic','German','French','Spanish','Quran',
    'Chemistry','Physics','Biology','History','Geography','Philosophy',
  ];
  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    if (value is Map && value['data'] is Map && value['data']['data'] is List) return List<dynamic>.from(value['data']['data']);
    return [];
  }
  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;
  String subjectName(dynamic value) => value is Map ? '${value['subject'] ?? value['name'] ?? ''}' : '$value';
  void msg(Object e) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', '')))); }

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    if (mounted) setState(() { loading = true; loadError = null; });
    Object? firstError;
    try { students = list(await ApiService.get('students')); } catch (e) { firstError = e; }
    try { subjects = list(await ApiService.get('subjects')).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList(); } catch (e) { firstError ??= e; }
    if (subjects.isEmpty) subjects = List<String>.from(fallbackSubjects);
    if (!mounted) return;
    setState(() { loading = false; loadError = students.isEmpty && firstError != null ? '$firstError'.replaceFirst('Exception: ', '') : null; });
  }

  Future<void> editForm({Map<String,dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    final parent = TextEditingController(text: '${existing?['parent_name'] ?? ''}');
    final grade = TextEditingController(text: '${existing?['grade'] ?? ''}');
    final selected = <String>{...list(existing?['subjects']).map(subjectName).where((x) => x.trim().isNotEmpty)};
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(existing == null ? 'إضافة طالب' : 'تعديل بيانات الطالب'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(key: key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
        TextFormField(controller: parent, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
        TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
        const SizedBox(height: 12),
        const Text('المواد المشترك بها', style: TextStyle(fontWeight: FontWeight.bold)),
        ...subjects.map((s) => CheckboxListTile(dense: true, value: selected.contains(s), title: Text(s), onChanged: (v) => set(() { if (v == true) selected.add(s); else selected.remove(s); }))),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(d, true); }, child: const Text('حفظ'))],
    )));
    if (ok == true) {
      try {
        final body = {'name': name.text.trim(), 'phone': phone.text.trim(), 'parent_name': parent.text.trim(), 'grade': grade.text.trim(), 'status': 'active', 'subjects': selected.toList()};
        if (existing == null) await ApiService.post('students', body); else await ApiService.put('students/${id(existing)}', body);
        await load();
      } catch (e) { msg(e); }
    }
    for (final c in [name, phone, parent, grade]) c.dispose();
  }

  Future<void> details(int studentId) async {
    try {
      final response = await ApiService.get('academic/students/$studentId');
      final data = response is Map && response['data'] is Map ? response['data'] : response;
      final student = data['student'] is Map ? Map<String,dynamic>.from(data['student']) : <String,dynamic>{};
      final resources = list(data['resources']);
      final evaluations = list(data['evaluations']);
      final plans = list(data['plans']);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (d) => AlertDialog(
        title: Text('${student['name'] ?? 'الطالب'}'),
        content: SizedBox(width: 620, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المواد: ${list(student['subjects']).map(subjectName).join('، ')}'),
          Text('المدرسون: ${list(student['teachers']).map((x) => x is Map ? '${x['name'] ?? ''}' : '').join('، ')}'),
          Text('المجموعات: ${list(student['groups']).map((x) => x is Map ? '${x['name'] ?? ''}' : '').join('، ')}'),
          Text('الحصص: ${list(student['lessons']).length} • الاشتراكات: ${list(student['subscriptions']).length} • المدفوعات: ${list(student['payments']).length}'),
          const Divider(), const Text('خطة الحصص الشهرية', style: TextStyle(fontWeight: FontWeight.bold)),
          ...plans.map((p) => Text('• ${p['subject']}: ${p['completed_lessons'] ?? 0}/${p['monthly_lessons'] ?? 0}')),
          const Divider(), const Text('التقييمات', style: TextStyle(fontWeight: FontWeight.bold)),
          ...evaluations.map((e) => Text('• ${e['title'] ?? 'تقييم'} — ${e['score'] ?? '-'}%')),
          const Divider(), const Text('الواجبات والامتحانات والروابط والمرفقات', style: TextStyle(fontWeight: FontWeight.bold)),
          ...resources.map((r) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('${r['title'] ?? ''}'), subtitle: Text('${r['type'] ?? ''} • ${r['description'] ?? ''}'), trailing: r['url'] == null ? null : IconButton(onPressed: () async { final u = Uri.tryParse('${r['url']}'); if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.open_in_new)))),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إغلاق'))],
      ));
    } catch (e) { msg(e); }
  }

  Future<void> remove(Map<String,dynamic> student) async {
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('حذف الطالب'), content: Text('حذف ${student['name'] ?? ''}؟'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف'))]));
    if (ok == true) { try { await ApiService.delete('students/${id(student)}'); await load(); } catch (e) { msg(e); } }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الطلاب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => editForm(), backgroundColor: AppColors.red, icon: const Icon(Icons.person_add), label: const Text('إضافة طالب')),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: loadError != null
      ? ListView(children: [const SizedBox(height: 160), Padding(padding: const EdgeInsets.all(24), child: Text('تعذر تحميل الطلاب. اضغط إعادة المحاولة بدل عرض قائمة فارغة.', textAlign: TextAlign.center)), Center(child: FilledButton(onPressed: load, child: const Text('إعادة المحاولة')))])
      : students.isEmpty ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد طلاب بعد.'))])
      : ListView.builder(padding: const EdgeInsets.fromLTRB(16,12,16,90), itemCount: students.length, itemBuilder: (_, i) { final s = Map<String,dynamic>.from(students[i]); return Card(child: ListTile(onTap: () => details(id(s)), leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${s['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${s['phone'] ?? ''}'), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'details') details(id(s)); if (v == 'edit') editForm(existing: s); if (v == 'delete') remove(s); }, itemBuilder: (_) => const [PopupMenuItem(value: 'details', child: Text('التفاصيل')), PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]))); }),
  );
}
