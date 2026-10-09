import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubscriptionsScreen extends StatefulWidget {
  final bool showDebtorsOnly;
  const SubscriptionsScreen({super.key, this.showDebtorsOnly = false});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<dynamic> subscriptions = [], students = [], groups = [];
  List<String> subjects = [];
  bool loading = true;

  static const fallbackSubjects = <String>[
    'العربية', 'اللغة الإنجليزية', 'مستوى إنجليزي', 'إنجليزي لغات', 'الرياضيات', 'الرياضيات (إنجليزي)', 'العلوم', 'العلوم (إنجليزي)', 'الدراسات الاجتماعية', 'الفرنسية',
    'Math (English)', 'Science (English)', 'English Level', 'German', 'French', 'Spanish', 'Quran',
    'Chemistry', 'Physics', 'Biology', 'History', 'Geography', 'Philosophy',
  ];

  List<dynamic> list(dynamic x) {
    if (x is List) return List<dynamic>.from(x);
    if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']);
    if (x is Map && x['data'] is Map && x['data']['data'] is List) {
      return List<dynamic>.from(x['data']['data']);
    }
    return [];
  }

  double outstanding(dynamic s) {
    if (s is! Map) return 0;
    final payments = list(s['payments']);
    final paid = payments.fold<double>(0, (sum, p) =>
        sum + (double.tryParse('${p is Map ? p['amount'] : 0}') ?? 0));
    final usageCount = int.tryParse('${s['lesson_usages_count'] ?? list(s['lesson_usages']).length}') ?? 0;
    final isPerLesson = '${s['billing_type'] ?? 'monthly'}' == 'per_lesson';
    final price = double.tryParse('${s['lesson_price'] ?? s['amount'] ?? 0}') ?? 0;
    final gross = isPerLesson ? price * usageCount : (double.tryParse('${s['amount'] ?? 0}') ?? 0);
    return gross > paid ? gross - paid : 0;
  }

  int usedLessons(dynamic s) =>
      int.tryParse('${s is Map ? s['lesson_usages_count'] ?? list(s['lesson_usages']).length : 0}') ?? 0;

  int remainingLessons(dynamic s) {
    final count = int.tryParse('${s is Map ? s['lesson_count'] ?? '' : ''}') ?? 0;
    final remaining = count - usedLessons(s);
    return remaining > 0 ? remaining : 0;
  }

  List<dynamic> get displayedSubscriptions => widget.showDebtorsOnly
      ? subscriptions.where((s) => outstanding(s) > 0.009).toList()
      : subscriptions;

  int id(dynamic x) => int.tryParse('${x['id']}') ?? 0;
  String sub(dynamic x) => x is Map ? '${x['subject'] ?? x['name'] ?? ''}' : '$x';

  void msg(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final r = await ApiService.get(widget.showDebtorsOnly ? 'subscriptions?debtors_only=1' : 'subscriptions');
      subscriptions = list(r);
    } catch (e) {
      msg(e);
    }
    try {
      students = list(await ApiService.get('students'));
    } catch (e) {
      msg(e);
    }
    try { groups = list(await ApiService.get('groups')); } catch (_) { groups = []; }
    try {
      final ss = list(await ApiService.get('subjects'))
          .map(sub).where((x) => x.trim().isNotEmpty).toSet().toList();
      subjects = ss.isEmpty ? List<String>.from(fallbackSubjects) : ss;
    } catch (_) {
      subjects = List<String>.from(fallbackSubjects);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> pickDate(TextEditingController controller) async {
    DateTime initial;
    try {
      initial = DateTime.parse(controller.text);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'اختر التاريخ',
    );
    if (picked != null) {
      controller.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> form({dynamic item}) async {
    if (students.isEmpty) {
      msg('أضف طالبًا أولًا.');
      return;
    }

    int studentId = id(item?['student'] ?? {'id': item?['student_id']});
    String subject = '${item?['subject'] ?? subjects.first}';
    if (!subjects.contains(subject)) subject = subjects.first;
    String status = '${item?['status'] ?? 'active'}';
    String serviceType = '${item?['service_type'] ?? 'group'}';
    String billingType = '${item?['billing_type'] ?? 'monthly'}';
    int? groupId = int.tryParse('${item?['group_id'] ?? item?['group']?['id'] ?? ''}');

    final amount = TextEditingController(text: '${item?['amount'] ?? ''}');
    final lessonPrice = TextEditingController(
      text: '${item?['lesson_price'] ?? item?['amount'] ?? ''}',
    );
    final lessonCount = TextEditingController(
      text: '${item?['lesson_count'] ?? 8}',
    );
    final defaultStart = DateTime.now();
    final defaultEnd = defaultStart.add(const Duration(days: 30));
    String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final start = TextEditingController(text: '${item?['starts_on'] ?? isoDate(defaultStart)}');
    final end = TextEditingController(text: '${item?['ends_on'] ?? isoDate(defaultEnd)}');
    final key = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(item == null ? 'إضافة اشتراك' : 'تعديل الاشتراك'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: students.any((s) => id(s) == studentId) ? studentId : null,
                      items: students.map((s) => DropdownMenuItem(
                        value: id(s), child: Text('${s['name'] ?? ''}'),
                      )).toList(),
                      onChanged: (v) { if (v != null) set(() { studentId = v; }); },
                      decoration: const InputDecoration(labelText: 'الطالب *'),
                      validator: (v) => v == null ? 'اختر الطالب' : null,
                    ),
                    if (serviceType == 'group')
                      DropdownButtonFormField<int>(
                        value: groups.any((g) => id(g) == groupId && g['students'] is List && (g['students'] as List).any((s) => id(s) == studentId)) ? groupId : null,
                        items: groups.where((g) => g['students'] is List && (g['students'] as List).any((s) => id(s) == studentId)).map((g) => DropdownMenuItem<int>(value: id(g), child: Text('${g['name'] ?? ''} • ${g['subject'] ?? ''} • ${g['teacher']?['name'] ?? ''}'))).toList(),
                        onChanged: (v) { if (v != null) set(() { groupId = v; final g = groups.firstWhere((x) => id(x) == v); final gs = '${g['subject'] ?? ''}'; if (subjects.contains(gs)) subject = gs; }); },
                        decoration: const InputDecoration(labelText: 'المجموعة المرتبط بها الطالب *'),
                        validator: (v) => v == null ? 'أضف الطالب إلى مجموعة أولًا ثم اخترها' : null,
                      ),
                    DropdownButtonFormField<String>(
                      value: subject,
                      items: subjects.map((s) => DropdownMenuItem(
                        value: s, child: Text(s),
                      )).toList(),
                      onChanged: (v) { if (v != null) set(() => subject = v); },
                      decoration: const InputDecoration(labelText: 'المادة *'),
                    ),
                    DropdownButtonFormField<String>(
                      value: serviceType,
                      items: const [
                        DropdownMenuItem(value: 'private', child: Text('Private — خاص')),
                        DropdownMenuItem(value: 'group', child: Text('Group — مجموعة')),
                      ],
                      onChanged: (v) {
                        if (v != null) set(() {
                          serviceType = v;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'نوع الخدمة *'),
                    ),
                    if (serviceType == 'private')
                      DropdownButtonFormField<String>(
                        value: billingType,
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                          DropdownMenuItem(value: 'per_lesson', child: Text('بالحصة')),
                        ],
                        onChanged: (v) { if (v != null) set(() => billingType = v); },
                        decoration: const InputDecoration(labelText: 'طريقة احتساب الاشتراك *'),
                      ),
                    if (serviceType == 'private')
                      TextFormField(
                        controller: lessonPrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'سعر الحصة الخاصة *'),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل سعر الحصة' : null,
                      ),
                    if (serviceType == 'private' && billingType == 'monthly')
                      TextFormField(
                        controller: lessonCount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'عدد الحصص شهريًا'),
                        validator: (v) => int.tryParse(v ?? '') == null ? 'أدخل عددًا صحيحًا' : null,
                      ),
                    if ((serviceType == 'private' && billingType == 'monthly') || serviceType == 'group')
                      TextFormField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'قيمة الاشتراك الشهري *'),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل قيمة الاشتراك الشهري' : null,
                      ),
                    if (serviceType == 'group')
                      TextFormField(
                        controller: lessonCount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'عدد حصص Group شهريًا'),
                        validator: (v) => int.tryParse(v ?? '') == null ? 'أدخل عددًا صحيحًا' : null,
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: start,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'بداية الاشتراك *'),
                            onTap: () => pickDate(start),
                            validator: (v) => DateTime.tryParse(v ?? '') == null ? 'اختر تاريخ البداية' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: end,
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'نهاية الاشتراك *'),
                            onTap: () => pickDate(end),
                            validator: (v) {
                              final a = DateTime.tryParse(start.text);
                              final b = DateTime.tryParse(v ?? '');
                              return a == null || b == null || b.isBefore(a) ? 'تاريخ النهاية غير صحيح' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشط')),
                        DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                        DropdownMenuItem(value: 'expired', child: Text('منتهي')),
                      ],
                      onChanged: (v) { if (v != null) set(() => status = v); },
                      decoration: const InputDecoration(labelText: 'الحالة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(d, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      try {
        final private = serviceType == 'private';
        final lp = double.tryParse(lessonPrice.text);
        final monthlyAmount = double.tryParse(amount.text);
        if (private && lp == null) {
          msg('أدخل سعر الحصة الخاصة.');
          return;
        }
        if ((private && billingType == 'monthly' || !private) && monthlyAmount == null) {
          msg('أدخل قيمة الاشتراك الشهري.');
          return;
        }
        final body = {
          'student_id': studentId,
          'group_id': serviceType == 'group' ? groupId : null,
          'subject': subject,
          'service_type': serviceType,
          'billing_type': private ? billingType : 'monthly',
          'amount': private ? (billingType == 'monthly' ? monthlyAmount : lp) : monthlyAmount,
          'lesson_price': private ? lp : null,
          'lesson_count': private ? (billingType == 'monthly' ? int.tryParse(lessonCount.text) : null) : int.tryParse(lessonCount.text),
          'starts_on': start.text.trim(),
          'ends_on': end.text.trim(),
          'status': status,
        };
        if (item == null) {
          await ApiService.post('subscriptions/enhanced', body);
        } else {
          await ApiService.put('subscriptions/${id(item)}', body);
        }
        await load();
      } catch (e) {
        msg(e);
      }
    }

    for (final c in [amount, lessonPrice, lessonCount, start, end]) {
      c.dispose();
    }
  }

  Future<void> remove(dynamic s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('حذف الاشتراك'),
        content: const Text('هل تريد الحذف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.delete('subscriptions/${id(s)}');
        await load();
      } catch (e) {
        msg(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.showDebtorsOnly ? 'الاشتراكات غير المسددة' : 'الاشتراكات'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => form(),
      icon: const Icon(Icons.add),
      label: const Text('إضافة اشتراك'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: displayedSubscriptions.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 180),
                    Center(child: Text(widget.showDebtorsOnly ? 'لا توجد اشتراكات عليها مديونية.' : 'لا توجد اشتراكات.')),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: displayedSubscriptions.length,
                    itemBuilder: (_, i) {
                      final s = displayedSubscriptions[i];
                      final student = s['student'];
                      return Card(
                        child: ListTile(
                          title: Text('${student?['name'] ?? 'طالب'}'),
                          subtitle: Text(
                            '${s['subject'] ?? ''} • ${s['service_type'] ?? 'group'} • ${s['amount'] ?? 0}\n'
                            '${s['starts_on'] ?? ''} → ${s['ends_on'] ?? ''} • ${s['status'] ?? ''}\\n'
                            'الحصص المستخدمة: ${usedLessons(s)} • المتبقي من الباقة: ${remainingLessons(s)} • المديونية: ${outstanding(s).toStringAsFixed(2)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(onPressed: () => form(item: s), icon: const Icon(Icons.edit)),
                              IconButton(onPressed: () => remove(s), icon: const Icon(Icons.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
  );
}
