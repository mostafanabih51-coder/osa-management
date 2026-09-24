import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> expenses = [];
  bool loading = true;
  String? error;

  List<dynamic> list(dynamic x) {
    if (x is List) return List<dynamic>.from(x);
    if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']);
    if (x is Map && x['data'] is Map && x['data']['data'] is List) return List<dynamic>.from(x['data']['data']);
    return [];
  }
  int id(dynamic x) => int.tryParse('${x['id']}') ?? 0;
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
  Future<void> pickDate(TextEditingController c) async { final initial=DateTime.tryParse(c.text.trim())??DateTime.now(); final d=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(2000),lastDate:DateTime(2100),helpText:'اختر التاريخ'); if(d!=null)c.text='${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'; }

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final r = await ApiService.get('expenses');
      if (mounted) setState(() { expenses = list(r); loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> form({dynamic item}) async {
    final category = TextEditingController(text: '${item?['category'] ?? ''}');
    final amount = TextEditingController(text: '${item?['amount'] ?? ''}');
    final date = TextEditingController(text: '${item?['spent_on'] ?? DateTime.now().toIso8601String().substring(0, 10)}');
    final description = TextEditingController(text: '${item?['description'] ?? ''}');
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(item == null ? 'إضافة مصروف' : 'تعديل المصروف'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: category, decoration: const InputDecoration(labelText: 'البند *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
              TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ *'), validator: (v) { final n = double.tryParse(v ?? ''); return n == null || n <= 0 ? 'أدخل مبلغًا صحيحًا' : null; }),
              TextFormField(controller: date, readOnly: true, onTap: () => pickDate(date), decoration: const InputDecoration(labelText: 'التاريخ'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
              TextFormField(controller: description, decoration: const InputDecoration(labelText: 'الوصف')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(d, true); }, child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final body = {'category': category.text.trim(), 'amount': double.parse(amount.text), 'spent_on': date.text.trim(), 'description': description.text.trim()};
        if (item == null) { await ApiService.post('expenses', body); } else { await ApiService.put('expenses/${id(item)}', body); }
        await load();
      } catch (e) { msg(e); }
    }
    for (final c in [category, amount, date, description]) { c.dispose(); }
  }

  Future<void> remove(dynamic item) async {
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('حذف المصروف'), content: Text('حذف ${item['category'] ?? 'المصروف'}؟'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف'))]));
    if (ok == true) {
      try { await ApiService.delete('expenses/${id(item)}'); await load(); } catch (e) { msg(e); }
    }
  }

  @override Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), const SizedBox(height: 12), FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))]));
    } else if (expenses.isEmpty) {
      body = RefreshIndicator(onRefresh: load, child: ListView(children: const [SizedBox(height: 180), Center(child: Text('لا توجد مصروفات'))]));
    } else {
      body = RefreshIndicator(onRefresh: load, child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), itemCount: expenses.length, itemBuilder: (_, i) {
        final x = expenses[i];
        return Card(child: ListTile(title: Text('${x['category'] ?? 'مصروف'}'), subtitle: Text('${x['spent_on'] ?? ''}\n${x['description'] ?? ''}'), isThreeLine: true, trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${x['amount'] ?? 0}'), IconButton(onPressed: () => form(item: x), icon: const Icon(Icons.edit)), IconButton(onPressed: () => remove(x), icon: const Icon(Icons.delete))])));
      }));
    }
    return Scaffold(appBar: AppBar(title: const Text('المصروفات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]), floatingActionButton: FloatingActionButton.extended(onPressed: () => form(), icon: const Icon(Icons.add), label: const Text('إضافة مصروف')), body: body);
  }
}
