import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../work/model/work_model.dart';
import '../../../core/services/salary_engine.dart';
import '../model/shift_model.dart';

class ShiftRepository {
  Future<Database> get _db async => AppDatabase.database();

  Future<List<Shift>> getByWork(String workId) async {
    final db = await _db;

    final result = await db.query(
      "shifts",
      where: "workId=?",
      whereArgs: [workId],
      orderBy: "workDate DESC",
    );

    final shifts = result.map((e) => Shift.fromMap(e)).toList();
    return Future.wait(shifts.map(_hydrateShiftTotals));
  }

  Future<void> insert(Shift shift) async {
    final db = await _db;

    await db.insert(
      "shifts",
      shift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _syncGeneratedIncomeForShift(shift);
  }

  Future<void> update(Shift shift) async {
    final db = await _db;

    await db.update(
      "shifts",
      shift.toMap(),
      where: "id=?",
      whereArgs: [shift.id],
    );

    await _syncGeneratedIncomeForShift(shift);
  }

  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete('income', where: 'shift_id = ?', whereArgs: [id]);
    await db.delete('expense', where: 'shift_id = ?', whereArgs: [id]);
    await db.delete("shifts", where: "id=?", whereArgs: [id]);
  }

  Future<List<Shift>> getAll() async {
    final db = await _db;

    final result = await db.query(
      "shifts",
      orderBy: "workDate DESC,startTime DESC",
    );

    final shifts = result.map((e) => Shift.fromMap(e)).toList();
    return Future.wait(shifts.map(_hydrateShiftTotals));
  }

  Future<Shift?> getById(String id) async {
    final db = await _db;

    final result = await db.query(
      "shifts",
      where: "id=?",
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return _hydrateShiftTotals(Shift.fromMap(result.first));
  }

  Future<Shift> _hydrateShiftTotals(Shift shift) async {
    final db = await _db;

    await _syncGeneratedIncomeForShift(shift);

    final incomeRows = await db.query(
      'income',
      where: 'shift_id=?',
      whereArgs: [shift.id],
    );

    final expenseRows = await db.query(
      'expense',
      where: 'shift_id=?',
      whereArgs: [shift.id],
    );

    final totalIncome = incomeRows.fold<double>(0, (sum, row) {
      return sum + (row['amount'] as num).toDouble();
    });

    final totalExpense = expenseRows.fold<double>(0, (sum, row) {
      return sum + (row['amount'] as num).toDouble();
    });

    return shift.copyWith(income: totalIncome, expense: totalExpense);
  }

  Future<void> refreshGeneratedIncomeForWork(String workId) async {
    final db = await _db;
    final result = await db.query(
      'shifts',
      where: 'workId = ?',
      whereArgs: [workId],
    );

    for (final shiftMap in result) {
      final shift = Shift.fromMap(shiftMap);
      await _syncGeneratedIncomeForShift(shift);
    }
  }

  Future<void> _syncGeneratedIncomeForShift(Shift shift) async {
    final db = await _db;
    final workRows = await db.query(
      'works',
      where: 'id = ?',
      whereArgs: [shift.workId],
      limit: 1,
    );

    if (workRows.isEmpty) {
      await db.delete(
        'income',
        where: 'id = ?',
        whereArgs: [SalaryEngine.salaryIncomeId(shift.id)],
      );
      return;
    }

    final work = Work.fromMap(workRows.first);
    final generatedIncome = SalaryEngine.buildSalaryIncomeForShift(work, shift);
    final generatedId = SalaryEngine.salaryIncomeId(shift.id);

    if (generatedIncome == null) {
      await db.delete('income', where: 'id = ?', whereArgs: [generatedId]);
      return;
    }

    await db.insert(
      'income',
      generatedIncome.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
