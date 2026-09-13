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
  Map<String, dynamic>? data; bool loading = true; String? error, role;
  @override void initState() { super.initState(); loadDashboard(); }
  Future<void> loadDashboard() async { try { final r = await Future.wait([ApiService.get('dashboard'), ApiService.get('user')]); if (!mounted) return; final u = r[1] is Map && r[1]['user'] is Map ? r[1]['user'] : r[1]; setState(() { data = Map<String,dynamic>.from(r[0] as Map); role='${u['role']??''}'; loading=false; error=null; }); } catch(e) { if(mounted) setState(() { error=e.toString().replaceFirst('Exception: ',''); loading=false; }); } }
  Future<void> logout() async { await ApiService.logout(); if(mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false); }
  void open(Widget s)=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>s));
  Widget item(IconData i,String t,Widget? s)=>ListTile(leading:Icon(i),title:Text(t),onTap:(){Navigator.pop(context);if(s!=null)open(s);});
  Widget card(String t,d,IconData i,VoidCallback f)=>Card(child:InkWell(onTap:f,child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,size:34,color:AppColors.red),const SizedBox(height:10),Text('${d??0}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),Text(t)]))));
  bool get canManageUsers=>['admin','super_admin','owner'].contains(role);
  @override Widget build(BuildContext context){
    final drawerItems=<Widget>[item(Icons.dashboard,'لوحة التحكم',null),item(Icons.people,'الطلاب',const StudentsScreen()),item(Icons.school,'المدرسون',const TeachersScreen()),item(Icons.supervisor_account,'المشرفون',const SupervisorsScreen()),item(Icons.groups,'المجموعات',const GroupsScreen()),item(Icons.menu_book,'الدروس والحصص',const LessonsScreen()),item(Icons.calendar_month,'الجداول',const SchedulesScreen()),item(Icons.fact_check,'الحضور',const AttendanceScreen()),item(Icons.event_available,'الاشتراكات',const SubscriptionsScreen()),const Divider(),item(Icons.payments,'المدفوعات',const PaymentsScreen()),item(Icons.money_off,'المصروفات',const ExpensesScreen()),item(Icons.account_balance_wallet,'المالية والمستحقات',const FinanceScreen()),item(Icons.bar_chart,'التقارير المالية',const ReportsScreen())];
    if(canManageUsers) drawerItems.add(item(Icons.admin_panel_settings,'المستخدمون والصلاحيات',const UsersScreen()));
    return Scaffold(appBar:AppBar(title:Text('${data?['academy_name']??'Online School Academy'}'),actions:[IconButton(onPressed:loading?null:loadDashboard,icon:const Icon(Icons.refresh)),IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),drawer:Drawer(child:ListView(padding:EdgeInsets.zero,children:[const DrawerHeader(decoration:BoxDecoration(color:AppColors.black),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.school,color:Colors.white,size:42),SizedBox(height:10),Text('Online School Academy',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),Text('إدارة الأكاديمية',style:TextStyle(color:Colors.white70))])),...drawerItems])),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:loadDashboard,child:const Text('إعادة المحاولة'))]))):RefreshIndicator(onRefresh:loadDashboard,child:GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(16),crossAxisSpacing:12,mainAxisSpacing:12,children:[card('الطلاب',data?['students'],Icons.people,()=>open(const StudentsScreen())),card('المدرسون',data?['teachers'],Icons.school,()=>open(const TeachersScreen())),card('حصص اليوم',data?['today_classes'],Icons.calendar_today,()=>open(const LessonsScreen())),card('حضور اليوم',data?['today_attendance'],Icons.fact_check,()=>open(const AttendanceScreen())),card('دخل الشهر',data?['monthly_income'],Icons.account_balance_wallet,()=>open(const PaymentsScreen())),card('مصروفات الشهر',data?['monthly_expenses'],Icons.money_off,()=>open(const ExpensesScreen())),card('تجديد خلال 7 أيام',data?['expiring_7_days'],Icons.warning_amber,()=>open(const SubscriptionsScreen()))]));
  }
}
