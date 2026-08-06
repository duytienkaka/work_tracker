import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../shift/model/shift_model.dart';
import '../../shift/provider/shift_provider.dart';
import '../../shift/screen/shift_detail_page.dart';
import '../../shift/screen/shift_form_page.dart';
import '../../work/model/work_model.dart';
import '../../work/provider/work_provider.dart';
import '../../work/screen/work_form_page.dart';
import '../provider/dashboard_provider.dart';

class ModernDashboardView extends StatefulWidget {
  const ModernDashboardView({super.key});

  @override
  State<ModernDashboardView> createState() => _ModernDashboardViewState();
}

class _ModernDashboardViewState extends State<ModernDashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_reload);
  }

  Future<void> _reload() async {
    if (!mounted) return;
    await Future.wait([
      context.read<DashboardProvider>().load(),
      context.read<ShiftProvider>().load(),
      context.read<WorkProvider>().loadWorks(),
    ]);
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>().dashboard;
    final shifts = context.watch<ShiftProvider>().shifts;
    final works = context.watch<WorkProvider>().works;
    final colorScheme = Theme.of(context).colorScheme;

    if (dashboard == null) {
      return const Scaffold(
        body: Center(
          child: Padding(padding: EdgeInsets.all(24), child: LoadingView()),
        ),
      );
    }

    final activeShift = dashboard.recentShift;
    final activeWork = _workForShift(activeShift, works);
    final recentShifts = _recentShiftsForToday(shifts);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work Tracker'),
            Text(
              'Your workday at a glance',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            _TodayHeader(
              income: dashboard.incomeToday,
              expense: dashboard.expenseToday,
              profit: dashboard.profitToday,
              shiftCount: dashboard.todayShifts,
            ),
            const SizedBox(height: 24),
            _ActiveShiftTimeline(
              shift: activeShift,
              work: activeWork,
              onTap: activeShift == null
                  ? null
                  : () => _openPage(
                        ShiftDetailPage(work: activeWork, shift: activeShift),
                      ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Recent shifts'),
            const SizedBox(height: 8),
            if (recentShifts.isEmpty)
              _EmptyWorkday(onAddShift: () => _openPage(const ShiftFormPage()))
            else
              ...recentShifts.map(
                (shift) {
                  final work = _workForShift(shift, works);
                  return _ShiftRow(
                    shift: shift,
                    work: work,
                    onTap: () => _openPage(
                      ShiftDetailPage(work: work, shift: shift),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Quick actions'),
            const SizedBox(height: 8),
            _QuickActionGrid(
              onNewShift: () => _openPage(const ShiftFormPage()),
              onNewWork: () => _openPage(const WorkFormPage()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
    );
  }

  Future<void> _showCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('New shift'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPage(const ShiftFormPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work_rounded),
                  title: const Text('New work'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openPage(const WorkFormPage());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final double income;
  final double expense;
  final double profit;
  final int shiftCount;

  const _TodayHeader({
    required this.income,
    required this.expense,
    required this.profit,
    required this.shiftCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profitColor = profit >= 0 ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$shiftCount shifts',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
            MoneyFormatter.format(profit),
            style: theme.textTheme.displaySmall?.copyWith(
              color: profitColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profit so far',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MoneyPill(
                  label: 'Income',
                  value: MoneyFormatter.format(income),
                  icon: Icons.arrow_upward_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MoneyPill(
                  label: 'Expense',
                  value: MoneyFormatter.format(expense),
                  icon: Icons.arrow_downward_rounded,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftTimeline extends StatelessWidget {
  final Shift? shift;
  final Work? work;
  final VoidCallback? onTap;

  const _ActiveShiftTimeline({this.shift, this.work, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentShift = shift;
    final now = DateTime.now();
    final progress = currentShift == null ? 0.0 : _shiftProgress(currentShift, now);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timeline_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentShift == null ? 'No active shift' : 'Shift timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentShift == null
                          ? 'Start a shift when your workday begins.'
                          : work?.name ?? 'Current work',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  currentShift == null ? 'Ready' : _remainingText(currentShift, now),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                currentShift == null
                    ? MoneyFormatter.format(0)
                    : MoneyFormatter.format(currentShift.income),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final VoidCallback onNewShift;
  final VoidCallback onNewWork;

  const _QuickActionGrid({required this.onNewShift, required this.onNewWork});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.schedule_rounded,
            label: 'New shift',
            onTap: onNewShift,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            icon: Icons.work_rounded,
            label: 'New work',
            onTap: onNewWork,
          ),
        ),
      ],
    );
  }
}

class _ShiftRow extends StatelessWidget {
  final Shift shift;
  final Work? work;
  final VoidCallback onTap;

  const _ShiftRow({required this.shift, required this.work, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.work_history_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work?.name ?? 'Work shift',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            MoneyFormatter.format(shift.profit),
            style: theme.textTheme.titleSmall?.copyWith(
              color: shift.profit >= 0 ? colorScheme.primary : colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MoneyPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 92,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkday extends StatelessWidget {
  final VoidCallback onAddShift;

  const _EmptyWorkday({required this.onAddShift});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No shifts today',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a shift to start tracking your workday.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddShift,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New shift'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

Work? _workForShift(Shift? shift, List<Work> works) {
  if (shift == null) return null;
  for (final work in works) {
    if (work.id == shift.workId) return work;
  }
  return null;
}

List<Shift> _recentShiftsForToday(List<Shift> shifts) {
  final today = DateTime.now();
  final items = shifts.where((shift) {
    return shift.workDate.year == today.year &&
        shift.workDate.month == today.month &&
        shift.workDate.day == today.day;
  }).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
  return items.take(4).toList();
}

double _shiftProgress(Shift shift, DateTime now) {
  final start = shift.startDateTime;
  final end = shift.endDateTime;
  if (start == null) return 0;
  if (end == null) return now.isBefore(start) ? 0 : 0.5;
  if (now.isBefore(start)) return 0;
  if (now.isAfter(end)) return 1;
  final total = end.difference(start).inSeconds;
  if (total <= 0) return 1;
  return (now.difference(start).inSeconds / total).clamp(0.0, 1.0).toDouble();
}

String _remainingText(Shift shift, DateTime now) {
  final start = shift.startDateTime;
  final end = shift.endDateTime;
  if (start == null) return 'No start time';
  if (now.isBefore(start)) {
    final wait = start.difference(now);
    return 'Starts in ${wait.inHours}h ${wait.inMinutes % 60}m';
  }
  if (end == null) return 'In progress';
  if (now.isAfter(end)) return 'Completed';
  final remaining = end.difference(now);
  return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
