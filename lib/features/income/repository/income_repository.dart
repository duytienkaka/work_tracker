import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../model/income_model.dart';

class IncomeRepository {
  Future<Database> get _db async => AppDatabase.database();

  Future<List<Income>> getByShift(String shiftId) async {
    final db = await _db;

    final result = await db.query(
      'income',
      where: 'shift_id=?',
      whereArgs: [shiftId],
      orderBy: 'created_at DESC',
    );

    return result.map((row) => Income.fromMap(row)).toList();
  }

  Future<void> insert(Income income) async {
    final db = await _db;

    await db.insert(
      'income',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Income income) async {
    final db = await _db;

    await db.update(
      'income',
      income.toMap(),
      where: 'id=?',
      whereArgs: [income.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete('income', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Income>> getAll() async {
    final db = await _db;

    final result = await db.query('income', orderBy: 'created_at DESC');

    return result.map((row) => Income.fromMap(row)).toList();
  }
}
