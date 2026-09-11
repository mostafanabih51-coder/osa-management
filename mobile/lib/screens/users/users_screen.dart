import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const permissions = <Map<String, String>>[
    {'key': 'view_students', 'label': 'عرض الطلاب'},
    {'key': 'manage_students', 'label': 'إدارة الطلاب'},
    {'key': 'view_teachers', 'label': 'عرض المدرسين'},
    {'key': 'manage_teachers', 'label': 'إدارة المدرسين'},
    {'key': 'view_supervisors', 'label': 'عرض المشرفين'},
    {'key': 'manage_supervisors', 'label': 'إدارة المشرفين'},
    {'key': 'view_groups', 'label': 'عرض المجموعات'},
    {'key': 'manage_groups', 'label': 'إدارة المجموعات'},
    {'key': 'view_schedules', 'label': 'عرض الجداول'},
    {'key': 'manage_schedules', 'label': 'إدارة الجداول'},
    {'key': 'view_attendance', 'label': 'عرض الحضور'},
    {'key': 'manage_attendance', 'label': 'إدارة الحضور'},
    {'key': 'view_subscriptions', 'label': 'عرض الاشتراكات'},
    {'key': 'manage_subscriptions', 'label': 'إدارة الاشتراكات'},
    {'key': 'view_finance', 'label': 'عرض المالية'},
    {'key': 'manage_finance', 'label': 'إدارة المالية'},
    {'key': 'view_lessons', 'label': 'عرض الدروس'},
    {'key': 'manage_lessons', 'label': 'إدارة الدروس'},
  ];

  List<Map<String, dynamic>> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.get('users');
      final list = response['data'];
      if (mounted) {
        setState(() {
          users = list is List ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> editPermissions(Map<String, dynamic> user) async {
    final initial = (user['permissions'] is List) ? List<String>.from(user['permissions']) : <String>[];
    final selected = {...initial};

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('صلاحيات ${user['name'] ?? ''}'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: permissions.map((permission) {
                  final key = permission['key']!;
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(permission['label']!),
                    value: selected.contains(key),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(key);
                      } else {
                        selected.remove(key);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                try {
                  await ApiService.put('users/${user['id']}/permissions', {'permissions': selected.toList()});
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  await loadUsers();
                  if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('تم تحديث الصلاحيات بنجاح')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون والصلاحيات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadUsers,
              child: users.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد مستخدمون'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final role = '${user['role'] ?? ''}';
                        final locked = ['admin', 'super_admin', 'owner'].contains(role);
                        final count = user['permissions'] is List ? (user['permissions'] as List).length : 0;
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text('${user['name'] ?? ''}'),
                            subtitle: Text('${user['email'] ?? ''}\nالدور: $role${locked ? ' — صلاحيات إدارية كاملة' : ' — $count صلاحية'}'),
                            isThreeLine: true,
                            trailing: locked ? const Icon(Icons.lock) : const Icon(Icons.tune),
                            onTap: locked ? null : () => editPermissions(user),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
