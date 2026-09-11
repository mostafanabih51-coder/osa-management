import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List lessons = [], teachers = [], students = [], supervisors = [];
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final r = await Future.wait([ApiService.get('lessons'), ApiService.get('teachers'), ApiService.get('students'), ApiService.get('supervisors')]);
      if (!mounted) return;
      setState(() { lessons=r[0]['data'] ?? []; teachers=r[1]['data'] ?? []; students=r[2]['data'] ?? []; supervisors=r[3]['data'] ?? []; loading=false; });
    } catch(e) { if(!mounted)return; setState((){loading=false;error=e.toString().replaceFirst('Exception: ','');}); }
  }

  Future<void> addLesson() async {
    if (teachers.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مدرسًا أولًا'))); return; }
    String type='private'; int teacherId=teachers.first['id']; int? studentId=students.isEmpty?null:students.first['id']; int? supervisorId=supervisors.isEmpty?null:supervisors.first['id'];
    final subject=TextEditingController(); final starts=TextEditingController(text: '${DateTime.now().toIso8601String().substring(0,10)} 16:00'); final ends=TextEditingController(text: '${DateTime.now().toIso8601String().substring(0,10)} 17:00'); final rate=TextEditingController(text:'0');
    final key=GlobalKey<FormState>();
    final ok=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('إضافة حصة'),content:Form(key:key,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'نوع الحصة'),items:const [DropdownMenuItem(value:'private',child:Text('خاصة')),DropdownMenuItem(value:'group',child:Text('مجموعة'))],onChanged:(v){if(v!=null)type=v;}),
      DropdownButtonFormField<int>(value:teacherId,decoration:const InputDecoration(labelText:'المدرس'),items:teachers.map((x)=>DropdownMenuItem<int>(value:x['id'] as int,child:Text('${x['name']??''}'))).toList(),onChanged:(v){if(v!=null)teacherId=v;}),
      if(students.isNotEmpty) DropdownButtonFormField<int?>(value:studentId,decoration:const InputDecoration(labelText:'الطالب للحصة الخاصة'),items:students.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text('${x['name']??''}'))).toList(),onChanged:(v)=>studentId=v),
      if(supervisors.isNotEmpty) DropdownButtonFormField<int?>(value:supervisorId,decoration:const InputDecoration(labelText:'المشرف'),items:[const DropdownMenuItem<int?>(value:null,child:Text('بدون مشرف')), ...supervisors.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text('${x['name']??''}')))],onChanged:(v)=>supervisorId=v),
      TextFormField(controller:subject,decoration:const InputDecoration(labelText:'المادة'),validator:(v)=>v==null||v.trim().isEmpty?'أدخل المادة':null),
      TextFormField(controller:starts,decoration:const InputDecoration(labelText:'البداية YYYY-MM-DD HH:MM')),
      TextFormField(controller:ends,decoration:const InputDecoration(labelText:'النهاية YYYY-MM-DD HH:MM')),
      TextFormField(controller:rate,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'مستحق المدرس')),
    ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),FilledButton(onPressed:(){if(key.currentState!.validate())Navigator.pop(context,true);},child:const Text('حفظ'))]));
    if(ok!=true)return;
    if(type=='private'&&studentId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر الطالب')));return;}
    try{await ApiService.post('lessons',{'type':type,'teacher_id':teacherId,'supervisor_id':supervisorId,'student_id':type=='private'?studentId:null,'subject':subject.text.trim(),'starts_at':starts.text.trim(), 'ends_at':ends.text.trim(),'teacher_rate':double.tryParse(rate.text)??0,'supervisor_rate':0,'status':'scheduled'});await load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تمت إضافة الحصة')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}
  }

  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الدروس والحصص'),actions:[IconButton(onPressed:loading?null:load,icon:const Icon(Icons.refresh))]),floatingActionButton:FloatingActionButton(onPressed:addLesson,child:const Icon(Icons.add)),body:loading?const Center(child:CircularProgressIndicator()):error!=null?_error():lessons.isEmpty?const Center(child:Text('لا توجد حصص مسجلة')):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:lessons.length,itemBuilder:(_,i){final x=lessons[i] as Map<String,dynamic>;final t=x['teacher'];final s=x['student'];return Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(leading:const CircleAvatar(child:Icon(Icons.menu_book)),title:Text('${x['subject']??''}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${t is Map?t['name']??'': ''} • ${s is Map?s['name']??'حصة مجموعة':'حصة'}\n${x['starts_at']??''} → ${x['ends_at']??''}'),isThreeLine:true,trailing:Text('${x['teacher_due']??0}')));}));
  Widget _error()=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off,size:52),const SizedBox(height:12),Text(error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:load,child:const Text('إعادة المحاولة'))])));
}
