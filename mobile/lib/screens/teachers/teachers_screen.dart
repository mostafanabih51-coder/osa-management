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
  List<dynamic> teachers = [];
  List<dynamic> students = [];
  List<dynamic> subjects = [];
  List<dynamic> supervisors = [];
  bool loading = true;

  static const fallbackSubjects = <String>[
    'العربية', 'اللغة الإنجليزية', 'الرياضيات', 'العلوم', 'الدراسات الاجتماعية',
    'Math', 'Science', 'English', 'Arabic', 'German', 'French', 'Spanish',
    'Quran', 'Chemistry', 'Physics', 'Biology', 'History', 'Geography', 'Philosophy',
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

  void msg(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
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
      teachers = list(await ApiService.get('teachers'));
    } catch (e) {
      msg(e);
    }
    try {
      students = list(await ApiService.get('students'));
    } catch (_) {}
    try {
      final loaded = list(await ApiService.get('subjects'))
          .map((x) => x is Map ? '${x['subject'] ?? x['name'] ?? ''}' : '$x')
          .where((x) => x.trim().isNotEmpty)
          .toSet()
          .toList();
      subjects = loaded.isEmpty ? fallbackSubjects : loaded;
    } catch (_) {
      subjects = fallbackSubjects;
    }
    try {
      supervisors = list(await ApiService.get('supervisors'));
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> remove(dynamic teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المدرس'),
        content: Text('حذف ${teacher['name'] ?? ''}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('teachers/${id(teacher)}');
        await load();
      } catch (e) {
        msg(e);
      }
    }
  }

  Future<void> edit(dynamic teacher) async {
    final name = TextEditingController(text: '${teacher['name'] ?? ''}');
    final phone = TextEditingController(text: '${teacher['phone'] ?? ''}');
    final email = TextEditingController(text: '${teacher['email'] ?? ''}');
    final specialization = TextEditingController(text: '${teacher['specialization'] ?? ''}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل المدرس'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد')),
              TextField(
                controller: specialization,
                decoration: const InputDecoration(labelText: 'المادة / التخصص'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ApiService.put('teachers/${id(teacher)}', {
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
          'specialization': specialization.text.trim(),
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }

    for (final controller in [name, phone, email, specialization]) {
      controller.dispose();
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final specialization = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مدرس'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد')),
              TextField(
                controller: specialization,
                decoration: const InputDecoration(labelText: 'المادة / التخصص'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ApiService.post('teachers', {
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'email': email.text.trim(),
          'specialization': specialization.text.trim(),
          'status': 'active',
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }

    for (final controller in [name, phone, email, specialization]) {
      controller.dispose();
    }
  }

  Future<void> assign(dynamic teacher) async {
    if (students.isEmpty) {
      msg('أضف طالبًا أولًا.');
      return;
    }

    final specialization = '${teacher['specialization'] ?? ''}'.trim();
    String subject = subjects.contains(specialization) ? specialization : '${subjects.first}';
    int studentId = id(students.first);
    int? supervisorId;
    final rate = TextEditingController();
    final percentage = TextEditingController(text: '0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('ربط طالب بمدرس: ${teacher['name'] ?? ''}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: studentId,
                      items: students
                          .map<DropdownMenuItem<int>>(
                            (student) => DropdownMenuItem<int>(
                              value: id(student),
                              child: Text('${student['name'] ?? ''}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => studentId = value);
                      },
                      decoration: const InputDecoration(labelText: 'الطالب'),
                    ),
                    DropdownButtonFormField<String>(
                      value: subject,
                      items: subjects
                          .map<DropdownMenuItem<String>>(
                            (value) => DropdownMenuItem<String>(value: '$value', child: Text('$value')),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => subject = value);
                      },
                      decoration: InputDecoration(
                        labelText: specialization.isEmpty ? 'المادة' : 'المادة: $specialization',
                      ),
                    ),
                    TextField(
                      controller: rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'سعر المدرس للحصة'),
                    ),
                    TextField(
                      controller: percentage,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'نسبة الأكاديمية %'),
                    ),
                    DropdownButtonFormField<int?>(
                      value: supervisorId,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(value: null, child: Text('بدون مشرف')),
                        ...supervisors.map<DropdownMenuItem<int?>>(
                          (supervisor) => DropdownMenuItem<int?>(
                            value: id(supervisor),
                            child: Text('${supervisor['name'] ?? ''}'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() => supervisorId = value),
                      decoration: const InputDecoration(labelText: 'المشرف (اختياري)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await ApiService.post('teacher-assignments', {
          'teacher_id': id(teacher),
          'student_id': studentId,
          'subject': subject,
          'teacher_rate': double.tryParse(rate.text) ?? 0,
          'academy_percentage': double.tryParse(percentage.text) ?? 0,
          'supervisor_id': supervisorId,
          'status': 'active',
        });
        msg('تم الحفظ وربط الطالب بالمدرس والمادة والسعر');
      } catch (e) {
        msg(e);
      }
    }

    rate.dispose();
    percentage.dispose();
  }

  Future<void> openUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      msg('الرابط غير صالح');
    }
  }

  Future<void> details(int teacherId) async {
    try {
      final response = await ApiService.get('teachers/$teacherId');
      final data = response is Map && response['data'] is Map ? response['data'] : response;
      final teacher = data['teacher'] is Map
          ? Map<String, dynamic>.from(data['teacher'])
          : <String, dynamic>{};
      final linkedStudents = list(data['students']);
      final assignments = list(data['assignments']);
      List<dynamic> resources = [];
      try {
        resources = list(await ApiService.get('academic/resources?teacher_id=$teacherId'));
      } catch (_) {}

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${teacher['name'] ?? 'المدرس'}'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('المادة: ${teacher['specialization'] ?? '-'}'),
                  FilledButton.icon(
                    onPressed: () => assign(teacher),
                    icon: const Icon(Icons.link),
                    label: const Text('ربط طالب / مادة / سعر'),
                  ),
                  const Divider(),
                  Text(
                    'الطلاب المرتبطون (${linkedStudents.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...linkedStudents.map(
                    (student) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${student['name'] ?? ''}'),
                      subtitle: Text(
                        student['pivot'] is Map ? '${student['pivot']['subject'] ?? ''}' : '',
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'الواجبات والامتحانات والروابط والمرفقات (${resources.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...resources.map(
                    (resource) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${resource['title'] ?? ''}'),
                      subtitle: Text(
                        '${resource['type'] ?? ''} • ${resource['description'] ?? ''}',
                      ),
                      trailing: resource['url'] == null
                          ? null
                          : IconButton(
                              onPressed: () => openUrl('${resource['url']}'),
                              icon: const Icon(Icons.open_in_new),
                            ),
                    ),
                  ),
                  const Divider(),
                  Text('العلاقات والأسعار: ${assignments.length}'),
                  ...assignments.map(
                    (assignment) => Text(
                      '• ${assignment['student'] is Map ? '${assignment['student']['name'] ?? ''}' : ''} — ${assignment['subject'] ?? ''} — ${assignment['teacher_rate'] ?? 0}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      msg(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدرسون'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مدرس'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('عدد الطلاب المسجلين: ${students.length}'),
                    ),
                  ),
                  ...teachers.map(
                    (teacher) => Card(
                      child: ListTile(
                        onTap: () => details(id(teacher)),
                        leading: const CircleAvatar(child: Icon(Icons.school)),
                        title: Text(
                          '${teacher['name'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'المادة: ${teacher['specialization'] ?? '-'}\n${teacher['phone'] ?? teacher['email'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => assign(teacher), icon: const Icon(Icons.link)),
                            IconButton(onPressed: () => edit(teacher), icon: const Icon(Icons.edit)),
                            IconButton(onPressed: () => remove(teacher), icon: const Icon(Icons.delete)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
