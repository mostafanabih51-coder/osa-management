import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SupervisorsScreen extends StatefulWidget {
  const SupervisorsScreen({super.key});
  @override State<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  List supervisors = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final r = await ApiService.get('supervisors');
      if (!mounted) return;
      setState(() { supervisors = r['data'] ?? []; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('إضافة مشرف'),
      content: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل الاسم' : null),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
        TextFormField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); }, child: const Text('حفظ'))],
    ));
    if (ok != true) return;
    try {
      await ApiService.post('supervisors', {'name': name.text.trim(), 'phone': phone.text.trim(), 'email': email.text.trim(), 'status': 'active'});
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشرفون'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: supervisors.length,
        itemBuilder: (_, i) {
          final s = supervisors[i] as Map<String, dynamic>;
          return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.supervisor_account)), title: Text('${s['name'] ?? ''}'), subtitle: Text('${s['phone'] ?? ''} • حصص: ${s['lessons_count'] ?? 0}')));
        },
      ),
    );
  }
}
