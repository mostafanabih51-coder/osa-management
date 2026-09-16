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
import '../payments/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../finance/finance_screen.dart';
import '../schedules/schedules_screen.dart';
import '../attendance/attendance_screen.dart';
import '../users/users_screen.dart';
import '../academic/academic_tracking_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); loadDashboard(); }

  Future<void> loadDashboard() async {
    try {
      final r = await ApiService.get('dashboard');
      final d = r is Map && r['data'] is Map ? r['data'] : r;
      if (!mounted) return;
      setState(() { data = Map<String, dynamic>.from(d); loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Widget menuItem(IconData icon, String title, Widget page) => ListTile(
    leading: Icon(icon), title: Text(title), onTap: () { Navigator.pop(context); open(page); },
  );

  Widget stat(String title, dynamic value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.red, size: 28),
        Text('${value ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final menu = <Widget>[
      menuItem(Icons.people, 'الطلاب', const StudentsScreen()),
      menuItem(Icons.family_restroom, 'أولياء الأمور', const ParentsScreen()),
      menuItem(Icons.school, 'المدرسون', const TeachersScreen()),
      menuItem(Icons.supervisor_account, 'المشرفون', const SupervisorsScreen()),
      menuItem(Icons.groups, 'المجموعات', const GroupsScreen()),
      menuItem(Icons.menu_book, 'الدروس والحصص', const LessonsScreen()),
      menuItem(Icons.fact_check, 'المتابعة الأكاديمية', const AcademicTrackingScreen()),
      menuItem(Icons.event_available, 'الاشتراكات', const SubscriptionsScreen()),
      menuItem(Icons.payments, 'المدفوعات', const PaymentsScreen()),
      const Divider(),
      menuItem(Icons.calendar_month, 'الجداول', const SchedulesScreen()),
      menuItem(Icons.fact_check_outlined, 'الحضور', const AttendanceScreen()),
      menuItem(Icons.money_off, 'المصروفات', const ExpensesScreen()),
      menuItem(Icons.account_balance_wallet, 'المالية', const FinanceScreen()),
      menuItem(Icons.bar_chart, 'التقارير', const ReportsScreen()),
      menuItem(Icons.admin_panel_settings, 'المستخدمون والصلاحيات', const UsersScreen()),
    ];

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: loadDashboard, child: const Text('إعادة المحاولة')),
        ]),
      ));
    } else {
      body = RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Online School Academy', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('إدارة الطلاب والمدرسين والحصص والمالية والمتابعة الأكاديمية من مكان واحد.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => open(const AcademicTrackingScreen()),
                  icon: const Icon(Icons.analytics),
                  label: const Text('المتابعة والحصص الشهرية'),
                ),
              ]),
            )),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                stat('الطلاب', data?['students'], Icons.people),
                stat('المدرسون', data?['teachers'], Icons.school),
                stat('حصص اليوم', data?['today_classes'], Icons.calendar_today),
                stat('حضور اليوم', data?['today_attendance'], Icons.fact_check),
                stat('دخل الشهر', data?['monthly_income'], Icons.payments),
                stat('مصروفات الشهر', data?['monthly_expenses'], Icons.money_off),
                stat('غير المسددين', data?['students_without_month_payment'], Icons.warning_amber),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${data?['academy_name'] ?? 'Online School Academy'}'),
        actions: [
          IconButton(onPressed: loading ? null : loadDashboard, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: Drawer(child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.black),
            child: Text('Online School Academy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ...menu,
        ],
      )),
      body: body,
    );
  }
}
