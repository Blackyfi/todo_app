import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:app_settings/app_settings.dart';

class PermissionHandler {
  final LoggerService _logger;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

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
      await markPermissionRequested();
      
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting notification permissions', e, stackTrace);
    }
  }

  Future<bool> arePermissionsGranted() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          return enabled ?? false;
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final settings = await iosPlugin.checkPermissions();
          return settings?.isEnabled ?? false;
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
      final hasPermissions = await arePermissionsGranted();
      
      if (hasPermissions) {
        await _logger.logInfo('Notifications already enabled');
        return;
      }

      if (!context.mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'To get reminders for your tasks, please enable notifications in your device settings. '
            'Tap "Open Settings" to go to the notification settings for this app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await _openAppSettings();
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error showing notification permission dialog', e, stackTrace);
    }
  }

  Future<void> requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final iosPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          try {
            final granted = await androidPlugin.requestNotificationsPermission();
            await _logger.logInfo('Android notification permission granted: $granted');
            
            // If permission was denied, show option to open settings
            if (granted == false) {
              await _logger.logInfo('Permission denied, consider opening app settings');
            }
          } catch (e) {
            // If the method doesn't exist, we'll just log and continue
            await _logger.logWarning('requestNotificationsPermission method not available: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting permissions', e, stackTrace);
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await _logger.logInfo('Opening app notification settings');
      
      if (Platform.isAndroid) {
        // For Android, open notification settings specifically
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      } else if (Platform.isIOS) {
        // For iOS, open general app settings
        await AppSettings.openAppSettings();
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error opening app settings', e, stackTrace);
      
      // Fallback to general app settings if notification-specific fails
      try {
        await AppSettings.openAppSettings();
      } catch (fallbackError, fallbackStackTrace) {
        await _logger.logError('Error opening fallback app settings', fallbackError, fallbackStackTrace);
      }
    }
  }

  /// Public method to open app settings from anywhere in the app
  Future<void> openAppSettings() async {
    await _openAppSettings();
  }
}