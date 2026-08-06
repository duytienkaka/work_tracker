import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';

class BackupService {
  Future<String> createBackup() async {
    final db = await AppDatabase.database();
    final payload = {
      'format': 'work_tracker_backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'works': await db.query('works'),
      'shifts': await db.query('shifts'),
      'income': await db.query('income'),
      'expense': await db.query('expense'),
    };

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/work_tracker_backup_$timestamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<bool> restoreBackup() async {
    final directory = await getApplicationDocumentsDirectory();
    final backups = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.contains('work_tracker_backup_'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    if (backups.isEmpty) return false;

    final file = backups.first;
    final payload = jsonDecode(await file.readAsString());
    if (payload is! Map || payload['format'] != 'work_tracker_backup') {
      throw const FormatException('Invalid Work Tracker backup file.');
    }

    final db = await AppDatabase.database();
    await db.transaction((transaction) async {
      await transaction.delete('income');
      await transaction.delete('expense');
      await transaction.delete('shifts');
      await transaction.delete('works');

      for (final row in _rows(payload['works'])) {
        await transaction.insert('works', row);
      }
      for (final row in _rows(payload['shifts'])) {
        await transaction.insert('shifts', row);
      }
      for (final row in _rows(payload['income'])) {
        await transaction.insert('income', row);
      }
      for (final row in _rows(payload['expense'])) {
        await transaction.insert('expense', row);
      }
    });
    return true;
  }

  List<Map<String, Object?>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((row) {
      return row.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }
}
