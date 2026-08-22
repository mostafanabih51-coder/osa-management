import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/group_model.dart';
import '../../providers/groups_provider.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GroupsProvider(context.read())..load(),
      child: const _GroupsView(),
    );
  }
}

class _GroupsView extends StatefulWidget {
  const _GroupsView();

  @override
  State<_GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<_GroupsView> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GroupsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات والفصول'),
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
        label: const Text('إضافة مجموعة'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: search,
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                setState(() {});
              },
              onSubmitted: (_) {
                state.load(query: search.text);
              },
              decoration: InputDecoration(
                hintText: 'ابحث باسم المجموعة أو المدرس',
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
              onRefresh: () => state.load(
                query: search.text,
              ),
              child: _buildBody(
                context,
                state,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroupsProvider state,
  ) {
    if (state.loading && state.groups.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.groups.isEmpty) {
      return _Error(
        state.error!,
        () => state.load(
          query: search.text,
        ),
      );
    }

    if (state.groups.isEmpty) {
      return const _Empty();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        100,
      ),
      itemCount: state.groups.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(
        height: 8,
      ),
      itemBuilder: (context, index) {
        if (index == state.groups.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final group = state.groups[index];

        return _Card(
          group: group,
          onEdit: () => _form(
            context,
            group: group,
          ),
          onDelete: () => _delete(
            context,
            group,
          ),
        );
      },
    );
  }

  Future<void> _form(
    BuildContext context, {
    GroupModel? group,
  }) async {
    final name = TextEditingController(
      text: group?.name ?? '',
    );
    final course = TextEditingController(
      text: group?.course ?? '',
    );
    final teacher = TextEditingController(
      text: group?.teacher ?? '',
    );
    final schedule = TextEditingController(
      text: group?.schedule ?? '',
    );

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    group == null
                        ? 'إضافة مجموعة'
                        : 'تعديل المجموعة',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _field(
                    name,
                    'اسم المجموعة',
                    Icons.groups_outlined,
                    true,
                  ),
                  _field(
                    course,
                    'الكورس',
                    Icons.menu_book_outlined,
                    false,
                  ),
                  _field(
                    teacher,
                    'المدرس',
                    Icons.person_outline,
                    false,
                  ),
                  _field(
                    schedule,
                    'المواعيد',
                    Icons.schedule_outlined,
                    false,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final ok = await context
                          .read<GroupsProvider>()
                          .save(
                            id: group?.id,
                            data: {
                              'name': name.text.trim(),
                              'course_name': course.text.trim(),
                              'teacher_name': teacher.text.trim(),
                              'schedule': schedule.text.trim(),
                            },
                          );

                      if (ok && sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    icon: const Icon(
                      Icons.save_outlined,
                    ),
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
    course.dispose();
    teacher.dispose();
    schedule.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: required
            ? (value) {
                if (value == null ||
                    value.trim().isEmpty) {
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
    GroupModel group,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف المجموعة'),
          content: Text(
            'هل تريد حذف ${group.name}؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (yes == true && context.mounted) {
      final ok = await context
          .read<GroupsProvider>()
          .remove(group.id);

      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<GroupsProvider>().error ??
                  'تعذر الحذف',
            ),
          ),
        );
      }
    }
  }
}

class _Card extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Card({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      group.course,
      group.teacher,
      group.schedule,
      if (group.studentsCount > 0)
        '${group.studentsCount} طالب',
    ].where((value) => value.isNotEmpty).join(' • ');

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
            Icons.groups,
            color: AppTheme.primary,
          ),
        ),
        title: Text(
          group.name.isEmpty
              ? 'بدون اسم'
              : group.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 5,
          ),
          child: Text(
            details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else {
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
          Icons.groups_outlined,
          size: 60,
          color: Colors.grey,
        ),
        SizedBox(height: 12),
        Center(
          child: Text('لا توجد مجموعات'),
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
