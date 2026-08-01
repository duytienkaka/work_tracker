import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:work_tracker/features/settings/provider/settings_provider.dart';
import 'package:work_tracker/features/settings/repository/settings_repository.dart';
import 'package:work_tracker/features/settings/screen/settings_page.dart';

void main() {
  testWidgets('Settings page shows app sections', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(SettingsRepository()),
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Export Shift to CSV'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });
}
