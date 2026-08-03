import '../../features/expense/model/expense_model.dart';
import '../../features/income/model/income_model.dart';
import '../../features/shift/model/shift_model.dart';
import '../../features/shift/model/shift_summary.dart';
import '../../features/work/model/work_model.dart';

class SalaryEngine {
  static const String salaryIncomeIdPrefix = 'salary-';

  static String salaryIncomeId(String shiftId) =>
      '$salaryIncomeIdPrefix$shiftId';

  static bool shouldAutoGenerateSalary(Work work) {
    return work.salaryType == Work.daily || work.salaryType == Work.hourly;
  }

  static double calculateSalary(
    Work work, {
    required DateTime startDateTime,
    required DateTime? endDateTime,
  }) {
    return work.computeSalaryForShift(
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );
  }

  static bool isSalaryIncomeId(String id) {
    return id.startsWith(salaryIncomeIdPrefix);
  }

  static String salaryTitleForWork(Work work) {
    return work.salaryType == Work.daily ? 'Daily salary' : 'Hourly salary';
  }

  static Income? buildSalaryIncomeForShift(Work work, Shift shift) {
    if (!shouldAutoGenerateSalary(work)) {
      return null;
    }

    if (shift.startDateTime == null) {
      return null;
    }

    final amount = calculateSalary(
      work,
      startDateTime: shift.startDateTime!,
      endDateTime: shift.endDateTime,
    );

    if (amount <= 0) {
      return null;
    }

    return Income(
      id: salaryIncomeId(shift.id),
      shiftId: shift.id,
      title: work.salaryType == Work.daily ? 'Daily salary' : 'Hourly salary',
      amount: amount,
      tip: 0,
      note: 'Auto-generated salary',
      generated: true,
      createdAt: DateTime.now(),
    );
  }

  static ShiftSummary calculateShiftSummary({
    required Work work,
    required Shift shift,
    required List<Income> incomes,
    required List<Expense> expenses,
  }) {
    final salaryIncome = buildSalaryIncomeForShift(work, shift);

    final displayedIncomes = List<Income>.from(incomes);
    if (salaryIncome != null &&
        displayedIncomes.every((income) => income.id != salaryIncome.id)) {
      displayedIncomes.insert(0, salaryIncome);
    }

    final totalIncome = displayedIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );

    final totalTip = displayedIncomes.fold<double>(
      0,
      (sum, income) => sum + income.tip,
    );

    final totalExpense = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return ShiftSummary(
      incomeCount: displayedIncomes.length,
      expenseCount: expenses.length,
      totalIncome: totalIncome,
      totalTip: totalTip,
      totalExpense: totalExpense,
      profit: totalIncome + totalTip - totalExpense,
    );
  }
}
