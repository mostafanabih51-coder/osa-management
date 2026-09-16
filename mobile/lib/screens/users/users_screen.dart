import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const permissions = <Map<String, String>>[
    {'key': 'view_students', 'label': 'عرض الطلاب'}, {'key': 'manage_students', 'label': 'إدارة الطلاب'},
    {'key': 'view_teachers', 'label': 'عرض المدرسين'}, {'key': 'manage_teachers', 'label': 'إدارة المدرسين'},
    {'key': 'view_supervisors', 'label': 'عرض المشرفين'}, {'key': 'manage_supervisors', 'label': 'إدارة المشرفين'},
    {'key': 'view_groups', 'label': 'عرض المجموعات'}, {'key': 'manage_groups', 'label': 'إدارة المجموعات'},
    {'key': 'view_schedules', 'label': 'عرض الجداول'}, {'key': 'manage_schedules', 'label': 'إدارة الجداول'},
    {'key': 'view_attendance', 'label': 'عرض الحضور'}, {'key': 'manage_attendance', 'label': 'إدارة الحضور'},
    {'key': 'view_subscriptions', 'label': 'عرض الاشتراكات'}, {'key': 'manage_subscriptions', 'label': 'إدارة الاشتراكات'},
    {'key': 'view_finance', 'label': 'عرض المالية'}, {'key': 'manage_finance', 'label': 'إدارة المالية'},
    {'key': 'view_lessons', 'label': 'عرض الدروس'}, {'key': 'manage_lessons', 'label': 'إدارة الدروس'},
  ];
  static const roles = <String, String>{
    'owner': 'Owner', 'admin': 'Admin', 'technical_admin': 'Technical Admin',
    'supervisor': 'Supervisor', 'teacher': 'Teacher', 'staff': 'Staff',
  };

  List<Map<String, dynamic>> users = [];
  bool loading = true;

  @override
  void initState() { super.initState(); loadUsers(); }

  Future<void> loadUsers() async {
    if (mounted) setState(() => loading = true);
    try {
      final response = await ApiService.get('users');
      final list = response['data'];
      if (mounted) setState(() { users = list is List ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : []; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    }
  }

  String _error(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> addUser() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'technical_admin';
    final selected = <String>{};
    bool obscure = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('إضافة مستخدم'),
        content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person))),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email))),
          TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(onPressed: () => setDialogState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Role'), items: roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) => setDialogState(() { if (v != null) role = v; })),
          const SizedBox(height: 12),
          if (role == 'technical_admin') const Align(alignment: Alignment.centerRight, child: Text('صلاحيات Technical Admin', style: TextStyle(fontWeight: FontWeight.bold))),
          if (role != 'owner' && role != 'admin') ...permissions.map((p) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(p['label']!), value: selected.contains(p['key']), onChanged: (v) => setDialogState(() { if (v == true) selected.add(p['key']!); else selected.remove(p['key']!); }))),
          if (role == 'owner' || role == 'admin') const Padding(padding: EdgeInsets.only(top: 8), child: Text('هذا الدور يمتلك صلاحيات الإدارة الكاملة.')),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 8) { ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('أدخل البيانات كاملة وكلمة مرور 8 أحرف على الأقل'))); return; }
            try {
              await ApiService.post('users', {'name': name.text.trim(), 'email': email.text.trim(), 'password': password.text, 'role': role, 'permissions': selected.toList()});
              if (!mounted) return;
              Navigator.pop(dialogContext); await loadUsers();
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('تم إنشاء المستخدم بنجاح')));
            } catch (e) { if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_error(e)))); }
          }, child: const Text('Save')),
        ],
      )),
    );
    name.dispose(); email.dispose(); password.dispose();
  }

  Future<void> editPermissions(Map<String, dynamic> user) async {
    final initial = user['permissions'] is List ? List<String>.from(user['permissions']) : <String>[];
    final selected = {...initial};
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('صلاحيات ${user['name'] ?? ''}'),
      content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: permissions.map((p) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(p['label']!), value: selected.contains(p['key']), onChanged: (v) => setDialogState(() { if (v == true) selected.add(p['key']!); else selected.remove(p['key']!); }))).toList()))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')), FilledButton(onPressed: () async { try { await ApiService.put('users/${user['id']}/permissions', {'permissions': selected.toList()}); if (!mounted) return; Navigator.pop(dialogContext); await loadUsers(); } catch (e) { if (mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_error(e)))); } }, child: const Text('حفظ'))],
    )));
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('حذف المستخدم'), content: Text('هل تريد حذف ${user['name'] ?? ''}؟'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف'))]));
    if (ok != true) return;
    try { await ApiService.delete('users/${user['id']}'); await loadUsers(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e)))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون والصلاحيات')),
      floatingActionButton: FloatingActionButton.extended(onPressed: addUser, icon: const Icon(Icons.person_add), label: const Text('إضافة مستخدم')),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(onRefresh: loadUsers, child: users.isEmpty ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد مستخدمون'))]) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: users.length, itemBuilder: (context, index) {
        final user = users[index]; final role = '${user['role'] ?? ''}'; final locked = ['admin', 'super_admin', 'owner'].contains(role); final count = user['permissions'] is List ? (user['permissions'] as List).length : 0;
        return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${user['name'] ?? ''}'), subtitle: Text('${user['email'] ?? ''}\nالدور: ${roles[role] ?? role}${locked ? ' — صلاحيات إدارية كاملة' : ' — $count صلاحية'}'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'permissions') editPermissions(user); if (v == 'delete') deleteUser(user); }, itemBuilder: (_) => [const PopupMenuItem(value: 'permissions', child: Text('الصلاحيات')), if (!locked) const PopupMenuItem(value: 'delete', child: Text('حذف'))])));
      })),
    );
  }
}
