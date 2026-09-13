import 'package:flutter/material.dart';
import '../../services/api_service.dart';
class GroupsScreen extends StatefulWidget{const GroupsScreen({super.key});@override State<GroupsScreen> createState()=>_GroupsScreenState();}
class _GroupsScreenState extends State<GroupsScreen>{
 List groups=[],students=[],teachers=[],subjects=[],supervisors=[];bool loading=true;
 List<dynamic> list(dynamic x)=>x is List?List<dynamic>.from(x):(x is Map&&x['data'] is List?List<dynamic>.from(x['data']):[]);
 void msg(Object e)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{final r=await Future.wait([ApiService.get('groups'),ApiService.get('students'),ApiService.get('teachers'),ApiService.get('subjects'),ApiService.get('supervisors')]);if(mounted)setState((){groups=list(r[0]);students=list(r[1]);teachers=list(r[2]);subjects=list(r[3]);supervisors=list(r[4]);loading=false;});}catch(e){if(mounted){setState(()=>loading=false);msg(e);}}}
 Future<void> add()async{
  if(teachers.isEmpty||students.isEmpty||subjects.isEmpty){msg(Exception('أضف مدرسين وطلابًا ومواد أولًا'));return;}
  int teacherId=teachers.first['id'];String subject='${subjects.first}';int? supervisorId;final name=TextEditingController(),rate=TextEditingController();final selected=<int>{};final form=GlobalKey<FormState>();
  final ok=await showDialog<bool>(context:context,builder:(dc)=>StatefulBuilder(builder:(context,setD)=>AlertDialog(title:const Text('إضافة مجموعة'),content:SingleChildScrollView(child:Form(key:form,child:Column(children:[
   TextFormField(controller:name,decoration:const InputDecoration(labelText:'اسم المجموعة'),validator:(v)=>v==null||v.trim().isEmpty?'مطلوب':null),
   DropdownButtonFormField<int>(value:teacherId,decoration:const InputDecoration(labelText:'المدرس'),items:teachers.map((x)=>DropdownMenuItem<int>(value:x['id'] as int,child:Text('${x['name']}'))).toList(),onChanged:(v){if(v!=null)setD(()=>teacherId=v);}),
   DropdownButtonFormField<String>(value:subject,decoration:const InputDecoration(labelText:'المادة'),items:subjects.map((x)=>DropdownMenuItem<String>(value:'$x',child:Text('$x'))).toList(),onChanged:(v){if(v!=null)setD(()=>subject=v);}),
   TextField(controller:rate,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'سعر الحصة للمدرس')),
   if(supervisors.isNotEmpty)DropdownButtonFormField<int?>(value:supervisorId,decoration:const InputDecoration(labelText:'المشرف اختياري'),items:[const DropdownMenuItem<int?>(value:null,child:Text('بدون مشرف')),...supervisors.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text('${x['name']}')))],onChanged:(v)=>setD(()=>supervisorId=v)),
   const Align(alignment:Alignment.centerRight,child:Text('طلاب المجموعة',style:TextStyle(fontWeight:FontWeight.bold))),
   ...students.map((x)=>CheckboxListTile(dense:true,value:selected.contains(x['id']),title:Text('${x['name']}'),onChanged:(v)=>setD((){if(v==true){selected.add(x['id'] as int);}else{selected.remove(x['id']);}}))),
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('إلغاء')),FilledButton(onPressed:(){if(form.currentState!.validate()&&selected.isNotEmpty)Navigator.pop(dc,true);},child:const Text('حفظ'))])));
  if(ok==true){try{await ApiService.post('groups',{'name':name.text.trim(),'subject':subject,'teacher_id':teacherId,'supervisor_id':supervisorId,'teacher_rate':double.tryParse(rate.text)??0,'student_ids':selected.toList(),'status':'active'});await load();}catch(e){msg(e);}}name.dispose();rate.dispose();
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('المجموعات'),actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))]),floatingActionButton:FloatingActionButton(onPressed:add,child:const Icon(Icons.add)),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView.builder(padding:const EdgeInsets.all(16),itemCount:groups.length,itemBuilder:(_,i){final g=groups[i];return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.groups)),title:Text('${g['name']??''}'),subtitle:Text('المدرس: ${g['teacher']?['name']??''}\nالمادة: ${g['subject']??''} • الطلاب: ${g['students_count']??0} • سعر الحصة: ${g['teacher_rate']??0}'),isThreeLine:true));})));
}
