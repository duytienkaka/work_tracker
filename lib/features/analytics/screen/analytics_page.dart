import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../model/analytics_dashboard.dart';
import '../model/analytics_time_filter.dart';
import '../provider/analytics_provider.dart';
import '../widgets/analytics_line_chart_card.dart';
import '../widgets/analytics_metric_card.dart';
import '../widgets/analytics_pie_chart_card.dart';
import '../widgets/best_work_card.dart';

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
          final dashboard = analytics.dashboard;

          if (analytics.isLoading || dashboard == null) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(24), child: LoadingView()),
            );
          }

          if (dashboard.revenue7Days.isEmpty &&
              dashboard.monthlyRevenue.isEmpty &&
              dashboard.expenseSeries.isEmpty &&
              dashboard.profitSeries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                SizedBox(height: AppSpacing.md),
                EmptyState(
                  icon: Icons.insights_rounded,
                  title: 'Chưa có dữ liệu phân tích',
                  subtitle: 'Thêm ca làm và giao dịch để xem biểu đồ thống kê.',
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                'Thống kê',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              // Time filter
              _TimeFilterSection(
                selectedFilter: analytics.selectedFilter,
                customRangeLabel:
                    analytics.selectedFilter == AnalyticsTimeFilter.customRange
                    ? '${_formatDate(dashboard.range.start)} - ${_formatDate(dashboard.range.end)}'
                    : null,
                onFilterSelected: (filter) async {
                  final provider = context.read<AnalyticsProvider>();
                  final currentContext = context;
                  if (filter == AnalyticsTimeFilter.customRange) {
                    final range = await showDateRangePicker(
                      context: currentContext,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: analytics.customRange,
                    );
                    if (!currentContext.mounted) return;
                    if (range != null) {
                      await provider.setFilter(filter, range: range);
                    }
                    return;
                  }
                  if (!currentContext.mounted) return;
                  await provider.setFilter(filter);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Work type filter
              _WorkTypeFilterSection(
                selectedFilter: analytics.selectedWorkType,
                onTypeSelected: (type) async => await context
                    .read<AnalyticsProvider>()
                    .setWorkTypeFilter(type),
              ),
              const SizedBox(height: AppSpacing.md),

              // Metrics
              _MetricsGrid(dashboard: dashboard),
              const SizedBox(height: AppSpacing.md),

              // Charts
              AnalyticsLineChartCard(
                title: 'Revenue Chart',
                subtitle: '7 Days',
                data: dashboard.revenue7Days,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Revenue Chart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: dashboard.monthlyRevenue.isEmpty
                          ? const Center(child: Text('No data'))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barGroups: dashboard.monthlyRevenue
                                    .asMap()
                                    .entries
                                    .map((e) {
                                      final idx = e.key;
                                      final item = e.value;
                                      return BarChartGroupData(
                                        x: idx,
                                        barRods: [
                                          BarChartRodData(
                                            toY: item.value,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            width: 18,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ],
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AnalyticsLineChartCard(
                title: 'Expense Chart',
                subtitle: dashboard.filter.label,
                data: dashboard.expenseSeries,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              AnalyticsLineChartCard(
                title: 'Profit Chart',
                subtitle: dashboard.filter.label,
                data: dashboard.profitSeries,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.md),

              AnalyticsPieChartCard(
                title: 'Income by Work',
                subtitle: dashboard.filter.label,
                slices: dashboard.incomeByWork
                    .map(
                      (i) =>
                          AnalyticsPieSlice(label: i.work.name, value: i.value),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              AnalyticsPieChartCard(
                title: 'Orders by Work',
                subtitle: dashboard.filter.label,
                slices: dashboard.ordersByWork
                    .map(
                      (i) => AnalyticsPieSlice(
                        label: i.work.name,
                        value: i.count.toDouble(),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              if (dashboard.bestWork != null)
                BestWorkCard(
                  statistic: dashboard.bestWork!,
                  title: 'Best Work',
                  accentColor: Colors.green,
                  icon: Icons.emoji_events_rounded,
                ),
              if (dashboard.bestWork != null)
                const SizedBox(height: AppSpacing.md),
              if (dashboard.worstWork != null)
                BestWorkCard(
                  statistic: dashboard.worstWork!,
                  title: 'Worst Work',
                  accentColor: Colors.red,
                  icon: Icons.trending_down_rounded,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AnalyticsDashboard dashboard;
  const _MetricsGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      AnalyticsMetricCard(
        label: 'Total Income',
        value: MoneyFormatter.format(dashboard.totalIncome),
        icon: Icons.arrow_upward_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      AnalyticsMetricCard(
        label: 'Total Expense',
        value: MoneyFormatter.format(dashboard.totalExpense),
        icon: Icons.arrow_downward_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      AnalyticsMetricCard(
        label: 'Total Tips',
        value: MoneyFormatter.format(dashboard.totalTips),
        icon: Icons.tips_and_updates_outlined,
        color: Colors.green,
      ),
      AnalyticsMetricCard(
        label: 'Net Profit',
        value: MoneyFormatter.format(dashboard.netProfit),
        icon: dashboard.netProfit >= 0
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: dashboard.netProfit >= 0
            ? Colors.green
            : Theme.of(context).colorScheme.error,
      ),
      AnalyticsMetricCard(
        label: 'Orders',
        value: dashboard.totalOrders.toString(),
        icon: Icons.receipt_long_rounded,
        color: Theme.of(context).colorScheme.secondary,
      ),
      AnalyticsMetricCard(
        label: 'Average Order',
        value: MoneyFormatter.format(dashboard.averageOrder),
        icon: Icons.calculate_outlined,
        color: AppColors.warning,
      ),
    ];

    final width =
        (MediaQuery.of(context).size.width -
            (AppSpacing.md * 2) -
            AppSpacing.sm) /
        2;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: metrics.map((m) => SizedBox(width: width, child: m)).toList(),
    );
  }
}

class _TimeFilterSection extends StatelessWidget {
  final AnalyticsTimeFilter selectedFilter;
  final String? customRangeLabel;
  final Future<void> Function(AnalyticsTimeFilter filter) onFilterSelected;

  const _TimeFilterSection({
    required this.selectedFilter,
    required this.customRangeLabel,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = AnalyticsTimeFilter.values;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Filter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            customRangeLabel == null
                ? selectedFilter.label
                : '${selectedFilter.label}: $customRangeLabel',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: f == selectedFilter,
                        onSelected: (_) => onFilterSelected(f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkTypeFilterSection extends StatelessWidget {
  final AnalyticsWorkTypeFilter selectedFilter;
  final Future<void> Function(AnalyticsWorkTypeFilter filter) onTypeSelected;

  const _WorkTypeFilterSection({
    required this.selectedFilter,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AnalyticsWorkTypeFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: f == selectedFilter,
                        onSelected: (_) => onTypeSelected(f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
