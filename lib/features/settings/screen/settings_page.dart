import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../shift/provider/shift_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../../work/provider/work_provider.dart';
import '../model/currency_option.dart';
import '../provider/settings_provider.dart';
import '../service/export_service.dart';
import 'privacy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text('This removes all works, shifts, income, and expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await AppDatabase.resetDatabase();
      await context.read<ShiftProvider>().load();
      await context.read<WorkProvider>().loadWorks();
      await context.read<DashboardProvider>().load();
      await context.read<AnalyticsProvider>().load();
      await context.read<TimelineProvider>().loadTimeline();
      if (context.mounted) AppFeedback.showSuccess(context, 'Data reset successfully');
    } catch (_) {
      if (context.mounted) AppFeedback.showError(context, 'Could not reset data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('Appearance'),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeLabel(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _themePicker(context, settings),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Currency'),
                subtitle: Text(settings.currency.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _currencyPicker(context, settings),
              ),
            ],
          ),
          _SectionLabel('Your data'),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Export data'),
                subtitle: const Text('Create a local backup of your records'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _export(context),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: colors.error),
                title: Text('Reset all data', style: TextStyle(color: colors.error)),
                subtitle: const Text('Permanently remove everything stored locally'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _reset(context),
              ),
            ],
          ),
          _SectionLabel('About'),
          _SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('About Work Tracker'),
                subtitle: const Text('Version 1.0.0'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Work Tracker',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Personal work management',
                ),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Privacy'),
                subtitle: const Text('Your data stays on this device'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Work Tracker',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final shiftProvider = context.read<ShiftProvider>();
    await shiftProvider.load();
    final path = await ExportService().exportShiftsToCsv(shiftProvider.shifts);
    if (!context.mounted) return;

    if (path == null) {
      AppFeedback.showError(
        context,
        shiftProvider.shifts.isEmpty
            ? 'There is no shift data to export'
            : 'Could not export data',
      );
      return;
    }

    AppFeedback.showSuccess(context, 'Exported to $path');
  }

  String _themeLabel(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => 'Use device settings',
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };

  void _themePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) => RadioListTile<AppThemeMode>(
            value: mode,
            groupValue: settings.themeMode,
            title: Text(_themeLabel(mode)),
            onChanged: (value) {
              if (value != null) settings.updateThemeMode(value);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _currencyPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: CurrencyOption.values.map((option) => RadioListTile<CurrencyOption>(
            value: option,
            groupValue: settings.currency,
            title: Text(option.label),
            onChanged: (value) {
              if (value != null) settings.updateCurrency(value);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}
