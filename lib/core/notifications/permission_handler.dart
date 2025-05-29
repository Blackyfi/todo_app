import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:app_settings/app_settings.dart';
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
      
      await _logger.logInfo('Requesting notification permissions');
      
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
          final granted = await androidPlugin.areNotificationsEnabled();
          await _logger.logInfo('Android notification enabled status: $granted');
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
          final result = await iosPlugin.pendingNotificationRequests();
          return result.isNotEmpty;
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          return await androidPlugin.areNotificationsEnabled() ?? false;
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
            'To get reminders for your tasks, please enable notifications in your device settings. '
            'Tap "Enable" to open the app settings where you can allow notifications.',
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
        await openAppSettings();
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error showing notification permission dialog', e, stackTrace);
    }
  }

  Future<void> openAppSettings() async {
    try {
      await _logger.logInfo('Opening app settings for notification permissions');
      
      // Use app_settings package to open the notification settings
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      
      await _logger.logInfo('Successfully opened app notification settings');
    } catch (e, stackTrace) {
      await _logger.logError('Error opening app settings, trying alternative method', e, stackTrace);
      
      // Fallback: try to open general app settings if notification settings fail
      try {
        await AppSettings.openAppSettings();
        await _logger.logInfo('Opened general app settings as fallback');
      } catch (fallbackError, fallbackStackTrace) {
        await _logger.logError('Error opening fallback app settings', fallbackError, fallbackStackTrace);
      }
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      final iOSPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    }
  }
}