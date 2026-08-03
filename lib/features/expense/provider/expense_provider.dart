import 'package:flutter/foundation.dart';

import '../../../core/services/app_refresh_coordinator.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../shift/provider/shift_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../../work/provider/work_provider.dart';
import '../model/expense_model.dart';
import '../repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository repository;
  final AppRefreshCoordinator _refreshCoordinator;
  final ShiftProvider? shiftProvider;
  final DashboardProvider? dashboardProvider;
  final AnalyticsProvider? analyticsProvider;
  final WorkProvider? workProvider;
  final TimelineProvider? timelineProvider;

  ExpenseProvider(
    this.repository, {
    AppRefreshCoordinator? refreshCoordinator,
    this.shiftProvider,
    this.dashboardProvider,
    this.analyticsProvider,
    this.workProvider,
    this.timelineProvider,
  }) : _refreshCoordinator = refreshCoordinator ?? AppRefreshCoordinator();

  List<Expense> expenses = [];

  Future<void> loadByShift(String shiftId) async {
    expenses = await repository.getExpensesByShift(shiftId);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await repository.insertExpense(expense);
    await _refreshAfterMutation(expense.shiftId);
  }

  Future<void> updateExpense(Expense expense) async {
    await repository.updateExpense(expense);
    await _refreshAfterMutation(expense.shiftId);
  }

  Future<void> deleteExpense(String id, String shiftId) async {
    await repository.deleteExpense(id);
    await _refreshAfterMutation(shiftId);
  }

  Future<void> _refreshAfterMutation(String shiftId) async {
    await _loadByShiftWithoutNotify(shiftId);

    await _refreshCoordinator.refreshAfterCrud(
      refreshShift: () async {
        await shiftProvider?.refreshCurrentView();
      },
      refreshDashboard: () async {
        await dashboardProvider?.load();
      },
      refreshAnalytics: () async {
        await analyticsProvider?.load();
      },
      refreshWork: () async {
        await workProvider?.loadWorks();
        await workProvider?.refreshCurrentWorkDetail();
      },
      refreshTimeline: () async {
        await timelineProvider?.loadTimeline();
      },
    );
  }

  Future<void> _loadByShiftWithoutNotify(String shiftId) async {
    expenses = await repository.getExpensesByShift(shiftId);
    notifyListeners();
  }

  int expenseCount() => expenses.length;

  double totalExpense() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
