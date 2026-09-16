import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class AcademicTrackingScreen extends StatefulWidget {
  const AcademicTrackingScreen({super.key});

  @override
  State<AcademicTrackingScreen> createState() => _AcademicTrackingScreenState();
}

class _AcademicTrackingScreenState extends State<AcademicTrackingScreen> {
  List<dynamic> students = [];
  List<dynamic> plans = [];
  List<dynamic> evaluations = [];
  List<dynamic> resources = [];
  int? selectedId;
  bool loading = true;

  List<dynamic> list(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is Map && value['data'] is List) return List<dynamic>.from(value['data']);
    if (value is Map && value['data'] is Map && value['data']['data'] is List) {
      return List<dynamic>.from(value['data']['data']);
    }
    return [];
  }

  int id(dynamic value) => int.tryParse('${value['id']}') ?? 0;

  void msg(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      students = list(await ApiService.get('students'));
      if (students.isNotEmpty) {
        selectedId = id(students.first);
        await select(selectedId!);
      }
    } catch (e) {
      msg(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> select(int studentId) async {
    try {
      final response = await ApiService.get('academic/students/$studentId');
      final data = response is Map && response['data'] is Map ? response['data'] : response;
      if (!mounted) return;
      setState(() {
        selectedId = studentId;
        plans = list(data['plans']);
        evaluations = list(data['evaluations']);
        resources = list(data['resources']);
      });
    } catch (e) {
      msg(e);
    }
  }

  Future<void> openUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      msg('الرابط غير صالح');
    }
  }

  Future<void> editPlan(dynamic plan) async {
    final total = TextEditingController(text: '${plan['monthly_lessons'] ?? 4}');
    final completed = TextEditingController(text: '${plan['completed_lessons'] ?? 0}');
    final month = TextEditingController(
      text: '${plan['plan_month'] ?? DateTime.now().toString().substring(0, 7)}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${plan['subject'] ?? ''} - خطة الشهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: total,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد الحصص الشهرية'),
            ),
            TextField(
              controller: completed,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الحصص التي حضرها بالفعل'),
            ),
            TextField(
              controller: month,
              decoration: const InputDecoration(labelText: 'الشهر YYYY-MM'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true && selectedId != null) {
      try {
        await ApiService.put('academic/plans/${id(plan)}', {
          'monthly_lessons': int.tryParse(total.text) ?? 0,
          'completed_lessons': int.tryParse(completed.text) ?? 0,
          'plan_month': month.text.trim(),
        });
        await select(selectedId!);
      } catch (e) {
        msg(e);
      }
    }

    total.dispose();
    completed.dispose();
    month.dispose();
  }

  Future<void> addEvaluation() async {
    if (selectedId == null) return;
    final title = TextEditingController();
    final score = TextEditingController();
    final notes = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تقييم الطالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(
              controller: score,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الدرجة %'),
            ),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ApiService.post('academic/evaluations', {
          'student_id': selectedId,
          'title': title.text.trim(),
          'score': double.tryParse(score.text),
          'notes': notes.text.trim(),
          'evaluation_date': DateTime.now().toIso8601String().substring(0, 10),
        });
        await select(selectedId!);
      } catch (e) {
        msg(e);
      }
    }

    title.dispose();
    score.dispose();
    notes.dispose();
  }

  Future<void> addResource() async {
    if (selectedId == null) return;
    final title = TextEditingController();
    final url = TextEditingController();
    final description = TextEditingController();
    String type = 'link';
    File? pickedFile;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('واجب / امتحان / رابط / مرفق'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'link', child: Text('رابط')),
                        DropdownMenuItem(value: 'video', child: Text('فيديو')),
                        DropdownMenuItem(value: 'web', child: Text('صفحة ويب')),
                        DropdownMenuItem(value: 'homework', child: Text('واجب')),
                        DropdownMenuItem(value: 'exam', child: Text('امتحان')),
                        DropdownMenuItem(value: 'file', child: Text('مرفق')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => type = value);
                      },
                      decoration: const InputDecoration(labelText: 'نوع المحتوى'),
                    ),
                    const SizedBox(height: 8),
                    if (pickedFile == null)
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(withData: false);
                          final path = result?.files.single.path;
                          if (path != null) {
                            setDialogState(() {
                              pickedFile = File(path);
                              type = 'file';
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('اختيار ملف من الهاتف'),
                      )
                    else
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(pickedFile!.path.split(Platform.pathSeparator).last),
                        trailing: IconButton(
                          onPressed: () => setDialogState(() => pickedFile = null),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    TextField(
                      controller: url,
                      decoration: const InputDecoration(labelText: 'الرابط URL (اختياري)'),
                    ),
                    TextField(
                      controller: description,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'الوصف'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      try {
        if (pickedFile != null) {
          await ApiService.uploadAcademicResource(
            file: pickedFile!,
            studentId: selectedId!,
            type: type,
            title: title.text.trim(),
            description: description.text.trim(),
          );
        } else {
          await ApiService.post('academic/resources', {
            'student_id': selectedId,
            'type': type,
            'title': title.text.trim(),
            'url': url.text.trim().isEmpty ? null : url.text.trim(),
            'description': description.text.trim(),
            'published_on': DateTime.now().toIso8601String().substring(0, 10),
          });
        }
        await select(selectedId!);
      } catch (e) {
        msg(e);
      }
    }

    title.dispose();
    url.dispose();
    description.dispose();
  }

  Widget _resourceTile(dynamic resource) {
    final resourceUrl = '${resource['url'] ?? ''}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${resource['title'] ?? ''}'),
      subtitle: Text('${resource['type'] ?? ''} • ${resource['description'] ?? ''}'),
      trailing: resourceUrl.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => openUrl(resourceUrl),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('المتابعة الأكاديمية')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (students.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('المتابعة الأكاديمية')),
        body: const Center(child: Text('أضف طالبًا أولًا.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتابعة الأكاديمية'),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: selectedId,
              items: students
                  .map<DropdownMenuItem<int>>(
                    (student) => DropdownMenuItem<int>(
                      value: id(student),
                      child: Text('${student['name'] ?? ''}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) select(value);
              },
              decoration: const InputDecoration(
                labelText: 'الطالب',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilledButton.icon(
                    onPressed: addEvaluation,
                    icon: const Icon(Icons.star),
                    label: const Text('تقييم'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilledButton.icon(
                    onPressed: addResource,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('محتوى / مرفق'),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'خطة الحصص الشهرية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...plans.map(
                  (plan) => Card(
                    child: ListTile(
                      onTap: () => editPlan(plan),
                      title: Text('${plan['subject'] ?? ''}'),
                      subtitle: Text(
                        'المقرر: ${plan['monthly_lessons'] ?? 0} • حضر: ${plan['completed_lessons'] ?? 0} • متبقي: ${plan['remaining'] ?? 0}\nنسبة التنفيذ: ${plan['completion_percent'] ?? 0}%',
                      ),
                      trailing: const Icon(Icons.edit),
                    ),
                  ),
                ),
                const Divider(),
                const Text(
                  'التقييمات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...evaluations.map(
                  (evaluation) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${evaluation['title'] ?? 'تقييم'}'),
                    subtitle: Text(
                      'الدرجة: ${evaluation['score'] ?? '-'}% • ${evaluation['notes'] ?? ''}',
                    ),
                  ),
                ),
                const Divider(),
                const Text(
                  'الواجبات والامتحانات والمحتوى',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...resources.map(_resourceTile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
