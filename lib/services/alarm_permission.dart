import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmPermission {
  static const String _permissionRequestedKey =
      'exact_alarm_permission_requested';
  static const String _notificationPermissionKey =
      'notification_permission_requested';
  static const String _batteryOptimizationCheckedKey =
      'battery_optimization_checked';

  /// Initialize all permission checks - call this once at app startup
  static Future<void> initializePermissions() async {
    try {
      if (Platform.isAndroid) {
        await _handleNotificationPermission();
        await _handleExactAlarmPermission();
        await _checkBatteryOptimization();
      }
    } catch (e, st) {
      debugPrint('AlarmPermission.initializePermissions error: $e\n$st');
    }
  }

  /// Handle notification permission (Android 13+)
  static Future<void> _handleNotificationPermission() async {
    try {
      final settingsBox = Hive.box('settings');
      final hasRequestedBefore = settingsBox.get(
        _notificationPermissionKey,
        defaultValue: false,
      );

      if (!hasRequestedBefore) {
        if (!await Permission.notification.isGranted) {
          final status = await Permission.notification.request();
          debugPrint(' Notification permission status: $status');
        }
        await settingsBox.put(_notificationPermissionKey, true);
        debugPrint('Notification permission check completed and saved');
      } else {
        debugPrint(' Notification permission already checked previously');
      }
    } catch (e) {
      debugPrint('Failed to handle notification permission: $e');
    }
  }

  /// alarm permission (Android 12+)
  static Future<void> _handleExactAlarmPermission() async {
    try {
      final settingsBox = Hive.box('settings');
      final hasRequestedBefore = settingsBox.get(
        _permissionRequestedKey,
        defaultValue: false,
      );

      if (!hasRequestedBefore && await _shouldRequestExactAlarmPermission()) {
        debugPrint(
          '🔔 Requesting exact alarm permission for the first time...',
        );
        await _requestExactAlarmPermission();

        await settingsBox.put(_permissionRequestedKey, true);
        debugPrint(' Exact alarm permission requested and saved to Hive');
      } else if (hasRequestedBefore) {
        debugPrint(' Exact alarm permission already requested previously');
      } else {
        debugPrint(' Device does not require exact alarm permission');
        await settingsBox.put(_permissionRequestedKey, true);
      }
    } catch (e) {
      debugPrint('Failed to handle exact alarm permission: $e');
    }
  }

  /// Check if we need to request exact alarm permission
  static Future<bool> _shouldRequestExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final needsPermission =
          androidInfo.version.sdkInt >= 31; // Android 12 = API 31
      debugPrint(
        ' Android ${androidInfo.version.sdkInt}, needs permission: $needsPermission',
      );
      return needsPermission;
    } catch (e) {
      debugPrint('not determine Android version, permission needed: $e');
      return true; // think we need it if we can't determine version
    }
  }

  /// Requestingggg exact alarm permission using method channel
  static Future<void> _requestExactAlarmPermission() async {
    try {
      const platform = MethodChannel('exact_alarm_permission');
      await platform.invokeMethod('requestExactAlarmPermission');
      debugPrint('Requestedalarm permission via method channel');
    } catch (e) {
      debugPrint(
        ' Faild to request exact alarm permission via method channel: $e',
      );

      await _openAlarmSettings();
    }
  }

  /// Open alarm settings page
  static Future<void> _openAlarmSettings() async {
    try {
      const platform = MethodChannel('exact_alarm_permission');
      await platform.invokeMethod('openAlarmSettings');
      debugPrint('Opened alarm settings page as fallback');
    } catch (e) {
      debugPrint('Could not open alarm settings: $e');
    }
  }

  /// Check battery optimization status
  static Future<void> _checkBatteryOptimization() async {
    try {
      final settingsBox = Hive.box('settings');
      final hasCheckedBefore = settingsBox.get(
        _batteryOptimizationCheckedKey,
        defaultValue: false,
      );

      if (!hasCheckedBefore) {
        final isOptimized =
            !await Permission.ignoreBatteryOptimizations.isGranted;
        if (isOptimized) {
          debugPrint(
            'Battery optimization is enabled - may affect scheduled notifications',
          );
          // Store the status for future reference
          await settingsBox.put('battery_optimization_enabled', true);
        } else {
          debugPrint(
            'Battery optimization is disabled - notifications should work properly',
          );
          await settingsBox.put('battery_optimization_enabled', false);
        }
        await settingsBox.put(_batteryOptimizationCheckedKey, true);
      }
    } catch (e) {
      debugPrint(' Could not check battery optimization: $e');
    }
  }

  /// Checking if exact alarm permission has been requested before-------
  static Future<bool> hasRequestedExactAlarmPermission() async {
    try {
      final settingsBox = Hive.box('settings');
      return settingsBox.get(_permissionRequestedKey, defaultValue: false);
    } catch (e) {
      debugPrint('Error checking exact alarm permission status: $e');
      return false;
    }
  }

  /// Reset permission tracking (useful for testing)
  static Future<void> resetPermissionTracking() async {
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.delete(_permissionRequestedKey);
      await settingsBox.delete(_notificationPermissionKey);
      await settingsBox.delete(_batteryOptimizationCheckedKey);
      await settingsBox.delete('battery_optimization_enabled');
      debugPrint(' Permission tracking reset');
    } catch (e) {
      debugPrint('Error resetting permission tracking: $e');
    }
  }

  /// Get current permission status (for debugging/UI)
  static Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      final settingsBox = Hive.box('settings');

      return {
        'exact_alarm_requested': settingsBox.get(
          _permissionRequestedKey,
          defaultValue: false,
        ),
        'notification_requested': settingsBox.get(
          _notificationPermissionKey,
          defaultValue: false,
        ),
        'battery_optimization_checked': settingsBox.get(
          _batteryOptimizationCheckedKey,
          defaultValue: false,
        ),
        'battery_optimization_enabled': settingsBox.get(
          'battery_optimization_enabled',
          defaultValue: null,
        ),
        'notification_granted': Platform.isAndroid
            ? await Permission.notification.isGranted
            : true,
        'battery_optimization_ignored': Platform.isAndroid
            ? await Permission.ignoreBatteryOptimizations.isGranted
            : true,
      };
    } catch (e) {
      debugPrint('Error getting permission status: $e');
      return {};
    }
  }
}
