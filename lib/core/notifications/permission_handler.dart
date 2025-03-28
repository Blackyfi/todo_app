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
        final settings = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.IOSFlutterLocalNotificationsPlugin>()
            ?.getNotificationAppLaunchDetails();
        return settings?.notificationResponse != null;
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
            'To get reminders for your tasks, please allow notifications. '
            'Without this permission, you won\'t receive any task reminders.',
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
        // Android-specific permissions can be handled here if needed
      }
    }
  }
}