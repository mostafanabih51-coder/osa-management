import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List students = [], subjects = [];
  bool loading = true;
  static const fallbackSubjects = ['العربية','اللغة الإنجليزية','الرياضيات','العلوم','الدراسات الاجتماعية','Math','Science','English','Arabic','German','French','Spanish','Quran'];
  List<dynamic> asList(dynamic v) => v is List ? List<dynamic>.from(v) : (v is Map && v['data'] is List ? List<dynamic>.from(v['data']) : []);
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final r = await Future.wait([ApiService.get('students'), ApiService.get('subjects')]);
      if (!mounted) return;
      final loadedSubjects = asList(r[1]).map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
      setState(() { students = asList(r[0]); subjects = loadedSubjects.isEmpty ? fallbackSubjects : loadedSubjects; loading = false; });
    } catch (e) { if (mounted) { setState(() { loading = false; subjects = fallbackSubjects; }); msg(e); } }
  }

  Future<void> add() async {
    final name = TextEditingController(), phone = TextEditingController(), parent = TextEditingController(), parentPhone = TextEditingController(), grade = TextEditingController(), curr = TextEditingController();
    final selected = <String>{};
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          title: const Text('إضافة طالب'),
          content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('أدخل بيانات الطالب ثم اختر المواد التي يدرسها. الاختيار يتم بالضغط على المربع بجوار المادة.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
            TextFormField(controller: parent, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
            TextFormField(controller: parentPhone, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
            TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
            TextFormField(controller: curr, decoration: const InputDecoration(labelText: 'المنهج')),
            const SizedBox(height: 14),
            const Text('المواد المشترك بها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('اختر مادة أو أكثر:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Column(children: subjects.map((s) { final value = '$s'; return CheckboxListTile(dense: true, controlAffinity: ListTileControlAffinity.leading, value: selected.contains(value), title: Text(value), onChanged: (v) => setD(() { if (v == true) selected.add(value); else selected.remove(value); })); }).toList())),
            if (selected.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('تم اختيار: ${selected.join('، ')}', style: const TextStyle(fontWeight: FontWeight.w600))),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton.icon(onPressed: () { if (form.currentState!.validate()) Navigator.pop(dialogContext, true); }, icon: const Icon(Icons.save), label: const Text('حفظ الطالب')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try { await ApiService.post('students', {'name': name.text.trim(), 'phone': phone.text.trim(), 'parent_name': parent.text.trim(), 'parent_phone': parentPhone.text.trim(), 'grade': grade.text.trim(), 'curriculum': curr.text.trim(), 'status': 'active', 'subjects': selected.toList()}); await load(); } catch (e) { msg(e); }
    }
    for (final c in [name, phone, parent, parentPhone, grade, curr]) { c.dispose(); }
  }

  Future<void> details(dynamic id) async {
    try {
      final r = await ApiService.get('students/$id');
      final d = Map<String, dynamic>.from(r is Map && r['data'] is Map ? r['data'] : r);
      if (!mounted) return;
      final sections = <String, List<dynamic>>{'المواد': asList(d['subjects']), 'المدرسون': asList(d['teachers']), 'المجموعات': asList(d['groups']), 'الحصص': asList(d['lessons']), 'الاشتراكات': asList(d['subscriptions']), 'المدفوعات': asList(d['payments'])};
      await showDialog(context: context, builder: (dialogContext) => AlertDialog(title: Text('${d['name'] ?? 'الطالب'}'), content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final entry in sections.entries) Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), if (entry.value.isEmpty) const Text('لا يوجد', style: TextStyle(color: Colors.grey)), ...entry.value.map((x) => Text('• ${x is Map ? (x['name'] ?? x['subject'] ?? x['amount'] ?? x) : x}'))]))]))), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))]));
    } catch (e) { msg(e); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الطلاب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: add, backgroundColor: AppColors.red, icon: const Icon(Icons.person_add), label: const Text('إضافة طالب')),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: students.isEmpty ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد طلاب بعد. اضغط «إضافة طالب» للبدء.'))]) : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), itemCount: students.length, itemBuilder: (_, i) { final s = students[i]; return Card(child: ListTile(onTap: () => details(s['id']), leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${s['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${s['phone'] ?? ''}'), trailing: const Icon(Icons.chevron_left))); }))));
}
