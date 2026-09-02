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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدرسون')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : teachers.isEmpty
              ? const Center(child: Text('لا يوجد مدرسون حاليًا'))
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${teacher['phone'] ?? teacher['email'] ?? ''}',
                          ),
                          trailing: const Icon(Icons.chevron_left),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
