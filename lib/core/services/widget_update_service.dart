import 'package:flutter/services.dart';

class WidgetUpdateService {
  WidgetUpdateService._();

  static const _channel = MethodChannel('work_tracker/widget');

  static Future<void> update({required String title, required String subtitle}) async {
    try {
      await _channel.invokeMethod<void>('updateWidget', {
        'title': title,
        'subtitle': subtitle,
      });
    } on MissingPluginException {
      // Desktop and test environments do not have the Android widget bridge.
    }
  }
}
