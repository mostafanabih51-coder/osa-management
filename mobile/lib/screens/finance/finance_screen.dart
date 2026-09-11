import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  Map<String, dynamic> summary = {};
  List<dynamic> teachers = [], supervisors = [], withdrawals = [], teacherDues = [], supervisorDues = [], bonuses = [], settings = [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  List<dynamic> _list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    return [];
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final a = await Future.wait([
        ApiService.get('finance/summary'),
        ApiService.get('teachers'),
        ApiService.get('supervisors'),
        ApiService.get('finance/withdrawals'),
        ApiService.get('finance/teacher-dues'),
        ApiService.get('finance/supervisor-dues'),
        ApiService.get('finance/bonuses'),
        ApiService.get('finance/withdrawal-settings'),
      ]);
      if (!mounted) return;
      setState(() {
        summary = Map<String, dynamic>.from(a[0]['data'] ?? a[0]);
        teachers = _list(a[1]);
        supervisors = _list(a[2]);
        withdrawals = _list(a[3]);
        teacherDues = _list(a[4]);
        supervisorDues = _list(a[5]);
        bonuses = _list(a[6]);
        settings = _list(a[7]);
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  void msg(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> payDue(String type, dynamic due) async {
    final remaining = (double.tryParse('${due['amount'] ?? 0}') ?? 0) - (double.tryParse('${due['paid_amount'] ?? 0}') ?? 0);
    if (remaining <= 0) { msg('هذا المستحق مدفوع بالكامل'); return; }
    final controller = TextEditingController(text: remaining.toStringAsFixed(2));
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(type == 'teacher' ? 'صرف مستحق مدرس' : 'صرف مستحق مشرف'),
      content: Form(key: key, child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'مبلغ الصرف'),
        validator: (v) { final n = double.tryParse(v ?? ''); if (n == null || n <= 0) return 'أدخل مبلغًا صحيحًا'; if (n > remaining + 0.0001) return 'المبلغ أكبر من المتبقي'; return null; },
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(c, true); }, child: const Text('صرف'))],
    ));
    if (ok != true) return;
    try {
      await ApiService.post('finance/dues/$type/${due['id']}/pay', {'amount': double.parse(controller.text)});
      await load();
      msg('تم تسجيل الصرف وتحديث المستحق والمصروفات');
    } catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> withdraw() async {
    String type = 'teacher';
    int? id = teachers.isEmpty ? null : teachers.first['id'];
    final amount = TextEditingController();
    final notes = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: const Text('طلب سحب'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, items: const [DropdownMenuItem(value: 'teacher', child: Text('مدرس')), DropdownMenuItem(value: 'supervisor', child: Text('مشرف'))], onChanged: (v) { if (v != null) setD(() { type = v; id = v == 'teacher' ? (teachers.isEmpty ? null : teachers.first['id']) : (supervisors.isEmpty ? null : supervisors.first['id']); }); }, decoration: const InputDecoration(labelText: 'النوع')),
        if ((type == 'teacher' ? teachers : supervisors).isNotEmpty) DropdownButtonFormField<int>(initialValue: id, items: (type == 'teacher' ? teachers : supervisors).map((x) => DropdownMenuItem<int>(value: x['id'], child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => id = v), decoration: const InputDecoration(labelText: 'المستحق')),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null),
        TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
      ])),),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate() && id != null) Navigator.pop(c, true); }, child: const Text('إرسال'))],
    )));
    if (ok != true || id == null) return;
    try {
      await ApiService.post('finance/withdrawals', {'recipient_type': type, 'recipient_id': id, 'amount': double.parse(amount.text), 'notes': notes.text.trim()});
      await load(); msg('تم إنشاء طلب السحب');
    } catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> updateWithdrawal(int id, String status) async {
    try { await ApiService.put('finance/withdrawals/$id', {'status': status}); await load(); }
    catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); }
  }

  Future<void> addBonus() async {
    String type = 'teacher';
    int? id = teachers.isEmpty ? null : teachers.first['id'];
    final name = TextEditingController(), amount = TextEditingController(), date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10)), notes = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setD) => AlertDialog(
      title: const Text('إضافة مكافأة'),
      content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, items: const [DropdownMenuItem(value: 'teacher', child: Text('مدرس')), DropdownMenuItem(value: 'supervisor', child: Text('مشرف'))], onChanged: (v) { if (v != null) setD(() { type = v; id = v == 'teacher' ? (teachers.isEmpty ? null : teachers.first['id']) : (supervisors.isEmpty ? null : supervisors.first['id']); }); }, decoration: const InputDecoration(labelText: 'النوع')),
        if ((type == 'teacher' ? teachers : supervisors).isNotEmpty) DropdownButtonFormField<int>(initialValue: id, items: (type == 'teacher' ? teachers : supervisors).map((x) => DropdownMenuItem<int>(value: x['id'], child: Text('${x['name'] ?? ''}'))).toList(), onChanged: (v) => setD(() => id = v), decoration: const InputDecoration(labelText: 'المستحق له')),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المكافأة'), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'المبلغ'), validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل مبلغًا صحيحًا' : null),
        TextFormField(controller: date, decoration: const InputDecoration(labelText: 'التاريخ YYYY-MM-DD')),
        TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
      ])),),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () { if (key.currentState!.validate() && id != null) Navigator.pop(c, true); }, child: const Text('حفظ'))],
    )));
    if (ok != true || id == null) return;
    try { await ApiService.post('finance/bonuses', {'recipient_type': type, 'recipient_id': id, 'name': name.text.trim(), 'amount': double.parse(amount.text), 'bonus_date': date.text.trim(), 'notes': notes.text.trim()}); await load(); msg('تم تسجيل المكافأة'); }
    catch (e) { msg(e.toString().replaceFirst('Exception: ', '')); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المالية والمستحقات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: PopupMenuButton<String>(onSelected: (v) { if (v == 'withdraw') withdraw(); if (v == 'bonus') addBonus(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'withdraw', child: Text('طلب سحب')), PopupMenuItem(value: 'bonus', child: Text('إضافة مكافأة'))], child: const FloatingActionButton(onPressed: null, child: Icon(Icons.add))),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) : RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
        _summaryCard('مستحقات المدرسين', summary['teacher_due'], summary['teacher_paid'], summary['teacher_remaining']),
        _summaryCard('مستحقات المشرفين', summary['supervisor_due'], summary['supervisor_paid'], summary['supervisor_remaining']),
        const SizedBox(height: 16),
        const Text('مستحقات المدرسين', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...teacherDues.map((d) => _dueCard('مدرس', d, 'teacher')),
        const SizedBox(height: 12),
        const Text('مستحقات المشرفين', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...supervisorDues.map((d) => _dueCard('مشرف', d, 'supervisor')),
        const SizedBox(height: 12),
        const Text('طلبات السحب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...withdrawals.map((w) => Card(child: ListTile(title: Text('${w['recipient_name'] ?? w['recipient_type'] ?? ''}'), subtitle: Text('المبلغ: ${w['amount'] ?? 0}\nالحالة: ${w['status'] ?? ''}'), trailing: w['status'] == 'paid' || w['status'] == 'rejected' ? null : PopupMenuButton<String>(onSelected: (s) => updateWithdrawal(w['id'], s), itemBuilder: (_) => const [PopupMenuItem(value: 'approved', child: Text('اعتماد')), PopupMenuItem(value: 'rejected', child: Text('رفض')), PopupMenuItem(value: 'paid', child: Text('تم الدفع'))])))),
        const SizedBox(height: 12),
        const Text('المكافآت', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...bonuses.map((b) => Card(child: ListTile(title: Text('${b['name'] ?? 'مكافأة'}'), subtitle: Text('${b['recipient_type'] ?? ''} • ${b['bonus_date'] ?? ''}'), trailing: Text('${b['amount'] ?? 0}')))),
        if (settings.isNotEmpty) ...[
          const SizedBox(height: 12), const Text('إعدادات السحب', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          ...settings.map((s) => Card(child: ListTile(title: Text(s['recipient_type'] == 'teacher' ? 'سحب المدرسين' : 'سحب المشرفين'), subtitle: Text('الحد الأدنى: ${s['minimum_amount'] ?? 0} • ${s['enabled'] == true ? 'مفتوح' : 'مغلق'}')))),
        ],
      ])),
    );
  }

  Widget _summaryCard(String title, dynamic total, dynamic paid, dynamic remaining) => Card(child: ListTile(title: Text(title), subtitle: Text('إجمالي: $total • مدفوع: $paid • متبقي: $remaining')));

  Widget _dueCard(String label, dynamic due, String type) {
    final teacher = due['teacher'];
    final supervisor = due['supervisor'];
    final person = type == 'teacher' ? teacher : supervisor;
    final name = person is Map ? '${person['name'] ?? label}' : label;
    final remaining = (double.tryParse('${due['amount'] ?? 0}') ?? 0) - (double.tryParse('${due['paid_amount'] ?? 0}') ?? 0);
    final lesson = due['lesson'];
    return Card(child: ListTile(title: Text(name), subtitle: Text('الحصة: ${lesson is Map ? (lesson['subject'] ?? '') : ''}\nالمستحق: ${due['amount'] ?? 0} • المدفوع: ${due['paid_amount'] ?? 0} • المتبقي: ${remaining.toStringAsFixed(2)}'), isThreeLine: true, trailing: remaining > 0 ? FilledButton(onPressed: () => payDue(type, due), child: const Text('صرف')) : const Icon(Icons.check_circle)));
  }
}
