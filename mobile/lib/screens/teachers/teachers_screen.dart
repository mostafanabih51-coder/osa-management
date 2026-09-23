import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> teachers = [], students = [], supervisors = [];
  List<String> subjects = [];
  bool loading = true;
  String? loadError;

  static const fallbackSubjects = <String>[
    'العربية', 'اللغة الإنجليزية', 'الرياضيات', 'العلوم', 'الدراسات الاجتماعية',
    'Math', 'Science', 'English', 'Arabic', 'German', 'French', 'Spanish', 'Quran',
    'Chemistry', 'Physics', 'Biology', 'History', 'Geography', 'Philosophy',
  ];

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    if (value is Map && value['data'] is Map && value['data']['data'] is List) {
      return List<dynamic>.from(value['data']['data']);
    }
    return [];
  }

  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;

  List<String> studentSubjects(dynamic student) {
    return list(student is Map ? student['subjects'] : null)
        .map((x) => x is Map ? '${x['subject'] ?? x['name'] ?? ''}' : '$x')
        .where((x) => x.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  void msg(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; loadError = null; });
    Object? firstError;
    try { teachers = list(await ApiService.get('teachers')); } catch (e) { firstError ??= e; }
    try { students = list(await ApiService.get('students')); } catch (e) { firstError ??= e; }
    try {
      subjects = list(await ApiService.get('subjects'))
          .map((x) => x is Map ? '${x['subject'] ?? x['name'] ?? ''}' : '$x')
          .where((x) => x.trim().isNotEmpty).toSet().toList();
    } catch (e) { firstError ??= e; }
    if (subjects.isEmpty) subjects = List<String>.from(fallbackSubjects);
    try { supervisors = list(await ApiService.get('supervisors')); } catch (e) { firstError ??= e; }
    if (!mounted) return;
    setState(() {
      loading = false;
      loadError = teachers.isEmpty && firstError != null
          ? '$firstError'.replaceFirst('Exception: ', '')
          : null;
    });
  }

  Future<void> addOrEdit({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    final email = TextEditingController(text: '${existing?['email'] ?? ''}');
    final specialization = TextEditingController(text: '${existing?['specialization'] ?? ''}');
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(existing == null ? 'إضافة مدرس' : 'تعديل المدرس'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'الاسم *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
              TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextFormField(controller: email, decoration: const InputDecoration(labelText: 'البريد'), keyboardType: TextInputType.emailAddress),
              TextFormField(controller: specialization, decoration: const InputDecoration(labelText: 'المادة / التخصص')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(d, true); }, child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final body = {
          'name': name.text.trim(), 'phone': phone.text.trim(), 'email': email.text.trim(),
          'specialization': specialization.text.trim(), 'status': 'active',
        };
        if (existing == null) {
          await ApiService.post('teachers', body);
        } else {
          await ApiService.put('teachers/${id(existing)}', body);
        }
        await load();
      } catch (e) { msg(e); }
    }
    for (final c in [name, phone, email, specialization]) c.dispose();
  }

  Future<void> remove(dynamic teacher) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('حذف المدرس'),
        content: Text('حذف ${teacher['name'] ?? ''}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try { await ApiService.delete('teachers/${id(teacher)}'); await load(); } catch (e) { msg(e); }
    }
  }

  Future<void> assign(dynamic teacher) async {
    if (students.isEmpty) {
      msg('لا يوجد طلاب محملون. افتح الطلاب وتأكد من اتصال التطبيق ثم أعد المحاولة.');
      return;
    }
    final available = students.where((s) => studentSubjects(s).isNotEmpty).toList();
    if (available.isEmpty) {
      msg('أضف مادة واحدة على الأقل للطالب قبل ربطه بالمدرس.');
      return;
    }

    int studentId = id(available.first);
    String subject = studentSubjects(available.first).first;
    int? supervisorId;
    final rate = TextEditingController();
    final percentage = TextEditingController(text: '0');

    List<dynamic> candidates() => students.where((s) => studentSubjects(s).contains(subject)).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (c, set) {
          final filtered = candidates();
          if (!filtered.any((s) => id(s) == studentId)) {
            studentId = filtered.isNotEmpty ? id(filtered.first) : 0;
          }
          final subjectOptions = subjects.where((s) => available.any((st) => studentSubjects(st).contains(s))).toList();
          return AlertDialog(
            title: Text('ربط طالب بمدرس: ${teacher['name'] ?? ''}'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: subjectOptions.contains(subject) ? subject : (subjectOptions.isNotEmpty ? subjectOptions.first : null),
                  items: subjectOptions.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v != null) set(() {
                      subject = v;
                      final f = candidates();
                      studentId = f.isEmpty ? 0 : id(f.first);
                    });
                  },
                  decoration: const InputDecoration(labelText: 'المادة المشترك بها الطالب'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: filtered.any((s) => id(s) == studentId) ? studentId : null,
                  items: filtered.map((s) => DropdownMenuItem<int>(value: id(s), child: Text('${s['name'] ?? ''}'))).toList(),
                  onChanged: (v) { if (v != null) set(() => studentId = v); },
                  decoration: const InputDecoration(labelText: 'الطالب'),
                ),
                TextField(controller: rate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر المدرس للحصة *')),
                TextField(controller: percentage, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'نسبة الأكاديمية %')),
                DropdownButtonFormField<int?>(
                  value: supervisorId,
                  items: <DropdownMenuItem<int?>>[
                    const DropdownMenuItem<int?>(value: null, child: Text('بدون مشرف')),
                    ...supervisors.map((s) => DropdownMenuItem<int?>(value: id(s), child: Text('${s['name'] ?? ''}'))),
                  ],
                  onChanged: (v) => set(() => supervisorId = v),
                  decoration: const InputDecoration(labelText: 'المشرف (اختياري)'),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (studentId > 0 && double.tryParse(rate.text) != null) {
                    Navigator.pop(d, true);
                  } else {
                    msg('اختر طالبًا وأدخل سعر المدرس.');
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true) {
      try {
        await ApiService.post('teacher-assignments', {
          'teacher_id': id(teacher), 'student_id': studentId, 'subject': subject,
          'teacher_rate': double.parse(rate.text),
          'academy_percentage': double.tryParse(percentage.text) ?? 0,
          'supervisor_id': supervisorId, 'status': 'active',
        });
        await load();
        msg('تم ربط الطالب بالمدرس والمادة والسعر.');
      } catch (e) { msg(e); }
    }
    rate.dispose();
    percentage.dispose();
  }

  Future<void> details(int teacherId) async {
    try {
      final response = await ApiService.get('teachers/$teacherId');
      final data = response is Map && response['data'] is Map ? response['data'] : response;
      final teacher = data['teacher'] is Map ? Map<String, dynamic>.from(data['teacher']) : <String, dynamic>{};
      final linked = list(data['students']);
      final assignments = list(data['assignments']);
      final lessons = list(data['lessons']);
      final privateLessons = list(data['private_lessons']);
      final groupLessons = list(data['group_lessons']);
      List<dynamic> resources = [];
      try { resources = list(await ApiService.get('academic/resources?teacher_id=$teacherId')); } catch (_) {}
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('${teacher['name'] ?? 'المدرس'}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('التخصص: ${teacher['specialization'] ?? '-'}'),
                Text('المستحق: ${data['due'] ?? 0} • المدفوع: ${data['paid'] ?? 0} • المتبقي: ${data['remaining'] ?? 0}'),
                FilledButton.icon(onPressed: () { Navigator.pop(d); assign(teacher); }, icon: const Icon(Icons.link), label: const Text('ربط طالب / مادة / سعر')),
                const Divider(),
                Text('الطلاب المرتبطون (${linked.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (linked.isEmpty) const Text('لا يوجد طلاب مرتبطون بهذا المدرس.'),
                ...linked.map((s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${s['name'] ?? ''}'),
                  subtitle: Text(s['pivot'] is Map ? '${s['pivot']['subject'] ?? ''} • سعر ${s['pivot']['teacher_rate'] ?? 0}' : ''),
                )),
                const Divider(),
                Text('Private (${privateLessons.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (privateLessons.isEmpty) const Text('لا توجد حصص Private.'),
                ...privateLessons.take(20).map((l) => Text('• ${l['student']?['name'] ?? 'طالب'} — ${l['subject'] ?? ''} — ${l['starts_at'] ?? ''}')),
                const Divider(),
                Text('Groups (${groupLessons.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (groupLessons.isEmpty) const Text('لا توجد حصص Groups.'),
                ...groupLessons.take(20).map((l) => Text('• ${l['group']?['name'] ?? 'مجموعة'} — ${l['subject'] ?? ''} — ${l['starts_at'] ?? ''}')),
                const Divider(),
                Text('كل الحصص (${lessons.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (lessons.isEmpty) const Text('لا توجد حصص مسجلة.'),
                ...lessons.take(20).map((l) => Text('• ${l['subject'] ?? ''} — ${l['starts_at'] ?? ''} — ${l['status'] ?? ''}')),
                const Divider(),
                Text('المرفقات (${resources.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (resources.isEmpty) const Text('لا توجد مرفقات.'),
                ...resources.map((r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${r['title'] ?? ''}'),
                  subtitle: Text('${r['type'] ?? ''} • ${r['description'] ?? ''}'),
                  trailing: r['url'] == null ? null : IconButton(
                    onPressed: () async {
                      final u = Uri.tryParse('${r['url']}');
                      if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new),
                  ),
                )),
                Text('العلاقات والأسعار: ${assignments.length}'),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) { msg(e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addOrEdit(), backgroundColor: AppColors.red,
        icon: const Icon(Icons.person_add), label: const Text('إضافة مدرس'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: loadError != null
                  ? ListView(children: [
                      const SizedBox(height: 160),
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('تعذر تحميل المدرسين. اضغط تحديث للمحاولة مرة أخرى.', textAlign: TextAlign.center))),
                      Center(child: FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      children: [
                        Card(child: Padding(padding: const EdgeInsets.all(14), child: Text('المدرسون: ${teachers.length} • الطلاب المتاحون للربط: ${students.length}'))),
                        if (teachers.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا يوجد مدرسون بعد.'))),
                        ...teachers.map((teacher) => Card(
                          child: ListTile(
                            onTap: () => details(id(teacher)),
                            leading: const CircleAvatar(child: Icon(Icons.school)),
                            title: Text('${teacher['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('المادة: ${teacher['specialization'] ?? '-'}\n${teacher['phone'] ?? teacher['email'] ?? ''}'),
                            isThreeLine: true,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(onPressed: () => assign(teacher), icon: const Icon(Icons.link)),
                              IconButton(onPressed: () => addOrEdit(existing: Map<String, dynamic>.from(teacher)), icon: const Icon(Icons.edit)),
                              IconButton(onPressed: () => remove(teacher), icon: const Icon(Icons.delete)),
                            ]),
                          ),
                        )),
                      ],
                    ),
            ),
    );
  }
}
