import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../model/analytics_point.dart';

class AnalyticsLineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AnalyticsPoint> data;
  final Color color;

  const AnalyticsLineChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.color,
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.show_chart_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? const Center(child: Text('No data'))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: _interval(data),
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data[index].label,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.12),
                          ),
                          spots: List.generate(
                            data.length,
                            (index) =>
                                FlSpot(index.toDouble(), data[index].value),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _interval(List<AnalyticsPoint> list) {
    if (list.isEmpty) return 1;
    final maxValue = list
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (maxValue <= 0) return 1;
    return (maxValue / 3).clamp(1, 1000000).toDouble();
  }
}
