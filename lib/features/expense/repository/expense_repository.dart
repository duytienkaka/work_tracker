import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../model/expense_model.dart';

class ExpenseRepository {
  Future<Database> get _db async => AppDatabase.database();

  Future<List<Expense>> getExpensesByShift(String shiftId) async {
    final db = await _db;
    final result = await db.query(
      'expense',
      where: 'shift_id=?',
      whereArgs: [shiftId],
      orderBy: 'created_at DESC',
    );

    return result.map((row) => Expense.fromMap(row)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await _db;
    await db.insert(
      'expense',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _db;
    await db.update(
      'expense',
      expense.toMap(),
      where: 'id=?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _db;
    await db.delete('expense', where: 'id=?', whereArgs: [id]);
  }
}
