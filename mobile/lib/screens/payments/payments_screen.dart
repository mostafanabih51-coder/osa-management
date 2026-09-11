import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List items = [], students = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final r = await Future.wait([ApiService.get('payments'), ApiService.get('students')]);
      if (!mounted) return;
      setState(() { items = r[0]['data'] ?? []; students = r[1]['data'] ?? []; loading = false; });
    } catch (e) {
      if (mounted) { setState(() => loading = false); _msg(e); }
    }
  }

  void _msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

  Future<void> add() async {
    if (students.isEmpty) { _msg(Exception('أضف طالبًا أولًا')); return; }
    int? studentId = students.first['id'];
    final amount = TextEditingController();
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final method = TextEditingController(text: 'نقدي');
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(value: studentId, decoration: const InputDecoration(labelText: 'الطالب'), items: students.map((s) => DropdownMenuItem<int>(value: s['id'] as int, child: Text('${s['name'] ?? ''}'))).toList(), onChanged: (v) => studentId = v),
              TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null),
              TextFormField(controller: date, decoration: const InputDecoration(labelText: 'التاريخ YYYY-MM-DD')),
              TextFormField(controller: method, decoration: const InputDecoration(labelText: 'طريقة الدفع')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true || studentId == null) return;
    try {
      await ApiService.post('payments', {'student_id': studentId, 'amount': double.parse(amount.text), 'paid_on': date.text, 'method': method.text});
      await load();
    } catch (e) { _msg(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدفوعات')),
      floatingActionButton: FloatingActionButton(onPressed: add, child: const Icon(Icons.add)),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: items.length,
          itemBuilder: (_, i) {
            final x = items[i] as Map<String, dynamic>;
            final s = x['student'];
            return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.payments)),
              title: Text(s is Map ? '${s['name'] ?? 'طالب'}' : 'طالب'),
              subtitle: Text('${x['paid_on'] ?? ''} • ${x['method'] ?? ''}'),
              trailing: Text('${x['amount'] ?? 0}'),
            ));
          },
        ),
      ),
    );
  }
}
