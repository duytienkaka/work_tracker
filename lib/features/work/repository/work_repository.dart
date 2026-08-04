import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../shift/model/shift_model.dart';
import '../../shift/repository/shift_repository.dart';
import '../model/work_model.dart';
import '../model/work_summary.dart';

class WorkRepository {
  Future<Database> get _db async => await AppDatabase.database();

  Future<List<Work>> getAllWorks() async {
    final db = await _db;

    final result = await db.query("works");

    return result.map((e) => Work.fromMap(e)).toList();
  }

  Future<void> insertWork(Work work) async {
    final db = await _db;

    await db.insert(
      "works",
      work.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWork(Work work) async {
    final db = await _db;

    await db.update(
      "works",
      work.toMap(),
      where: "id = ?",
      whereArgs: [work.id],
    );

    final shiftRepository = ShiftRepository();
    await shiftRepository.refreshGeneratedIncomeForWork(work.id);
  }

  Future<void> deleteWork(String id) async {
    final db = await _db;

    await db.transaction((txn) async {
      final shiftIds = await txn.rawQuery(
        'SELECT id FROM shifts WHERE workId = ?',
        [id],
      );

      if (shiftIds.isNotEmpty) {
        final ids = shiftIds
            .map((row) => row['id'])
            .whereType<String>()
            .toList();

        await txn.delete(
          'income',
          where: 'shift_id IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
        await txn.delete(
          'expense',
          where: 'shift_id IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
      }

      await txn.delete('shifts', where: 'workId = ?', whereArgs: [id]);
      await txn.delete('works', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Map<String, int>> getDeleteSummary(String workId) async {
    final db = await _db;

    final shiftRows = await db.query(
      'shifts',
      columns: ['id'],
      where: 'workId = ?',
      whereArgs: [workId],
    );
    final shiftIds = shiftRows
        .map((row) => row['id'])
        .whereType<String>()
        .toList();

    final incomeCount = shiftIds.isEmpty
        ? 0
        : (await db.rawQuery(
                'SELECT COUNT(*) as count FROM income WHERE shift_id IN (${List.filled(shiftIds.length, '?').join(',')})',
                shiftIds,
              )).first['count']
              as int;

    final expenseCount = shiftIds.isEmpty
        ? 0
        : (await db.rawQuery(
                'SELECT COUNT(*) as count FROM expense WHERE shift_id IN (${List.filled(shiftIds.length, '?').join(',')})',
                shiftIds,
              )).first['count']
              as int;

    return {
      'shifts': shiftIds.length,
      'income': incomeCount,
      'expense': expenseCount,
    };
  }

  Future<List<Shift>> getShiftsByWork(String workId) async {
    final repository = ShiftRepository();
    return repository.getByWork(workId);
  }

  Future<List<WorkSummary>> getWorkSummary() async {
    final db = await _db;
    final shiftRepository = ShiftRepository();

    final works = await db.query("works");
    final shifts = await shiftRepository.getAll();

    final List<WorkSummary> result = [];

    for (final workMap in works) {
      final work = Work.fromMap(workMap);

      final workShifts = shifts.where((shift) {
        return shift.workId == work.id;
      }).toList();

      double income = 0;
      double expense = 0;

      for (final shift in workShifts) {
        income += shift.income;
        expense += shift.expense;
      }

      result.add(
        WorkSummary(
          work: work,
          totalShifts: workShifts.length,
          totalIncome: income,
          totalExpense: expense,
          workId: work.id,
          totalShift: workShifts.length,
          income: income,
          expense: expense,
        ),
      );
    }

    return result;
  }

  Future<WorkSummary> getSummary(String workId) async {
    final db = await _db;
    final shiftRepository = ShiftRepository();

    final shifts = await shiftRepository.getByWork(workId);

    double income = 0;
    double expense = 0;

    for (final shift in shifts) {
      income += shift.income;
      expense += shift.expense;
    }

    final work = await db.query("works", where: "id=?", whereArgs: [workId]);
    final workModel = work.isEmpty ? null : Work.fromMap(work.first);

    return WorkSummary(
      work:
          workModel ??
          Work(
            id: workId,
            name: 'Unknown',
            description: '',
            salaryType: Work.legacyFixed,
            dailyRate: 0,
            hourlyRate: 0,
            color: 0,
            icon: Icons.work.codePoint,
            isActive: true,
            createdAt: DateTime.now(),
          ),
      totalShifts: shifts.length,
      totalIncome: income,
      totalExpense: expense,
      workId: workId,
      totalShift: shifts.length,
      income: income,
      expense: expense,
    );
  }
}
