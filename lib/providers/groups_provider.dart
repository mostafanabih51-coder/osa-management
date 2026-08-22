import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/group_model.dart';
class GroupsProvider extends ChangeNotifier {
 final ApiClient api; GroupsProvider(this.api);
 List<GroupModel> groups=[]; bool loading=false,hasMore=false; String? error; int page=1; String search='';
 Future<void> load({String? query,bool append=false}) async { if(!append){page=1;groups=[];} loading=true;error=null;notifyListeners(); try{
  final q=<String,dynamic>{'page':page}; final term=query??search; if(term.trim().isNotEmpty)q['search']=term.trim();
  final response=await api.get(ApiEndpoints.groups,query:q); final raw=response['data']??response['groups']??response; List<dynamic> items=[];
  if(raw is List)items=raw; if(raw is Map&&raw['data'] is List)items=raw['data'];
  final parsed=items.whereType<Map>().map((e)=>GroupModel.fromJson(Map<String,dynamic>.from(e))).where((e)=>e.id>0).toList(); groups=append?[...groups,...parsed]:parsed;
  final meta=response['meta']??(raw is Map?raw['meta']:null); if(meta is Map){final cur=int.tryParse('${meta['current_page']??page}')??page;final last=int.tryParse('${meta['last_page']??cur}')??cur;hasMore=cur<last;}else{hasMore=parsed.length>=15;}
 } on ApiException catch(e){error=e.message;}catch(_){error='تعذر تحميل المجموعات.';} loading=false;notifyListeners(); }
 Future<bool> save({int? id,required Map<String,dynamic> data})async{try{if(id==null)await api.post(ApiEndpoints.groups,body:data);else await api.put('/groups/$id',body:data);await load(query:search);return true;}on ApiException catch(e){error=e.message;notifyListeners();return false;}}
 Future<bool> remove(int id)async{try{await api.delete('/groups/$id');await load(query:search);return true;}on ApiException catch(e){error=e.message;notifyListeners();return false;}}
}
