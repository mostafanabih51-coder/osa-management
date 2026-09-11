import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.get('reports/financial');
      if (!mounted) return;
      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        actions: [
          IconButton(
            onPressed: loading ? null : loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 52),
                        const SizedBox(height: 12),
                        Text(error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadReports,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReports,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _card('إجمالي الدخل', data?['income'] ?? 0),
                      _card('إجمالي المصروفات', data?['expenses'] ?? 0),
                      _card('مستحقات المدرسين', data?['teacher_dues'] ?? 0),
                      _card('المدفوع للمدرسين', data?['teacher_paid'] ?? 0),
                      _card(
                        'صافي التشغيل',
                        _number(data?['income']) - _number(data?['expenses']) - _number(data?['teacher_paid']),
                      ),
                    ],
                  ),
                ),
    );
  }

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  Widget _card(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.bar_chart, color: AppColors.red),
        title: Text(title),
        trailing: Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
