import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class RolePortalScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const RolePortalScreen({super.key, required this.user});
  @override
  State<RolePortalScreen> createState() => _RolePortalScreenState();
}

class _RolePortalScreenState extends State<RolePortalScreen> {
  Map<String, dynamic> portal = {};
  bool loading = true;
  String error = '';

  List<dynamic> list(dynamic value) => value is List ? List<dynamic>.from(value) : [];

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final response = await ApiService.get('user');
      final value = response['portal'];
      if (value is Map) portal = Map<String, dynamic>.from(value);
      if (portal.isEmpty) error = 'لا يوجد ملف تشغيلي مرتبط بهذا الحساب. أنشئ الحساب من Users & Permissions أو اربطه بملف المدرس/المشرف.';
    } catch (e) { error = '$e'; }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final role = '${widget.user['role'] ?? portal['type'] ?? ''}';
    final isTeacher = role == 'teacher' || portal['type'] == 'teacher';
    final profile = portal['profile'] is Map ? portal['profile'] as Map : <dynamic,dynamic>{};
    final students = list(portal['students']);
    final lessons = list(portal['lessons']);
    final dues = list(portal['dues']);
    return Scaffold(
      appBar: AppBar(title: Text(isTeacher ? 'حساب المدرس' : 'حساب المشرف'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${profile['name'] ?? widget.user['name'] ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6), Text(isTeacher ? 'مدرس' : 'مشرف', style: const TextStyle(color: AppColors.red)),
            if ('${profile['specialization'] ?? ''}'.isNotEmpty) Text('التخصص: ${profile['specialization']}'),
            Text('${widget.user['email'] ?? profile['email'] ?? ''}'),
          ]))),
          if (error.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(error))),
          _section('الطلاب المرتبطون (${students.length})', Icons.people, students.map((s) => ListTile(leading: const Icon(Icons.person), title: Text('${s['name'] ?? ''}'), subtitle: Text('${s['grade'] ?? ''} ${s['phone'] ?? ''}'))).toList()),
          _section('الحصص (${lessons.length})', Icons.school, lessons.map((l) => ListTile(leading: const Icon(Icons.event), title: Text('${l['subject'] ?? 'حصة'}'), subtitle: Text('${l['starts_at'] ?? l['date'] ?? ''} • ${l['student'] is Map ? l['student']['name'] ?? '' : l['group'] is Map ? l['group']['name'] ?? '' : ''}'))).toList()),
          _section('المستحقات (${dues.length})', Icons.account_balance_wallet, dues.map((d) => ListTile(leading: const Icon(Icons.payments_outlined), title: Text('المبلغ: ${d['amount'] ?? 0}'), subtitle: Text('المدفوع: ${d['paid_amount'] ?? 0}'))).toList()),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Card(margin: const EdgeInsets.only(top: 12), child: ExpansionTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), initiallyExpanded: true, children: children.isEmpty ? [const ListTile(title: Text('لا توجد بيانات حاليًا'))] : children));
}
