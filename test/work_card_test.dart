import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';
import 'package:work_tracker/features/work/model/work_model.dart';
import 'package:work_tracker/features/work/model/work_summary.dart';
import 'package:work_tracker/features/work/provider/work_provider.dart';
import 'package:work_tracker/features/work/repository/work_repository.dart';
import 'package:work_tracker/features/work/screen/work_detail_page.dart';
import 'package:work_tracker/features/work/widgets/work_card.dart';

class FakeWorkRepository extends WorkRepository {
  @override
  Future<List<Shift>> getShiftsByWork(String workId) async => [];
}

void main() {
  testWidgets('WorkCard shows summary statistics', (tester) async {
    final work = Work(
      id: '1',
      name: 'Grab',
      description: 'Giao hàng',
      salaryType: 3,
      color: 0,
      icon: Icons.work.codePoint,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final summary = WorkSummary(
      workId: work.id,
      totalShift: 3,
      income: 1900000,
      expense: 400000,
      work: work,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WorkCard(summary: summary)),
      ),
    );

    expect(find.text('Grab'), findsOneWidget);
    expect(find.text('3 ca'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(find.text('Lợi nhuận'), findsOneWidget);
  });

  testWidgets('WorkDetailPage shows add-shift action', (tester) async {
    final work = Work(
      id: '2',
      name: 'Taxi',
      description: 'Đi lại',
      salaryType: 1,
      color: 0,
      icon: Icons.work.codePoint,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final summary = WorkSummary(
      workId: work.id,
      totalShift: 0,
      income: 0,
      expense: 0,
      work: work,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WorkProvider(FakeWorkRepository()),
        child: MaterialApp(home: WorkDetailPage(summary: summary)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Thêm ca làm'), findsOneWidget);
  });
}
