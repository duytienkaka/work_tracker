import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../work/model/work_model.dart';
import '../../work/provider/work_provider.dart';
import '../model/shift_model.dart';
import '../provider/shift_provider.dart';
import 'shift_detail_page.dart';
import 'shift_form_page.dart';

class ShiftListPage extends StatefulWidget {
  final Work? work;
  const ShiftListPage({super.key, this.work});

  @override
  State<ShiftListPage> createState() => _ShiftListPageState();
}

class _ShiftListPageState extends State<ShiftListPage> {
  String query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ShiftProvider>().load(widget.work?.id);
      context.read<WorkProvider>().loadWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShiftProvider>();
    final works = context.watch<WorkProvider>().works;
    final colors = Theme.of(context).colorScheme;
    final shifts = provider.shifts.where((shift) {
      if (query.trim().isEmpty) return true;
      final work = _workFor(shift, works);
      final text = '${work?.name ?? ''} ${shift.workDate} ${shift.note}'.toLowerCase();
      return text.contains(query.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.work?.name ?? 'All shifts')),
      body: RefreshIndicator(
        onRefresh: () => provider.load(widget.work?.id),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Search shifts',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (shifts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: EmptyState(
                    icon: Icons.event_note_rounded,
                    title: 'No shifts found',
                    subtitle: 'Create a shift to start tracking your workday.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shift = shifts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ShiftCard(
                          shift: shift,
                          work: _workFor(shift, works),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShiftDetailPage(
                                  work: _workFor(shift, works),
                                  shift: shift,
                                ),
                              ),
                            );
                            if (mounted) provider.load(widget.work?.id);
                          },
                        ),
                      );
                    },
                    childCount: shifts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: widget.work == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ShiftFormPage(work: widget.work)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New shift'),
            ),
    );
  }
}

Work? _workFor(Shift shift, List<Work> works) {
  for (final work in works) {
    if (work.id == shift.workId) return work;
  }
  return null;
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;
  final Work? work;
  final VoidCallback onTap;
  const _ShiftCard({required this.shift, required this.work, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = _status(shift);
    final profitColor = shift.profit >= 0 ? colors.primary : colors.error;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(work?.name ?? 'Work shift', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${_date(shift.workDate)}  ·  ${shift.startTime} - ${shift.endTime.isEmpty ? 'In progress' : shift.endTime}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Value(label: 'Income', value: MoneyFormatter.format(shift.income), color: colors.primary)),
              Expanded(child: _Value(label: 'Expense', value: MoneyFormatter.format(shift.expense), color: colors.error)),
              Expanded(child: _Value(label: 'Profit', value: MoneyFormatter.format(shift.profit), color: profitColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Value({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800))]);
}

String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _status(Shift shift) {
  final now = DateTime.now();
  final start = shift.startDateTime;
  final end = shift.endDateTime;
  if (start != null && now.isBefore(start)) return 'Upcoming';
  if (end == null && start != null && now.isAfter(start)) return 'In progress';
  if (end != null && now.isAfter(end)) return 'Completed';
  return 'Scheduled';
}
