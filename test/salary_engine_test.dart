import 'package:flutter_test/flutter_test.dart';
import 'package:work_tracker/core/services/salary_engine.dart';
import 'package:work_tracker/features/expense/model/expense_model.dart';
import 'package:work_tracker/features/income/model/income_model.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/work/model/work_model.dart';

void main() {
  test('Hourly work auto-generates salary income based on duration', () {
    final work = Work(
      id: 'work-hourly',
      name: 'Hourly Work',
      description: 'Hourly job',
      salaryType: Work.hourly,
      dailyRate: 0,
      hourlyRate: 50,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 'shift-hourly',
      workId: work.id,
      workDate: DateTime(2025, 1, 1),
      startTime: '09:00',
      endTime: '12:30',
      income: 0,
      expense: 0,
      note: '',
    );

    final salaryIncome = SalaryEngine.buildSalaryIncomeForShift(work, shift);

    expect(salaryIncome, isNotNull);
    expect(salaryIncome!.amount, 175);
    expect(salaryIncome.title, 'Hourly salary');

    final summary = SalaryEngine.calculateShiftSummary(
      work: work,
      shift: shift,
      incomes: [],
      expenses: [],
    );

    expect(summary.totalIncome, 175);
    expect(summary.profit, 175);
    expect(summary.incomeCount, 1);
  });

  test('Daily work auto-generates salary income as daily rate', () {
    final work = Work(
      id: 'work-daily',
      name: 'Daily Work',
      description: 'Daily job',
      salaryType: Work.daily,
      dailyRate: 200,
      hourlyRate: 0,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 'shift-daily',
      workId: work.id,
      workDate: DateTime(2025, 1, 2),
      startTime: '08:00',
      endTime: '17:00',
      income: 0,
      expense: 0,
      note: '',
    );

    final salaryIncome = SalaryEngine.buildSalaryIncomeForShift(work, shift);

    expect(salaryIncome, isNotNull);
    expect(salaryIncome!.amount, 200);
    expect(salaryIncome.title, 'Daily salary');

    final summary = SalaryEngine.calculateShiftSummary(
      work: work,
      shift: shift,
      incomes: [salaryIncome],
      expenses: [
        Expense(
          id: 'expense-1',
          shiftId: shift.id,
          title: 'Transport',
          amount: 20,
          note: '',
          createdAt: DateTime.now(),
        ),
      ],
    );

    expect(summary.totalIncome, 200);
    expect(summary.totalExpense, 20);
    expect(summary.profit, 180);
  });

  test('Freelance work does not auto-generate salary income', () {
    final work = Work(
      id: 'work-freelance',
      name: 'Freelance Work',
      description: 'Freelance job',
      salaryType: Work.freelance,
      dailyRate: 0,
      hourlyRate: 0,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 'shift-freelance',
      workId: work.id,
      workDate: DateTime(2025, 1, 3),
      startTime: '10:00',
      endTime: '14:00',
      income: 75,
      expense: 0,
      note: '',
    );

    final salaryIncome = SalaryEngine.buildSalaryIncomeForShift(work, shift);

    expect(salaryIncome, isNull);

    final summary = SalaryEngine.calculateShiftSummary(
      work: work,
      shift: shift,
      incomes: [
        Income(
          id: 'income-1',
          shiftId: shift.id,
          title: 'Freelance order',
          amount: 75,
          tip: 0,
          note: '',
          createdAt: DateTime.now(),
        ),
      ],
      expenses: [],
    );

    expect(summary.totalIncome, 75);
    expect(summary.profit, 75);
  });
}
