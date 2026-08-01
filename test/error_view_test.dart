import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_tracker/shared/widgets/error_view.dart';

void main() {
  testWidgets('ErrorView shows message and retry action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(message: 'Không thể tải dữ liệu', onRetry: () {}),
        ),
      ),
    );

    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
