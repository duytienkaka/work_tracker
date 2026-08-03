import 'package:flutter/foundation.dart';

import '../model/expense_model.dart';
import '../repository/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository repository;

  ExpenseProvider(this.repository);

  List<Expense> expenses = [];
  String? _currentShiftId;

  Future<void> loadByShift(String shiftId) async {
    _currentShiftId = shiftId;
    expenses = await repository.getExpensesByShift(shiftId);
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await repository.insertExpense(expense);
    await loadByShift(_currentShiftId ?? expense.shiftId);
  }

  Future<void> updateExpense(Expense expense) async {
    await repository.updateExpense(expense);
    await loadByShift(_currentShiftId ?? expense.shiftId);
  }

  Future<void> deleteExpense(String id, String shiftId) async {
    await repository.deleteExpense(id);
    await loadByShift(_currentShiftId ?? shiftId);
  }

  int expenseCount() => expenses.length;

  double totalExpense() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
