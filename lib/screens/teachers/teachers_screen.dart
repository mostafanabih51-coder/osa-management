import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/teacher_model.dart';
import '../../providers/teachers_provider.dart';

class TeachersScreen extends StatelessWidget {
  const TeachersScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => TeachersProvider(context.read())..load(),
        child: const _TeachersView(),
      );
}

class _TeachersView extends StatefulWidget {
  const _TeachersView();

  @override
  State<_TeachersView> createState() => _TeachersViewState();
}

class _TeachersViewState extends State<_TeachersView> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeachersProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المدرسون'),
        actions: [
          IconButton(
            onPressed: state.loading
                ? null
                : () => state.load(query: search.text),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة مدرس'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => state.load(query: search.text),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد أو الهاتف',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          search.clear();
                          state.load();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => state.load(query: search.text),
              child: state.loading && state.teachers.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : state.error != null && state.teachers.isEmpty
                      ? _Error(
                          message: state.error!,
                          retry: () => state.load(query: search.text),
                        )
                      : state.teachers.isEmpty
                          ? const _Empty()
                          : NotificationListener<ScrollNotification>(
                              onNotification: (n) {
                                if (n.metrics.pixels >=
                                        n.metrics.maxScrollExtent - 300 &&
                                    state.hasMore &&
                                    !state.loading) {
                                  state.page++;
                                  state.load(
                                    query: search.text,
                                    append: true,
                                  );
                                }
                                return false;
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  100,
                                ),
                                itemCount: state.teachers.length +
                                    (state.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  if (i == state.teachers.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final teacher = state.teachers[i];

                                  return _TeacherCard(
                                    teacher: teacher,
                                    onEdit: () => _openForm(
                                      context,
                                      teacher: teacher,
                                    ),
                                    onDelete: () => _confirmDelete(
                                      context,
                                      teacher,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    TeacherModel? teacher,
  }) async {
    final name = TextEditingController(
      text: teacher?.name ?? '',
    );
    final email = TextEditingController(
      text: teacher?.email ?? '',
    );
    final phone = TextEditingController(
      text: teacher?.phone ?? '',
    );
    final spec = TextEditingController(
      text: teacher?.specialization ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(sheet).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  teacher == null
                      ? 'إضافة مدرس'
                      : 'تعديل بيانات المدرس',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _field(
                  name,
                  'اسم المدرس',
                  Icons.person_outline,
                  required: true,
                ),
                _field(
                  email,
                  'البريد الإلكتروني',
                  Icons.email_outlined,
                ),
                _field(
                  phone,
                  'رقم الهاتف',
                  Icons.phone_outlined,
                ),
                _field(
                  spec,
                  'التخصص / المادة',
                  Icons.menu_book_outlined,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final ok = await context
                        .read<TeachersProvider>()
                        .save(
                      id: teacher?.id,
                      data: {
                        'name': name.text.trim(),
                        'email': email.text.trim(),
                        'phone': phone.text.trim(),
                        'specialization': spec.text.trim(),
                      },
                    );

                    if (ok && sheet.mounted) {
                      Navigator.pop(sheet);
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    name.dispose();
    email.dispose();
    phone.dispose();
    spec.dispose();
  }

  InputDecoration _dec(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: _dec(label, icon),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'هذا الحقل مطلوب'
                : null
            : null,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeacherModel teacher,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('حذف المدرس'),
        content: Text('هل تريد حذف ${teacher.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (yes == true && context.mounted) {
      final ok = await context
          .read<TeachersProvider>()
          .remove(teacher.id);

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<TeachersProvider>().error ??
                  'تعذر الحذف',
            ),
          ),
        );
      }
    }
  }
}

class _TeacherCard extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            teacher.name.isNotEmpty
                ? teacher.name.characters.first
                : '?',
          ),
        ),
        title: Text(
          teacher.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          teacher.specialization?.isNotEmpty == true
              ? teacher.specialization!
              : teacher.email ?? '',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('تعديل'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback retry;

  const _Error({
    required this.message,
    required this.retry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا يوجد مدرسون حاليًا',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
