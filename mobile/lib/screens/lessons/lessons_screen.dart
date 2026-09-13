import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<dynamic> lessons = [];
  List<dynamic> teachers = [];
  List<dynamic> students = [];
  List<dynamic> supervisors = [];
  List<dynamic> groups = [];
  List<String> subjects = [];
  bool loading = true;
  String? error;

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
        ApiService.get('lessons'),
        ApiService.get('teachers'),
        ApiService.get('students'),
        ApiService.get('supervisors'),
        ApiService.get('groups'),
        ApiService.get('subjects'),
      ]);
      final loadedSubjects = list(result[5]).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList();
      if (!mounted) return;
      setState(() {
        lessons = list(result[0]);
        teachers = list(result[1]);
        students = list(result[2]);
        supervisors = list(result[3]);
        groups = list(result[4]);
        subjects = loadedSubjects.isEmpty ? fallbackSubjects : loadedSubjects;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; subjects = fallbackSubjects; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  String studentSubject(dynamic student) {
    final values = list(student['subjects']).map(subjectName).where((x) => x.trim().isNotEmpty).toList();
    return values.isEmpty ? subjects.first : values.first;
  }

  List<String> subjectsForStudent(dynamic student) {
    final values = list(student['subjects']).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList();
    return values.isEmpty ? subjects : values;
  }

  List<dynamic> teachersForStudent(dynamic student, String subject) {
    final assigned = list(student['teachers']).where((teacher) {
      final pivot = teacher is Map ? teacher['pivot'] : null;
      if (pivot is Map && pivot['subject'] != null) return '${pivot['subject']}' == subject;
      return true;
    }).toList();
    return assigned.isEmpty ? teachers : assigned;
  }

  Future<void> addLesson(String initialType) async {
    if (teachers.isEmpty) {
      msg(Exception('أضف مدرسًا أولًا من شاشة المدرسين.'));
      return;
    }
    if (initialType == 'private' && students.isEmpty) {
      msg(Exception('أضف طالبًا أولًا من شاشة الطلاب.'));
      return;
    }
    if (initialType == 'group' && groups.isEmpty) {
      msg(Exception('أنشئ مجموعة أولًا من شاشة المجموعات.'));
      return;
    }

    String type = initialType;
    dynamic selectedStudent = students.isEmpty ? null : students.first;
    dynamic selectedGroup = groups.isEmpty ? null : groups.first;
    String subject = type == 'private' ? studentSubject(selectedStudent) : '${selectedGroup['subject'] ?? subjects.first}';
    int teacherId = type == 'private' ? id(teachersForStudent(selectedStudent, subject).first) : id(selectedGroup['teacher'] ?? teachers.first);
    int? supervisorId;
    final rate = TextEditingController(text: type == 'group' ? '${selectedGroup['teacher_rate'] ?? ''}' : '');
    final starts = TextEditingController();
    final ends = TextEditingController();
    final form = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableSubjects = type == 'private' ? subjectsForStudent(selectedStudent) : <String>['${selectedGroup['subject'] ?? subject}'];
            final availableTeachers = type == 'private' ? teachersForStudent(selectedStudent, subject) : <dynamic>[selectedGroup['teacher'] ?? teachers.first];
            if (!availableSubjects.contains(subject)) subject = availableSubjects.first;
            if (!availableTeachers.any((teacher) => id(teacher) == teacherId)) teacherId = id(availableTeachers.first);
            return AlertDialog(
              title: Text(type == 'private' ? 'إضافة حصة خاصة' : 'إضافة حصة جروب'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                          child: Text(type == 'private'
                              ? 'الحصة الخاصة: طالب + مدرس مرتبط + مادة الطالب + سعر الحصة + مشرف اختياري.'
                              : 'حصة الجروب: مجموعة + مدرس المجموعة + مادة المجموعة + سعر الحصة + مشرف اختياري.'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: const InputDecoration(labelText: 'نوع الحصة'),
                          items: const [
                            DropdownMenuItem(value: 'private', child: Text('حصة خاصة')),
                            DropdownMenuItem(value: 'group', child: Text('حصة جروب')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            if (value == 'private' && students.isEmpty) return;
                            if (value == 'group' && groups.isEmpty) return;
                            setDialogState(() {
                              type = value;
                              if (type == 'private') {
                                selectedStudent = students.first;
                                subject = studentSubject(selectedStudent);
                                teacherId = id(teachersForStudent(selectedStudent, subject).first);
                              } else {
                                selectedGroup = groups.first;
                                subject = '${selectedGroup['subject'] ?? subjects.first}';
                                teacherId = id(selectedGroup['teacher'] ?? teachers.first);
                                rate.text = '${selectedGroup['teacher_rate'] ?? ''}';
                              }
                            });
                          },
                        ),
                        if (type == 'private')
                          DropdownButtonFormField<int>(
                            value: id(selectedStudent),
                            decoration: const InputDecoration(labelText: 'الطالب *'),
                            items: students.map((student) => DropdownMenuItem<int>(value: id(student), child: Text('${student['name']}'))).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              selectedStudent = students.firstWhere((student) => id(student) == value);
                              final available = subjectsForStudent(selectedStudent);
                              setDialogState(() {
                                subject = available.first;
                                teacherId = id(teachersForStudent(selectedStudent, subject).first);
                              });
                            },
                          ),
                        if (type == 'group')
                          DropdownButtonFormField<int>(
                            value: id(selectedGroup),
                            decoration: const InputDecoration(labelText: 'المجموعة *'),
                            items: groups.map((group) => DropdownMenuItem<int>(value: id(group), child: Text('${group['name']}'))).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              selectedGroup = groups.firstWhere((group) => id(group) == value);
                              setDialogState(() {
                                subject = '${selectedGroup['subject'] ?? subjects.first}';
                                teacherId = id(selectedGroup['teacher'] ?? teachers.first);
                                rate.text = '${selectedGroup['teacher_rate'] ?? ''}';
                              });
                            },
                          ),
                        DropdownButtonFormField<int>(
                          value: teacherId,
                          decoration: const InputDecoration(labelText: 'المدرس *'),
                          items: availableTeachers.map((teacher) => DropdownMenuItem<int>(value: id(teacher), child: Text('${teacher['name']}'))).toList(),
                          onChanged: type == 'group' ? null : (value) { if (value != null) setDialogState(() => teacherId = value); },
                        ),
                        DropdownButtonFormField<String>(
                          value: subject,
                          decoration: const InputDecoration(labelText: 'المادة *'),
                          items: availableSubjects.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                          onChanged: type == 'group' ? null : (value) { if (value != null) setDialogState(() { subject = value; teacherId = id(teachersForStudent(selectedStudent, subject).first); }); },
                        ),
                        if (supervisors.isNotEmpty)
                          DropdownButtonFormField<int?>(
                            value: supervisorId,
                            decoration: const InputDecoration(labelText: 'المشرف (اختياري)'),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('بدون مشرف')),
                              ...supervisors.map((supervisor) => DropdownMenuItem<int?>(value: id(supervisor), child: Text('${supervisor['name']}'))),
                            ],
                            onChanged: (value) => setDialogState(() => supervisorId = value),
                          ),
                        TextFormField(
                          controller: rate,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'سعر الحصة للمدرس *'),
                          validator: (value) => double.tryParse(value ?? '') == null ? 'أدخل سعرًا صحيحًا' : null,
                        ),
                        TextFormField(controller: starts, decoration: const InputDecoration(labelText: 'البداية - YYYY-MM-DD HH:MM'), validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null),
                        TextFormField(controller: ends, decoration: const InputDecoration(labelText: 'النهاية - YYYY-MM-DD HH:MM'), validator: (value) => value == null || value.trim().isEmpty ? 'مطلوب' : null),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
                FilledButton.icon(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الحصة'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await ApiService.post('lessons', {
          'type': type,
          'teacher_id': teacherId,
          'supervisor_id': supervisorId,
          'group_id': type == 'group' ? id(selectedGroup) : null,
          'student_id': type == 'private' ? id(selectedStudent) : null,
          'subject': subject,
          'starts_at': starts.text.trim(),
          'ends_at': ends.text.trim(),
          'teacher_rate': double.parse(rate.text),
          'status': 'scheduled',
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    rate.dispose();
    starts.dispose();
    ends.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدروس والحصص'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                            Text('طريقة التشغيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            SizedBox(height: 5),
                            Text('الحصة الخاصة: الطالب والمواد أولًا، ثم ربط المدرس بالطالب والمادة من شاشة المدرسين. حصة الجروب: أنشئ المجموعة وحدد طلابها ثم أنشئ الحصة من هنا.'),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: FilledButton.icon(onPressed: () => addLesson('private'), icon: const Icon(Icons.person), label: const Text('حصة خاصة'))),
                          const SizedBox(width: 10),
                          Expanded(child: FilledButton.icon(onPressed: () => addLesson('group'), icon: const Icon(Icons.groups), label: const Text('حصة جروب'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('الحصص المسجلة (${lessons.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 6),
                      if (lessons.isEmpty) const Padding(padding: EdgeInsets.all(25), child: Center(child: Text('لا توجد حصص بعد. استخدم أحد الزرين بالأعلى.'))),
                      ...lessons.map((lesson) {
                        final teacher = lesson['teacher'];
                        final student = lesson['student'];
                        final group = lesson['group'];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(lesson['type'] == 'group' ? Icons.groups : Icons.person)),
                            title: Text('${lesson['subject'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${lesson['type'] == 'group' ? 'جروب' : 'خاصة'} • المدرس: ${teacher?['name'] ?? ''}\n${lesson['type'] == 'group' ? 'المجموعة: ${group?['name'] ?? ''}' : 'الطالب: ${student?['name'] ?? ''}'}\n${lesson['starts_at'] ?? ''}'),
                            isThreeLine: true,
                            trailing: Text('${lesson['teacher_due'] ?? 0}'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
