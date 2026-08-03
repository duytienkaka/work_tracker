import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../shift/model/shift_model.dart';
import '../../shift/repository/shift_repository.dart';
import '../model/dashboard_model.dart';

class DashboardRepository {
  Future<Database> get _db async => AppDatabase.database();

  Future<DashboardModel> load() async {
    final db = await _db;
    final shiftRepository = ShiftRepository();

    final works = await db.query("works");
    final shifts = await shiftRepository.getAll();

    Shift? recentShift;

    if (shifts.isNotEmpty) {
      recentShift = shifts.first;
    }

    final today = DateTime.now();

    double income = 0;
    double expense = 0;

    int todayShift = 0;

    for (final shift in shifts) {
      final date = shift.workDate;

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        todayShift++;
        income += shift.income;
        expense += shift.expense;
      }
    }

    return DashboardModel(
      totalWorks: works.length,
      todayShifts: todayShift,
      incomeToday: income,
      expenseToday: expense,
      recentShift: recentShift,
    );
  }
}
