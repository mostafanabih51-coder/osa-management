import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscriptions_provider.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => SubscriptionsProvider(c.read())..load(),
    child: const _SubscriptionsView(),
  );
}

class _SubscriptionsView extends StatefulWidget {
  const _SubscriptionsView();
  @override State<_SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<_SubscriptionsView> {
  final search = TextEditingController();
  @override void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SubscriptionsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراكات والمدفوعات'), actions: [
        IconButton(onPressed: s.loading ? null : () => s.load(search: search.text), icon: const Icon(Icons.refresh_rounded)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        onPressed: () => _form(context), icon: const Icon(Icons.add), label: const Text('اشتراك جديد'),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), child: TextField(
          controller: search, textInputAction: TextInputAction.search,
          onSubmitted: (_) => s.load(search: search.text),
          decoration: InputDecoration(hintText: 'ابحث باسم الطالب أو الكورس', prefixIcon: const Icon(Icons.search), suffixIcon: search.text.isEmpty ? null : IconButton(onPressed: () { search.clear(); s.load(); setState(() {}); }, icon: const Icon(Icons.clear))),
        )),
        SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          _filter(context, s, '', 'الكل'), _filter(context, s, 'active', 'نشط'), _filter(context, s, 'expired', 'منتهي'), _filter(context, s, 'pending', 'معلق'),
        ])),
        Expanded(child: RefreshIndicator(
          onRefresh: () => s.load(search: search.text),
          child: s.loading && s.subscriptions.isEmpty ? const Center(child: CircularProgressIndicator()) :
            s.error != null && s.subscriptions.isEmpty ? _Error(s.error!, () => s.load(search: search.text)) :
            s.subscriptions.isEmpty ? const _Empty() : NotificationListener<ScrollNotification>(
              onNotification: (n) { if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300 && s.hasMore && !s.loading) { s.page++; s.load(search: search.text, append: true); } return false; },
              child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), itemCount: s.subscriptions.length + (s.hasMore ? 1 : 0), separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
                if (i == s.subscriptions.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                final item = s.subscriptions[i];
                return _SubscriptionCard(item, onEdit: () => _form(context, item: item), onDelete: () => _delete(context, item));
              }),
            ),
        )),
      ]),
    );
  }

  Widget _filter(BuildContext context, SubscriptionsProvider s, String value, String label) => Padding(padding: const EdgeInsetsDirectional.only(end: 8, top: 5, bottom: 5), child: ChoiceChip(label: Text(label), selected: s.status == value, onSelected: (_) => s.setStatus(value)));

  Future<void> _form(BuildContext context, {SubscriptionModel? item}) async {
    final student = TextEditingController(text: item?.studentId == 0 ? '' : item!.studentId.toString());
    final course = TextEditingController(text: item?.courseId == 0 ? '' : item!.courseId.toString());
    final amount = TextEditingController(text: item?.amount == 0 ? '' : item!.amount.toString());
    final paid = TextEditingController(text: item?.paid == 0 ? '' : item!.paid.toString());
    final start = TextEditingController(text: item?.startDate ?? '');
    final end = TextEditingController(text: item?.endDate ?? '');
    final notes = TextEditingController(text: item?.notes ?? '');
    String status = item?.status.isNotEmpty == true ? item!.status : 'active';
    final key = GlobalKey<FormState>();
    await showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (sheet) => StatefulBuilder(builder: (sheet, setSheet) => Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheet).viewInsets.bottom + 20),
      child: Form(key: key, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(item == null ? 'إضافة اشتراك' : 'تعديل الاشتراك', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 18),
        _field(student, 'رقم الطالب', Icons.person_outline, true), _field(course, 'رقم الكورس', Icons.menu_book_outlined, true),
        Row(children: [Expanded(child: _field(amount, 'إجمالي المبلغ', Icons.payments_outlined, true)), const SizedBox(width: 10), Expanded(child: _field(paid, 'المدفوع', Icons.account_balance_wallet_outlined, false))]),
        DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'حالة الاشتراك', prefixIcon: Icon(Icons.flag_outlined)), items: const [DropdownMenuItem(value: 'active', child: Text('نشط')), DropdownMenuItem(value: 'pending', child: Text('معلق')), DropdownMenuItem(value: 'expired', child: Text('منتهي')), DropdownMenuItem(value: 'cancelled', child: Text('ملغي'))], onChanged: (v) => setSheet(() => status = v ?? 'active')),
        const SizedBox(height: 12), Row(children: [Expanded(child: _field(start, 'تاريخ البداية', Icons.date_range_outlined, false)), const SizedBox(width: 10), Expanded(child: _field(end, 'تاريخ النهاية', Icons.event_outlined, false))]),
        _field(notes, 'ملاحظات', Icons.notes_outlined, false, maxLines: 3), const SizedBox(height: 18),
        FilledButton.icon(onPressed: () async { if (!key.currentState!.validate()) return; final ok = await context.read<SubscriptionsProvider>().save(id: item?.id, data: {'student_id': int.tryParse(student.text.trim()) ?? 0, 'course_id': int.tryParse(course.text.trim()) ?? 0, 'amount': num.tryParse(amount.text.trim()) ?? 0, 'paid_amount': num.tryParse(paid.text.trim()) ?? 0, 'status': status, 'start_date': start.text.trim(), 'end_date': end.text.trim(), 'notes': notes.text.trim()}); if (ok && sheet.mounted) Navigator.pop(sheet); }, icon: const Icon(Icons.save_outlined), label: const Text('حفظ الاشتراك')),
      ])))),
    ));
    for (final c in [student, course, amount, paid, start, end, notes]) c.dispose();
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool required, {int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: c, maxLines: maxLines, keyboardType: label.contains('مبلغ') || label.contains('رقم') ? TextInputType.number : null, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)), validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null : null));

  Future<void> _delete(BuildContext context, SubscriptionModel item) async {
    final yes = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('حذف الاشتراك'), content: Text('هل تريد حذف اشتراك ${item.studentName.isEmpty ? 'الطالب' : item.studentName}؟'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف'))]));
    if (yes == true && context.mounted) { final ok = await context.read<SubscriptionsProvider>().remove(item.id); if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<SubscriptionsProvider>().error ?? 'تعذر الحذف'))); }
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel item; final VoidCallback onEdit, onDelete;
  const _SubscriptionCard(this.item, {required this.onEdit, required this.onDelete});
  @override Widget build(BuildContext context) {
    final remaining = item.remaining;
    return Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), leading: CircleAvatar(radius: 26, backgroundColor: const Color(0xFFFFE8EA), child: const Icon(Icons.card_membership, color: AppTheme.primary)), title: Text(item.studentName.isEmpty ? 'طالب #${item.studentId}' : item.studentName, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text([item.courseName.isEmpty ? 'كورس #${item.courseId}' : item.courseName, 'الإجمالي ${item.amount} جنيه', 'المتبقي $remaining جنيه'].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis)), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') onEdit(); else onDelete(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))])));
  }
}
class _Empty extends StatelessWidget { const _Empty(); @override Widget build(BuildContext c) => ListView(children: const [SizedBox(height: 100), Icon(Icons.card_membership_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Center(child: Text('لا توجد اشتراكات'))]); }
class _Error extends StatelessWidget { final String m; final VoidCallback r; const _Error(this.m, this.r); @override Widget build(BuildContext c) => ListView(children: [const SizedBox(height: 100), const Icon(Icons.cloud_off_outlined, size: 52), const SizedBox(height: 10), Center(child: Text(m)), TextButton(onPressed: r, child: const Text('إعادة المحاولة'))]); }
