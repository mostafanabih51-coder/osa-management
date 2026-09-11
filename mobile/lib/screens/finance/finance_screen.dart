import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  Map<String, dynamic> summary = {};
  List<dynamic> teachers = [], supervisors = [], withdrawals = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final a = await Future.wait([
        ApiService.get('finance/summary'),
        ApiService.get('teachers'),
        ApiService.get('supervisors'),
        ApiService.get('finance/withdrawals'),
      ]);
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(a[0]['data'] ?? a[0]);
        teachers = List<dynamic>.from(a[1]['data'] ?? a[1]);
        supervisors = List<dynamic>.from(a[2]['data'] ?? a[2]);
        withdrawals = List<dynamic>.from(a[3]['data'] ?? a[3]);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  void msg(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> withdraw() async {
    String type = 'teacher';
    int? id = teachers.isEmpty ? null : teachers.first['id'];
    final amount = TextEditingController();
    final notes = TextEditingController();
    final key = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: const Text('طلب سحب'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text('مدرس')),
                    DropdownMenuItem(value: 'supervisor', child: Text('مشرف')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setD(() {
                      type = v;
                      id = v == 'teacher'
                          ? (teachers.isEmpty ? null : teachers.first['id'])
                          : (supervisors.isEmpty ? null : supervisors.first['id']);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'النوع'),
                ),
                if ((type == 'teacher' ? teachers : supervisors).isNotEmpty)
                  DropdownButtonFormField<int>(
                    value: id,
                    items: (type == 'teacher' ? teachers : supervisors)
                        .map((x) => DropdownMenuItem<int>(
                              value: x['id'],
                              child: Text('${x['name'] ?? ''}'),
                            ))
                        .toList(),
                    onChanged: (v) => setD(() => id = v),
                    decoration: const InputDecoration(labelText: 'المستحق'),
                  ),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null,
                ),
                TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate() && id != null) Navigator.pop(c, true);
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || id == null) return;
    try {
      await ApiService.post('finance/withdrawals', {
        'recipient_type': type,
        'recipient_id': id,
        'amount': double.parse(amount.text),
        'notes': notes.text.trim(),
      });
      await load();
      msg('تم إنشاء طلب السحب');
    } catch (e) {
      msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> updateWithdrawal(int id, String status) async {
    try {
      await ApiService.put('finance/withdrawals/$id', {'status': status});
      await load();
    } catch (e) {
      msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المالية والمستحقات'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton(onPressed: withdraw, child: const Icon(Icons.add)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          title: const Text('مستحقات المدرسين'),
                          subtitle: Text(
                            'إجمالي: ${summary['teacher_due'] ?? 0} | مدفوع: ${summary['teacher_paid'] ?? 0} | متبقي: ${summary['teacher_remaining'] ?? 0}',
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('مستحقات المشرفين'),
                          subtitle: Text(
                            'إجمالي: ${summary['supervisor_due'] ?? 0} | مدفوع: ${summary['supervisor_paid'] ?? 0} | متبقي: ${summary['supervisor_remaining'] ?? 0}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('طلبات السحب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ...withdrawals.map((w) {
                        return Card(
                          child: ListTile(
                            title: Text('${w['recipient_name'] ?? w['recipient_type'] ?? ''}'),
                            subtitle: Text('المبلغ: ${w['amount'] ?? 0}\nالحالة: ${w['status'] ?? ''}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (s) => updateWithdrawal(w['id'], s),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'approved', child: Text('اعتماد')),
                                PopupMenuItem(value: 'rejected', child: Text('رفض')),
                                PopupMenuItem(value: 'paid', child: Text('تم الدفع')),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
