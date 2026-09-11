import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List subscriptions = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = await ApiService.get('subscriptions');
      if (!mounted) return;
      setState(() {
        subscriptions = result['data'] ?? result['subscriptions'] ?? [];
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
        title: const Text('الاشتراكات'),
        actions: [
          IconButton(
            onPressed: loading ? null : loadSubscriptions,
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
                        FilledButton(onPressed: loadSubscriptions, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : subscriptions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadSubscriptions,
                      child: ListView(children: const [
                        SizedBox(height: 240),
                        Center(child: Text('لا توجد اشتراكات حاليًا')),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: loadSubscriptions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subscriptions.length,
                        itemBuilder: (_, index) {
                          final item = subscriptions[index] as Map<String, dynamic>;
                          final student = item['student'];
                          final studentName = student is Map ? '${student['name'] ?? 'طالب'}' : 'طالب';
                          final status = '${item['status'] ?? 'active'}';
                          final active = status == 'active';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(active ? Icons.check : Icons.event_busy),
                              ),
                              title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text([
                                if (item['subject'] != null) 'المادة: ${item['subject']}',
                                if (item['starts_on'] != null) 'من: ${item['starts_on']}',
                                if (item['ends_on'] != null) 'إلى: ${item['ends_on']}',
                              ].join('\n')),
                              trailing: Text(
                                '${item['amount'] ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
