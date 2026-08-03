import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../model/work_statistic.dart';

class BestWorkCard extends StatelessWidget {
  final WorkStatistic statistic;
  final String title;
  final Color accentColor;
  final IconData icon;

  const BestWorkCard({
    super.key,
    required this.statistic,
    this.title = 'Công việc hiệu quả nhất',
    this.accentColor = AppColors.warning,
    this.icon = Icons.emoji_events_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            statistic.work.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MetricRow(label: 'Ca làm', value: '${statistic.shiftCount}'),
          _MetricRow(
            label: 'Thu',
            value: MoneyFormatter.format(statistic.income),
          ),
          _MetricRow(
            label: 'Chi',
            value: MoneyFormatter.format(statistic.expense),
          ),
          _MetricRow(
            label: 'Lợi nhuận',
            value: MoneyFormatter.format(statistic.profit),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
