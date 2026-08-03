import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SummaryGrid extends StatelessWidget {
  final double income;
  final double expense;
  final double profit;
  final int totalShift;

  const SummaryGrid({
    super.key,
    required this.income,
    required this.expense,
    required this.profit,
    required this.totalShift,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryTile(
          label: 'Tổng thu',
          value: MoneyFormatter.format(income),
          color: AppColors.primary,
          icon: Icons.arrow_downward_rounded,
        ),
        _SummaryTile(
          label: 'Tổng chi',
          value: MoneyFormatter.format(expense),
          color: AppColors.danger,
          icon: Icons.arrow_upward_rounded,
        ),
        _SummaryTile(
          label: 'Lợi nhuận',
          value: MoneyFormatter.format(profit),
          color: AppColors.success,
          icon: Icons.account_balance_wallet_rounded,
        ),
        _SummaryTile(
          label: 'Ca',
          value: '$totalShift',
          color: AppColors.secondary,
          icon: Icons.calendar_today_rounded,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.number.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
