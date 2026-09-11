import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../students/students_screen.dart';
import '../teachers/teachers_screen.dart';
import '../payments/payments_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../schedules/schedules_screen.dart';
import '../attendance/attendance_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../lessons/lessons_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget { const DashboardScreen({super.key}); @override State<DashboardScreen> createState()=>_DashboardScreenState(); }
class _DashboardScreenState extends State<DashboardScreen>{
  Map<String,dynamic>? data;bool loading=true;String? error;
  @override void initState(){super.initState();loadDashboard();}
  Future<void> loadDashboard()async{if(mounted)setState((){loading=true;error=null;});try{final result=await ApiService.get('dashboard');if(!mounted)return;setState((){data=result;loading=false;});}catch(e){if(!mounted)return;setState((){error=e.toString().replaceFirst('Exception: ','');loading=false;});if(ApiService.token==null&&mounted)Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}}
  Future<void> logout()async{await ApiService.logout();if(!mounted)return;Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
  void open(Widget screen)=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>screen));
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text('${data?['academy_name']??'Online School Academy'}'),actions:[IconButton(tooltip:'تحديث',onPressed:loading?null:loadDashboard,icon:const Icon(Icons.refresh)),IconButton(tooltip:'تسجيل الخروج',onPressed:logout,icon:const Icon(Icons.logout))]),
    drawer:Drawer(child:ListView(padding:EdgeInsets.zero,children:[
      const DrawerHeader(decoration:BoxDecoration(color:AppColors.black),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.school,color:Colors.white,size:42),SizedBox(height:10),Text('Online School Academy',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),Text('إدارة الأكاديمية',style:TextStyle(color:Colors.white70))])),
      ListTile(leading:const Icon(Icons.dashboard),title:const Text('لوحة التحكم'),onTap:()=>Navigator.pop(context)),
      ListTile(leading:const Icon(Icons.people),title:const Text('الطلاب'),onTap:(){Navigator.pop(context);open(const StudentsScreen());}),
      ListTile(leading:const Icon(Icons.school),title:const Text('المدرسون'),onTap:(){Navigator.pop(context);open(const TeachersScreen());}),
      ListTile(leading:const Icon(Icons.menu_book),title:const Text('الدروس والحصص'),onTap:(){Navigator.pop(context);open(const LessonsScreen());}),
      ListTile(leading:const Icon(Icons.calendar_month),title:const Text('الجداول'),onTap:(){Navigator.pop(context);open(const SchedulesScreen());}),
      ListTile(leading:const Icon(Icons.fact_check),title:const Text('الحضور'),onTap:(){Navigator.pop(context);open(const AttendanceScreen());}),
      ListTile(leading:const Icon(Icons.event_available),title:const Text('الاشتراكات'),onTap:(){Navigator.pop(context);open(const SubscriptionsScreen());}),
      const Divider(),ListTile(leading:const Icon(Icons.payments),title:const Text('المدفوعات'),onTap:(){Navigator.pop(context);open(const PaymentsScreen());}),ListTile(leading:const Icon(Icons.money_off),title:const Text('المصروفات'),onTap:(){Navigator.pop(context);open(const ExpensesScreen());}),ListTile(leading:const Icon(Icons.bar_chart),title:const Text('التقارير المالية'),onTap:(){Navigator.pop(context);open(const ReportsScreen());})
    ])),
    body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off,size:52),const SizedBox(height:12),Text(error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:loadDashboard,child:const Text('إعادة المحاولة'))]))):RefreshIndicator(onRefresh:loadDashboard,child:GridView.count(crossAxisCount:2,padding:const EdgeInsets.all(16),crossAxisSpacing:12,mainAxisSpacing:12,children:[_card('الطلاب',data?['students'],Icons.people,()=>open(const StudentsScreen())),_card('المدرسون',data?['teachers'],Icons.school,()=>open(const TeachersScreen())),_card('حصص اليوم',data?['today_classes'],Icons.calendar_today,()=>open(const LessonsScreen())),_card('حضور اليوم',data?['today_attendance'],Icons.fact_check,()=>open(const AttendanceScreen())),_card('دخل الشهر',data?['monthly_income'],Icons.account_balance_wallet,()=>open(const PaymentsScreen())),_card('مصروفات الشهر',data?['monthly_expenses'],Icons.money_off,()=>open(const ExpensesScreen())),_card('تجديد خلال 7 أيام',data?['expiring_7_days'],Icons.warning_amber,()=>open(const SubscriptionsScreen()))]));
  Widget _card(String title,dynamic value,IconData icon,VoidCallback onTap)=>Card(child:InkWell(borderRadius:BorderRadius.circular(12),onTap:onTap,child:Padding(padding:const EdgeInsets.all(16),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:34,color:AppColors.red),const SizedBox(height:10),Text('${value??0}',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),Text(title)]))));
}
