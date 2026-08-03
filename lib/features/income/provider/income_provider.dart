import 'package:flutter/material.dart';

import '../model/income_model.dart';
import '../repository/income_repository.dart';

class IncomeProvider extends ChangeNotifier {
  final IncomeRepository repository;

  IncomeProvider(this.repository);

  List<Income> incomes = [];
  String? _currentShiftId;

  Future<void> loadByShift(String shiftId) async {
    _currentShiftId = shiftId;
    incomes = await repository.getByShift(shiftId);
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    await repository.insert(income);
    await loadByShift(_currentShiftId ?? income.shiftId);
  }

  Future<void> updateIncome(Income income) async {
    await repository.update(income);
    await loadByShift(_currentShiftId ?? income.shiftId);
  }

  Future<void> deleteIncome(String id, String shiftId) async {
    await repository.delete(id);
    await loadByShift(_currentShiftId ?? shiftId);
  }

  double totalIncome() {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }

  double totalTip() {
    return incomes.fold(0.0, (sum, income) => sum + income.tip);
  }

  int incomeCount() => incomes.length;
}
