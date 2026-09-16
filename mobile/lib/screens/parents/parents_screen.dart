import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});
  @override State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentGroup {
  final String name;
  final String phone;
  final List<dynamic> children;
  _ParentGroup(this.name, this.phone, this.children);
}

class _ParentsScreenState extends State<ParentsScreen> {
  List<dynamic> students = [];
  bool loading = true;
  String? error;

  List<dynamic> list(dynamic x) {
    if (x is List) return List<dynamic>.from(x);
    if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']);
    if (x is Map && x['data'] is Map && x['data']['data'] is List) return List<dynamic>.from(x['data']['data']);
    return [];
  }

  int id(dynamic x) => int.tryParse('${x['id']}') ?? 0;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      final r = await ApiService.get('students');
      if (mounted) setState(() { students = list(r); loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  List<_ParentGroup> groups() {
    final map = <String, _ParentGroup>{};
    for (final raw in students) {
      if (raw is! Map) continue;
      final name = '${raw['parent_name'] ?? ''}'.trim();
      final phone = '${raw['parent_phone'] ?? ''}'.trim();
      if (name.isEmpty && phone.isEmpty) continue;
      final key = '${phone.toLowerCase()}|${name.toLowerCase()}';
      map.putIfAbsent(key, () => _ParentGroup(name.isEmpty ? 'ولي أمر بدون اسم' : name, phone, []));
      map[key]!.children.add(raw);
    }
    final result = map.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  String names(dynamic value, String key) {
    return list(value).map((x) => x is Map ? '${x[key] ?? x['name'] ?? ''}' : '$x').where((x) => x.isNotEmpty).join('، ');
  }

  Future<void> details(_ParentGroup parent) async {
    final loaded = <dynamic>[];
    for (final child in parent.children) {
      try {
        final r = await ApiService.get('students/${id(child)}');
        loaded.add(r is Map && r['data'] is Map ? r['data'] : r);
      } catch (_) {
        loaded.add(child);
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.family_restroom),
          const SizedBox(width: 8),
          Expanded(child: Text(parent.name)),
        ]),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (parent.phone.isNotEmpty) Text('هاتف ولي الأمر: ${parent.phone}'),
                const SizedBox(height: 12),
                Text('عدد الأبناء: ${loaded.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 8),
                ...loaded.map((c) {
                  final m = c is Map ? c : <String, dynamic>{};
                  final subjects = names(m['subjects'], 'subject');
                  final teachers = names(m['teachers'], 'name');
                  final groups = names(m['groups'], 'name');
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${m['name'] ?? 'طالب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'الصف: ${m['grade'] ?? '-'}\n'
                        'المواد: ${subjects.isEmpty ? '-' : subjects}\n'
                        'المدرسون: ${teachers.isEmpty ? '-' : teachers}\n'
                        'المجموعات: ${groups.isEmpty ? '-' : groups}\n'
                        'الحصص: ${list(m['lessons']).length} • الاشتراكات: ${list(m['subscriptions']).length} • المدفوعات: ${list(m['payments']).length}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('إغلاق'))],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final parents = groups();
    return Scaffold(
      appBar: AppBar(title: const Text('أولياء الأمور'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), const SizedBox(height: 12), FilledButton(onPressed: load, child: const Text('إعادة المحاولة'))]))
              : RefreshIndicator(
                  onRefresh: load,
                  child: parents.isEmpty
                      ? ListView(children: const [SizedBox(height: 180), Center(child: Text('لا يوجد أولياء أمور مسجلون. أضف اسم ولي الأمر في بيانات الطلاب.'))])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                          itemCount: parents.length,
                          itemBuilder: (_, i) {
                            final p = parents[i];
                            return Card(
                              child: ListTile(
                                onTap: () => details(p),
                                leading: const CircleAvatar(child: Icon(Icons.family_restroom)),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p.phone.isEmpty ? 'بدون هاتف' : p.phone} • ${p.children.length} ${p.children.length == 1 ? 'ابن' : 'أبناء'}'),
                                trailing: const Icon(Icons.chevron_left),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
