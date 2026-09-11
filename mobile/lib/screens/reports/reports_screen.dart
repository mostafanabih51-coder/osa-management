import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;
  late String month;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    month = '${n.year}-${n.month.toString().padLeft(2, '0')}';
    loadReports();
  }

  Future<void> loadReports() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final r = await ApiService.get('reports/financial?month=$month');
      if (!mounted) return;
      setState(() { data = r; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> changeMonth(int delta) async {
    final parts = month.split('-');
    final d = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta, 1);
    setState(() => month = '${d.year}-${d.month.toString().padLeft(2, '0')}');
    await loadReports();
  }

  double _number(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(appBar: AppBar(title: const Text('التقارير المالية')), body: const Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: const Text('التقارير المالية')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: loadReports, child: const Text('إعادة المحاولة'))]))));

    final income = _number(data?['income']);
    final expenses = _number(data?['expenses']);
    // expenses already includes teacher/supervisor payments recorded by FinanceController.
    // Do not subtract teacherPaid/supervisorPaid a second time.
    final net = income - expenses;

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير المالية'), actions: [IconButton(onPressed: loadReports, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(
        onRefresh: loadReports,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: ListTile(leading: IconButton(onPressed: () => changeMonth(-1), icon: const Icon(Icons.chevron_right)), title: Center(child: Text(month, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), trailing: IconButton(onPressed: () => changeMonth(1), icon: const Icon(Icons.chevron_left)))),
          _card('إجمالي الدخل', data?['income'] ?? 0),
          _card('إجمالي المصروفات', data?['expenses'] ?? 0),
          _card('مستحقات المدرسين', data?['teacher_dues'] ?? 0),
          _card('المدفوع للمدرسين', data?['teacher_paid'] ?? 0),
          _card('مستحقات المشرفين', data?['supervisor_dues'] ?? 0),
          _card('المدفوع للمشرفين', data?['supervisor_paid'] ?? 0),
          _card('صافي التشغيل', net),
        ],),
      ),
    );
  }

  Widget _card(String title, dynamic value) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const Icon(Icons.bar_chart, color: AppColors.red), title: Text(title), trailing: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))));
}
