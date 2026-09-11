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
    catch (_) { if (mounted) setState(() => loading = false); }
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
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  Future<void> details(dynamic id) async {
    try {
      final r = await ApiService.get('teachers/$id');
      if (!mounted) return;
      final d = Map<String, dynamic>.from(r['data'] ?? r);
      showDialog(context: context, builder: (c) => AlertDialog(title: Text('${d['name'] ?? 'المدرس'}'), content: Text('الطلاب: ${d['students_count'] ?? (d['students'] is List ? d['students'].length : 0)}\nالمجموعات: ${d['groups_count'] ?? 0}\nالمستحق: ${d['due'] ?? 0}\nالمدفوع: ${d['paid'] ?? 0}\nالمتبقي: ${d['remaining'] ?? 0}'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق'))]));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون')),
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
