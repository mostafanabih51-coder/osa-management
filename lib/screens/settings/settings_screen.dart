import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget { const SettingsScreen({super.key}); @override State<SettingsScreen> createState()=>_SettingsScreenState(); }
class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications=true, sound=true, biometric=false;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){notifications=p.getBool('notifications')??true;sound=p.getBool('sound')??true;biometric=p.getBool('biometric')??false;});}
  Future<void> _set(String key,bool value) async {final p=await SharedPreferences.getInstance();await p.setBool(key,value);}
  Widget _section(String title,List<Widget> children)=>Padding(padding:const EdgeInsets.only(bottom:18),child:Card(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.fromLTRB(18,16,18,8),child:Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),),...children])));
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:ListView(padding:const EdgeInsets.all(16),children:[_section('التفضيلات',[SwitchListTile(value:notifications,onChanged:(v){setState(()=>notifications=v);_set('notifications',v);},activeColor:AppTheme.primary,title:const Text('الإشعارات'),subtitle:const Text('استقبال تنبيهات النظام')),SwitchListTile(value:sound,onChanged:(v){setState(()=>sound=v);_set('sound',v);},activeColor:AppTheme.primary,title:const Text('أصوات التنبيهات'),subtitle:const Text('تشغيل صوت عند وصول تنبيه')),SwitchListTile(value:biometric,onChanged:(v){setState(()=>biometric=v);_set('biometric',v);},activeColor:AppTheme.primary,title:const Text('الدخول السريع'),subtitle:const Text('تفضيل الدخول السريع عند توفره'))]),_section('حول التطبيق',[const ListTile(leading:Icon(Icons.info_outline),title:Text('OSA Management'),subtitle:Text('نظام إدارة Online School Academy')),ListTile(leading:const Icon(Icons.verified_outlined),title:const Text('إصدار التطبيق'),subtitle:const Text('1.8.0+9'))]) ]));
}
