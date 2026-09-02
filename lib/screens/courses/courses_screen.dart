import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../providers/courses_provider.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CoursesProvider(context.read())..load(),
      child: const _CoursesView(),
    );
  }
}

class _CoursesView extends StatefulWidget {
  const _CoursesView();

  @override
  State<_CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<_CoursesView> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoursesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الكورسات والمواد'),
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
        onPressed: () => _form(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة كورس'),
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
                hintText: 'ابحث باسم الكورس أو المادة',
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
              child: state.loading && state.courses.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : state.error != null && state.courses.isEmpty
                      ? _Error(
                          state.error!,
                          () => state.load(query: search.text),
                        )
                      : state.courses.isEmpty
                          ? const _Empty()
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                        notification.metrics.maxScrollExtent -
                                            300 &&
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
                                itemCount: state.courses.length +
                                    (state.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  if (index == state.courses.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final course = state.courses[index];

                                  return _CourseCard(
                                    course: course,
                                    onEdit: () => _form(
                                      context,
                                      course: course,
                                    ),
                                    onDelete: () => _delete(
                                      context,
                                      course,
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

  Future<void> _form(
    BuildContext context, {
    CourseModel? course,
  }) async {
    final name = TextEditingController(
      text: course?.name ?? '',
    );

    final subject = TextEditingController(
      text: course?.subject ?? '',
    );

    final level = TextEditingController(
      text: course?.level ?? '',
    );

    final price = TextEditingController(
      text: course?.price == 0
          ? ''
          : course?.price.toString() ?? '',
    );

    final description = TextEditingController(
      text: course?.description ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) {
        return Padding(
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
                    course == null
                        ? 'إضافة كورس'
                        : 'تعديل الكورس',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _field(
                    name,
                    'اسم الكورس',
                    Icons.menu_book_outlined,
                    true,
                  ),
                  _field(
                    subject,
                    'المادة',
                    Icons.book_outlined,
                    false,
                  ),
                  _field(
                    level,
                    'المرحلة / الصف',
                    Icons.school_outlined,
                    false,
                  ),
                  _field(
                    price,
                    'السعر',
                    Icons.payments_outlined,
                    false,
                  ),
                  _field(
                    description,
                    'الوصف',
                    Icons.notes_outlined,
                    false,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final ok = await context
                          .read<CoursesProvider>()
                          .save(
                        id: course?.id,
                        data: {
                          'name': name.text.trim(),
                          'subject': subject.text.trim(),
                          'level': level.text.trim(),
                          'price':
                              num.tryParse(price.text.trim()) ?? 0,
                          'description':
                              description.text.trim(),
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
        );
      },
    );

    name.dispose();
    subject.dispose();
    level.dispose();
    price.dispose();
    description.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: label == 'السعر'
            ? TextInputType.number
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    CourseModel course,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الكورس'),
          content: Text(
            'هل تريد حذف ${course.name}؟',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (yes == true && context.mounted) {
      final ok = await context
          .read<CoursesProvider>()
          .remove(course.id);

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<CoursesProvider>().error ??
                  'تعذر الحذف',
            ),
          ),
        );
      }
    }
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: const CircleAvatar(
          radius: 26,
          backgroundColor: Color(0xFFFFE8EA),
          child: Icon(
            Icons.menu_book,
            color: AppTheme.primary,
          ),
        ),
        title: Text(
          course.name.isEmpty ? 'بدون اسم' : course.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            [
              course.subject,
              course.level,
              if (course.price > 0)
                '${course.price} جنيه',
            ].where((value) => value.isNotEmpty).join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.menu_book_outlined,
          size: 60,
          color: Colors.grey,
        ),
        SizedBox(height: 12),
        Center(
          child: Text('لا توجد كورسات'),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback retry;

  const _Error(
    this.message,
    this.retry,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.cloud_off_outlined,
          size: 52,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(message),
        ),
        TextButton(
          onPressed: retry,
          child: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}
