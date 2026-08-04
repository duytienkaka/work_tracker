import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/section_title.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../shift/provider/shift_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../../work/provider/work_provider.dart';
import '../model/currency_option.dart';
import '../provider/settings_provider.dart';
import '../service/export_service.dart';
import 'privacy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final themeMode = provider.themeMode;
    final currency = provider.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: 'Theme'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(
                  value: AppThemeMode.system,
                  label: Text('System'),
                ),
                ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
                ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  provider.updateThemeMode(selection.first);
                }
              },
            ),
          ),
          const SectionTitle(title: 'Currency'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<CurrencyOption>(
              segments: CurrencyOption.values
                  .map(
                    (option) =>
                        ButtonSegment(value: option, label: Text(option.label)),
                  )
                  .toList(),
              selected: {currency},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  provider.updateCurrency(selection.first);
                }
              },
            ),
          ),
          const SectionTitle(title: 'Data'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export Shift to CSV'),
                  subtitle: const Text('Lưu file vào thư mục Download'),
                  onTap: () async {
                    final shiftProvider = context.read<ShiftProvider>();
                    final service = ExportService();
                    final path = await service.exportShiftsToCsv(
                      shiftProvider.shifts,
                    );

                    if (!context.mounted) return;

                    if (path == null) {
                      if (shiftProvider.shifts.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chưa có dữ liệu để xuất.'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể xuất dữ liệu.'),
                          ),
                        );
                      }
                      return;
                    }

                    if (!context.mounted) return;

                    await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Export thành công'),
                          content: Text('File đã lưu tại: $path'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Reset data'),
                  subtitle: const Text(
                    'Xoá toàn bộ công việc, ca làm và giao dịch đã lưu.',
                  ),
                  onTap: () async {
                    final currentContext = context;
                    final shiftProvider = currentContext.read<ShiftProvider>();
                    final workProvider = currentContext.read<WorkProvider>();
                    final dashboardProvider = currentContext
                        .read<DashboardProvider>();
                    final analyticsProvider = currentContext
                        .read<AnalyticsProvider>();
                    final timelineProvider = currentContext
                        .read<TimelineProvider>();

                    final confirmed = await showDialog<bool>(
                      context: currentContext,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Xác nhận đặt lại dữ liệu'),
                          content: const Text(
                            'Bạn có chắc muốn xoá toàn bộ dữ liệu? Hành động này không thể hoàn tác.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Huỷ'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Đồng ý'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true || !currentContext.mounted) return;

                    try {
                      await AppDatabase.resetDatabase();
                      if (!currentContext.mounted) return;

                      await shiftProvider.load();
                      await workProvider.loadWorks();
                      await dashboardProvider.load();
                      await analyticsProvider.load();
                      await timelineProvider.loadTimeline();

                      if (!currentContext.mounted) return;
                      AppFeedback.showSuccess(
                        currentContext,
                        'Dữ liệu đã được đặt lại thành công.',
                      );
                    } catch (_) {
                      if (!currentContext.mounted) return;
                      AppFeedback.showError(
                        currentContext,
                        'Reset dữ liệu thất bại. Vui lòng thử lại.',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'Information'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App version and platform details'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Work Tracker',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Made with Flutter\nSQLite Local Database\nMaterial 3',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy'),
                  subtitle: const Text('Xem chính sách riêng tư'),
                  onTap: () {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('License'),
                  subtitle: const Text('Open Flutter license page'),
                  onTap: () {
                    if (!context.mounted) return;
                    showLicensePage(
                      context: context,
                      applicationName: 'Work Tracker',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
