import 'package:flutter/material.dart';

import '../../expense/model/expense_model.dart';
import '../../income/model/income_model.dart';
import '../model/shift_model.dart';
import '../model/shift_summary.dart';
import '../repository/shift_repository.dart';

class ShiftProvider extends ChangeNotifier {
  final ShiftRepository repository;

  ShiftProvider(this.repository);

  List<Shift> shifts = [];
  String? _currentWorkId;

  double get totalIncome {
    return shifts.fold(0.0, (sum, item) => sum + item.income);
  }

  double get totalExpense {
    return shifts.fold(0.0, (sum, item) => sum + item.expense);
  }

  double get totalProfit {
    return totalIncome - totalExpense;
  }

  ShiftSummary buildSummary({
    required List<Income> incomes,
    required List<Expense> expenses,
  }) {
    final totalIncomeValue = incomes.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final totalTipValue = incomes.fold(0.0, (sum, item) => sum + item.tip);
    final totalExpenseValue = expenses.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return ShiftSummary(
      incomeCount: incomes.length,
      expenseCount: expenses.length,
      totalIncome: totalIncomeValue,
      totalTip: totalTipValue,
      totalExpense: totalExpenseValue,
      profit: totalIncomeValue + totalTipValue - totalExpenseValue,
    );
  }

  Future<void> load([String? workId]) async {
    _currentWorkId = workId;

    if (workId == null) {
      shifts = await repository.getAll();
    } else {
      shifts = await repository.getByWork(workId);
    }

    notifyListeners();
  }

  Future<void> refreshCurrentView() async {
    await load(_currentWorkId);
  }

  Future<void> add(Shift shift) async {
    await repository.insert(shift);

    await load(_currentWorkId ?? shift.workId);
  }

  Future<void> update(Shift shift) async {
    await repository.update(shift);

    await load(_currentWorkId ?? shift.workId);
  }

  Future<void> delete(String id, String workId) async {
    await repository.delete(id);

    await load(_currentWorkId ?? workId);
  }
}
