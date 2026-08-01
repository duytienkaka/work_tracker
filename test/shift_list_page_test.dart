import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/shift/provider/shift_provider.dart';
import 'package:work_tracker/features/shift/repository/shift_repository.dart';
import 'package:work_tracker/features/shift/screen/shift_list_page.dart';
import 'package:work_tracker/features/work/model/work_model.dart';
import 'package:work_tracker/features/work/provider/work_provider.dart';
import 'package:work_tracker/features/work/repository/work_repository.dart';

class TestShiftProvider extends ShiftProvider {
  TestShiftProvider(List<Shift> initialShifts) : super(ShiftRepository()) {
    shifts = List.from(initialShifts);
  }

  @override
  Future<void> load([String? workId]) async {
    notifyListeners();
  }
}

class TestWorkProvider extends WorkProvider {
  TestWorkProvider(List<Work> initialWorks) : super(WorkRepository()) {
    works = List.from(initialWorks);
    filteredWorks = List.from(initialWorks);
    summaries = [];
  }

  @override
  Future<void> loadWorks() async {
    notifyListeners();
  }
}

void main() {
  testWidgets('Shift list filters by search query', (tester) async {
    final shiftProvider = TestShiftProvider([
      Shift(
        id: '1',
        workId: 'w1',
        workDate: DateTime(2024, 1, 1),
        startTime: '08:00',
        endTime: '12:00',
        income: 500000,
        expense: 100000,
        note: 'Grab',
      ),
      Shift(
        id: '2',
        workId: 'w2',
        workDate: DateTime(2024, 1, 2),
        startTime: '18:00',
        endTime: '22:00',
        income: 320000,
        expense: 100000,
        note: 'Cafe',
      ),
    ]);

    final workProvider = TestWorkProvider([
      Work(
        id: 'w1',
        name: 'Grab',
        description: '',
        salaryType: 0,
        color: 0,
        icon: 0,
        isActive: true,
        createdAt: DateTime(2024),
      ),
      Work(
        id: 'w2',
        name: 'Cafe',
        description: '',
        salaryType: 0,
        color: 0,
        icon: 0,
        isActive: true,
        createdAt: DateTime(2024),
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShiftProvider>.value(value: shiftProvider),
          ChangeNotifierProvider<WorkProvider>.value(value: workProvider),
        ],
        child: const MaterialApp(home: ShiftListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tất cả ca làm'), findsWidgets);
    expect(find.text('Tìm kiếm ca làm'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'grab');
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
  });
}
