import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money_formatter.dart';

class DashboardSummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double profit;

  const DashboardSummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.profit,
  });

  Widget _row(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _row(
              "Thu hôm nay",
              MoneyFormatter.format(income),
              AppColors.success,
            ),
            const Divider(),
            _row(
              "Chi hôm nay",
              MoneyFormatter.format(expense),
              AppColors.danger,
            ),
            const Divider(),
            _row("Lợi nhuận", MoneyFormatter.format(profit), Colors.blue),
          ],
        ),
      ),
    );
  }
}
