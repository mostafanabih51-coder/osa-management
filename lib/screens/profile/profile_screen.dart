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

    final name = _displayValue(
      user?.name,
      'مستخدم OSA',
    );

    final email = _displayValue(
      user?.email,
      '—',
    );

    final role = _displayValue(
      user?.role,
      '—',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        children: [
          _ProfileHeader(
            name: name,
            email: email,
            role: role,
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'بيانات الحساب',
            children: [
              _InfoTile(
                icon: Icons.person_outline,
                title: 'الاسم',
                value: name,
              ),
              const _TileDivider(),
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'البريد الإلكتروني',
                value: email,
              ),
              const _TileDivider(),
              _InfoTile(
                icon: Icons.badge_outlined,
                title: 'الصلاحية',
                value: role,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'الحساب',
            children: [
              ListTile(
                leading: _IconBox(
                  icon: Icons.logout_rounded,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'الخروج من حساب OSA الحالي',
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                Text(
                  'OSA Management',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نظام إدارة Online School Academy',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _displayValue(
    String? value,
    String fallback,
  ) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  Future<void> _confirmLogout(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
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
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );

    if (result != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(
                  alpha: 0.09,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 17,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              10,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 3,
      ),
      leading: _IconBox(
        icon: icon,
        color: AppTheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 74,
      endIndent: 16,
    );
  }
}
