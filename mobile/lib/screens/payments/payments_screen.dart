import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<dynamic> items = [];
  List<dynamic> students = [];
  List<dynamic> subscriptions = [];
  bool loading = true;

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    return [];
  }

  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;

  void msg(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await Future.wait([
        ApiService.get('payments'),
        ApiService.get('students'),
        ApiService.get('subscriptions'),
      ]);
      if (!mounted) return;
      setState(() {
        items = list(result[0]);
        students = list(result[1]);
        subscriptions = list(result[2]);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      msg(e);
    }
  }

  Future<void> add() async {
    if (students.isEmpty) {
      msg(Exception('أضف طالبًا أولًا.'));
      return;
    }

    int studentId = id(students.first);
    int? subscriptionId;
    final amount = TextEditingController();
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final method = TextEditingController(text: 'نقدي');
    final form = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableSubscriptions = subscriptions.where((subscription) {
            final student = subscription['student'];
            return id(student ?? {}) == studentId || id(subscription) > 0 && '${subscription['student_id'] ?? ''}' == '$studentId';
          }).toList();

          if (subscriptionId != null && !availableSubscriptions.any((subscription) => id(subscription) == subscriptionId)) {
            subscriptionId = null;
          }

          return AlertDialog(
            title: const Text('إضافة دفعة'),
            content: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: studentId,
                    decoration: const InputDecoration(labelText: 'الطالب *'),
                    items: students.map((student) => DropdownMenuItem<int>(value: id(student), child: Text('${student['name']}'))).toList(),
                    onChanged: (value) { if (value != null) setDialogState(() => studentId = value); },
                  ),
                  DropdownButtonFormField<int?>(
                    value: subscriptionId,
                    decoration: const InputDecoration(labelText: 'الاشتراك (اختياري)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('بدون اشتراك')),
                      ...availableSubscriptions.map((subscription) => DropdownMenuItem<int?>(value: id(subscription), child: Text('${subscription['subject'] ?? ''} • ${subscription['amount'] ?? 0}'))),
                    ],
                    onChanged: (value) => setDialogState(() => subscriptionId = value),
                  ),
                  TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ *'), validator: (v) => double.tryParse(v ?? '') == null ? 'مبلغ غير صحيح' : null),
                  TextFormField(controller: date, decoration: const InputDecoration(labelText: 'التاريخ YYYY-MM-DD'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                  TextFormField(controller: method, decoration: const InputDecoration(labelText: 'طريقة الدفع')),
                  if (availableSubscriptions.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerRight, child: Text('لا يوجد اشتراك لهذا الطالب؛ يمكنك تسجيل الدفعة بدونه.'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ الدفعة')),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      try {
        await ApiService.post('payments', {
          'student_id': studentId,
          'subscription_id': subscriptionId,
          'amount': double.parse(amount.text),
          'paid_on': date.text.trim(),
          'method': method.text.trim(),
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    amount.dispose();
    date.dispose();
    method.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدفوعات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add), label: const Text('إضافة دفعة')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final payment = items[index];
                  final student = payment['student'];
                  final subscription = payment['subscription'];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.payments)),
                      title: Text('${student?['name'] ?? 'طالب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الاشتراك: ${subscription?['subject'] ?? 'غير مرتبط'}\n${payment['paid_on'] ?? ''} • ${payment['method'] ?? ''}'),
                      isThreeLine: true,
                      trailing: Text('${payment['amount'] ?? 0}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
