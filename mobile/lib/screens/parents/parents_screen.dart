import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
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

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    if (value is Map && value['data'] is Map && value['data']['data'] is List) {
      return List<dynamic>.from(value['data']['data']);
    }
    return [];
  }

  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;

  String names(dynamic value, String key) {
    return list(value)
        .map((item) => item is Map ? '${item[key] ?? item['name'] ?? ''}' : '$item')
        .where((name) => name.isNotEmpty)
        .join('، ');
  }

  void msg(Object exception) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$exception'.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() => loading = true);
    try {
      students = list(await ApiService.get('students'));
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = '$e'.replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => loading = false);
  }

  List<_ParentGroup> groups() {
    final grouped = <String, _ParentGroup>{};
    for (final raw in students) {
      if (raw is! Map) continue;
      final name = '${raw['parent_name'] ?? ''}'.trim();
      final phone = '${raw['parent_phone'] ?? ''}'.trim();
      if (name.isEmpty && phone.isEmpty) continue;

      final key = '${phone.toLowerCase()}|${name.toLowerCase()}';
      grouped.putIfAbsent(
        key,
        () => _ParentGroup(name.isEmpty ? 'ولي أمر بدون اسم' : name, phone, []),
      ).children.add(raw);
    }

    final result = grouped.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<void> openUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      msg('الرابط غير صالح');
    }
  }

  Future<void> details(_ParentGroup parent) async {
    final loaded = <dynamic>[];
    for (final child in parent.children) {
      try {
        final response = await ApiService.get('academic/students/${id(child)}');
        loaded.add(
          response is Map && response['data'] is Map ? response['data'] : response,
        );
      } catch (_) {
        loaded.add(child);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(parent.name),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (parent.phone.isNotEmpty) Text('هاتف ولي الأمر: ${parent.phone}'),
                Text(
                  'عدد الأبناء: ${loaded.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...loaded.map((childData) {
                  final map = childData is Map ? childData : <String, dynamic>{};
                  final student = map['student'] is Map ? map['student'] : map;
                  final resources = list(map['resources']);
                  final evaluations = list(map['evaluations']);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${student['name'] ?? 'طالب'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('الصف: ${student['grade'] ?? '-'}'),
                          Text('المواد: ${names(student['subjects'], 'subject')}'),
                          Text('المدرسون: ${names(student['teachers'], 'name')}'),
                          Text('المجموعات: ${names(student['groups'], 'name')}'),
                          Text(
                            'الحصص: ${list(student['lessons']).length} • الاشتراكات: ${list(student['subscriptions']).length} • المدفوعات: ${list(student['payments']).length}',
                          ),
                          if (evaluations.isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              'التقييمات',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...evaluations.map(
                              (evaluation) => Text(
                                '• ${evaluation['title'] ?? 'تقييم'} — ${evaluation['score'] ?? '-'}%',
                              ),
                            ),
                          ],
                          if (resources.isNotEmpty) ...[
                            const Divider(),
                            const Text(
                              'الواجبات والامتحانات والروابط والمرفقات',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...resources.map(
                              (resource) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${resource['title'] ?? ''}'),
                                subtitle: Text(
                                  '${resource['type'] ?? ''} • ${resource['description'] ?? ''}',
                                ),
                                trailing: resource['url'] == null
                                    ? null
                                    : IconButton(
                                        onPressed: () => openUrl('${resource['url']}'),
                                        icon: const Icon(Icons.open_in_new),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parents = groups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('أولياء الأمور'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: parents.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 180),
                            Center(child: Text('لا يوجد أولياء أمور مسجلون.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: parents.length,
                          itemBuilder: (context, index) {
                            final parent = parents[index];
                            return Card(
                              child: ListTile(
                                onTap: () => details(parent),
                                leading: const CircleAvatar(
                                  child: Icon(Icons.family_restroom),
                                ),
                                title: Text(parent.name),
                                subtitle: Text(
                                  '${parent.phone.isEmpty ? 'بدون هاتف' : parent.phone} • ${parent.children.length} ${parent.children.length == 1 ? 'ابن' : 'أبناء'}',
                                ),
                                trailing: const Icon(Icons.chevron_left),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
