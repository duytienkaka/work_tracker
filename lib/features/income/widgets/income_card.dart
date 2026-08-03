import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../model/income_model.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IncomeCard({
    super.key,
    required this.income,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final createdTime = TimeOfDay.fromDateTime(
      income.createdAt.toLocal(),
    ).format(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      income.title.isEmpty ? 'Income' : income.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      income.amount.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (income.note.isNotEmpty)
                Text(
                  income.note,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Tip',
                      value: income.tip.toStringAsFixed(0),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Created',
                      value: createdTime,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
