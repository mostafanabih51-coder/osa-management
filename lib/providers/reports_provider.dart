import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/report_model.dart';
class ReportsProvider extends ChangeNotifier {
 final ApiClient api; ReportsProvider(this.api);
 bool loading=false; String? error; ReportSummary data=ReportSummary.empty; String period='month';
 Future<void> load({String? from,String? to}) async { loading=true; error=null; notifyListeners(); try { final q=<String,dynamic>{'period':period,if(from!=null)'from':from,if(to!=null)'to':to}; final res=await api.get(ApiEndpoints.reports,query:q); data=ReportSummary.fromJson(res); } catch(e){error=e.toString();} finally {loading=false;notifyListeners();} }
 void setPeriod(String value){period=value;load();}
}
