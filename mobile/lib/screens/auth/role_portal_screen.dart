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

  List<dynamic> list(dynamic value) =>
      value is List ? List<dynamic>.from(value) : [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = ''; });
    try {
      final response = await ApiService.get('user');
      final value = response is Map && response['portal'] is Map
          ? response['portal']
          : response is Map && response['data'] is Map && response['data']['portal'] is Map
              ? response['data']['portal']
              : null;
      if (value is Map) portal = Map<String, dynamic>.from(value);
      if (portal.isEmpty) {
        error = 'لا يوجد ملف تشغيلي مرتبط بهذا الحساب. أنشئ الحساب من المستخدمين والصلاحيات أو اربطه بملف المدرس/المشرف.';
      }
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => loading = false);
  }

  Widget _metric(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 11),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(top: 14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.magenta.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold, size: 21),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        initiallyExpanded: true,
        children: children.isEmpty
            ? [const ListTile(title: Text('لا توجد بيانات مسجلة حاليًا', style: TextStyle(color: AppColors.muted)))]
            : children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = '${widget.user['role'] ?? portal['type'] ?? ''}';
    final isTeacher = role == 'teacher' || portal['type'] == 'teacher';
    final profile = portal['profile'] is Map
        ? portal['profile'] as Map
        : <dynamic, dynamic>{};
    final students = list(portal['students']);
    final lessons = list(portal['lessons']);
    final dues = list(portal['dues']);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'حساب المدرس' : 'حساب المشرف'),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              color: AppColors.gold,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppColors.magenta, AppColors.surfaceDeep],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                              ),
                              child: Icon(
                                isTeacher ? Icons.school_rounded : Icons.supervisor_account_rounded,
                                color: Colors.white,
                                size: 29,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.verified_user_outlined, color: AppColors.gold, size: 22),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${profile['name'] ?? widget.user['name'] ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isTeacher ? 'بوابة المدرس' : 'بوابة المشرف',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                        ),
                        if ('${profile['specialization'] ?? ''}'.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'التخصص: ${profile['specialization']}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${widget.user['email'] ?? profile['email'] ?? ''}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (error.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.gold),
                            const SizedBox(width: 10),
                            Expanded(child: Text(error, style: const TextStyle(height: 1.45))),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _metric('الطلاب', '${students.length}', Icons.people_alt_rounded, AppColors.gold),
                      const SizedBox(width: 9),
                      _metric('الحصص', '${lessons.length}', Icons.event_available_rounded, AppColors.magenta),
                      const SizedBox(width: 9),
                      _metric('المستحقات', '${dues.length}', Icons.account_balance_wallet_rounded, AppColors.yellow),
                    ],
                  ),
                  _section(
                    'الطلاب المرتبطون (${students.length})',
                    Icons.people_alt_rounded,
                    students.map((s) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceDeep,
                        child: Icon(Icons.person_outline_rounded, color: AppColors.gold),
                      ),
                      title: Text('${s['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        ['${s['grade'] ?? ''}', '${s['phone'] ?? ''}']
                            .where((v) => v.trim().isNotEmpty)
                            .join(' • '),
                      ),
                    )).toList(),
                  ),
                  _section(
                    'الحصص (${lessons.length})',
                    Icons.event_available_rounded,
                    lessons.map((l) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceDeep,
                        child: Icon(Icons.menu_book_rounded, color: AppColors.gold),
                      ),
                      title: Text('${l['subject'] ?? 'حصة'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${l['starts_at'] ?? l['date'] ?? ''} • ${l['student'] is Map ? l['student']['name'] ?? '' : l['group'] is Map ? l['group']['name'] ?? '' : ''}',
                      ),
                    )).toList(),
                  ),
                  _section(
                    'المستحقات (${dues.length})',
                    Icons.account_balance_wallet_rounded,
                    dues.map((d) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceDeep,
                        child: Icon(Icons.payments_outlined, color: AppColors.gold),
                      ),
                      title: Text('المبلغ: ${d['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('المدفوع: ${d['paid_amount'] ?? 0}'),
                    )).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}
