import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/subscription_model.dart';

class SubscriptionsProvider extends ChangeNotifier {
  final ApiClient api;
  SubscriptionsProvider(this.api);

  final List<SubscriptionModel> subscriptions = [];
  bool loading = false;
  bool saving = false;
  bool hasMore = false;
  int page = 1;
  String? error;
  String query = '';
  String status = '';

  Future<void> load({String? search, bool append = false}) async {
    if (loading) return;
    if (!append) page = 1;
    query = search ?? query;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final response = await api.get(ApiEndpoints.subscriptions, query: {
        'page': page,
        'per_page': 20,
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (status.isNotEmpty) 'status': status,
      });
      final raw = response['data'] ?? response['subscriptions'] ?? response;
      List<dynamic> items = [];
      int? lastPage;
      if (raw is List) items = raw;
      if (raw is Map) {
        if (raw['data'] is List) items = raw['data'];
        final meta = raw['meta'];
        if (meta is Map) lastPage = int.tryParse('${meta['last_page'] ?? ''}');
      }
      final parsed = items.whereType<Map>().map((e) => SubscriptionModel.fromJson(Map<String, dynamic>.from(e))).where((e) => e.id > 0).toList();
      if (append) {
        subscriptions.addAll(parsed);
      } else {
        subscriptions
          ..clear()
          ..addAll(parsed);
      }
      hasMore = lastPage != null ? page < lastPage : parsed.length >= 20;
    } on ApiException catch (e) {
      error = e.message;
      if (!append) subscriptions.clear();
    } catch (_) {
      error = 'تعذر تحميل الاشتراكات.';
      if (!append) subscriptions.clear();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save({int? id, required Map<String, dynamic> data}) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      if (id == null) {
        await api.post(ApiEndpoints.subscriptions, body: data);
      } else {
        await api.put('${ApiEndpoints.subscriptions}/$id', body: data);
      }
      await load(search: query);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'تعذر حفظ الاشتراك.';
      notifyListeners();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> remove(int id) async {
    try {
      await api.delete('${ApiEndpoints.subscriptions}/$id');
      subscriptions.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void setStatus(String value) {
    status = value;
    load(search: query);
  }
}
