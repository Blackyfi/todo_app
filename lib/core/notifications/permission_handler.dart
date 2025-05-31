import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:todo_app/core/logger/logger_service.dart';

class PermissionHandler {
  final LoggerService _logger;
  final flutter_notifications.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  PermissionHandler(this._logger, this._flutterLocalNotificationsPlugin);

  Future<void> requestPermission(
    Future<bool> Function() isFirstRunCheck,
    Future<void> Function() markPermissionRequested,
  ) async {
    try {
      final isFirstRun = await isFirstRunCheck();
      
      if (!isFirstRun) {
        await _logger.logInfo('Notification permissions already requested in the past');
        return;
      }
      
      await _logger.logInfo('Requesting notification permissions for first time');
      
      if (Platform.isIOS) {
        final iosPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
                
        if (iosPlugin != null) {
          final result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
          await _logger.logInfo('iOS notification permission request result: $result');
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          // For Android 13+ (API 33+), request notification permission
          bool granted = false;
          try {
            granted = await androidPlugin.requestNotificationsPermission() ?? false;
          } catch (e) {
            await _logger.logWarning('requestNotificationsPermission not available: $e');
            granted = await androidPlugin.areNotificationsEnabled() ?? false;
          }
          await _logger.logInfo('Android notification permission request result: $granted');
          
          // Also request exact alarm permission for precise scheduling
          bool exactAlarmGranted = false;
          try {
            exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission() ?? false;
          } catch (e) {
            await _logger.logWarning('requestExactAlarmsPermission not available: $e');
            exactAlarmGranted = true; // Assume granted on older versions
          }
          await _logger.logInfo('Android exact alarms permission request result: $exactAlarmGranted');
        }
      }
      
      await markPermissionRequested();
      
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting notification permissions', e, stackTrace);
    }
  }

  Future<bool> arePermissionsGranted() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          // For iOS, check if permissions are granted
          final settings = await iosPlugin.checkPermissions();
          final granted = (settings?.isAlertEnabled ?? false) && 
                          (settings?.isSoundEnabled ?? false) && 
                          (settings?.isBadgeEnabled ?? false);
          await _logger.logInfo('iOS notification permissions granted: $granted');
          return granted;
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final notificationsEnabled = await androidPlugin.areNotificationsEnabled() ?? false;
          bool exactAlarmsAllowed = true; // Default to true for older Android versions
          
          try {
            exactAlarmsAllowed = await androidPlugin.canScheduleExactNotifications() ?? false;
          } catch (e) {
            await _logger.logWarning('canScheduleExactNotifications not available: $e');
            exactAlarmsAllowed = true;
          }
          
          await _logger.logInfo('Android notifications enabled: $notificationsEnabled');
          await _logger.logInfo('Android exact alarms allowed: $exactAlarmsAllowed');
          
          return notificationsEnabled && exactAlarmsAllowed;
        }
      }
      return false;
    } catch (e, stackTrace) {
      await _logger.logError('Error checking notification permissions', e, stackTrace);
      return false;
    }
  }
  
  Future<void> showPermissionDialog(BuildContext context) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'To get reminders for your tasks, please allow notifications and exact alarms. '
            'Without these permissions, you won\'t receive any task reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await requestPermissions();
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error showing notification permission dialog', e, stackTrace);
    }
  }

  Future<void> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final iOSPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
        if (iOSPlugin != null) {
          final result = await iOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          await _logger.logInfo('iOS permission request result: $result');
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // Request notification permission
          bool notificationResult = false;
          try {
            notificationResult = await androidPlugin.requestNotificationsPermission() ?? false;
          } catch (e) {
            await _logger.logWarning('requestNotificationsPermission not available: $e');
          }
          await _logger.logInfo('Android notification permission result: $notificationResult');
          
          // Request exact alarms permission for precise scheduling
          bool exactAlarmResult = true; // Default to true for older versions
          try {
            exactAlarmResult = await androidPlugin.requestExactAlarmsPermission() ?? false;
          } catch (e) {
            await _logger.logWarning('requestExactAlarmsPermission not available: $e');
          }
          await _logger.logInfo('Android exact alarms permission result: $exactAlarmResult');
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting permissions', e, stackTrace);
    }
  }

  Future<void> showPermissionSettings(BuildContext context) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Settings'),
          content: const Text(
            'Please enable notifications and exact alarms in your device settings for this app to receive task reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      await _logger.logError('Error showing permission settings dialog', e, stackTrace);
    }
  }
}