import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../model/timeline_item.dart';
import '../provider/timeline_provider.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<TimelineProvider>().loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Consumer<TimelineProvider>(
      builder: (context, provider, _) {
        final item = _itemFor(provider.timeline, selectedDate);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              IconButton(
                tooltip: 'Today',
                onPressed: () => setState(() => selectedDate = DateTime.now()),
                icon: const Icon(Icons.today_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  _monthLabel(selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan your work week',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _WeekStrip(
                  selectedDate: selectedDate,
                  items: provider.timeline,
                  onSelected: (date) => setState(() => selectedDate = date),
                ),
                const SizedBox(height: 24),
                if (item == null || item.shifts.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'Nothing planned',
                      subtitle: 'Your shifts for this day will appear here.',
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateLabel(selectedDate),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${item.shifts.length} shifts', style: TextStyle(color: colors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DaySummary(item: item),
                  const SizedBox(height: 16),
                  ...item.shifts.map((shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 52,
                            decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(8)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${shift.startTime} - ${shift.endTime.isEmpty ? 'In progress' : shift.endTime}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(shift.note.isEmpty ? 'No note' : shift.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text(MoneyFormatter.format(shift.profit), style: TextStyle(color: shift.profit >= 0 ? colors.primary : colors.error, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<TimelineItem> items;
  final ValueChanged<DateTime> onSelected;
  const _WeekStrip({required this.selectedDate, required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final start = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return Row(
      children: List.generate(7, (index) {
        final date = DateTime(start.year, start.month, start.day + index);
        final selected = _sameDay(date, selectedDate);
        final hasShift = _itemFor(items, date)?.shifts.isNotEmpty == true;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selected ? colors.primary : colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text(_weekday(date), style: TextStyle(color: selected ? colors.onPrimary : colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${date.day}', style: TextStyle(color: selected ? colors.onPrimary : colors.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: hasShift ? (selected ? colors.onPrimary : colors.primary) : Colors.transparent, shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DaySummary extends StatelessWidget {
  final TimelineItem item;
  const _DaySummary({required this.item});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Expanded(child: _SummaryValue(label: 'Income', value: MoneyFormatter.format(item.income), color: colors.primary)),
          Expanded(child: _SummaryValue(label: 'Expense', value: MoneyFormatter.format(item.expense), color: colors.error)),
          Expanded(child: _SummaryValue(label: 'Profit', value: MoneyFormatter.format(item.profit), color: item.profit >= 0 ? colors.primary : colors.error)),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryValue({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w800))]);
}

TimelineItem? _itemFor(List<TimelineItem> items, DateTime date) {
  for (final item in items) {
    final parsed = DateTime.tryParse(item.date);
    if (parsed != null && _sameDay(parsed, date)) return item;
  }
  return null;
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String _weekday(DateTime date) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
String _monthLabel(DateTime date) => '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][date.month - 1]} ${date.year}';
String _dateLabel(DateTime date) => '${_weekday(date)}, ${date.day} ${_monthLabel(date).split(' ').first}';
