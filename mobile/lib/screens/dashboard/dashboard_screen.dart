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
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String,dynamic>? data;
  bool loading=true;
  String? error;
  String role='';

  @override void initState(){super.initState();loadDashboard();}
  Future<void> loadDashboard() async {
    try {
      final dashboard=await ApiService.get('dashboard');
      if(!mounted)return;
      setState((){data=Map<String,dynamic>.from(dashboard is Map && dashboard['data'] is Map ? dashboard['data'] : dashboard);loading=false;error=null;});
    } catch(e) { if(mounted)setState((){loading=false;error=e.toString().replaceFirst('Exception: ','');}); }
  }
  Future<void> logout() async { await ApiService.logout(); if(mounted)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false); }
  void open(Widget page){Navigator.of(context).push(MaterialPageRoute(builder:(_)=>page));}
  Widget drawerItem(IconData icon,String title,Widget? page){return ListTile(leading:Icon(icon),title:Text(title),onTap:(){Navigator.pop(context);if(page!=null)open(page);});}
  Widget stat(String title,dynamic value,IconData icon,Widget page){return Card(child:InkWell(onTap:()=>open(page),child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:AppColors.red,size:32),const SizedBox(height:8),Text('${value??0}',style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),Text(title)]))));}

  @override Widget build(BuildContext context){
    final items=<Widget>[
      drawerItem(Icons.people,'الطلاب',const StudentsScreen()),
      drawerItem(Icons.school,'المدرسون',const TeachersScreen()),
      drawerItem(Icons.supervisor_account,'المشرفون',const SupervisorsScreen()),
      drawerItem(Icons.groups,'المجموعات',const GroupsScreen()),
      drawerItem(Icons.menu_book,'الدروس والحصص',const LessonsScreen()),
      drawerItem(Icons.calendar_month,'الجداول',const SchedulesScreen()),
      drawerItem(Icons.fact_check,'الحضور',const AttendanceScreen()),
      drawerItem(Icons.event_available,'الاشتراكات',const SubscriptionsScreen()),
      const Divider(),
      drawerItem(Icons.payments,'المدفوعات',const PaymentsScreen()),
      drawerItem(Icons.money_off,'المصروفات',const ExpensesScreen()),
      drawerItem(Icons.account_balance_wallet,'المالية',const FinanceScreen()),
      drawerItem(Icons.bar_chart,'التقارير',const ReportsScreen()),
      drawerItem(Icons.admin_panel_settings,'المستخدمون والصلاحيات',const UsersScreen()),
    ];
    Widget body;
    if(loading){body=const Center(child:CircularProgressIndicator());}
    else if(error!=null){body=Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton(onPressed:loadDashboard,child:const Text('إعادة المحاولة'))])));}
    else {body=RefreshIndicator(onRefresh:loadDashboard,child:GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(16),crossAxisSpacing:12,mainAxisSpacing:12,children:[stat('الطلاب',data?['students'],Icons.people,const StudentsScreen()),stat('المدرسون',data?['teachers'],Icons.school,const TeachersScreen()),stat('حصص اليوم',data?['today_classes'],Icons.calendar_today,const LessonsScreen()),stat('حضور اليوم',data?['today_attendance'],Icons.fact_check,const AttendanceScreen()),stat('دخل الشهر',data?['monthly_income'],Icons.payments,const PaymentsScreen()),stat('مصروفات الشهر',data?['monthly_expenses'],Icons.money_off,const ExpensesScreen()),stat('تجديد خلال 7 أيام',data?['expiring_7_days'],Icons.warning,const SubscriptionsScreen())]));}
    return Scaffold(appBar:AppBar(title:Text('${data?['academy_name']??'Online School Academy'}'),actions:[IconButton(onPressed:loading?null:loadDashboard,icon:const Icon(Icons.refresh)),IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),drawer:Drawer(child:ListView(padding:EdgeInsets.zero,children:[const DrawerHeader(decoration:BoxDecoration(color:AppColors.black),child:Text('Online School Academy',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),...items])),body:body);
  }
}
