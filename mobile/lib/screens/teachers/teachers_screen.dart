import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class TeachersScreen extends StatefulWidget { const TeachersScreen({super.key}); @override State<TeachersScreen> createState() => _TeachersScreenState(); }
class _TeachersScreenState extends State<TeachersScreen> {
  List teachers = [], students = [], subjects = [], supervisors = []; bool loading = true;
  static const fallback = ['العربية','اللغة الإنجليزية','الرياضيات','العلوم','الدراسات الاجتماعية','Math','Science','English','Arabic','German','French','Spanish','Quran','Chemistry','Physics','Biology','History','Geography','Philosophy'];
  List<dynamic> list(dynamic x) { if (x is List) return List<dynamic>.from(x); if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']); if (x is Map && x['data'] is Map && x['data']['data'] is List) return List<dynamic>.from(x['data']['data']); return []; }
  int id(dynamic x) => int.tryParse('${x['id']}') ?? 0;
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try { teachers = list(await ApiService.get('teachers')); } catch (e) { msg(e); }
    try { students = list(await ApiService.get('students')); } catch (_) {}
    try { final s = list(await ApiService.get('subjects')).map((x) => x is Map ? '${x['subject'] ?? x['name'] ?? ''}' : '$x').where((x) => x.isNotEmpty).toSet().toList(); subjects = s.isEmpty ? fallback : s; } catch (_) { subjects = fallback; }
    try { supervisors = list(await ApiService.get('supervisors')); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }
  Future<void> edit(dynamic t) async {
    final n=TextEditingController(text:'${t['name']??''}'), p=TextEditingController(text:'${t['phone']??''}'), e=TextEditingController(text:'${t['email']??''}'), s=TextEditingController(text:'${t['specialization']??''}');
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('تعديل المدرس'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف')),TextField(controller:e,decoration:const InputDecoration(labelText:'البريد')),TextField(controller:s,decoration:const InputDecoration(labelText:'المادة / التخصص'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))]));
    if(ok==true){try{await ApiService.put('teachers/${id(t)}',{'name':n.text.trim(),'phone':p.text.trim(),'email':e.text.trim(),'specialization':s.text.trim()});await load();}catch(e2){msg(e2);}} for(final c in[n,p,e,s])c.dispose();
  }
  Future<void> add() async {
    final n=TextEditingController(),p=TextEditingController(),e=TextEditingController(),s=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('إضافة مدرس'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:p,decoration:const InputDecoration(labelText:'الهاتف')),TextField(controller:e,decoration:const InputDecoration(labelText:'البريد')),TextField(controller:s,decoration:const InputDecoration(labelText:'المادة / التخصص'))])),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))]));
    if(ok==true){try{await ApiService.post('teachers',{'name':n.text.trim(),'phone':p.text.trim(),'email':e.text.trim(),'specialization':s.text.trim(),'status':'active'});await load();}catch(e2){msg(e2);}} for(final c in[n,p,e,s])c.dispose();
  }
  Future<void> assign(dynamic teacher) async {
    if(students.isEmpty){msg(Exception('أضف طالبًا أولًا.'));return;}
    final specialization='${teacher['specialization']??''}'.trim(); String subject=subjects.contains(specialization)?specialization:(subjects.isNotEmpty?subjects.first:fallback.first); int studentId=id(students.first); int? supervisorId;
    final rate=TextEditingController(), percent=TextEditingController(text:'0');
    final ok=await showDialog<bool>(context:context,builder:(d)=>StatefulBuilder(builder:(c,set)=>AlertDialog(title:Text('ربط طالب بمدرس: ${teacher['name']??''}'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<int>(value:studentId,items:students.map<DropdownMenuItem<int>>((s)=>DropdownMenuItem(value:id(s),child:Text('${s['name']??''}'))).toList(),onChanged:(v){if(v!=null)set(()=>studentId=v);},decoration:const InputDecoration(labelText:'الطالب')),
      DropdownButtonFormField<String>(value:subject,items:subjects.map<DropdownMenuItem<String>>((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),onChanged:(v){if(v!=null)set(()=>subject=v);},decoration:InputDecoration(labelText:specialization.isEmpty?'المادة':'المادة (تخصص المدرس: $specialization)')),
      TextField(controller:rate,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'سعر المدرس للحصة *')),
      TextField(controller:percent,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'نسبة الأكاديمية %')),
      DropdownButtonFormField<int?>(value:supervisorId,items:<DropdownMenuItem<int?>>[const DropdownMenuItem(value:null,child:Text('بدون مشرف')),...supervisors.map<DropdownMenuItem<int?>>((s)=>DropdownMenuItem(value:id(s),child:Text('${s['name']??''}')))],onChanged:(v)=>set(()=>supervisorId=v),decoration:const InputDecoration(labelText:'المشرف (اختياري)')),
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حفظ'))])));
    if(ok==true){try{await ApiService.post('teacher-assignments',{'teacher_id':id(teacher),'student_id':studentId,'subject':subject,'teacher_rate':double.tryParse(rate.text)??0,'academy_percentage':double.tryParse(percent.text)??0,'supervisor_id':supervisorId,'status':'active'});msg('تم الحفظ وربط الطالب بالمدرس والمادة والسعر');}catch(e){msg(e);}} for(final c in[rate,percent])c.dispose();
  }
  Future<void> remove(dynamic t) async { final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('حذف المدرس'),content:Text('حذف ${t['name']??''}؟'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حذف'))])); if(ok==true){try{await ApiService.delete('teachers/${id(t)}');await load();}catch(e){msg(e);}} }
  Future<void> details(int teacherId) async {
    try { final r=await ApiService.get('teachers/$teacherId'); final d=Map<String,dynamic>.from(r is Map&&r['data'] is Map?r['data']:r); final sl=list(d['students']), a=list(d['assignments']); if(!mounted)return;
      await showDialog(context:context,builder:(dc)=>AlertDialog(title:Text(d['teacher'] is Map?'${d['teacher']['name']??'المدرس'}':'المدرس'),content:SizedBox(width:560,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('المادة: ${d['teacher'] is Map?d['teacher']['specialization']??'-':'-'}'),FilledButton.icon(onPressed:()=>assign(d['teacher']),icon:const Icon(Icons.link),label:const Text('ربط طالب / مادة / سعر')),const Divider(),Text('الطلاب المرتبطون (${sl.length})',style:const TextStyle(fontWeight:FontWeight.bold)),...sl.map((s)=>ListTile(dense:true,leading:const Icon(Icons.person),title:Text('${s['name']??''}'),subtitle:Text(s['pivot'] is Map?'${s['pivot']['subject']??''}':''))),const Divider(),Text('العلاقات والأسعار: ${a.length}'),...a.map((x)=>Text('• ${x['student'] is Map?'${x['student']['name']??''}':''} — ${x['subject']??''} — ${x['teacher_rate']??0}'))]))),actions:[TextButton(onPressed:()=>Navigator.pop(dc),child:const Text('إغلاق'))]));
    } catch(e){msg(e);}
  }
  @override Widget build(BuildContext context) {
    return Scaffold(appBar:AppBar(title:const Text('المدرسون'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),floatingActionButton:FloatingActionButton.extended(onPressed:add,backgroundColor:AppColors.red,icon:const Icon(Icons.person_add),label:const Text('إضافة مدرس')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,90),children:[
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Text('عدد الطلاب المسجلين: ${students.length}'))),
      if(teachers.isEmpty) const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('لا يوجد مدرسون.'))),
      ...teachers.map((t)=>Card(child:ListTile(onTap:()=>details(id(t)),leading:const CircleAvatar(child:Icon(Icons.school)),title:Text('${t['name']??''}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('المادة: ${t['specialization']??'-'}\n${t['phone']??t['email']??''}'),isThreeLine:true,trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(onPressed:()=>assign(t),icon:const Icon(Icons.link)),IconButton(onPressed:()=>edit(t),icon:const Icon(Icons.edit)),IconButton(onPressed:()=>remove(t),icon:const Icon(Icons.delete))]))),
    ])));
  }
}
