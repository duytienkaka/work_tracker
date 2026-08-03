import 'package:flutter/material.dart';

import 'analytics_point.dart';
import 'work_breakdown.dart';
import 'work_statistic.dart';
import 'analytics_time_filter.dart';

class AnalyticsDashboard {
  final AnalyticsTimeFilter filter;
  final DateTimeRange range;
  final int totalOrders;
  final double totalIncome;
  final double totalTips;
  final double totalExpense;
  final double netProfit;
  final double averageOrder;
  final List<AnalyticsPoint> revenue7Days;
  final List<AnalyticsPoint> monthlyRevenue;
  final List<AnalyticsPoint> expenseSeries;
  final List<AnalyticsPoint> profitSeries;
  final List<WorkBreakdown> incomeByWork;
  final List<WorkBreakdown> ordersByWork;
  final WorkStatistic? bestWork;
  final WorkStatistic? worstWork;

  const AnalyticsDashboard({
    required this.filter,
    required this.range,
    required this.totalOrders,
    required this.totalIncome,
    required this.totalTips,
    required this.totalExpense,
    required this.netProfit,
    required this.averageOrder,
    required this.revenue7Days,
    required this.monthlyRevenue,
    required this.expenseSeries,
    required this.profitSeries,
    required this.incomeByWork,
    required this.ordersByWork,
    required this.bestWork,
    required this.worstWork,
  });
}
