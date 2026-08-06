import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/provider/analytics_provider.dart';
import 'features/dashboard/provider/dashboard_provider.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/expense/provider/expense_provider.dart';
import 'features/expense/repository/expense_repository.dart';
import 'features/income/provider/income_provider.dart';
import 'features/income/repository/income_repository.dart';
import 'features/settings/provider/settings_provider.dart';
import 'features/settings/repository/settings_repository.dart';
import 'features/shift/provider/shift_provider.dart';
import 'features/shift/repository/shift_repository.dart';
import 'features/timeline/provider/timeline_provider.dart';
import 'features/work/provider/work_provider.dart';
import 'features/work/repository/work_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LocalNotificationService.instance.initialize();
  runApp(const WorkTrackerApp());
}

class WorkTrackerApp extends StatelessWidget {
  const WorkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => WorkRepository()),
        ChangeNotifierProvider(
          create: (context) => WorkProvider(context.read<WorkRepository>()),
        ),
        Provider(create: (_) => DashboardRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              DashboardProvider(context.read<DashboardRepository>()),
        ),
        Provider(create: (_) => ShiftRepository()),
        ChangeNotifierProvider(
          create: (context) => ShiftProvider(context.read<ShiftRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => TimelineProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        Provider(create: (_) => IncomeRepository()),
        ChangeNotifierProvider(
          create: (context) => IncomeProvider(
            context.read<IncomeRepository>(),
            shiftProvider: context.read<ShiftProvider>(),
            dashboardProvider: context.read<DashboardProvider>(),
            analyticsProvider: context.read<AnalyticsProvider>(),
            workProvider: context.read<WorkProvider>(),
            timelineProvider: context.read<TimelineProvider>(),
          ),
        ),
        Provider(create: (_) => ExpenseRepository()),
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider(
            context.read<ExpenseRepository>(),
            shiftProvider: context.read<ShiftProvider>(),
            dashboardProvider: context.read<DashboardProvider>(),
            analyticsProvider: context.read<AnalyticsProvider>(),
            workProvider: context.read<WorkProvider>(),
            timelineProvider: context.read<TimelineProvider>(),
          ),
        ),
        Provider(create: (_) => SettingsRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              SettingsProvider(context.read<SettingsRepository>())
                ..loadSettings(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: "Work Tracker",
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: settings.currentThemeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
