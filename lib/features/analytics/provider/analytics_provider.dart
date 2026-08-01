import 'package:flutter/material.dart';

import '../model/analytics_summary.dart';
import '../model/daily_income.dart';
import '../model/work_statistic.dart';
import '../repository/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  final repository = AnalyticsRepository();

  AnalyticsSummary? summary;
  WorkStatistic? bestWork;
  List<DailyIncome> incomes = [];

  Future<void> load() async {
    summary = await repository.getSummary();
    bestWork = await repository.getBestWork();
    incomes = await repository.getLast7DaysIncome();
    notifyListeners();
  }
}
