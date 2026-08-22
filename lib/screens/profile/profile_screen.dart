import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
        const CircleAvatar(radius: 42, backgroundColor: AppColors.red, child: Icon(Icons.person, size: 45, color: Colors.white)),
        const SizedBox(height: 14),
        Text(user?.name ?? 'مستخدم OSA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
      ]))),
      const SizedBox(height: 14),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.person_outline), title: const Text('الاسم'), subtitle: Text(user?.name ?? '—')),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.email_outlined), title: const Text('البريد الإلكتروني'), subtitle: Text(user?.email ?? '—')),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('الصلاحية'), subtitle: Text(user?.role ?? '—')),
      ])),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => context.read<AuthProvider>().logout(), icon: const Icon(Icons.logout), label: const Text('تسجيل الخروج'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, minimumSize: const Size.fromHeight(52))),
    ]);
  }
}
