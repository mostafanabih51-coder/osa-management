import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
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

  String subjectName(dynamic value) {
    if (value is String) return value;
    if (value is Map) return '${value['subject'] ?? value['name'] ?? ''}';
    return '$value';
  }

  void msg(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await Future.wait([
        ApiService.get('students'),
        ApiService.get('subjects'),
      ]);
      final loaded = list(result[1])
          .map(subjectName)
          .where((x) => x.trim().isNotEmpty)
          .toSet()
          .toList();
      if (!mounted) return;
      setState(() {
        students = list(result[0]);
        subjects = loaded.isEmpty ? fallbackSubjects : loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        subjects = fallbackSubjects;
      });
      msg(e);
    }
  }

  Future<void> add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final parent = TextEditingController();
    final parentPhone = TextEditingController();
    final grade = TextEditingController();
    final curriculum = TextEditingController();
    final selected = <String>{};
    final form = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة طالب'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('أدخل بيانات الطالب، ثم اختر المواد المشترك بها من القائمة.'),
                        const SizedBox(height: 10),
                        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب *'), validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null),
                        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
                        TextFormField(controller: parent, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
                        TextFormField(controller: parentPhone, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
                        TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
                        TextFormField(controller: curriculum, decoration: const InputDecoration(labelText: 'المنهج')),
                        const SizedBox(height: 14),
                        const Text('المواد المشترك بها *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('اختر مادة أو أكثر بالضغط على المربع.'),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            children: subjects.map((subject) {
                              return CheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: selected.contains(subject),
                                title: Text(subject),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selected.add(subject);
                                    } else {
                                      selected.remove(subject);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        if (selected.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('المختار: ${selected.join('، ')}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
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
                      ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('اختر مادة واحدة على الأقل.')));
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الطالب'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        await ApiService.post('students', {
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'parent_name': parent.text.trim(),
          'parent_phone': parentPhone.text.trim(),
          'grade': grade.text.trim(),
          'curriculum': curriculum.text.trim(),
          'status': 'active',
          'subjects': selected.toList(),
        });
        await load();
      } catch (e) {
        msg(e);
      }
    }
    name.dispose();
    phone.dispose();
    parent.dispose();
    parentPhone.dispose();
    grade.dispose();
    curriculum.dispose();
  }

  Future<void> details(int studentId) async {
    try {
      final response = await ApiService.get('students/$studentId');
      final data = Map<String, dynamic>.from(response is Map && response['data'] is Map ? response['data'] : response);
      if (!mounted) return;
      final sections = <String, List<dynamic>>{
        'المواد': list(data['subjects']),
        'المدرسون': list(data['teachers']),
        'المجموعات': list(data['groups']),
        'الحصص': list(data['lessons']),
        'الاشتراكات': list(data['subscriptions']),
        'المدفوعات': list(data['payments']),
      };
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${data['name'] ?? 'الطالب'}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (entry.value.isEmpty) const Text('لا يوجد', style: TextStyle(color: Colors.grey)),
                        ...entry.value.map((item) {
                          if (item is Map) {
                            return Text('• ${item['name'] ?? item['subject'] ?? item['amount'] ?? ''}');
                          }
                          return Text('• $item');
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
        ),
      );
    } catch (e) {
      msg(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: add, backgroundColor: AppColors.red, icon: const Icon(Icons.person_add), label: const Text('إضافة طالب')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: students.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد طلاب بعد. اضغط «إضافة طالب» للبدء.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: students.length,
                      itemBuilder: (_, index) {
                        final student = students[index];
                        return Card(
                          child: ListTile(
                            onTap: () => details(id(student)),
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text('${student['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${student['phone'] ?? ''}'),
                            trailing: const Icon(Icons.chevron_left),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
