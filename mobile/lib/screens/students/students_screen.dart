import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    try {
      final data = await ApiService.get('students');
      if (!mounted) return;
      setState(() {
        students = data['data'] ?? data['students'] ?? [];
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addStudent() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final parentName = TextEditingController();
    final parentPhone = TextEditingController();
    final grade = TextEditingController();
    final curriculum = TextEditingController();
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('إضافة طالب'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'اسم الطالب *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم الطالب' : null,
                      ),
                      TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'هاتف الطالب')),
                      TextFormField(controller: parentName, decoration: const InputDecoration(labelText: 'اسم ولي الأمر')),
                      TextFormField(controller: parentPhone, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
                      TextFormField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')),
                      TextFormField(controller: curriculum, decoration: const InputDecoration(labelText: 'المنهج')),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await ApiService.post('students', {
                            'name': name.text.trim(),
                            'phone': _nullable(phone.text),
                            'parent_name': _nullable(parentName.text),
                            'parent_phone': _nullable(parentPhone.text),
                            'grade': _nullable(grade.text),
                            'curriculum': _nullable(curriculum.text),
                            'status': 'active',
                          });
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          await loadStudents();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الطالب بنجاح')));
                        } on ApiException catch (e) {
                          setDialogState(() => saving = false);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        } catch (_) {
                          setDialogState(() => saving = false);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الطالب')));
                        }
                      },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('حفظ'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      phone.dispose();
      parentName.dispose();
      parentPhone.dispose();
      grade.dispose();
      curriculum.dispose();
    }
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        onPressed: addStudent,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadStudents,
                  child: ListView(children: const [SizedBox(height: 260), Center(child: Text('لا يوجد طلاب حاليًا', style: TextStyle(fontSize: 18)))]),
                )
              : RefreshIndicator(
                  onRefresh: loadStudents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (_, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: AppColors.red, child: Text('${index + 1}', style: const TextStyle(color: Colors.white))),
                          title: Text('${student['name'] ?? 'بدون اسم'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${student['phone'] ?? student['email'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_left),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
