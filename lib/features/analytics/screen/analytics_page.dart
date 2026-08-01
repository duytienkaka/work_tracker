import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/loading_view.dart';
import '../../../theme/app_spacing.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../analytics/widgets/best_work_card.dart';
import '../../analytics/widgets/income_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, _) {
          if (analytics.summary == null) {
            return const LoadingView();
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Thống kê',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng quan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryItem(
                            label: 'Tổng thu',
                            value: analytics.summary!.totalIncome.toStringAsFixed(0),
                          ),
                          _SummaryItem(
                            label: 'Tổng chi',
                            value: analytics.summary!.totalExpense.toStringAsFixed(0),
                          ),
                          _SummaryItem(
                            label: 'Ca làm',
                            value: analytics.summary!.totalShift.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              IncomeChart(data: analytics.incomes),
              const SizedBox(height: AppSpacing.md),
              if (analytics.bestWork != null) BestWorkCard(statistic: analytics.bestWork!),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
