import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'alarm_permission.dart';

import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize plugin, create channel, and request permissions
  static Future<void> init({
    void Function(String? payload)? onDidReceiveNotificationResponse,
  }) async {
    try {
      // Initializ---------timezone data (for zonedSchedule)
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false, // We'll handle this manually
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          try {
            onDidReceiveNotificationResponse?.call(response.payload);
          } catch (e, st) {
            debugPrint('Notification payload handler error: $e\n$st');
          }
        },
      );

      // Create notification channel for Android 8+
      await _createNotificationChannel();

      // Handle all permissions using our AlarmPermission manager
      await AlarmPermission.initializePermissions();

      // Handle iOS permissions separately
      if (Platform.isIOS || Platform.isMacOS) {
        await _requestIOSPermissions();
      }

      debugPrint('NotificationService initialized successfully---');
    } catch (e, st) {
      debugPrint('NotificationService.init error: $e\n$st');
    }
  }

  /// Create Android notification channel
  static Future<void> _createNotificationChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        'todo_channel', // id (keep same name to avoid breaking other code)
        'To-Do Notifications', // title
        description: 'Task reminders and updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      debugPrint('Android notification channel created');
    } catch (e) {
      debugPrint(' Failed to create notification channel: $e');
    }
  }

  /// Request iOS/macOS permissions
  static Future<void> _requestIOSPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint(
        ' iOS permissions requested for us not required for android projecttt',
      );
    } catch (e) {
      debugPrint('Failed to request iOS permissions: $e');
    }
  }

  /// Show an immediate notification
  static Future<bool> showNow(
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      const android = AndroidNotificationDetails(
        'todo_channel',
        'To-Do Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        when: null, // Use current time
      );

      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: android, iOS: ios);

      await _plugin.show(0, title, body, details, payload: payload);
      debugPrint('Immediate notification sent: $title');
      return true;
    } catch (e, st) {
      debugPrint('showNow error: $e\n$st');
      return false;
    }
  }

  /// Schedule notification (returns notification id or null on failure)
  static Future<int?> schedule(
    String title,
    String body,
    DateTime dateTime, {
    String? payload,
  }) async {
    try {
      // Ensure timezone is set to IST
      if (tz.local.name == 'UTC') {
        final kolkataLocation = tz.getLocation('Asia/Kolkata');
        tz.setLocalLocation(kolkataLocation);
        debugPrint(' Reset timezone to: ${tz.local.name}');
      }

      // Get current time and create scheduled time in IST
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = tz.TZDateTime(
        tz.local,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      );

      // Validate it's in the future
      if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
        debugPrint('Cannot schedule notification in the past or present');
        debugPrint('Current: $now');
        debugPrint('Scheduled: $scheduledDate');
        return null;
      }

      final id = dateTime.millisecondsSinceEpoch ~/ 1000;

      const android = AndroidNotificationDetails(
        'todo_channel',
        'To-Do Notifications',
        channelDescription: 'Task reminders and updates',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        autoCancel: true,
        fullScreenIntent: true, // Helps show notification when app is closed
        category: AndroidNotificationCategory.reminder,
      );

      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const details = NotificationDetails(android: android, iOS: ios);

      debugPrint('Current time (IST): $now');
      debugPrint('Scheduled time (IST): $scheduledDate');
      debugPrint('Notification ID: $id');
      debugPrint(
        ' Time difference: ${scheduledDate.difference(now).inSeconds} seconds',
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // Verify the notification was scheduled
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      final scheduledNotif = pendingNotifications
          .where((n) => n.id == id)
          .firstOrNull;

      if (scheduledNotif != null) {
        debugPrint(
          ' Notification successfully scheduled: ${scheduledNotif.title}',
        );
        debugPrint(
          ' Total pending notifications: ${pendingNotifications.length}',
        );
      } else {
        debugPrint(
          ' Failed to schedule notification - not found in pending list',
        );
        return null;
      }

      return id;
    } catch (e, st) {
      debugPrint(' Schedule error: $e\n$st');
      return null;
    }
  }

  /// Cancel a notification
  static Future<bool> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint(' Cancelled notification with ID: $id');
      return true;
    } catch (e, st) {
      debugPrint(' Cancel error: $e\n$st');
      return false;
    }
  }

  /// Cancel all notifications
  static Future<bool> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint(' Cancelled all notifications');
      return true;
    } catch (e, st) {
      debugPrint('CancelAll error: $e\n$st');
      return false;
    }
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      final notifications = await _plugin.pendingNotificationRequests();
      debugPrint('Found ${notifications.length} pending notifications');
      return notifications;
    } catch (e, st) {
      debugPrint('GetPendingNotifications error: $e\n$st');
      return [];
    }
  }

  /// Get permission status for debugging
  static Future<Map<String, dynamic>> getPermissionStatus() async {
    return await AlarmPermission.getPermissionStatus();
  }

  /// Reset all permission tracking (for testing)
  static Future<void> resetPermissions() async {
    await AlarmPermission.resetPermissionTracking();
  }
}
