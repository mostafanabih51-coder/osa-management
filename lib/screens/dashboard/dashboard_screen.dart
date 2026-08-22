import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/permissions.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

import '../attendance/attendance_screen.dart';
import '../courses/courses_screen.dart';
import '../groups/groups_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../students/students_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../teachers/teachers_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardProvider(
        context.read(),
      )..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const _QuickTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('OSA Management'),
        actions: [
          if (index == 0)
            IconButton(
              tooltip: 'تحديث',
              onPressed: () {
                context.read<DashboardProvider>().load();
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
          IconButton(
            tooltip: 'حسابي',
            onPressed: () {
              setState(() => index = 2);
            },
            icon: const Icon(
              Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.apps_outlined,
            ),
            selectedIcon: Icon(
              Icons.apps,
            ),
            label: 'الإدارة',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () {
        return context.read<DashboardProvider>().load();
      },
      child: Consumer<DashboardProvider>(
        builder: (context, state, _) {
          final data = state.data;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            children: [
              _Welcome(
                userName: auth.user?.name ?? 'مدير النظام',
              ),
              const SizedBox(height: 18),
              if (state.error != null)
                _ErrorBanner(
                  message: state.error!,
                  onRetry: state.load,
                ),
              if (state.loading &&
                  data.students == 0 &&
                  data.teachers == 0 &&
                  data.todayClasses == 0 &&
                  data.todayAttendance == 0 &&
                  data.monthlyIncome == 0 &&
                  data.monthlyExpenses == 0 &&
                  data.expiring7Days == 0)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              _SectionTitle(
                title: 'ملخص اليوم',
                action: state.loading
                    ? null
                    : const Icon(
                        Icons.today_outlined,
                        size: 20,
                      ),
              ),
              const SizedBox(height: 10),
              _StatsGrid(
                data: data,
              ),
              const SizedBox(height: 22),
              _FinancialSummary(
                data: data,
              ),
              const SizedBox(height: 22),
              _ExpiringSubscriptions(
                count: data.expiring7Days,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionsScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final String userName;

  const _Welcome({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primary,
            Color(0xFF8D0D18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.16,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحبًا بك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'إليك ملخص نظام الإدارة اليوم',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionTitle({
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardModel data;

  const _StatsGrid({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          title: 'الطلاب',
          value: data.students.toString(),
          subtitle: '${data.activeStudents} نشط',
          icon: Icons.groups_rounded,
        ),
        _StatCard(
          title: 'المدرسون',
          value: data.teachers.toString(),
          subtitle: 'مدرس نشط',
          icon: Icons.person_rounded,
        ),
        _StatCard(
          title: 'حصص اليوم',
          value: data.todayClasses.toString(),
          subtitle: 'حصة مجدولة',
          icon: Icons.calendar_month_rounded,
        ),
        _StatCard(
          title: 'حضور اليوم',
          value: data.todayAttendance.toString(),
          subtitle: 'سجل حضور',
          icon: Icons.fact_check_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primary,
                    size: 21,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  final DashboardModel data;

  const _FinancialSummary({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final net = data.monthlyNet;
    final isPositive = net >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الشهر المالي',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MoneyItem(
                    title: 'الإيرادات',
                    value: data.monthlyIncome,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                Expanded(
                  child: _MoneyItem(
                    title: 'المصروفات',
                    value: data.monthlyExpenses,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 21,
                ),
                const SizedBox(width: 8),
                const Text(
                  'صافي الشهر',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${net.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isPositive
                        ? Colors.green.shade700
                        : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyItem extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;

  const _MoneyItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${value.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpiringSubscriptions extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ExpiringSubscriptions({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasWarnings = count > 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasWarnings
                      ? Colors.orange.withValues(
                          alpha: 0.12,
                        )
                      : Colors.green.withValues(
                          alpha: 0.10,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasWarnings
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: hasWarnings
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الاشتراكات القريبة من الانتهاء',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasWarnings
                          ? '$count اشتراك ينتهي خلال 7 أيام'
                          : 'لا توجد اشتراكات تنتهي خلال 7 أيام',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3F3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  const _QuickTab();

  @override
  Widget build(BuildContext context) {
    final permissions = AppPermissions(
      context.read<AuthProvider>().user,
    );

    final items = <_QuickItem>[
      _QuickItem(
        'students',
        'الطلاب',
        Icons.groups_rounded,
        () => _open(
          context,
          const StudentsScreen(),
        ),
      ),
      _QuickItem(
        'teachers',
        'المدرسون',
        Icons.person_rounded,
        () => _open(
          context,
          const TeachersScreen(),
        ),
      ),
      _QuickItem(
        'courses',
        'الكورسات',
        Icons.menu_book_rounded,
        () => _open(
          context,
          const CoursesScreen(),
        ),
      ),
      _QuickItem(
        'groups',
        'المجموعات',
        Icons.groups_rounded,
        () => _open(
          context,
          const GroupsScreen(),
        ),
      ),
      _QuickItem(
        'subscriptions',
        'الاشتراكات',
        Icons.card_membership_rounded,
        () => _open(
          context,
          const SubscriptionsScreen(),
        ),
      ),
      _QuickItem(
        'attendance',
        'الحضور',
        Icons.fact_check_rounded,
        () => _open(
          context,
          const AttendanceScreen(),
        ),
      ),
      _QuickItem(
        'reports',
        'التقارير',
        Icons.analytics_rounded,
        () => _open(
          context,
          const ReportsScreen(),
        ),
      ),
      _QuickItem(
        'notifications',
        'الإشعارات',
        Icons.notifications_rounded,
        () => _open(
          context,
          const NotificationsScreen(),
        ),
      ),
      _QuickItem(
        'settings',
        'الإعدادات',
        Icons.settings_rounded,
        () => _open(
          context,
          const SettingsScreen(),
        ),
      ),
    ];

    final visible = items
        .where(
          (item) => permissions.can(
            item.permission,
          ),
        )
        .toList();

    if (visible.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'لا توجد صلاحيات إدارية متاحة لهذا الحساب.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: visible
          .map(
            (item) => _QuickCard(
              item.title,
              item.icon,
              item.onTap,
            ),
          )
          .toList(),
    );
  }

  static void _open(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }
}

class _QuickItem {
  final String permission;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickItem(
    this.permission,
    this.title,
    this.icon,
    this.onTap,
  );
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickCard(
    this.title,
    this.icon,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
