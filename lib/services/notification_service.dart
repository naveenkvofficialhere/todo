import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);
    } catch (e, st) {
      debugPrint('Notification init failed: $e\n$st');
    }
  }

  static Future<bool> show(String title, String body) async {
    try {
      const android = AndroidNotificationDetails(
        'todo_channel',
        'To-Do Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: android);
      await _plugin.show(0, title, body, details);
      return true;
    } catch (e, st) {
      debugPrint('Notification show failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> schedule(String title, String body, DateTime when) async {
    try {
      const android = AndroidNotificationDetails(
        'todo_channel',
        'To-Do Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      final details = NotificationDetails(android: android);

      await _plugin.zonedSchedule(
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        when.millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        details,
        // uiLocalNotificationDateInterpretation:
        //     UILocalNotificationDateInterpretation.absoluteTime,
        // androidAllowWhileIdle: true,
      );
      return true;
    } catch (e, st) {
      debugPrint('Notification schedule failed: $e\n$st');
      return false;
    }
  }
}
