import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../shift/model/shift_model.dart';
import '../../shift/repository/shift_repository.dart';
import '../model/dashboard_model.dart';

class DashboardRepository {
  Future<Database> get _db async => AppDatabase.database();

  static Shift? selectActiveShiftForToday(
    List<Shift> shifts,
    DateTime today, [
    DateTime? now,
  ]) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final currentTime = now ?? DateTime.now();
    final matchingShifts = shifts.where((shift) {
      final shiftDay = DateTime(
        shift.workDate.year,
        shift.workDate.month,
        shift.workDate.day,
      );
      return shiftDay == normalizedToday;
    }).toList();

    if (matchingShifts.isEmpty) {
      return null;
    }

    matchingShifts.sort((a, b) {
      final startComparison = a.startTime.compareTo(b.startTime);
      if (startComparison != 0) return startComparison;
      return a.endTime.compareTo(b.endTime);
    });

    final activeShifts = matchingShifts.where((shift) {
      final start = shift.startDateTime;
      if (start == null) return false;

      final end = shift.endDateTime;
      if (end == null) {
        return !currentTime.isBefore(start);
      }

      return !currentTime.isBefore(start) && !currentTime.isAfter(end);
    }).toList();

    if (activeShifts.isNotEmpty) {
      return activeShifts.last;
    }

    final upcomingShifts = matchingShifts.where((shift) {
      final start = shift.startDateTime;
      return start != null && currentTime.isBefore(start);
    }).toList();

    if (upcomingShifts.isNotEmpty) {
      return upcomingShifts.first;
    }

    if (matchingShifts.isNotEmpty) {
      return matchingShifts.last;
    }

    return null;
  }

  Future<DashboardModel> load() async {
    final db = await _db;
    final shiftRepository = ShiftRepository();

    final works = await db.query("works");
    final shifts = await shiftRepository.getAll();

    final today = DateTime.now();
    final recentShift = selectActiveShiftForToday(
      shifts,
      today,
      DateTime.now(),
    );

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
