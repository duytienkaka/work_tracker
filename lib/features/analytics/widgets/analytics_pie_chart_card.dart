import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';

class AnalyticsPieSlice {
  final String label;
  final double value;

  const AnalyticsPieSlice({required this.label, required this.value});
}

class AnalyticsPieChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AnalyticsPieSlice> slices;

  const AnalyticsPieChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.slices,
  });

  @override
  Widget build(BuildContext context) {
    final palette = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      AppColors.secondary,
      AppColors.primary,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: slices.isEmpty
                ? const Center(child: Text('No data'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 42,
                      sections: List.generate(slices.length, (index) {
                        final slice = slices[index];
                        final color = palette[index % palette.length];
                        return PieChartSectionData(
                          value: slice.value,
                          color: color,
                          title: slice.label,
                          radius: 70,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(slices.length, (index) {
              final slice = slices[index];
              final color = palette[index % palette.length];
              return _LegendItem(
                label: slice.label,
                value: slice.value,
                color: color,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label (${MoneyFormatter.format(value)})',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
