import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../shift/model/shift_model.dart';
import '../model/dashboard_model.dart';

class DashboardRepository {
  Future<Database> get _db async => AppDatabase.database();

  Future<DashboardModel> load() async {
    final db = await _db;

    final works = await db.query("works");

    final shifts = await db.query("shifts");

    Shift? recentShift;

    if (shifts.isNotEmpty) {
      final latest = shifts.last;
      recentShift = Shift.fromMap(latest);
    }

    final today = DateTime.now();

    double income = 0;

    double expense = 0;

    int todayShift = 0;

    for (final item in shifts) {
      final date = DateTime.parse(item["workDate"] as String);

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        todayShift++;

        income += (item["income"] as num).toDouble();

        expense += (item["expense"] as num).toDouble();
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
