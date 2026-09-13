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
  List<dynamic> asList(dynamic v) => v is List ? List<dynamic>.from(v) : (v is Map && v['data'] is List ? List<dynamic>.from(v['data']) : []);
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final r = await Future.wait([ApiService.get('students'), ApiService.get('subjects')]);
      if (!mounted) return;
      setState(() { students = asList(r[0]); subjects = asList(r[1]); loading = false; });
    } catch (e) { if (mounted) { setState(() => loading = false); msg(e); } }
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
          content: SingleChildScrollView(child: Form(key: form, child: Column(children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
            TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
            TextFormField(controller: parent, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
            TextFormField(controller: parentPhone, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
            TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
            TextFormField(controller: curr, decoration: const InputDecoration(labelText: 'المنهج')),
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerRight, child: Text('المواد المشترك بها', style: TextStyle(fontWeight: FontWeight.bold))),
            ...subjects.map((s) { final value = '$s'; return CheckboxListTile(dense: true, value: selected.contains(value), title: Text(value), onChanged: (v) => setD(() { if (v == true) { selected.add(value); } else { selected.remove(value); } })); }),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ')),
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
      final sections = <String, List<dynamic>>{
        'المواد': asList(d['subjects']), 'المدرسون': asList(d['teachers']), 'المجموعات': asList(d['groups']),
        'الحصص': asList(d['lessons']), 'الاشتراكات': asList(d['subscriptions']), 'المدفوعات': asList(d['payments']),
      };
      await showDialog(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('${d['name'] ?? 'الطالب'}'),
        content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final entry in sections.entries) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (entry.value.isEmpty) const Text('لا يوجد'),
            ...entry.value.map((x) => Text('• ${x is Map ? (x['name'] ?? x['subject'] ?? x['amount'] ?? x) : x}')),
          ])),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
      ));
    } catch (e) { msg(e); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الطلاب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton(onPressed: add, backgroundColor: AppColors.red, child: const Icon(Icons.add)),
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: load, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: students.length, itemBuilder: (_, i) { final s = students[i]; return Card(child: ListTile(onTap: () => details(s['id']), title: Text('${s['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${s['phone'] ?? ''}'), trailing: const Icon(Icons.chevron_left))); })),
  );
}
