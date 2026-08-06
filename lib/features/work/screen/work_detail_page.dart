import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../shift/screen/shift_detail_page.dart';
import '../../shift/screen/shift_form_page.dart';
import '../model/work_summary.dart';
import '../provider/work_provider.dart';

class WorkDetailPage extends StatefulWidget {
  final WorkSummary summary;
  const WorkDetailPage({super.key, required this.summary});

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<WorkProvider>().loadWorkDetail(widget.summary.work.id);
    });
  }

  Future<void> _newShift() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ShiftFormPage(work: widget.summary.work)),
    );
    if (mounted) context.read<WorkProvider>().loadWorkDetail(widget.summary.work.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Consumer<WorkProvider>(
      builder: (context, provider, _) {
        final shifts = provider.currentWorkShifts;
        final income = shifts.fold<double>(0, (sum, shift) => sum + shift.income);
        final expense = shifts.fold<double>(0, (sum, shift) => sum + shift.expense);
        final profit = income - expense;

        return Scaffold(
          appBar: AppBar(title: Text(widget.summary.work.name)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _newShift,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New shift'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              _WorkHero(summary: widget.summary),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _Stat(value: MoneyFormatter.format(income), label: 'Income')),
                  Expanded(child: _Stat(value: MoneyFormatter.format(expense), label: 'Expense', color: colors.error)),
                  Expanded(child: _Stat(value: MoneyFormatter.format(profit), label: 'Profit', color: profit >= 0 ? colors.primary : colors.error)),
                ],
              ),
              const SectionTitle(title: 'Shift history'),
              if (shifts.isEmpty)
                const EmptyState(
                  icon: Icons.event_note_rounded,
                  title: 'No shifts yet',
                  subtitle: 'Add your first shift to start building a work history.',
                )
              else
                ...shifts.map((shift) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShiftDetailPage(work: widget.summary.work, shift: shift),
                        ),
                      );
                      if (mounted) provider.loadWorkDetail(widget.summary.work.id);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.schedule_rounded, color: colors.onPrimaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${shift.startTime} - ${shift.endTime}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(_dateLabel(shift.workDate), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Text(MoneyFormatter.format(shift.profit), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: shift.profit >= 0 ? colors.primary : colors.error, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class _WorkHero extends StatelessWidget {
  final WorkSummary summary;
  const _WorkHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.work_history_rounded, size: 42, color: colors.onPrimaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.work.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: colors.onPrimaryContainer, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(summary.work.salaryTypeName, style: TextStyle(color: colors.onPrimaryContainer.withValues(alpha: 0.78))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const _Stat({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ],
  );
}

String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
