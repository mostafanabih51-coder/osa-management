import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> teachers = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final r = await ApiService.get('teachers'); if (mounted) setState(() { teachers = List<dynamic>.from(r['data'] ?? r); loading = false; }); }
    catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); } }
  }

  Future<void> add() async {
    final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), spec = TextEditingController(), rate = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('إضافة مدرس'),
      content: SingleChildScrollView(child: Form(key: key, child: Column(children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
        TextFormField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
        TextFormField(controller: spec, decoration: const InputDecoration(labelText: 'التخصص')),
        TextFormField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الساعة')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); }, child: const Text('حفظ'))],
    ));
    if (ok != true) return;
    try { await ApiService.post('teachers', {'name': name.text.trim(), 'phone': phone.text.trim(), 'email': email.text.trim(), 'specialization': spec.text.trim(), 'hourly_rate': double.tryParse(rate.text) ?? 0, 'active': true}); await load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> details(dynamic id) async {
    try {
      final r = await ApiService.get('teachers/$id');
      if (!mounted) return;
      final d = Map<String, dynamic>.from(r['data'] ?? r);
      final students = d['students'] is List ? List<dynamic>.from(d['students']) : <dynamic>[];
      final groups = d['groups'] is List ? List<dynamic>.from(d['groups']) : <dynamic>[];
      showDialog(context: context, builder: (c) => AlertDialog(
        title: Text('${d['teacher'] is Map ? d['teacher']['name'] : d['name'] ?? 'المدرس'}'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('عدد الطلاب: ${students.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (students.isNotEmpty) ...students.map((s) => ListTile(dense: true, leading: const Icon(Icons.person), title: Text('${s['name'] ?? 'طالب'}'))),
          const Divider(),
          Text('عدد المجموعات: ${groups.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (groups.isNotEmpty) ...groups.map((g) => ListTile(dense: true, leading: const Icon(Icons.groups), title: Text('${g['name'] ?? 'مجموعة'}'))),
          const Divider(),
          Text('إجمالي المستحق: ${d['due'] ?? 0}'),
          Text('إجمالي المدفوع: ${d['paid'] ?? 0}'),
          Text('المتبقي: ${d['remaining'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))],
      ));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: load,
        child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: teachers.length, itemBuilder: (_, i) {
          final t = teachers[i];
          return Card(child: ListTile(onTap: () => details(t['id']), leading: CircleAvatar(backgroundColor: AppColors.black, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))), title: Text('${t['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${t['phone'] ?? t['email'] ?? ''}'), trailing: const Icon(Icons.chevron_left)));
        }),
      ),
    );
  }
}
