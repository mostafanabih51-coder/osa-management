import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List expenses = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ApiService.get('expenses');
      if (!mounted) return;
      setState(() {
        expenses = result['data'] ?? result['expenses'] ?? [];
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
        title: const Text('المصروفات'),
        actions: [
          IconButton(
            onPressed: loading ? null : loadExpenses,
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
                          onPressed: loadExpenses,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : expenses.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadExpenses,
                      child: ListView(
                        children: const [
                          SizedBox(height: 220),
                          Center(child: Text('لا توجد مصروفات حاليًا')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadExpenses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (_, index) {
                          final item = expenses[index] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.money_off)),
                              title: Text(
                                '${item['category'] ?? item['description'] ?? 'مصروف'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${item['spent_on'] ?? ''}'),
                              trailing: Text(
                                '${item['amount'] ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
