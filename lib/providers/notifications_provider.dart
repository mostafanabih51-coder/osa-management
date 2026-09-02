import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationsProvider extends ChangeNotifier {
  final ApiClient api;
  NotificationsProvider({required this.api});
  bool loading = false;
  String? error;
  List<NotificationModel> items = [];

  int get unreadCount => items.where((e) => !e.read).length;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      final res = await api.get('/notifications');
      final raw = res['data'] is List ? res['data'] : (res['notifications'] is List ? res['notifications'] : []);
      items = raw.whereType<Map>().map((e) => NotificationModel.fromJson(Map<String,dynamic>.from(e))).toList();
    } catch (e) { error = e.toString(); }
    loading = false; notifyListeners();
  }

  Future<void> markRead(NotificationModel n) async {
    if (n.read || n.id == 0) return;
    try { await api.put('/notifications/${n.id}/read'); } catch (_) {}
    final i = items.indexWhere((x) => x.id == n.id);
    if (i >= 0) { final old = items[i]; items[i] = NotificationModel(id: old.id,title: old.title,body: old.body,type: old.type,read:true,createdAt:old.createdAt); notifyListeners(); }
  }

  Future<void> markAllRead() async {
    try { await api.post('/notifications/read-all'); } catch (_) {}
    items = items.map((n) => NotificationModel(id:n.id,title:n.title,body:n.body,type:n.type,read:true,createdAt:n.createdAt)).toList(); notifyListeners();
  }
}
