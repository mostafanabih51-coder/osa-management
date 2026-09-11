import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List teachers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTeachers();
  }

  Future<void> loadTeachers() async {
    try {
      final result = await ApiService.get('teachers');
      if (!mounted) return;
      setState(() {
        teachers = result['data'] ?? result['teachers'] ?? [];
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> addTeacher() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final specialization = TextEditingController();
    final hourlyRate = TextEditingController();
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('إضافة مدرس'),
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
                        decoration: const InputDecoration(labelText: 'اسم المدرس *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم المدرس' : null,
                      ),
                      TextFormField(
                        controller: phone,
                        decoration: const InputDecoration(labelText: 'الهاتف'),
                      ),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                              ? null
                              : 'البريد الإلكتروني غير صحيح';
                        },
                      ),
                      TextFormField(
                        controller: specialization,
                        decoration: const InputDecoration(labelText: 'التخصص'),
                      ),
                      TextFormField(
                        controller: hourlyRate,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'الأجر بالساعة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await ApiService.post('teachers', {
                            'name': name.text.trim(),
                            'phone': _nullable(phone.text),
                            'email': _nullable(email.text),
                            'specialization': _nullable(specialization.text),
                            'hourly_rate': hourlyRate.text.trim().isEmpty
                                ? null
                                : double.tryParse(hourlyRate.text.trim()),
                            'status': 'active',
                          });
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          await loadTeachers();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تمت إضافة المدرس بنجاح')),
                            );
                          }
                        } on ApiException catch (e) {
                          setDialogState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        } catch (_) {
                          setDialogState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تعذر حفظ المدرس')),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ'),
              ),
            ],
          ),
        ),
      );
    } finally {
      name.dispose();
      phone.dispose();
      email.dispose();
      specialization.dispose();
      hourlyRate.dispose();
    }
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        onPressed: addTeacher,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : teachers.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadTeachers,
                  child: ListView(
                    children: const [
                      SizedBox(height: 260),
                      Center(child: Text('لا يوجد مدرسون حاليًا')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadTeachers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: teachers.length,
                    itemBuilder: (_, index) {
                      final teacher = teachers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.black,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${teacher['name'] ?? 'بدون اسم'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${teacher['phone'] ?? teacher['email'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_left),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
