import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => NotificationsProvider(api: context.read<ApiClient>())..load(),
    child: const _NotificationsView(),
  );
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإشعارات'), actions: [IconButton(tooltip:'تحديد الكل كمقروء', onPressed: () => context.read<NotificationsProvider>().markAllRead(), icon: const Icon(Icons.done_all_rounded))]),
    body: Consumer<NotificationsProvider>(builder: (context,p,_){
      if(p.loading && p.items.isEmpty) return const Center(child:CircularProgressIndicator());
      if(p.error != null && p.items.isEmpty) return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.cloud_off_rounded,size:52),const SizedBox(height:12),Text(p.error!,textAlign:TextAlign.center),const SizedBox(height:16),FilledButton(onPressed:p.load,child:const Text('إعادة المحاولة'))])));
      if(p.items.isEmpty) return RefreshIndicator(onRefresh:p.load,child:ListView(children:[SizedBox(height:180),Icon(Icons.notifications_none_rounded,size:70,color:AppTheme.primary),const SizedBox(height:12),const Center(child:Text('لا توجد إشعارات حاليًا'))]));
      return RefreshIndicator(onRefresh:p.load,child:ListView.separated(padding:const EdgeInsets.all(16),itemCount:p.items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,i){final n=p.items[i];return Card(child:ListTile(onTap:()=>p.markRead(n),leading:CircleAvatar(backgroundColor:n.read?Colors.black12:AppTheme.primary.withOpacity(.12),child:Icon(n.read?Icons.notifications_none:Icons.notifications_active,color:n.read?Colors.black54:AppTheme.primary)),title:Text(n.title,style:TextStyle(fontWeight:n.read?FontWeight.w600:FontWeight.w800)),subtitle:Padding(padding:const EdgeInsets.only(top:6),child:Text(n.body)),trailing:n.read?null:Container(width:9,height:9,decoration:const BoxDecoration(color:AppTheme.primary,shape:BoxShape.circle))));}));
    }),
  );
}
