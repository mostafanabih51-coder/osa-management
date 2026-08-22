import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/students_provider.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});
  @override Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => StudentsProvider(context.read<ApiClient>())..load(), child: const _StudentsView());
}

class _StudentsView extends StatefulWidget { const _StudentsView(); @override State<_StudentsView> createState()=>_StudentsViewState(); }
class _StudentsViewState extends State<_StudentsView> {
  final search = TextEditingController();
  @override void dispose(){search.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final state = context.watch<StudentsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب'), actions:[IconButton(onPressed: state.loading?null:()=>state.load(query: search.text), icon:const Icon(Icons.refresh_rounded))]),
      floatingActionButton: FloatingActionButton.extended(onPressed:()=>_openForm(context), backgroundColor:AppTheme.primary, icon:const Icon(Icons.person_add_alt_1,color:Colors.white), label:const Text('إضافة طالب',style:TextStyle(color:Colors.white))),
      body: Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,12,16,8), child: TextField(controller:search, textInputAction:TextInputAction.search, onSubmitted:(_)=>state.load(query:search.text), decoration:InputDecoration(hintText:'ابحث باسم الطالب أو الهاتف أو البريد', prefixIcon:const Icon(Icons.search), suffixIcon:search.text.isEmpty?null:IconButton(onPressed:(){search.clear();state.load();setState((){});},icon:const Icon(Icons.clear))))),
        if(state.error!=null) Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(color:const Color(0xFFFFF3F3),child:ListTile(leading:const Icon(Icons.error_outline,color:AppTheme.primary),title:Text(state.error!),trailing:TextButton(onPressed:()=>state.load(query:search.text),child:const Text('إعادة'))))),
        Expanded(child: RefreshIndicator(onRefresh:()=>state.load(query:search.text), child: state.loading && state.students.isEmpty ? const Center(child:CircularProgressIndicator()) : state.students.isEmpty ? ListView(children:[const SizedBox(height:130),Icon(Icons.groups_outlined,size:60,color:Colors.grey),SizedBox(height:12),Center(child:Text('لا يوجد طلاب'))]) : ListView.separated(padding:const EdgeInsets.fromLTRB(16,8,16,100),itemCount:state.students.length + (state.hasMore?1:0),separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i){if(i==state.students.length){return Center(child:TextButton(onPressed:state.loading?null:(){state.page++;state.load(query:search.text,append:true);},child:const Text('تحميل المزيد')));} return _StudentCard(student:state.students[i], onEdit:()=>_openForm(context,student:state.students[i]), onDelete:()=>_delete(context,state.students[i]));})))
      ]));
  }

  Future<void> _openForm(BuildContext context,{StudentModel? student}) async { final result=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,showDragHandle:true,builder:(_)=>_StudentForm(student:student)); if(result==true && mounted) context.read<StudentsProvider>().load(query:search.text); }
  Future<void> _delete(BuildContext context,StudentModel student) async { final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('حذف الطالب'),content:Text('هل تريد حذف ${student.name}؟'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('إلغاء')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('حذف'))])); if(ok==true && context.mounted){final done=await context.read<StudentsProvider>().remove(student.id); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(done?'تم حذف الطالب':'تعذر حذف الطالب')));}}
}

class _StudentCard extends StatelessWidget { final StudentModel student; final VoidCallback onEdit,onDelete; const _StudentCard({required this.student,required this.onEdit,required this.onDelete});
  @override Widget build(BuildContext context)=>Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:8),leading:CircleAvatar(backgroundColor:const Color(0xFFFFE8EA),child:Text(student.name.trim().isEmpty?'؟':student.name.trim()[0],style:const TextStyle(color:AppTheme.primary,fontWeight:FontWeight.w900))),title:Text(student.name,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text([if(student.phone.isNotEmpty)student.phone,if(student.grade.isNotEmpty)student.grade,if(student.email.isNotEmpty)student.email].join(' • ')),trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?onEdit():onDelete(),itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('تعديل')),PopupMenuItem(value:'delete',child:Text('حذف'))])));
}

class _StudentForm extends StatefulWidget { final StudentModel? student; const _StudentForm({this.student}); @override State<_StudentForm> createState()=>_StudentFormState(); }
class _StudentFormState extends State<_StudentForm>{
  final form=GlobalKey<FormState>(); late final TextEditingController name,email,phone,grade; bool saving=false;
  @override void initState(){super.initState();final s=widget.student;name=TextEditingController(text:s?.name??'');email=TextEditingController(text:s?.email??'');phone=TextEditingController(text:s?.phone??'');grade=TextEditingController(text:s?.grade??'');}
  @override void dispose(){name.dispose();email.dispose();phone.dispose();grade.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(left:16,right:16,bottom:MediaQuery.viewInsetsOf(context).bottom+16),child:SingleChildScrollView(child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(widget.student==null?'إضافة طالب':'تعديل بيانات الطالب',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:16),TextFormField(controller:name,decoration:const InputDecoration(labelText:'اسم الطالب',prefixIcon:Icon(Icons.person_outline)),validator:(v)=>v==null||v.trim().isEmpty?'اكتب اسم الطالب':null),const SizedBox(height:10),TextFormField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'رقم الهاتف',prefixIcon:Icon(Icons.phone_outlined))),const SizedBox(height:10),TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'البريد الإلكتروني',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:10),TextFormField(controller:grade,decoration:const InputDecoration(labelText:'الصف / المستوى',prefixIcon:Icon(Icons.school_outlined))),const SizedBox(height:18),SizedBox(height:50,child:FilledButton(onPressed:saving?null:_save,child:saving?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(widget.student==null?'إضافة الطالب':'حفظ التعديلات')))]))));
  Future<void> _save() async {if(!form.currentState!.validate())return;setState(()=>saving=true);final ok=await context.read<StudentsProvider>().save(id:widget.student?.id,data:{'name':name.text.trim(),'phone':phone.text.trim(),'email':email.text.trim(),'grade':grade.text.trim()});if(!mounted)return;if(ok)Navigator.pop(context,true);else{setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.read<StudentsProvider>().error??'تعذر الحفظ')));}}
}
