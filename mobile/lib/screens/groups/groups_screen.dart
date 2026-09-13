import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> groups = [];
  List<dynamic> students = [];
  List<dynamic> teachers = [];
  List<dynamic> supervisors = [];
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
        ApiService.get('groups'),
        ApiService.get('students'),
        ApiService.get('teachers'),
        ApiService.get('subjects'),
        ApiService.get('supervisors'),
      ]);
      final loadedSubjects = list(result[3]).map(subjectName).where((x) => x.trim().isNotEmpty).toSet().toList();
      if (!mounted) return;
      setState(() {
        groups = list(result[0]);
        students = list(result[1]);
        teachers = list(result[2]);
        supervisors = list(result[4]);
        subjects = loadedSubjects.isEmpty ? fallbackSubjects : loadedSubjects;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; subjects = fallbackSubjects; });
      msg(e);
    }
  }

  Future<void> add() async {
    if (teachers.isEmpty) {
      msg(Exception('أضف مدرسًا أولًا من شاشة المدرسين.'));
      return;
    }
    if (students.isEmpty) {
      msg(Exception('أضف طلابًا أولًا من شاشة الطلاب.'));
      return;
    }

    int teacherId = id(teachers.first);
    String subject = subjects.first;
    int? supervisorId;
    final name = TextEditingController();
    final rate = TextEditingController();
    final grade = TextEditingController();
    final selected = <int>{};
    final form = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إنشاء مجموعة'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('المجموعة هي الأساس لحصة الجروب. اختر المدرس والمادة والطلاب وسعر الحصة.'),
                        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المجموعة *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                        TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
                        DropdownButtonFormField<int>(
                          value: teacherId,
                          decoration: const InputDecoration(labelText: 'المدرس *'),
                          items: teachers.map((teacher) => DropdownMenuItem<int>(value: id(teacher), child: Text('${teacher['name']}'))).toList(),
                          onChanged: (value) { if (value != null) setDialogState(() => teacherId = value); },
                        ),
                        DropdownButtonFormField<String>(
                          value: subject,
                          decoration: const InputDecoration(labelText: 'المادة *'),
                          items: subjects.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                          onChanged: (value) { if (value != null) setDialogState(() => subject = value); },
                        ),
                        TextFormField(
                          controller: rate,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'سعر الحصة للمدرس *'),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'أدخل سعرًا صحيحًا' : null,
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
                        const SizedBox(height: 10),
                        const Text('طلاب المجموعة *', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: students.map((student) {
                              final studentId = id(student);
                              return CheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: selected.contains(studentId),
                                title: Text('${student['name']}'),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) selected.add(studentId); else selected.remove(studentId);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        if (selected.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('تم اختيار ${selected.length} طالب/طلاب')),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
                FilledButton.icon(
                  onPressed: () {
                    if (form.currentState!.validate() && selected.isNotEmpty) {
                      Navigator.pop(dialogContext, true);
                    } else if (selected.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('اختر طالبًا واحدًا على الأقل.')));
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المجموعة'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await ApiService.post('groups', {
          'name': name.text.trim(),
          'grade': grade.text.trim(),
          'subject': subject,
          'teacher_id': teacherId,
          'supervisor_id': supervisorId,
          'teacher_rate': double.parse(rate.text),
          'student_ids': selected.toList(),
          'status': 'active',
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    name.dispose();
    rate.dispose();
    grade.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجموعات'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: add, icon: const Icon(Icons.groups), label: const Text('إنشاء مجموعة')),
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                        Text('طريقة العمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        SizedBox(height: 4),
                        Text('1) أضف الطلاب والمدرس.  2) أنشئ المجموعة وحدد الطلاب.  3) افتح الدروس والحصص واختر «حصة جروب».  4) ستستخدم الحصة نفس مدرس ومادة المجموعة.'),
                      ]),
                    ),
                  ),
                  if (groups.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا توجد مجموعات بعد. اضغط «إنشاء مجموعة».'))),
                  ...groups.map((group) {
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.groups)),
                        title: Text('${group['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('المدرس: ${group['teacher']?['name'] ?? ''}\nالمادة: ${group['subject'] ?? ''} • الطلاب: ${group['students_count'] ?? 0} • سعر الحصة: ${group['teacher_rate'] ?? 0}'),
                        isThreeLine: true,
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
