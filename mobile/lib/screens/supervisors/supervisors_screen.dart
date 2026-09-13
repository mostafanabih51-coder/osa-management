import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SupervisorsScreen extends StatefulWidget {
  const SupervisorsScreen({super.key});
  @override
  State<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  List supervisors = [];
  bool loading = true;

  List<dynamic> list(dynamic x) {
    if (x is List) return List<dynamic>.from(x);
    if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']);
    return [];
  }

  void msg(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await ApiService.get('supervisors');
      if (mounted) {
        setState(() {
          supervisors = list(r);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        msg(e);
      }
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final form = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة مشرف'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف'),
                ),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'البريد'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      try {
        await ApiService.post('supervisors', {
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
          'status': 'active',
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    name.dispose();
    phone.dispose();
    email.dispose();
  }

  Future<void> details(int id) async {
    try {
      final r = await ApiService.get('supervisors/$id');
      final d = Map<String, dynamic>.from(
        r is Map && r['data'] is Map ? r['data'] : r,
      );
      if (!mounted) return;

      final privateLessons = list(d['private_lessons']);
      final groupLessons = list(d['group_lessons']);
      final history = list(d['lessons']);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('${d['supervisor']?['name'] ?? 'المشرف'}'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Private: ${privateLessons.length}'),
                    Text('Group: ${groupLessons.length}'),
                    Text('إجمالي الحصص: ${d['lessons_count'] ?? 0}'),
                    Text('المستحق: ${d['due'] ?? 0}'),
                    Text('المدفوع: ${d['paid'] ?? 0}'),
                    Text(
                      'المتبقي: ${d['remaining'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('المكافآت: ${d['bonus_total'] ?? 0}'),
                    const Divider(),
                    const Text(
                      'سجل الحصص',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...history.map(
                      (x) => Text(
                        '• ${x['type'] ?? ''} / ${x['subject'] ?? ''} / ${x['starts_at'] ?? ''}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      msg(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المشرفون'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: add,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: supervisors.length,
                itemBuilder: (_, i) {
                  final s = supervisors[i];
                  return Card(
                    child: ListTile(
                      onTap: () => details(s['id']),
                      leading: const CircleAvatar(
                        child: Icon(Icons.supervisor_account),
                      ),
                      title: Text('${s['name'] ?? ''}'),
                      subtitle: Text('${s['phone'] ?? ''}'),
                      trailing: const Icon(Icons.chevron_left),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
