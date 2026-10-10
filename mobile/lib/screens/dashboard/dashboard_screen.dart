import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../students/students_screen.dart';
import '../parents/parents_screen.dart';
import '../teachers/teachers_screen.dart';
import '../supervisors/supervisors_screen.dart';
import '../groups/groups_screen.dart';
import '../lessons/lessons_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../subscriptions/subscription_reminders_screen.dart';
import '../payments/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../finance/finance_screen.dart';
import '../finance/role_portal_screen.dart';
import '../schedules/schedules_screen.dart';
import '../attendance/attendance_screen.dart';
import '../users/users_screen.dart';
import '../academic/academic_tracking_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  Map<String, dynamic>? currentUser;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final ur = await ApiService.get('user');
      final u = ur is Map && ur['data'] is Map ? ur['data'] : ur;
      final r = await ApiService.get('dashboard');
      final d = r is Map && r['data'] is Map ? r['data'] : r;
      if (!mounted) return;
      setState(() {
        currentUser = Map<String, dynamic>.from(u as Map);
        data = Map<String, dynamic>.from(d);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget menuItem(IconData icon, String title, Widget page) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          open(page);
        },
      );

  Widget dashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
    required Color color,
    dynamic value,
    bool showValue = true,
  }) {
    final hasValue = showValue && value != null;
    return AnimatedPressable(
      onTap: () => open(page),
      borderRadius: BorderRadius.circular(22),
      child: GlassSurface(
        padding: const EdgeInsets.all(16),
        radius: 22,
        blur: 18,
        tint: color.withValues(alpha: 0.30),
        borderColor: AppColors.text.withValues(alpha: 0.22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 118),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded,
                    color: Colors.white.withValues(alpha: 0.78), size: 19),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasValue) ...[
              const SizedBox(height: 3),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = '${currentUser?['role'] ?? ''}';
    final staff = role == 'teacher' || role == 'supervisor';

    final menu = <Widget>[
      if (staff)
        menuItem(Icons.account_balance_wallet, 'بوابة المستحقات والسحب',
            const RolePortalScreen())
      else ...[
        menuItem(Icons.people, 'الطلاب', const StudentsScreen()),
        menuItem(Icons.family_restroom, 'أولياء الأمور', const ParentsScreen()),
        menuItem(Icons.school, 'المدرسون', const TeachersScreen()),
        menuItem(Icons.supervisor_account, 'المشرفون', const SupervisorsScreen()),
        menuItem(Icons.groups, 'المجموعات', const GroupsScreen()),
        menuItem(Icons.menu_book, 'الدروس والحصص', const LessonsScreen()),
        menuItem(Icons.fact_check, 'المتابعة الأكاديمية',
            const AcademicTrackingScreen()),
        menuItem(Icons.event_available, 'الاشتراكات', const SubscriptionsScreen()),
        menuItem(Icons.notifications_active, 'تنبيهات الاشتراكات',
            const SubscriptionRemindersScreen()),
        menuItem(Icons.payments, 'المدفوعات', const PaymentsScreen()),
        const Divider(),
        menuItem(Icons.calendar_month, 'الجداول', const SchedulesScreen()),
        menuItem(Icons.fact_check_outlined, 'الحضور', const AttendanceScreen()),
        menuItem(Icons.money_off, 'المصروفات', const ExpensesScreen()),
        menuItem(Icons.account_balance_wallet, 'المالية', const FinanceScreen()),
        menuItem(Icons.bar_chart, 'التقارير', const ReportsScreen()),
        menuItem(Icons.admin_panel_settings, 'المستخدمون والصلاحيات',
            const UsersScreen()),
      ],
    ];

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.gold, size: 42),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: loadDashboard,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    } else if (staff) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet,
                  size: 56, color: AppColors.gold),
              const SizedBox(height: 12),
              Text(role == 'teacher' ? 'بوابة المدرس' : 'بوابة المشرف',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('تابع مستحقات الحصص واطلب السحب من حسابك.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => open(const RolePortalScreen()),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح بوابة المستحقات'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: loadDashboard,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // The highlight belongs to the screen surface; cards remain solid.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.magenta,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -34,
                    left: -18,
                    child: IgnorePointer(
                      child: Container(
                        width: 150,
                        height: 95,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.23),
                              ),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Colors.white, size: 27),
                          ),
                          const Spacer(),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Online School Academy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'إدارة الطلاب والمدرسين والحصص والمالية من مكان واحد.',
                        style: TextStyle(
                          color: Color(0xFFFBEAF1),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.45)),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () => open(const AcademicTrackingScreen()),
                        icon: const Icon(Icons.analytics_outlined, size: 19),
                        label: const Text('المتابعة والحصص الشهرية'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'إدارة الأكاديمية',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.96,
              children: [
                // Intentionally no counts or statistics on student/teacher cards.
                dashboardCard(
                  title: 'الطلاب',
                  subtitle: 'ملفات الطلاب واشتراكاتهم',
                  icon: Icons.people_alt_rounded,
                  page: const StudentsScreen(),
                  color: AppColors.magenta,
                  showValue: false,
                ),
                dashboardCard(
                  title: 'المدرسون',
                  subtitle: 'البيانات والمستحقات',
                  icon: Icons.school_rounded,
                  page: const TeachersScreen(),
                  color: AppColors.surface,
                  showValue: false,
                ),
                dashboardCard(
                  title: 'حصص اليوم',
                  subtitle: 'الحصص المجدولة اليوم',
                  icon: Icons.calendar_month_rounded,
                  page: const LessonsScreen(),
                  color: AppColors.surface,
                  value: data?['today_classes'] ?? 0,
                ),
                dashboardCard(
                  title: 'حضور اليوم',
                  subtitle: 'متابعة الحضور والغياب',
                  icon: Icons.fact_check_rounded,
                  page: const AttendanceScreen(),
                  color: AppColors.magenta,
                  value: data?['today_attendance'] ?? 0,
                ),
                dashboardCard(
                  title: 'دخل الشهر',
                  subtitle: 'المدفوعات والإيرادات',
                  icon: Icons.payments_rounded,
                  page: const PaymentsScreen(),
                  color: AppColors.magenta,
                  value: data?['monthly_income'] ?? 0,
                ),
                dashboardCard(
                  title: 'مصروفات الشهر',
                  subtitle: 'المصروفات المسجلة',
                  icon: Icons.money_off_rounded,
                  page: const ExpensesScreen(),
                  color: AppColors.surface,
                  value: data?['monthly_expenses'] ?? 0,
                ),
                dashboardCard(
                  title: 'غير المسددين',
                  subtitle: 'متابعة الاشتراكات المستحقة',
                  icon: Icons.receipt_long_rounded,
                  page: const SubscriptionsScreen(showDebtorsOnly: true),
                  color: AppColors.surface,
                  value: data?['students_without_month_payment'] ?? 0,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'باقي الأقسام',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceDeep,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickAction(
                    icon: Icons.groups_rounded,
                    label: 'المجموعات',
                    onTap: () => open(const GroupsScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.family_restroom_rounded,
                    label: 'أولياء الأمور',
                    onTap: () => open(const ParentsScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.notifications_active_rounded,
                    label: 'التنبيهات',
                    onTap: () => open(const SubscriptionRemindersScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'المالية',
                    onTap: () => open(const FinanceScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.bar_chart_rounded,
                    label: 'التقارير',
                    onTap: () => open(const ReportsScreen()),
                  ),
                  _QuickAction(
                    icon: Icons.settings_rounded,
                    label: 'الصلاحيات',
                    onTap: () => open(const UsersScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${data?['academy_name'] ?? 'Online School Academy'}'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: loading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surfaceDeep,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.magenta),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.school_rounded, color: Colors.white, size: 35),
                  SizedBox(height: 12),
                  Text(
                    'Online School Academy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ...menu,
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: body),
          // Low-cost glossy reflection across the overall screen, not card fills.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.centerRight,
                    stops: [0, 0.22, 0.62, 1],
                    colors: [
                      Color(0x12FFFFFF),
                      Color(0x04FFFFFF),
                      Color(0x00000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.text),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
