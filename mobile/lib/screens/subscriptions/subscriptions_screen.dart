import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<dynamic> subscriptions = [];
  List<dynamic> students = [];
  List<String> subjects = [];
  bool loading = true;

  static const fallbackSubjects = <String>[
    'العربية', 'اللغة الإنجليزية', 'الرياضيات', 'العلوم', 'الدراسات الاجتماعية',
    'Math', 'Science', 'English', 'Arabic', 'German', 'French', 'Spanish', 'Quran'
  ];

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    return [];
  }

  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;
  String subjectName(dynamic value) => value is Map ? '${value['subject'] ?? value['name'] ?? ''}' : '$value';

  void msg(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await Future.wait([
        ApiService.get('subscriptions'),
        ApiService.get('students'),
        ApiService.get('subjects'),
      ]);
      final loadedSubjects = list(result[2]).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList();
      if (!mounted) return;
      setState(() {
        subscriptions = list(result[0]);
        students = list(result[1]);
        subjects = loadedSubjects.isEmpty ? fallbackSubjects : loadedSubjects;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      msg(e);
    }
  }

  Future<void> add() async {
    if (students.isEmpty) {
      msg(Exception('أضف طالبًا أولًا.'));
      return;
    }
    int studentId = id(students.first);
    String subject = subjects.first;
    String status = 'active';
    final amount = TextEditingController();
    final start = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final end = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10));
    final form = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة اشتراك'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: studentId,
                  decoration: const InputDecoration(labelText: 'الطالب *'),
                  items: students.map((student) => DropdownMenuItem<int>(value: id(student), child: Text('${student['name']}'))).toList(),
                  onChanged: (value) { if (value != null) setDialogState(() => studentId = value); },
                ),
                DropdownButtonFormField<String>(
                  value: subject,
                  decoration: const InputDecoration(labelText: 'المادة *'),
                  items: subjects.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (value) { if (value != null) setDialogState(() => subject = value); },
                ),
                TextFormField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ *'), validator: (v) => double.tryParse(v ?? '') == null ? 'مبلغ غير صحيح' : null),
                TextFormField(controller: start, decoration: const InputDecoration(labelText: 'البداية YYYY-MM-DD'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                TextFormField(controller: end, decoration: const InputDecoration(labelText: 'النهاية YYYY-MM-DD'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                    DropdownMenuItem(value: 'expired', child: Text('منتهي')),
                  ],
                  onChanged: (value) { if (value != null) setDialogState(() => status = value); },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('حفظ الاشتراك')),
          ],
        ),
      ),
    );

    if (saved == true) {
      try {
        await ApiService.post('subscriptions', {
          'student_id': studentId,
          'subject': subject,
          'amount': double.parse(amount.text),
          'starts_on': start.text.trim(),
          'ends_on': end.text.trim(),
          'status': status,
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    amount.dispose();
    start.dispose();
    end.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراكات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.add), label: const Text('إضافة اشتراك')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: subscriptions.length,
                itemBuilder: (_, index) {
                  final subscription = subscriptions[index];
                  final student = subscription['student'];
                  final payments = list(subscription['payments']);
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.event_available)),
                      title: Text('${student?['name'] ?? 'طالب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${subscription['subject'] ?? ''} • ${subscription['amount'] ?? 0}\n${subscription['starts_on'] ?? ''} → ${subscription['ends_on'] ?? ''} • ${subscription['status'] ?? ''}\nمدفوعات مرتبطة: ${payments.length}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
