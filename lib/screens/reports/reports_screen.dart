import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/reports_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReportsProvider(
        context.read(),
      )..load(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            onPressed: provider.loading
                ? null
                : () => provider.load(),
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PeriodSelector(provider),

            const SizedBox(height: 12),

            if (provider.error != null)
              _ErrorBanner(
                provider.error!,
                provider.load,
              ),

            if (provider.loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            _FinancialSummary(provider.data),

            const SizedBox(height: 14),

            _AttendanceSummary(provider.data),

            const SizedBox(height: 14),

            _CountsSummary(provider.data),

            if (provider.data.items.isNotEmpty) ...[
              const SizedBox(height: 18),

              const Text(
                'تفاصيل التقرير',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              ...provider.data.items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(
                      item.label,
                    ),
                    trailing: Text(
                      item.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ReportsProvider provider;

  const _PeriodSelector(this.provider);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: provider.period,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'day',
                child: Text('اليوم'),
              ),
              DropdownMenuItem(
                value: 'week',
                child: Text('هذا الأسبوع'),
              ),
              DropdownMenuItem(
                value: 'month',
                child: Text('هذا الشهر'),
              ),
              DropdownMenuItem(
                value: 'year',
                child: Text('هذا العام'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                provider.setPeriod(value);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  final dynamic data;

  const _FinancialSummary(this.data);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'الماليات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _Metric(
                  'الإيرادات',
                  data.revenue,
                ),
                _Metric(
                  'المحصّل',
                  data.collected,
                ),
                _Metric(
                  'المتبقي',
                  data.outstanding,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;

  const _Metric(
    this.label,
    this.value,
  );

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  final dynamic data;

  const _AttendanceSummary(this.data);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'الحضور',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _AttendanceItem(
                  'حاضر',
                  data.present,
                  Colors.green,
                ),
                _AttendanceItem(
                  'غائب',
                  data.absent,
                  AppTheme.primary,
                ),
                _AttendanceItem(
                  'متأخر',
                  data.late,
                  Colors.orange,
                ),
                _AttendanceItem(
                  'معتذر',
                  data.excused,
                  Colors.blueGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AttendanceItem(
    this.label,
    this.value,
    this.color,
  );

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(
              alpha: 0.12,
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(label),
        ],
      ),
    );
  }
}

class _CountsSummary extends StatelessWidget {
  final dynamic data;

  const _CountsSummary(this.data);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _CountCard(
          'الطلاب',
          data.students,
          Icons.groups_rounded,
        ),
        _CountCard(
          'المدرسون',
          data.teachers,
          Icons.person_rounded,
        ),
        _CountCard(
          'الكورسات',
          data.courses,
          Icons.menu_book_rounded,
        ),
        _CountCard(
          'المجموعات',
          data.groups,
          Icons.class_rounded,
        ),
        _CountCard(
          'الاشتراكات النشطة',
          data.activeSubscriptions,
          Icons.card_membership_rounded,
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _CountCard(
    this.label,
    this.value,
    this.icon,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primary,
        ),
        title: Text(
          '$value',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        subtitle: Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner(
    this.message,
    this.onRetry,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3F3),
      child: ListTile(
        leading: const Icon(
          Icons.error_outline,
          color: AppTheme.primary,
        ),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('إعادة'),
        ),
      ),
    );
  }
}
