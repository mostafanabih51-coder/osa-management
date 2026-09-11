import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await ApiService.get('payments');
      if (!mounted) return;
      setState(() {
        items = result['data'] ?? result['payments'] ?? [];
        loading = false;
        error = null;
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
      appBar: AppBar(title: const Text('المدفوعات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: load, child: const Text('إعادة المحاولة')),
                  ]),
                ))
              : items.isEmpty
                  ? RefreshIndicator(
                      onRefresh: load,
                      child: ListView(children: const [
                        SizedBox(height: 220),
                        Center(child: Text('لا توجد مدفوعات حاليًا')),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i] as Map<String, dynamic>;
                          final student = item['student'];
                          final studentName = student is Map ? '${student['name'] ?? 'طالب'}' : 'طالب';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.payments)),
                              title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['paid_on'] ?? ''}'),
                              trailing: Text('${item['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
