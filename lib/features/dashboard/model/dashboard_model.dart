import '../../shift/model/shift_model.dart';

class DashboardModel {
  final int totalWorks;

  final int todayShifts;

  final double incomeToday;

  final double expenseToday;

  final Shift? recentShift;

  DashboardModel({
    required this.totalWorks,
    required this.todayShifts,
    required this.incomeToday,
    required this.expenseToday,
    required this.recentShift,
  });

  double get profitToday => incomeToday - expenseToday;
}
