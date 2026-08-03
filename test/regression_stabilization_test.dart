import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:work_tracker/features/analytics/model/analytics_summary.dart';
import 'package:work_tracker/features/analytics/model/daily_income.dart';
import 'package:work_tracker/features/analytics/model/work_statistic.dart';
import 'package:work_tracker/features/analytics/provider/analytics_provider.dart';
import 'package:work_tracker/features/analytics/repository/analytics_repository.dart';
import 'package:work_tracker/features/dashboard/model/dashboard_model.dart';
import 'package:work_tracker/features/dashboard/provider/dashboard_provider.dart';
import 'package:work_tracker/features/dashboard/repository/dashboard_repository.dart';
import 'package:work_tracker/features/dashboard/widgets/dashboard_view.dart';
import 'package:work_tracker/features/expense/model/expense_model.dart';
import 'package:work_tracker/features/income/model/income_model.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/shift/provider/shift_provider.dart';
import 'package:work_tracker/features/shift/repository/shift_repository.dart';
import 'package:work_tracker/features/work/model/work_model.dart';
import 'package:work_tracker/features/work/model/work_summary.dart';
import 'package:work_tracker/features/work/provider/work_provider.dart';
import 'package:work_tracker/features/work/repository/work_repository.dart';
import 'package:work_tracker/shared/widgets/loading_view.dart';

class _FakeDashboardRepository extends DashboardRepository {
  @override
  Future<DashboardModel> load() async {
    return DashboardModel(
      totalWorks: 0,
      todayShifts: 0,
      incomeToday: 0,
      expenseToday: 0,
      recentShift: null,
    );
  }
}

class _FakeAnalyticsRepository extends AnalyticsRepository {
  @override
  Future<List<Work>> getWorks() async => [];

  @override
  Future<List<Shift>> getShifts() async => [];

  @override
  Future<List<Income>> getIncomes() async => [];

  @override
  Future<List<Expense>> getExpenses() async => [];

  @override
  Future<AnalyticsSummary> getSummary() async {
    return const AnalyticsSummary(
      totalIncome: 0,
      totalExpense: 0,
      totalShift: 0,
      averageIncome: 0,
    );
  }

  @override
  Future<WorkStatistic?> getBestWork() async => null;

  @override
  Future<List<DailyIncome>> getLast7DaysIncome() async => [];
}

class _FakeWorkRepository extends WorkRepository {
  final List<Work> _works = [];
  final List<WorkSummary> _summaries = [];

  @override
  Future<List<Work>> getAllWorks() async => List.from(_works);

  @override
  Future<List<WorkSummary>> getWorkSummary() async => List.from(_summaries);

  @override
  Future<void> insertWork(Work work) async {
    _works.add(work);
    _summaries.add(
      WorkSummary(work: work, totalShifts: 0, totalIncome: 0, totalExpense: 0),
    );
  }

  @override
  Future<void> updateWork(Work work) async {
    final index = _works.indexWhere((item) => item.id == work.id);
    if (index != -1) {
      _works[index] = work;
      _summaries[index] = WorkSummary(
        work: work,
        totalShifts: 0,
        totalIncome: 0,
        totalExpense: 0,
      );
    }
  }

  @override
  Future<void> deleteWork(String id) async {
    _works.removeWhere((item) => item.id == id);
    _summaries.removeWhere((item) => item.work.id == id);
  }

  @override
  Future<List<Shift>> getShiftsByWork(String workId) async => [];

  @override
  Future<WorkSummary> getSummary(String workId) async {
    final match = _summaries.firstWhere(
      (summary) => summary.work.id == workId,
      orElse: () => WorkSummary(
        work: Work(
          id: workId,
          name: 'Unknown',
          description: '',
          salaryType: 0,
          dailyRate: 0,
          hourlyRate: 0,
          color: 0,
          icon: 0,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        totalShifts: 0,
        totalIncome: 0,
        totalExpense: 0,
      ),
    );
    return match;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home dashboard renders empty state without spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => DashboardProvider(_FakeDashboardRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => AnalyticsProvider(_FakeAnalyticsRepository()),
          ),
        ],
        child: const MaterialApp(home: DashboardView()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('Tổng quan hôm nay'), findsOneWidget);
  });

  test('WorkProvider addWork refreshes provider state', () async {
    final repository = _FakeWorkRepository();
    final provider = WorkProvider(repository);

    await provider.addWork('Regression Work', 'Test description', 1, 0, 0);

    expect(provider.works.length, 1);
    expect(provider.filteredWorks.length, 1);
    expect(provider.summaries.length, 1);
    expect(provider.works.first.name, 'Regression Work');
  });

  test('Shift summary totals income tips and expenses correctly', () async {
    final provider = ShiftProvider(ShiftRepository());

    final work = Work(
      id: 'w1',
      name: 'Test Work',
      description: '',
      salaryType: Work.freelance,
      dailyRate: 0,
      hourlyRate: 0,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 's1',
      workId: 'w1',
      workDate: DateTime.now(),
      startTime: '09:00',
      endTime: '10:00',
      income: 0,
      expense: 0,
      note: '',
    );

    final summary = provider.buildSummary(
      work: work,
      shift: shift,
      incomes: [
        Income(
          id: 'i1',
          shiftId: 's1',
          title: 'A',
          amount: 100,
          tip: 10,
          note: '',
          createdAt: DateTime.now(),
        ),
        Income(
          id: 'i2',
          shiftId: 's1',
          title: 'B',
          amount: 50,
          tip: 5,
          note: '',
          createdAt: DateTime.now(),
        ),
        Income(
          id: 'i3',
          shiftId: 's1',
          title: 'C',
          amount: 25,
          tip: 0,
          note: '',
          createdAt: DateTime.now(),
        ),
      ],
      expenses: [
        Expense(
          id: 'e1',
          shiftId: 's1',
          title: 'Expense A',
          amount: 20,
          note: '',
          createdAt: DateTime.now(),
        ),
        Expense(
          id: 'e2',
          shiftId: 's1',
          title: 'Expense B',
          amount: 15,
          note: '',
          createdAt: DateTime.now(),
        ),
      ],
    );

    expect(summary.totalIncome, 175);
    expect(summary.totalTip, 15);
    expect(summary.totalExpense, 35);
    expect(summary.profit, 155);
  });
}
