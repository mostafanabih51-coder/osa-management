import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/auth/permissions.dart';
import '../../models/dashboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../profile/profile_screen.dart';
import '../students/students_screen.dart';
import '../teachers/teachers_screen.dart';
import '../courses/courses_screen.dart';
import '../groups/groups_screen.dart';
import '../attendance/attendance_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../reports/reports_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardProvider(context.read())..load(),
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
          IconButton(
            onPressed: () {
              context.read<DashboardProvider>().load();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline_rounded),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'الإدارة',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
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
                  state.data.students == 0 &&
                  state.data.teachers == 0 &&
                  state.data.courses == 0 &&
                  state.data.subscriptions == 0 &&
                  state.data.activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

              _StatsGrid(data: state.data),

              const SizedBox(height: 22),

              const Text(
                'النشاط الأخير',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              if (state.data.activities.isEmpty)
                const _EmptyActivity(),

              ...state.data.activities.map(
                (activity) => _ActivityTile(
                  activity: activity,
                ),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
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
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'إليك ملخص نظام الإدارة اليوم',
                  style: TextStyle(
                    color: Colors.white70,
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
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          'الطلاب',
          data.students,
          Icons.groups_rounded,
        ),
        _StatCard(
          'المدرسون',
          data.teachers,
          Icons.person_rounded,
        ),
        _StatCard(
          'الكورسات',
          data.courses,
          Icons.menu_book_rounded,
        ),
        _StatCard(
          'الاشتراكات',
          data.subscriptions,
          Icons.card_membership_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const _StatCard(
    this.title,
    this.value,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppTheme.primary,
              size: 27,
            ),
            const Spacer(),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DashboardActivity activity;

  const _ActivityTile({
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFE8EA),
          child: Icon(
            Icons.notifications_none,
            color: AppTheme.primary,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(activity.subtitle),
        trailing: Text(
          activity.time,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد أنشطة حديثة',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentsScreen(),
          ),
        ),
      ),
      _QuickItem(
        'teachers',
        'المدرسون',
        Icons.person_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TeachersScreen(),
          ),
        ),
      ),
      _QuickItem(
        'courses',
        'الكورسات',
        Icons.menu_book_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CoursesScreen(),
          ),
        ),
      ),
      _QuickItem(
        'groups',
        'المجموعات',
        Icons.groups_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const GroupsScreen(),
          ),
        ),
      ),
      _QuickItem(
        'subscriptions',
        'الاشتراكات',
        Icons.card_membership_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubscriptionsScreen(),
          ),
        ),
      ),
      _QuickItem(
        'attendance',
        'الحضور',
        Icons.fact_check_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendanceScreen(),
          ),
        ),
      ),
      _QuickItem(
        'reports',
        'التقارير',
        Icons.analytics_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
          ),
        ),
      ),
      _QuickItem(
        'notifications',
        'الإشعارات',
        Icons.notifications_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        ),
      ),
      _QuickItem(
        'settings',
        'الإعدادات',
        Icons.settings_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        ),
      ),
    ];

    final visible = items
        .where((item) => permissions.can(item.permission))
        .toList();

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
