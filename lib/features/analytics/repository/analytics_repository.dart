import '../../../core/database/app_database.dart';
import '../../expense/model/expense_model.dart';
import '../../income/model/income_model.dart';
import '../../shift/model/shift_model.dart';
import '../../work/model/work_model.dart';
import '../model/analytics_summary.dart';
import '../model/daily_income.dart';
import '../model/work_statistic.dart';

class AnalyticsRepository {
  Future<List<Work>> getWorks() async {
    final db = await AppDatabase.database();
    final result = await db.query('works');
    return result.map((row) => Work.fromMap(row)).toList();
  }

  Future<List<Shift>> getShifts() async {
    final db = await AppDatabase.database();
    final result = await db.query('shifts', orderBy: 'workDate ASC');
    return result.map((row) => Shift.fromMap(row)).toList();
  }

  Future<List<Income>> getIncomes() async {
    final db = await AppDatabase.database();
    final result = await db.query('income', orderBy: 'created_at ASC');
    return result.map((row) => Income.fromMap(row)).toList();
  }

  Future<List<Expense>> getExpenses() async {
    final db = await AppDatabase.database();
    final result = await db.query('expense', orderBy: 'created_at ASC');
    return result.map((row) => Expense.fromMap(row)).toList();
  }

  Future<AnalyticsSummary> getSummary() async {
    final db = await AppDatabase.database();

    final shifts = await db.query("shifts");

    double income = 0;
    double expense = 0;

    for (final shift in shifts) {
      income += (shift["income"] as num).toDouble();
      expense += (shift["expense"] as num).toDouble();
    }

    final average = shifts.isEmpty ? 0 : income / shifts.length;

    return AnalyticsSummary(
      totalIncome: income,
      totalExpense: expense,
      totalShift: shifts.length,
      averageIncome: average.toDouble(),
    );
  }

  Future<List<DailyIncome>> getLast7DaysIncome() async {
    final db = await AppDatabase.database();

    final shifts = await db.query("shifts", orderBy: "workDate ASC");

    final Map<String, double> map = {};

    for (final shift in shifts) {
      final date = shift["workDate"] as String;
      final income = (shift["income"] as num).toDouble();

      map.update(date, (value) => value + income, ifAbsent: () => income);
    }

    final list = map.entries
        .map((e) => DailyIncome(date: e.key, income: e.value))
        .toList();

    if (list.length > 7) {
      return list.sublist(list.length - 7);
    }

    return list;
  }

  Future<WorkStatistic?> getBestWork() async {
    final db = await AppDatabase.database();

    final works = await db.query("works");
    final shifts = await db.query("shifts");

    WorkStatistic? best;

    for (final workMap in works) {
      final work = Work.fromMap(workMap);

      final workShifts = shifts.where((shift) {
        return shift["workId"] == work.id;
      }).toList();

      double income = 0;
      double expense = 0;

      for (final shift in workShifts) {
        income += (shift["income"] as num).toDouble();
        expense += (shift["expense"] as num).toDouble();
      }

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
}
