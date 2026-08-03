import 'package:flutter/material.dart';

import '../../expense/model/expense_model.dart';
import '../../income/model/income_model.dart';
import '../../shift/model/shift_model.dart';
import '../../work/model/work_model.dart';
import '../model/analytics_summary.dart';
import '../model/analytics_dashboard.dart';
import '../model/analytics_point.dart';
import '../model/analytics_time_filter.dart';
import '../model/daily_income.dart';
import '../model/work_breakdown.dart';
import '../model/work_statistic.dart';
import '../repository/analytics_repository.dart';

enum AnalyticsWorkTypeFilter { all, hourly, daily, freelance }

extension AnalyticsWorkTypeFilterLabel on AnalyticsWorkTypeFilter {
  String get label {
    switch (this) {
      case AnalyticsWorkTypeFilter.all:
        return 'All';
      case AnalyticsWorkTypeFilter.hourly:
        return 'Hourly';
      case AnalyticsWorkTypeFilter.daily:
        return 'Daily';
      case AnalyticsWorkTypeFilter.freelance:
        return 'Freelance';
    }
  }
}

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository repository;

  AnalyticsProvider([AnalyticsRepository? repository])
    : repository = repository ?? AnalyticsRepository();

  AnalyticsSummary? summary;
  WorkStatistic? bestWork;
  List<DailyIncome> incomes = [];
  List<Work> works = [];
  List<Shift> shifts = [];
  List<Income> incomeItems = [];
  List<Expense> expenseItems = [];
  AnalyticsDashboard? dashboard;
  bool isLoading = false;
  AnalyticsTimeFilter selectedFilter = AnalyticsTimeFilter.sevenDays;
  AnalyticsWorkTypeFilter selectedWorkType = AnalyticsWorkTypeFilter.all;
  DateTimeRange? customRange;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      repository.getWorks(),
      repository.getShifts(),
      repository.getIncomes(),
      repository.getExpenses(),
    ]);

    works = results[0] as List<Work>;
    shifts = results[1] as List<Shift>;
    incomeItems = results[2] as List<Income>;
    expenseItems = results[3] as List<Expense>;

    summary = await repository.getSummary();
    bestWork = await repository.getBestWork();
    incomes = await repository.getLast7DaysIncome();
    _rebuildDashboard();
    isLoading = false;
    notifyListeners();
  }

  Future<void> setFilter(
    AnalyticsTimeFilter filter, {
    DateTimeRange? range,
  }) async {
    selectedFilter = filter;
    customRange = range;
    _rebuildDashboard();
    notifyListeners();
  }

  Future<void> setWorkTypeFilter(AnalyticsWorkTypeFilter filter) async {
    selectedWorkType = filter;
    _rebuildDashboard();
    notifyListeners();
  }

  void _rebuildDashboard() {
    final range = _resolveRange();

    if (works.isEmpty &&
        shifts.isEmpty &&
        incomeItems.isEmpty &&
        expenseItems.isEmpty) {
      dashboard = AnalyticsDashboard(
        filter: selectedFilter,
        range: range,
        totalOrders: 0,
        totalIncome: 0,
        totalTips: 0,
        totalExpense: 0,
        netProfit: 0,
        averageOrder: 0,
        revenue7Days: const [],
        monthlyRevenue: const [],
        expenseSeries: const [],
        profitSeries: const [],
        incomeByWork: const [],
        ordersByWork: const [],
        bestWork: null,
        worstWork: null,
      );
      return;
    }

    final filteredShifts = shifts.where((shift) {
      return _isWithinRange(shift.workDate, range) &&
          _shiftMatchesFilter(shift);
    }).toList();

    final filteredIncomes = incomeItems.where((income) {
      final shift = _shiftForIncome(income);
      return shift != null &&
          _isWithinRange(shift.workDate, range) &&
          _shiftMatchesFilter(shift);
    }).toList();

    final filteredExpenses = expenseItems.where((expense) {
      final shift = _shiftForExpense(expense);
      return shift != null &&
          _isWithinRange(shift.workDate, range) &&
          _shiftMatchesFilter(shift);
    }).toList();

    final filteredManualIncomes = filteredIncomes
        .where((income) => !income.generated)
        .toList();

    final totalOrders = filteredManualIncomes.length;
    final totalIncome = filteredIncomes.fold(
      0.0,
      (sum, income) => sum + income.amount,
    );
    final totalTips = filteredIncomes.fold(
      0.0,
      (sum, income) => sum + income.tip,
    );
    final totalExpense = filteredExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final manualOrderIncome = filteredManualIncomes.fold(
      0.0,
      (sum, income) => sum + income.amount,
    );
    final averageOrder = totalOrders == 0
        ? 0.0
        : manualOrderIncome / totalOrders;

    dashboard = AnalyticsDashboard(
      filter: selectedFilter,
      range: range,
      totalOrders: totalOrders,
      totalIncome: totalIncome,
      totalTips: totalTips,
      totalExpense: totalExpense,
      netProfit: totalIncome + totalTips - totalExpense,
      averageOrder: averageOrder,
      revenue7Days: _buildDailySeries(
        filteredShifts: filteredShifts,
        range: range,
        valueForShift: (shift) {
          final shiftIncomes = filteredIncomes.where(
            (income) => income.shiftId == shift.id,
          );
          return shiftIncomes.fold(0.0, (sum, income) => sum + income.amount);
        },
        labelFormatter: (date) => '${date.month}/${date.day}',
      ).takeLast(7),
      monthlyRevenue: _buildMonthlyRevenue(
        filteredShifts,
        filteredIncomes,
        range,
      ),
      expenseSeries: _buildDailySeries(
        filteredShifts: filteredShifts,
        range: range,
        valueForShift: (shift) {
          final shiftExpenses = filteredExpenses.where(
            (expense) => _shiftForExpense(expense)?.id == shift.id,
          );
          return shiftExpenses.fold(
            0.0,
            (sum, expense) => sum + expense.amount,
          );
        },
        labelFormatter: (date) => '${date.month}/${date.day}',
      ),
      profitSeries: _buildDailySeries(
        filteredShifts: filteredShifts,
        range: range,
        valueForShift: (shift) {
          final shiftIncomes = filteredIncomes.where(
            (income) => income.shiftId == shift.id,
          );
          final shiftExpenses = filteredExpenses.where(
            (expense) => _shiftForExpense(expense)?.id == shift.id,
          );
          final incomeTotal = shiftIncomes.fold(
            0.0,
            (sum, income) => sum + income.amount + income.tip,
          );
          final expenseTotal = shiftExpenses.fold(
            0.0,
            (sum, expense) => sum + expense.amount,
          );
          return incomeTotal - expenseTotal;
        },
        labelFormatter: (date) => '${date.month}/${date.day}',
      ),
      incomeByWork: _buildWorkBreakdown(
        filteredIncomes,
        (income) => income.amount,
      ),
      ordersByWork: _buildWorkBreakdown(filteredManualIncomes, (income) => 1),
      bestWork: _buildBestWork(filteredShifts),
      worstWork: _buildWorstWork(filteredShifts),
    );
  }

  DateTimeRange _resolveRange() {
    final now = DateTime.now();

    switch (selectedFilter) {
      case AnalyticsTimeFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: now);
      case AnalyticsTimeFilter.sevenDays:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: now);
      case AnalyticsTimeFilter.thirtyDays:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: now);
      case AnalyticsTimeFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: now);
      case AnalyticsTimeFilter.thisYear:
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: now);
      case AnalyticsTimeFilter.customRange:
        return customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 6)),
              end: now,
            );
    }
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  bool _shiftMatchesFilter(Shift shift) {
    final work = works.firstWhere(
      (item) => item.id == shift.workId,
      orElse: () => Work(
        id: shift.workId,
        name: shift.workId,
        description: '',
        salaryType: Work.legacyFixed,
        dailyRate: 0,
        hourlyRate: 0,
        color: 0,
        icon: 0,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );

    switch (selectedWorkType) {
      case AnalyticsWorkTypeFilter.all:
        return true;
      case AnalyticsWorkTypeFilter.hourly:
        return work.salaryType == Work.hourly;
      case AnalyticsWorkTypeFilter.daily:
        return work.salaryType == Work.daily;
      case AnalyticsWorkTypeFilter.freelance:
        return work.salaryType == Work.freelance;
    }
  }

  Shift? _shiftForIncome(Income income) {
    try {
      return shifts.firstWhere((shift) => shift.id == income.shiftId);
    } catch (_) {
      return null;
    }
  }

  Shift? _shiftForExpense(Expense expense) {
    try {
      return shifts.firstWhere((shift) => shift.id == expense.shiftId);
    } catch (_) {
      return null;
    }
  }

  List<AnalyticsPoint> _buildDailySeries({
    required List<Shift> filteredShifts,
    required DateTimeRange range,
    required double Function(Shift shift) valueForShift,
    required String Function(DateTime date) labelFormatter,
  }) {
    final days = <DateTime>[];
    var current = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);

    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    return days.map((date) {
      final dayShifts = filteredShifts.where((shift) {
        return shift.workDate.year == date.year &&
            shift.workDate.month == date.month &&
            shift.workDate.day == date.day;
      }).toList();
      final value = dayShifts.fold(
        0.0,
        (sum, shift) => sum + valueForShift(shift),
      );
      return AnalyticsPoint(
        date: date,
        label: labelFormatter(date),
        value: value,
      );
    }).toList();
  }

  List<AnalyticsPoint> _buildMonthlyRevenue(
    List<Shift> filteredShifts,
    List<Income> filteredIncomes,
    DateTimeRange range,
  ) {
    final map = <String, double>{};

    for (final shift in filteredShifts) {
      final key =
          '${shift.workDate.year}-${shift.workDate.month.toString().padLeft(2, '0')}';
      final amount = filteredIncomes
          .where((income) => income.shiftId == shift.id)
          .fold(0.0, (sum, income) => sum + income.amount);
      map.update(key, (value) => value + amount, ifAbsent: () => amount);
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return AnalyticsPoint(
        date: DateTime(year, month, 1),
        label: '${month.toString().padLeft(2, '0')}/$year',
        value: entry.value,
      );
    }).toList();
  }

  List<WorkBreakdown> _buildWorkBreakdown(
    List<Income> filteredIncomes,
    num Function(Income income) valueForIncome,
  ) {
    final result = <String, _MutableBreakdown>{};

    for (final income in filteredIncomes) {
      final shift = _shiftForIncome(income);
      if (shift == null) continue;
      final work = works.firstWhere(
        (item) => item.id == shift.workId,
        orElse: () => Work(
          id: shift.workId,
          name: shift.workId,
          description: '',
          salaryType: Work.legacyFixed,
          dailyRate: 0,
          hourlyRate: 0,
          color: 0,
          icon: 0,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );

      final key = work.id;
      final existing = result.putIfAbsent(key, () => _MutableBreakdown(work));
      existing.value += valueForIncome(income).toDouble();
      existing.count += 1;
    }

    final breakdowns =
        result.values
            .map(
              (entry) => WorkBreakdown(
                work: entry.work,
                value: entry.value,
                count: entry.count,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return breakdowns;
  }

  WorkStatistic? _buildBestWork(List<Shift> filteredShifts) {
    if (works.isEmpty || filteredShifts.isEmpty) return null;

    WorkStatistic? best;
    for (final work in works) {
      final workShifts = filteredShifts
          .where((shift) => shift.workId == work.id)
          .toList();
      if (workShifts.isEmpty) continue;
      final income = workShifts.fold(0.0, (sum, shift) => sum + shift.income);
      final expense = workShifts.fold(0.0, (sum, shift) => sum + shift.expense);
      final statistic = WorkStatistic(
        work: work,
        shiftCount: workShifts.length,
        income: income,
        expense: expense,
      );
      if (best == null || statistic.profit > best.profit) {
        best = statistic;
      }
    }

    return best;
  }

  WorkStatistic? _buildWorstWork(List<Shift> filteredShifts) {
    if (works.isEmpty || filteredShifts.isEmpty) return null;

    WorkStatistic? worst;
    for (final work in works) {
      final workShifts = filteredShifts
          .where((shift) => shift.workId == work.id)
          .toList();
      if (workShifts.isEmpty) continue;
      final income = workShifts.fold(0.0, (sum, shift) => sum + shift.income);
      final expense = workShifts.fold(0.0, (sum, shift) => sum + shift.expense);
      final statistic = WorkStatistic(
        work: work,
        shiftCount: workShifts.length,
        income: income,
        expense: expense,
      );
      if (worst == null || statistic.profit < worst.profit) {
        worst = statistic;
      }
    }

    return worst;
  }
}

class _MutableBreakdown {
  final Work work;
  double value = 0;
  int count = 0;

  _MutableBreakdown(this.work);
}

extension _TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
