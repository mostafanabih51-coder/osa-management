import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/attendance_provider.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AttendanceProvider(context.read<ApiClient>())..loadGroups(),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  const _AttendanceView();

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(builder: (context, p, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الحضور والغياب'),
          actions: [
            IconButton(onPressed: p.loading ? null : p.loadAttendance, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: Column(children: [
          _Filters(provider: p),
          if (p.error != null) Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(color: const Color(0xFFFFF3F3), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              const Icon(Icons.error_outline, color: AppTheme.primary), const SizedBox(width: 8),
              Expanded(child: Text(p.error!)),
              TextButton(onPressed: p.loadAttendance, child: const Text('إعادة')),
            ]))),
          ),
          Expanded(child: p.loading
              ? const Center(child: CircularProgressIndicator())
              : p.selectedGroupId == null
                  ? const _Empty(text: 'اختر مجموعة لعرض الحضور')
                  : p.records.isEmpty
                      ? const _Empty(text: 'لا توجد بيانات حضور لهذا اليوم')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: p.records.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _AttendanceTile(record: p.records[i], onStatus: (s) => p.setStatus(p.records[i].studentId, s)),
                        )),
        ]),
        floatingActionButton: p.records.isEmpty ? null : FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: p.saving ? null : () async {
            final ok = await p.saveAttendance();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'تم حفظ الحضور بنجاح' : (p.error ?? 'تعذر حفظ الحضور'))));
          },
          icon: p.saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
          label: const Text('حفظ الحضور'),
        ),
      );
    });
  }
}

class _Filters extends StatelessWidget {
  final AttendanceProvider provider;
  const _Filters({required this.provider});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    DropdownButtonFormField<int>(
      value: provider.selectedGroupId,
      decoration: const InputDecoration(labelText: 'المجموعة', prefixIcon: Icon(Icons.groups_rounded)),
      items: provider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
      onChanged: provider.setGroup,
    ),
    const SizedBox(height: 10),
    InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: provider.selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100), locale: const Locale('ar'));
        if (date != null) provider.setDate(date);
      },
      child: InputDecorator(decoration: const InputDecoration(labelText: 'التاريخ', prefixIcon: Icon(Icons.calendar_month_rounded)), child: Text('${provider.selectedDate.day}/${provider.selectedDate.month}/${provider.selectedDate.year}')),
    ),
  ])));
}

class _AttendanceTile extends StatelessWidget {
  final dynamic record;
  final ValueChanged<String> onStatus;
  const _AttendanceTile({required this.record, required this.onStatus});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const CircleAvatar(child: Icon(Icons.person_outline)), const SizedBox(width: 12), Expanded(child: Text(record.studentName.isEmpty ? 'طالب' : record.studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))]),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [
      _StatusChip('حاضر', 'present', record.status, onStatus),
      _StatusChip('غائب', 'absent', record.status, onStatus),
      _StatusChip('متأخر', 'late', record.status, onStatus),
      _StatusChip('معتذر', 'excused', record.status, onStatus),
    ]),
  ])));
}

class _StatusChip extends StatelessWidget {
  final String label, value, current; final ValueChanged<String> onTap;
  const _StatusChip(this.label, this.value, this.current, this.onTap);
  @override
  Widget build(BuildContext context) => ChoiceChip(label: Text(label), selected: current == value, onSelected: (_) => onTap(value));
}

class _Empty extends StatelessWidget { final String text; const _Empty({required this.text}); @override Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.shade400), const SizedBox(height: 12), Text(text, style: TextStyle(color: Colors.grey.shade600))])); }
