import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class SubscriptionRemindersScreen extends StatefulWidget {
  const SubscriptionRemindersScreen({super.key});

  @override
  State<SubscriptionRemindersScreen> createState() => _SubscriptionRemindersScreenState();
}

class _SubscriptionRemindersScreenState extends State<SubscriptionRemindersScreen> {
  List<dynamic> reminders = [];
  bool loading = true;
  bool unreadOnly = true;
  String? error;

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    return [];
  }

  int id(dynamic value) => int.tryParse('${value is Map ? value['id'] : ''}') ?? 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      reminders = list(await ApiService.get('subscription-reminders?unread_only=${unreadOnly ? 1 : 0}'));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> markRead(dynamic reminder) async {
    try {
      await ApiService.post('subscription-reminders/${id(reminder)}/read', {});
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String typeLabel(dynamic type) {
    switch ('$type') {
      case 'renewal_due': return 'تجديد قريب';
      case 'overdue': return 'مديونية متأخرة';
      case 'collection_due': return 'موعد تحصيل';
      default: return 'تنبيه اشتراك';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('تنبيهات الاشتراكات'),
      actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        PopupMenuButton<bool>(
          initialValue: unreadOnly,
          onSelected: (value) { setState(() => unreadOnly = value); load(); },
          itemBuilder: (_) => const [
            PopupMenuItem(value: true, child: Text('غير المقروءة فقط')),
            PopupMenuItem(value: false, child: Text('كل التنبيهات')),
          ],
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))])))
            : RefreshIndicator(
                onRefresh: load,
                child: reminders.isEmpty
                    ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا توجد تنبيهات في هذا العرض.'))])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: reminders.length,
                        itemBuilder: (_, index) {
                          final raw = reminders[index];
                          final r = raw is Map ? raw : {};
                          final read = r['read_at'] != null;
                          return GlassSurface(padding: EdgeInsets.zero, radius: 20, blur: 12,
                            child: ListTile(
                              leading: Icon(read ? Icons.notifications_none : Icons.notifications_active, color: read ? null : Theme.of(context).colorScheme.primary),
                              title: Text('${r['title'] ?? typeLabel(r['reminder_type'])}'),
                              subtitle: Text('${r['message'] ?? ''}\nالتاريخ: ${r['due_on'] ?? ''}'),
                              isThreeLine: true,
                              trailing: read ? const Icon(Icons.done) : IconButton(tooltip: 'تحديد كمقروء', onPressed: () => markRead(r), icon: const Icon(Icons.mark_email_read)),
                            ),
                          );
                        },
                      ),
              ),
  );
}
