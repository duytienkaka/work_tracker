import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_tracker/features/dashboard/widgets/dashboard_header.dart';

void main() {
  testWidgets('DashboardHeader shows welcome content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DashboardHeader())),
    );

    expect(find.textContaining('Work Tracker'), findsOneWidget);
    expect(find.textContaining('Theo dõi thu nhập'), findsOneWidget);
  });
}
