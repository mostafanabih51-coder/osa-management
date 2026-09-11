import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List subscriptions = [], students = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); loadSubscriptions(); }

  Future<void> loadSubscriptions() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([ApiService.get('subscriptions'), ApiService.get('students')]);
      if (!mounted) return;
      setState(() { subscriptions = r[0]['data'] ?? []; students = r[1]['data'] ?? []; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> addSubscription() async {
    if (students.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف طالبًا أولًا'))); return; }
    int studentId = students.first['id'] as int;
    final subject = TextEditingController();
    final amount = TextEditingController();
    final starts = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final ends = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10));
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('إضافة اشتراك'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(value: studentId, decoration: const InputDecoration(labelText: 'الطالب'), items: students.map((s) => DropdownMenuItem<int>(value: s['id'] as int, child: Text('${s['name'] ?? ''}'))).toList(), onChanged: (v) { if (v != null) studentId = v; }),
        TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'المادة'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل المادة' : null),
        TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null),
        TextFormField(controller: starts, decoration: const InputDecoration(labelText: 'بداية الاشتراك')),
        TextFormField(controller: ends, decoration: const InputDecoration(labelText: 'نهاية الاشتراك')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('حفظ'))],
    ));
    if (ok != true) return;
    try {
      await ApiService.post('subscriptions', {'student_id': studentId, 'subject': subject.text.trim(), 'amount': double.parse(amount.text), 'starts_on': starts.text.trim(), 'ends_on': ends.text.trim(), 'status': 'active'});
      await loadSubscriptions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الاشتراك')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = _error();
    } else {
      body = RefreshIndicator(
        onRefresh: loadSubscriptions,
        child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: subscriptions.length,
          itemBuilder: (_, i) {
            final item = subscriptions[i] as Map<String, dynamic>;
            final student = item['student'];
            final name = student is Map ? '${student['name'] ?? 'طالب'}' : 'طالب';
            return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.event_available)),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('المادة: ${item['subject'] ?? ''}\n${item['starts_on'] ?? ''} → ${item['ends_on'] ?? ''}'),
              isThreeLine: true,
              trailing: Text('${item['amount'] ?? 0}'),
            ));
          },
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('الاشتراكات'), actions: [IconButton(onPressed: loading ? null : loadSubscriptions, icon: const Icon(Icons.refresh))]), floatingActionButton: FloatingActionButton(onPressed: addSubscription, child: const Icon(Icons.add)), body: body);
  }

  Widget _error() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 52), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: loadSubscriptions, child: const Text('إعادة المحاولة'))])));
}
