import 'package:flutter/material.dart';

import '../../../core/services/app_refresh_coordinator.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../shift/provider/shift_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../../work/provider/work_provider.dart';
import '../model/income_model.dart';
import '../repository/income_repository.dart';

class IncomeProvider extends ChangeNotifier {
  final IncomeRepository repository;
  final AppRefreshCoordinator _refreshCoordinator;
  final ShiftProvider? shiftProvider;
  final DashboardProvider? dashboardProvider;
  final AnalyticsProvider? analyticsProvider;
  final WorkProvider? workProvider;
  final TimelineProvider? timelineProvider;

  IncomeProvider(
    this.repository, {
    AppRefreshCoordinator? refreshCoordinator,
    this.shiftProvider,
    this.dashboardProvider,
    this.analyticsProvider,
    this.workProvider,
    this.timelineProvider,
  }) : _refreshCoordinator = refreshCoordinator ?? AppRefreshCoordinator();

  List<Income> incomes = [];

  Future<void> loadByShift(String shiftId) async {
    incomes = await repository.getByShift(shiftId);
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    await repository.insert(income);
    await _refreshAfterMutation(income.shiftId);
  }

  Future<void> updateIncome(Income income) async {
    if (income.generated) return;
    await repository.update(income);
    await _refreshAfterMutation(income.shiftId);
  }

  Future<void> deleteIncome(String id, String shiftId) async {
    final income = await repository.getById(id);
    if (income?.generated == true) return;

    await repository.delete(id);
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
    incomes = await repository.getByShift(shiftId);
    notifyListeners();
  }

  double totalIncome() {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double totalTip() {
    return incomes.fold(0.0, (sum, income) => sum + income.tip);
  }

  int incomeCount() => incomes.length;
}
