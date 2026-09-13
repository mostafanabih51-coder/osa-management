import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../students/students_screen.dart';
import '../teachers/teachers_screen.dart';
import '../supervisors/supervisors_screen.dart';
import '../groups/groups_screen.dart';
import '../payments/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../schedules/schedules_screen.dart';
import '../attendance/attendance_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../lessons/lessons_screen.dart';
import '../finance/finance_screen.dart';
import '../users/users_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final response = await ApiService.get('dashboard');
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(response is Map && response['data'] is Map ? response['data'] : response);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Widget drawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        open(page);
      },
    );
  }

  Widget stat(String title, dynamic value, IconData icon, Widget page) {
    return Card(
      child: InkWell(
        onTap: () => open(page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.red, size: 30),
              const SizedBox(height: 6),
              Text('${value ?? 0}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget workflowStep(int number, String title, String description, IconData icon, Widget page) {
    return Card(
      child: InkWell(
        onTap: () => open(page),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.red, child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Icon(icon, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(description)])),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawer = <Widget>[
      drawerItem(Icons.people, 'الطلاب', const StudentsScreen()),
      drawerItem(Icons.school, 'المدرسون', const TeachersScreen()),
      drawerItem(Icons.supervisor_account, 'المشرفون', const SupervisorsScreen()),
      drawerItem(Icons.groups, 'المجموعات', const GroupsScreen()),
      drawerItem(Icons.menu_book, 'الدروس والحصص', const LessonsScreen()),
      drawerItem(Icons.calendar_month, 'الجداول', const SchedulesScreen()),
      drawerItem(Icons.fact_check, 'الحضور', const AttendanceScreen()),
      drawerItem(Icons.event_available, 'الاشتراكات', const SubscriptionsScreen()),
      const Divider(),
      drawerItem(Icons.payments, 'المدفوعات', const PaymentsScreen()),
      drawerItem(Icons.money_off, 'المصروفات', const ExpensesScreen()),
      drawerItem(Icons.account_balance_wallet, 'المالية', const FinanceScreen()),
      drawerItem(Icons.bar_chart, 'التقارير', const ReportsScreen()),
      drawerItem(Icons.admin_panel_settings, 'المستخدمون والصلاحيات', const UsersScreen()),
    ];

    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: loadDashboard, child: const Text('إعادة المحاولة'))])));
    } else {
      body = RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('طريقة تشغيل الأكاديمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 6),
                  Text('التطبيق مبني على دورة عمل واحدة: الطالب ومواده → المدرس وعلاقته بالطالب → المجموعة عند الحاجة → الحصة → الاشتراك → الدفع → متابعة المستحقات.'),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            workflowStep(1, 'الطلاب والمواد', 'أضف الطالب واختر المواد المشترك بها فعليًا.', Icons.people, const StudentsScreen()),
            workflowStep(2, 'المدرسون والربط', 'افتح المدرس واربطه بالطالب والمادة وحدد سعر الحصة ونسبة الأكاديمية.', Icons.school, const TeachersScreen()),
            workflowStep(3, 'المجموعات', 'للدروس الجماعية: أنشئ مجموعة وحدد المدرس والمادة وأكثر من طالب.', Icons.groups, const GroupsScreen()),
            workflowStep(4, 'الدروس والحصص', 'أنشئ حصة خاصة أو جروب؛ العلاقات المطلوبة تُتحقق قبل الحفظ.', Icons.menu_book, const LessonsScreen()),
            workflowStep(5, 'الاشتراك والدفع', 'سجل اشتراك الطالب ثم سجل الدفعة واربطها بالاشتراك عند الحاجة.', Icons.payments, const SubscriptionsScreen()),
            const SizedBox(height: 10),
            const Text('ملخص سريع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                stat('الطلاب', data?['students'], Icons.people, const StudentsScreen()),
                stat('المدرسون', data?['teachers'], Icons.school, const TeachersScreen()),
                stat('حصص اليوم', data?['today_classes'], Icons.calendar_today, const LessonsScreen()),
                stat('حضور اليوم', data?['today_attendance'], Icons.fact_check, const AttendanceScreen()),
                stat('دخل الشهر', data?['monthly_income'], Icons.payments, const PaymentsScreen()),
                stat('مصروفات الشهر', data?['monthly_expenses'], Icons.money_off, const ExpensesScreen()),
                stat('تجديد خلال 7 أيام', data?['expiring_7_days'], Icons.warning, const SubscriptionsScreen()),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${data?['academy_name'] ?? 'Online School Academy'}'),
        actions: [IconButton(onPressed: loading ? null : loadDashboard, icon: const Icon(Icons.refresh)), IconButton(onPressed: logout, icon: const Icon(Icons.logout))],
      ),
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [const DrawerHeader(decoration: BoxDecoration(color: AppColors.black), child: Text('Online School Academy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))), ...drawer]),
      body: body,
    );
  }
}
