import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class RolePortalScreen extends StatefulWidget {
  const RolePortalScreen({super.key});

  @override
  State<RolePortalScreen> createState() => _RolePortalScreenState();
}

class _RolePortalScreenState extends State<RolePortalScreen> {
  Map<String, dynamic> portal = {};
  List<dynamic> withdrawals = [];
  bool loading = true;
  String? error;

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    return [];
  }

  double number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
  String statusLabel(dynamic value) {
    switch ('$value') {
      case 'pending': return 'قيد المراجعة';
      case 'approved': return 'تمت الموافقة';
      case 'rejected': return 'مرفوض';
      case 'paid': return 'تم الصرف';
      default: return '${value ?? ''}';
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = await ApiService.get('portal/me');
      portal = result is Map ? Map<String, dynamic>.from(result['data'] is Map ? result['data'] : result) : {};
      withdrawals = list(await ApiService.get('portal/withdrawals'));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> requestWithdrawal() async {
    final amount = TextEditingController();
    final notes = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('طلب سحب مستحقات'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ المطلوب'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'أدخل مبلغًا صحيحًا';
                  return null;
                },
              ),
              TextFormField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('إرسال الطلب')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.post('portal/withdrawals', {
          'amount': double.parse(amount.text.trim()),
          'notes': notes.text.trim(),
        });
        await load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب السحب للإدارة.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
    amount.dispose();
    notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dues = list(portal['dues']);
    final dueTotal = dues.fold<double>(0, (sum, due) => sum + number(due is Map ? due['amount'] : 0));
    final paidTotal = dues.fold<double>(0, (sum, due) => sum + number(due is Map ? due['paid_amount'] : 0));
    final remaining = (dueTotal - paidTotal).clamp(0, double.infinity).toDouble();
    final profile = portal['profile'] is Map ? portal['profile'] as Map : {};
    return Scaffold(
      appBar: AppBar(title: const Text('بوابة المستحقات والسحب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: requestWithdrawal,
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text('طلب سحب'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))])))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      Card(child: ListTile(title: Text('${profile['name'] ?? 'الحساب'}'), subtitle: Text('${portal['role'] == 'teacher' ? 'مدرس' : 'مشرف'}'))),
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('ملخص المستحقات', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('إجمالي المستحق: ${dueTotal.toStringAsFixed(2)}'),
                        Text('تم صرفه: ${paidTotal.toStringAsFixed(2)}'),
                        Text('المتبقي: ${remaining.toStringAsFixed(2)}'),
                      ]))),
                      const SizedBox(height: 8),
                      const Text('مستحقات الحصص المكتملة', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (dues.isEmpty) const ListTile(title: Text('لا توجد مستحقات مسجلة حتى الآن.')),
                      ...dues.map((raw) {
                        final due = raw is Map ? raw : {};
                        final lesson = due['lesson'] is Map ? due['lesson'] as Map : {};
                        final rest = (number(due['amount']) - number(due['paid_amount'])).clamp(0, double.infinity).toDouble();
                        return Card(child: ListTile(
                          title: Text('${lesson['subject'] ?? 'حصة'} • ${number(due['amount']).toStringAsFixed(2)}'),
                          subtitle: Text('${lesson['starts_at'] ?? ''}\nالمصروف: ${number(due['paid_amount']).toStringAsFixed(2)} • المتبقي: ${rest.toStringAsFixed(2)}'),
                          isThreeLine: true,
                        ));
                      }),
                      const SizedBox(height: 12),
                      const Text('طلبات السحب', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (withdrawals.isEmpty) const ListTile(title: Text('لم ترسل طلبات سحب بعد.')),
                      ...withdrawals.map((raw) {
                        final w = raw is Map ? raw : {};
                        return Card(child: ListTile(
                          title: Text('${number(w['amount']).toStringAsFixed(2)}'),
                          subtitle: Text('${statusLabel(w['status'])} • ${w['created_at'] ?? ''}'),
                        ));
                      }),
                    ],
                  ),
                ),
    );
  }
}
