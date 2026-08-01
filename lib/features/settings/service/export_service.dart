import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../../shift/model/shift_model.dart';

class ExportService {
  Future<String?> exportShiftsToCsv(List<Shift> shifts) async {
    if (shifts.isEmpty) return null;

    final permissionGranted = await _requestStoragePermission();
    if (!permissionGranted) {
      return null;
    }

    final directory = await _getDownloadDirectory();
    if (directory == null) {
      return null;
    }

    final fileName = _fileNameForNow();
    final file = File('${directory.path}/$fileName');

    final csvBuffer = StringBuffer();
    csvBuffer.writeln(
      'Date,Work,Start Time,End Time,Income,Expense,Profit,Note',
    );

    for (final shift in shifts) {
      final profit = shift.income - shift.expense;
      csvBuffer.writeln(
        '${_formatDate(shift.workDate)},${_escape(shift.workId)},${shift.startTime},${shift.endTime},${shift.income.toStringAsFixed(0)},${shift.expense.toStringAsFixed(0)},${profit.toStringAsFixed(0)},${_escape(shift.note)}',
      );
    }

    await file.writeAsString(csvBuffer.toString());
    return file.path;
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Prefer the public Downloads folder when available
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;

      // Fallback to external storage directory (app-specific)
      return await getExternalStorageDirectory();
    }

    return await getApplicationDocumentsDirectory();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    return value;
  }

  String _fileNameForNow() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'work_tracker_$year$month${day}_$hour$minute.csv';
  }
}
