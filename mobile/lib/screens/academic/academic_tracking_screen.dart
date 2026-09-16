import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class AcademicTrackingScreen extends StatefulWidget {
  const AcademicTrackingScreen({super.key});
  @override State<AcademicTrackingScreen> createState() => _AcademicTrackingScreenState();
}
class _AcademicTrackingScreenState extends State<AcademicTrackingScreen> {
  List students = [], plans = [], evaluations = [], resources = [];
  int? selectedId; bool loading = true;
  List<dynamic> list(dynamic x) { if (x is List) return List<dynamic>.from(x); if (x is Map && x['data'] is List) return List<dynamic>.from(x['data']); if (x is Map && x['data'] is Map && x['data']['data'] is List) return List<dynamic>.from(x['data']['data']); return []; }
  int id(dynamic x) => int.tryParse('${x['id']}') ?? 0;
  void msg(Object e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { try { students = list(await ApiService.get('students')); if (students.isNotEmpty) { selectedId = id(students.first); await select(selectedId!); } } catch (e) { if (mounted) msg(e); } if (mounted) setState(() => loading = false); }
  Future<void> select(int sid) async { try { final r = await ApiService.get('academic/students/$sid'); final d = r is Map && r['data'] is Map ? r['data'] : r; if (mounted) setState(() { selectedId = sid; plans = list(d['plans']); evaluations = list(d['evaluations']); resources = list(d['resources']); }); } catch (e) { if (mounted) msg(e); } }
  Future<void> openUrl(String raw) async { final u = Uri.tryParse(raw); if (u != null && await canLaunchUrl(u)) { await launchUrl(u, mode: LaunchMode.externalApplication); } else if (mounted) msg('الرابط غير صالح'); }
  Future<void> editPlan(dynamic p) async {
    final total = TextEditingController(text: '${p['monthly_lessons'] ?? 4}'); final done = TextEditingController(text: '${p['completed_lessons'] ?? 0}'); final month = TextEditingController(text: '${p['plan_month'] ?? DateTime.now().toString().substring(0, 7)}');
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: Text('${p['subject'] ?? ''} - خطة الشهر'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: total, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الحصص الشهرية')), TextField(controller: done, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحصص التي حضرها بالفعل')), TextField(controller: month, decoration: const InputDecoration(labelText: 'الشهر YYYY-MM'))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))]));
    if (ok == true) { try { await ApiService.put('academic/plans/${id(p)}', {'monthly_lessons': int.parse(total.text), 'completed_lessons': int.parse(done.text), 'plan_month': month.text}); await select(selectedId!); } catch (e) { if (mounted) msg(e); } }
    for (final c in [total, done, month]) c.dispose();
  }
  Future<void> addEvaluation() async {
    final title = TextEditingController(), score = TextEditingController(), notes = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('تقييم الطالب'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')), TextField(controller: score, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الدرجة %')), TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات'))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))]));
    if (ok == true) { try { await ApiService.post('academic/evaluations', {'student_id': selectedId, 'title': title.text, 'score': double.tryParse(score.text), 'notes': notes.text, 'evaluation_date': DateTime.now().toIso8601String().substring(0, 10)}); await select(selectedId!); } catch (e) { if (mounted) msg(e); } }
    for (final c in [title, score, notes]) c.dispose();
  }
  Future<void> addResource() async {
    final title = TextEditingController(), url = TextEditingController(), desc = TextEditingController(); String type = 'link';
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (c, set) => AlertDialog(title: const Text('واجب / امتحان / رابط'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')), DropdownButtonFormField<String>(value: type, items: const [DropdownMenuItem(value: 'link', child: Text('رابط')), DropdownMenuItem(value: 'video', child: Text('فيديو')), DropdownMenuItem(value: 'web', child: Text('صفحة ويب')), DropdownMenuItem(value: 'homework', child: Text('واجب')), DropdownMenuItem(value: 'exam', child: Text('امتحان')), DropdownMenuItem(value: 'file', child: Text('مرفق'))], onChanged: (v) { if (v != null) set(() => type = v); }), TextField(controller: url, decoration: const InputDecoration(labelText: 'الرابط URL')), TextField(controller: desc, decoration: const InputDecoration(labelText: 'الوصف'))]), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))])));
    if (ok == true) { try { await ApiService.post('academic/resources', {'student_id': selectedId, 'type': type, 'title': title.text, 'url': url.text.isEmpty ? null : url.text, 'description': desc.text, 'published_on': DateTime.now().toIso8601String().substring(0, 10)}); await select(selectedId!); } catch (e) { if (mounted) msg(e); } }
    for (final c in [title, url, desc]) c.dispose();
  }
  @override Widget build(BuildContext context) {
    if (loading) return Scaffold(appBar: AppBar(title: const Text('المتابعة الأكاديمية')), body: const Center(child: CircularProgressIndicator()));
    if (students.isEmpty) return Scaffold(appBar: AppBar(title: const Text('المتابعة الأكاديمية')), body: const Center(child: Text('أضف طالبًا أولًا.')));
    return Scaffold(appBar: AppBar(title: const Text('المتابعة الأكاديمية'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]), body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: DropdownButtonFormField<int>(value: selectedId, items: students.map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: id(s), child: Text('${s['name'] ?? ''}'))).toList(), onChanged: (v) { if (v != null) select(v); }, decoration: const InputDecoration(labelText: 'الطالب', border: OutlineInputBorder()))),
      Row(children: [Expanded(child: Padding(padding: const EdgeInsets.all(4), child: FilledButton.icon(onPressed: addEvaluation, icon: const Icon(Icons.star), label: const Text('تقييم')))), Expanded(child: Padding(padding: const EdgeInsets.all(4), child: FilledButton.icon(onPressed: addResource, icon: const Icon(Icons.attach_file), label: const Text('محتوى'))))]),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('خطة الحصص الشهرية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...plans.map((p) => Card(child: ListTile(onTap: () => editPlan(p), title: Text('${p['subject'] ?? ''}'), subtitle: Text('المقرر: ${p['monthly_lessons'] ?? 0} • حضر: ${p['completed_lessons'] ?? 0} • متبقي: ${p['remaining'] ?? 0}\nنسبة التنفيذ: ${p['completion_percent'] ?? 0}%'), trailing: const Icon(Icons.edit)))),
        const Divider(), const Text('التقييمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...evaluations.map((e) => ListTile(title: Text('${e['title'] ?? 'تقييم'}'), subtitle: Text('الدرجة: ${e['score'] ?? '-'}% • ${e['notes'] ?? ''}'))),
        const Divider(), const Text('الواجبات والامتحانات والمحتوى', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...resources.map((r) => ListTile(title: Text('${r['title'] ?? ''}'), subtitle: Text('${r['type'] ?? ''} • ${r['description'] ?? ''}'), trailing: r['url'] == null ? null : IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => openUrl('${r['url']}')))),
      ])),
    ]));
  }
}
