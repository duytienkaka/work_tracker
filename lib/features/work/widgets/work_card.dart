import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../model/work_model.dart';
import '../model/work_summary.dart';

class WorkCard extends StatelessWidget {
  final WorkSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final work = summary.work;
    final profitColor = summary.profit >= 0 ? colors.primary : colors.error;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _WorkIcon(work: work),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Badge(label: _typeLabel(work), filled: true),
                          _Badge(label: _rateLabel(work)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More actions',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit work'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete work'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Shifts',
                      value: '${summary.totalShifts}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Income',
                      value: MoneyFormatter.format(summary.totalIncome),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Profit',
                      value: MoneyFormatter.format(summary.profit),
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(Work work) => switch (work.salaryType) {
    Work.hourly => 'Hourly',
    Work.daily => 'Daily',
    Work.freelance => 'Freelance',
    _ => 'Fixed',
  };

  String _rateLabel(Work work) => switch (work.salaryType) {
    Work.hourly => '${MoneyFormatter.format(work.hourlyRate)}/h',
    Work.daily => '${MoneyFormatter.format(work.dailyRate)}/day',
    Work.freelance => 'Manual income',
    _ => 'Fixed salary',
  };
}

class _WorkIcon extends StatelessWidget {
  final Work work;
  const _WorkIcon({required this.work});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (work.salaryType) {
      Work.hourly => Icons.schedule_rounded,
      Work.daily => Icons.today_rounded,
      Work.freelance => Icons.design_services_rounded,
      _ => Icons.work_rounded,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: colors.onPrimaryContainer),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool filled;
  const _Badge({required this.label, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: filled ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Metric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
