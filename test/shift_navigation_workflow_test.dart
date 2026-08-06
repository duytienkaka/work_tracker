import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:work_tracker/features/expense/model/expense_model.dart';
import 'package:work_tracker/features/expense/provider/expense_provider.dart';
import 'package:work_tracker/features/expense/repository/expense_repository.dart';
import 'package:work_tracker/features/income/model/income_model.dart';
import 'package:work_tracker/features/income/provider/income_provider.dart';
import 'package:work_tracker/features/income/repository/income_repository.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/shift/provider/shift_provider.dart';
import 'package:work_tracker/features/shift/repository/shift_repository.dart';
import 'package:work_tracker/features/shift/screen/shift_detail_page.dart';
import 'package:work_tracker/features/shift/screen/shift_form_page.dart';
import 'package:work_tracker/features/income/widgets/income_card.dart';
import 'package:work_tracker/features/work/model/work_model.dart';
import 'package:work_tracker/features/work/model/work_summary.dart';
import 'package:work_tracker/features/work/provider/work_provider.dart';
import 'package:work_tracker/features/work/repository/work_repository.dart';
import 'package:work_tracker/features/work/screen/work_detail_page.dart';

class _FakeIncomeRepository extends IncomeRepository {
  final List<Income> _incomes;

  _FakeIncomeRepository({List<Income>? incomes}) : _incomes = incomes ?? [];

  @override
  Future<List<Income>> getByShift(String shiftId) async => List.from(_incomes);
}

class _FakeExpenseRepository extends ExpenseRepository {
  final List<Expense> _expenses;

  _FakeExpenseRepository({List<Expense>? expenses})
    : _expenses = expenses ?? [];

  @override
  Future<List<Expense>> getExpensesByShift(String shiftId) async =>
      List.from(_expenses);
}

class _FakeWorkRepository extends WorkRepository {
  final List<Work> _works;
  final List<Shift> _shiftsByWork;

  _FakeWorkRepository({List<Work>? works, List<Shift>? shiftsByWork})
    : _works = works ?? [],
      _shiftsByWork = shiftsByWork ?? [];

  @override
  Future<List<Work>> getAllWorks() async => List.from(_works);

  @override
  Future<List<WorkSummary>> getWorkSummary() async {
    return _works
        .map(
          (work) => WorkSummary(
            work: work,
            totalShifts: 0,
            totalIncome: 0,
            totalExpense: 0,
          ),
        )
        .toList();
  }

  @override
  Future<List<Shift>> getShiftsByWork(String workId) async {
    return _shiftsByWork.where((shift) => shift.workId == workId).toList();
  }

  @override
  Future<WorkSummary> getSummary(String workId) async {
    final work = _works.firstWhere(
      (item) => item.id == workId,
      orElse: () => Work(
        id: workId,
        name: 'Unknown',
        description: '',
        salaryType: 0,
        dailyRate: 0,
        hourlyRate: 0,
        color: 0,
        icon: 0,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );

    return WorkSummary(
      work: work,
      totalShifts: 0,
      totalIncome: 0,
      totalExpense: 0,
    );
  }
}

void main() {
  testWidgets('shift detail page loads persisted incomes and expenses', (
    tester,
  ) async {
    final work = Work(
      id: 'work-1',
      name: 'Coffee Shop',
      description: 'Test work',
      salaryType: 1,
      dailyRate: 0,
      hourlyRate: 0,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 'shift-1',
      workId: work.id,
      workDate: DateTime(2024, 1, 15),
      startTime: '09:00',
      endTime: '17:00',
      income: 100,
      expense: 20,
      note: 'Test shift',
    );

    final income = Income(
      id: 'income-1',
      shiftId: shift.id,
      title: 'Coffee order',
      amount: 80,
      tip: 5,
      note: 'Online order',
      createdAt: DateTime.now(),
    );

    final expense = Expense(
      id: 'expense-1',
      shiftId: shift.id,
      title: 'Taxi',
      amount: 15,
      note: 'Ride home',
      createdAt: DateTime.now(),
    );

    final incomeProvider = IncomeProvider(
      _FakeIncomeRepository(incomes: [income]),
    );
    await incomeProvider.loadByShift(shift.id);

    final expenseProvider = ExpenseProvider(
      _FakeExpenseRepository(expenses: [expense]),
    );
    await expenseProvider.loadByShift(shift.id);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => WorkProvider(
              _FakeWorkRepository(works: [work], shiftsByWork: [shift]),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ShiftProvider(ShiftRepository()),
          ),
          ChangeNotifierProvider.value(value: incomeProvider),
          ChangeNotifierProvider.value(value: expenseProvider),
        ],
        child: MaterialApp(
          home: ShiftDetailPage(work: work, shift: shift),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump();

    // Verify providers were preloaded with test data
    expect(
      incomeProvider.incomes.length,
      1,
      reason: 'IncomeProvider should have one income loaded',
    );
    expect(
      expenseProvider.expenses.length,
      1,
      reason: 'ExpenseProvider should have one expense loaded',
    );

    // debug output for troubleshooting
    print('INCOMES: ${incomeProvider.incomes.map((i) => i.title).toList()}');
    print('EXPENSES: ${expenseProvider.expenses.map((e) => e.title).toList()}');

    // Dump all Text widgets rendered for inspection
    final textData = tester
        .widgetList(find.byType(Text))
        .map((w) => (w as Text).data)
        .toList();
    print('TEXT WIDGETS: $textData');

    // Dump IncomeCard count
    final incomeCardCount = tester.widgetList(find.byType(IncomeCard)).length;
    print('IncomeCard count: $incomeCardCount');

    expect(find.text('Coffee order'), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('tapping a shift in work detail opens shift detail', (
    tester,
  ) async {
    final work = Work(
      id: 'work-1',
      name: 'Coffee Shop',
      description: 'Test work',
      salaryType: 1,
      dailyRate: 0,
      hourlyRate: 0,
      color: 0,
      icon: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final shift = Shift(
      id: 'shift-1',
      workId: work.id,
      workDate: DateTime(2024, 1, 15),
      startTime: '09:00',
      endTime: '17:00',
      income: 100,
      expense: 20,
      note: 'Test shift',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => WorkProvider(
              _FakeWorkRepository(works: [work], shiftsByWork: [shift]),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ShiftProvider(ShiftRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => IncomeProvider(_FakeIncomeRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => ExpenseProvider(_FakeExpenseRepository()),
          ),
        ],
        child: MaterialApp(
          home: WorkDetailPage(
            summary: WorkSummary(
              work: work,
              totalShifts: 1,
              totalIncome: 100,
              totalExpense: 20,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('09:00 → 17:00'));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftDetailPage), findsOneWidget);
    expect(find.byType(ShiftFormPage), findsNothing);
  });
}
