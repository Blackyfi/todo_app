import 'dart:io';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';

/// Simplified notification service for compatibility with older plugin versions
class NotificationServiceFallback {
  static final NotificationServiceFallback _instance = NotificationServiceFallback._internal();

  factory NotificationServiceFallback() => _instance;

  NotificationServiceFallback._internal();

  final LoggerService _logger = LoggerService();
  final flutter_notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      flutter_notifications.FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('NotificationService already initialized');
      return;
    }

    try {
      await _logger.logInfo('Initializing NotificationService (Fallback)');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
      
      // Initialize plugin settings
      await _initializePluginSettings();
      
      // Create notification channels for Android
      await _createNotificationChannels();
      
      _isInitialized = true;
      await _logger.logInfo('NotificationService initialized successfully (Fallback)');
      
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService (Fallback)', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializePluginSettings() async {
    const androidSettings = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSSettings = flutter_notifications.DarwinInitializationSettings();
    
    const initSettings = flutter_notifications.InitializationSettings(
      android: androidSettings, 
      iOS: iOSSettings
    );

    final success = await flutterLocalNotificationsPlugin.initialize(initSettings);
    
    if (!(success ?? false)) {
      await _logger.logError('NotificationService initialization failed (Fallback)');
      throw Exception('Failed to initialize notification plugin');
    } else {
      await _logger.logInfo('Notification plugin initialized successfully (Fallback)');
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const androidChannel = flutter_notifications.AndroidNotificationChannel(
        'todo_app_channel',
        'Task Reminders',
        description: 'Notifications for task reminders',
        importance: flutter_notifications.Importance.high,
      );
      
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await _logger.logInfo('Notification channel created for Android (Fallback)');
      }
    }
  }

  Future<void> scheduleTaskNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
  ) async {
    if (!_isInitialized) {
      await _logger.logError('NotificationService not initialized, cannot schedule notification');
      return;
    }

    try {
      if (task.dueDate == null) {
        await _logger.logWarning('Cannot schedule notification: task has no due date, TaskID=${task.id}');
        return;
      }

      final notificationTime = setting.timeOption.calculateNotificationTime(
        task.dueDate!,
        setting.customTime,
      );

      // Don't schedule if the notification time is in the past
      if (notificationTime.isBefore(DateTime.now())) {
        await _logger.logWarning(
          'Skipping notification scheduling: notification time is in the past, TaskID=${task.id}'
        );
        return;
      }

      final notificationId = (task.id ?? 0) * 1000 + setting.timeOption.index;
      
      // Try to schedule with timezone, fallback to immediate if needed
      try {
        final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
        
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Task Reminder: ${task.title}',
          task.description.isNotEmpty ? task.description : 'This task is due soon.',
          scheduledDate,
          const flutter_notifications.NotificationDetails(
            android: flutter_notifications.AndroidNotificationDetails(
              'todo_app_channel',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: flutter_notifications.Importance.high,
              priority: flutter_notifications.Priority.high,
            ),
            iOS: flutter_notifications.DarwinNotificationDetails(),
          ),
          uiLocalNotificationDateInterpretation:
              flutter_notifications.UILocalNotificationDateInterpretation.absoluteTime,
        );
        
        await _logger.logInfo('Notification scheduled: TaskID=${task.id}, NotificationID=$notificationId');
        
      } catch (e) {
        await _logger.logWarning('zonedSchedule failed, using immediate notification: $e');
        
        // Fallback to immediate notification
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          'Task Reminder: ${task.title}',
          task.description.isNotEmpty ? task.description : 'This task is due soon.',
          const flutter_notifications.NotificationDetails(
            android: flutter_notifications.AndroidNotificationDetails(
              'todo_app_channel',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: flutter_notifications.Importance.high,
              priority: flutter_notifications.Priority.high,
            ),
            iOS: flutter_notifications.DarwinNotificationDetails(),
          ),
        );
      }
      
    } catch (e, stackTrace) {
      await _logger.logError('Error scheduling task notification (Fallback)', e, stackTrace);
    }
  }

  Future<void> showTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999999,
        'Test Notification',
        'This is a test notification to verify the system is working.',
        const flutter_notifications.NotificationDetails(
          android: flutter_notifications.AndroidNotificationDetails(
            'todo_app_channel',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: flutter_notifications.Importance.high,
            priority: flutter_notifications.Priority.high,
          ),
          iOS: flutter_notifications.DarwinNotificationDetails(),
        ),
      );
      await _logger.logInfo('Test notification shown (Fallback)');
    } catch (e, stackTrace) {
      await _logger.logError('Error showing test notification (Fallback)', e, stackTrace);
    }
  }

  Future<List<flutter_notifications.PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      await _logger.logInfo('Found ${pending.length} pending notifications (Fallback)');
      return pending;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting pending notifications (Fallback)', e, stackTrace);
      return [];
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      await _logger.logInfo('Notification canceled: ID=$id (Fallback)');
    } catch (e, stackTrace) {
      await _logger.logError('Error canceling notification (Fallback)', e, stackTrace);
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      await _logger.logInfo('All notifications canceled (Fallback)');
    } catch (e, stackTrace) {
      await _logger.logError('Error canceling all notifications (Fallback)', e, stackTrace);
    }
  }

  // Simplified permission methods
  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        try {
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          await _logger.logWarning('iOS permission request failed: $e');
        }
      }
    }
  }

  Future<bool> areNotificationPermissionsGranted() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    }
    return true; // Assume granted for iOS or unknown platforms
  }

  Future<void> requestNotificationPermission() async {
    await requestPermissions();
  }

  Future<void> showNotificationPermissionDialog(mat.BuildContext context) async {
    // Simplified permission dialog
    await mat.showDialog(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: const mat.Text('Enable Notifications'),
        content: const mat.Text('Please enable notifications in your device settings to receive task reminders.'),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(),
            child: const mat.Text('OK'),
          ),
        ],
      ),
    );
  }
}