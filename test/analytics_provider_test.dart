import 'package:flutter_test/flutter_test.dart';

import 'package:work_tracker/features/analytics/model/analytics_summary.dart';
import 'package:work_tracker/features/analytics/model/analytics_time_filter.dart';
import 'package:work_tracker/features/analytics/model/daily_income.dart';
import 'package:work_tracker/features/analytics/model/work_statistic.dart';
import 'package:work_tracker/features/analytics/provider/analytics_provider.dart';
import 'package:work_tracker/features/analytics/repository/analytics_repository.dart';
import 'package:work_tracker/features/expense/model/expense_model.dart';
import 'package:work_tracker/features/income/model/income_model.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/work/model/work_model.dart';

class FakeAnalyticsRepository extends AnalyticsRepository {
  @override
  Future<List<Work>> getWorks() async => [];

  @override
  Future<List<Shift>> getShifts() async => [];

  @override
  Future<List<Income>> getIncomes() async => [];

  @override
  Future<List<Expense>> getExpenses() async => [];

  @override
  Future<AnalyticsSummary> getSummary() async => const AnalyticsSummary(
    totalIncome: 0,
    totalExpense: 0,
    totalShift: 0,
    averageIncome: 0,
  );

  @override
  Future<WorkStatistic?> getBestWork() async => null;

  @override
  Future<List<DailyIncome>> getLast7DaysIncome() async => [];
}

void main() {
  test(
    'load should build a dashboard even when the database is empty',
    () async {
      final provider = AnalyticsProvider(FakeAnalyticsRepository());

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.summary, isNotNull);
      expect(provider.dashboard, isNotNull);
      expect(provider.dashboard!.filter, AnalyticsTimeFilter.sevenDays);
      expect(provider.dashboard!.totalIncome, 0);
      expect(provider.dashboard!.totalExpense, 0);
    },
  );
}
