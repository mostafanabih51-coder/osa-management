import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List expenses = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); loadExpenses(); }

  Future<void> loadExpenses() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = await ApiService.get('expenses');
      if (!mounted) return;
      setState(() { expenses = result['data'] ?? []; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> addExpense() async {
    final category = TextEditingController();
    final amount = TextEditingController();
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final description = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('إضافة مصروف'),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: category, decoration: const InputDecoration(labelText: 'البند'), validator: (v) => v == null || v.trim().isEmpty ? 'أدخل البند' : null),
        TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null),
        TextFormField(controller: date, decoration: const InputDecoration(labelText: 'التاريخ YYYY-MM-DD')),
        TextFormField(controller: description, decoration: const InputDecoration(labelText: 'الوصف')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(context, true); }, child: const Text('حفظ'))],
    ));
    if (ok != true) return;
    try {
      await ApiService.post('expenses', {'category': category.text.trim(), 'amount': double.parse(amount.text), 'spent_on': date.text.trim(), 'description': description.text.trim()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل المصروف')));
      await loadExpenses();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('المصروفات'), actions: [IconButton(onPressed: loading ? null : loadExpenses, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton(onPressed: addExpense, child: const Icon(Icons.add)),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? _error() : expenses.isEmpty ? RefreshIndicator(onRefresh: loadExpenses, child: ListView(children: const [SizedBox(height: 220), Center(child: Text('لا توجد مصروفات حاليًا'))])) : RefreshIndicator(onRefresh: loadExpenses, child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: expenses.length, itemBuilder: (_, i) { final item = expenses[i] as Map<String, dynamic>; return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.money_off)), title: Text('${item['category'] ?? 'مصروف'}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${item['spent_on'] ?? ''}\n${item['description'] ?? ''}'), isThreeLine: true, trailing: Text('${item['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))); })),
  );

  Widget _error() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 52), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: loadExpenses, child: const Text('إعادة المحاولة'))])));
}
