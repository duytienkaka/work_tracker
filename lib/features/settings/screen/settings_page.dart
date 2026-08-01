import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shift/provider/shift_provider.dart';
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
          const Text(
            'Theme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text('Light'),
                  ),
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
          ),
          const SizedBox(height: 16),
          const Text(
            'Currency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<CurrencyOption>(
                segments: CurrencyOption.values
                    .map(
                      (option) => ButtonSegment(
                        value: option,
                        label: Text(option.label),
                      ),
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
          ),
          const SizedBox(height: 16),
          const Text(
            'Data',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Export Shift to CSV'),
                  subtitle: const Text('Lưu file vào thư mục Download'),
                  trailing: const Icon(Icons.file_download_outlined),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('About'),
                  subtitle: const Text('App version and platform details'),
                  leading: const Icon(Icons.info_outline),
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
                  title: const Text('Privacy'),
                  subtitle: const Text('Xem chính sách riêng tư'),
                  leading: const Icon(Icons.privacy_tip_outlined),
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
                  title: const Text('License'),
                  subtitle: const Text('Open Flutter license page'),
                  leading: const Icon(Icons.verified_user_outlined),
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
