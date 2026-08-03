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
import 'package:work_tracker/features/work/model/work_model.dart';
import 'package:work_tracker/features/work/model/work_summary.dart';
import 'package:work_tracker/features/work/provider/work_provider.dart';
import 'package:work_tracker/features/work/repository/work_repository.dart';
import 'package:work_tracker/features/work/screen/work_detail_page.dart';

class _FakeIncomeRepository extends IncomeRepository {
  @override
  Future<List<Income>> getByShift(String shiftId) async => [];
}

class _FakeExpenseRepository extends ExpenseRepository {
  @override
  Future<List<Expense>> getExpensesByShift(String shiftId) async => [];
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
  testWidgets('tapping a shift in work detail opens shift detail', (
    tester,
  ) async {
    final work = Work(
      id: 'work-1',
      name: 'Coffee Shop',
      description: 'Test work',
      salaryType: 1,
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
