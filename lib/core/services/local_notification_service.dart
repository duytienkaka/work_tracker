import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/shift/model/shift_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  Future<void> scheduleShiftReminder(Shift shift) async {
    final start = shift.startDateTime;
    if (start == null) return;

    await cancelShiftReminder(shift.id);
    final scheduled = tz.TZDateTime.from(start, tz.local).subtract(
      const Duration(minutes: 30),
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: _notificationId(shift.id),
      title: 'Shift starts in 30 minutes',
      body: 'Work Tracker has a shift scheduled at ${shift.startTime}.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_reminders',
          'Shift reminders',
          channelDescription: 'Reminders for upcoming work shifts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelShiftReminder(String shiftId) async {
    await _plugin.cancel(id: _notificationId(shiftId));
  }

  Future<void> showFamilyUpdate(String body) async {
    await _plugin.show(
      id: 9001,
      title: 'Family workspace updated',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('family_updates', 'Family updates', channelDescription: 'Updates from your family workspace', importance: Importance.defaultImportance),
      ),
    );
  }

  int _notificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
