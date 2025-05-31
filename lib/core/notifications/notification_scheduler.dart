import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:intl/intl.dart' as intl;

class NotificationScheduler {
  final LoggerService _logger;
  final flutter_notifications.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationScheduler(this._logger, this._flutterLocalNotificationsPlugin);

  Future<void> scheduleNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
  ) async {
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
          'Skipping notification scheduling: notification time is in the past, TaskID=${task.id}, NotificationTime=${notificationTime.toIso8601String()}'
        );
        return;
      }

      final notificationId = _generateNotificationId(task, setting);
      
      // Check if plugin is properly initialized before trying to use it
      if (!await _isNotificationPluginInitialized()) {
        await _logger.logError('Failed to initialize notification plugin');
        return;
      }
      
      await _scheduleZonedNotification(task, setting, notificationTime, notificationId);
      
    } catch (e, stackTrace) {
      await _logger.logError('Error scheduling task notification', e, stackTrace);
      // Don't rethrow here - we want task saving to proceed even if notification fails
    }
  }

  int _generateNotificationId(task_model.Task task, notification_model.NotificationSetting setting) {
    // Generate a unique notification ID based on task ID and setting type
    final taskId = task.id ?? 0;
    final settingIndex = setting.timeOption.index;
    return (taskId * 1000) + settingIndex;
  }
  
  Future<void> _scheduleZonedNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
    DateTime notificationTime,
    int notificationId,
  ) async {
    try {
      final currentTime = DateTime.now();
      final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
      
      await _logger.logInfo(
        'Scheduling notification: Time=$formattedTime, TaskID=${task.id}, Title="${task.title}", '
        'NotificationID=$notificationId, ScheduledFor=${notificationTime.toIso8601String()}'
      );

      // Create TZDateTime for the notification time
      final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      
      await _logger.logInfo(
        'Converted to TZDateTime: ${scheduledDate.toIso8601String()}, Local timezone: ${tz.local.name}'
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
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
            playSound: true,
            enableVibration: true,
            autoCancel: true,
            ongoing: false,
            ticker: 'Task Reminder',
          ),
          iOS: flutter_notifications.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: flutter_notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            flutter_notifications.UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.title, // Add the task title as the payload
      );
      
      await _logger.logInfo(
        'Notification scheduled successfully: TaskID=${task.id}, SettingID=${setting.id}, '
        'NotificationID=$notificationId, NotificationTime=${notificationTime.toIso8601String()}, '
        'TimeOption=${setting.timeOption.name}'
      );

      // Verify the notification was scheduled by checking pending notifications
      await _verifyNotificationScheduled(notificationId);
      
    } catch (e, stackTrace) {
      await _logger.logError('Error in zonedSchedule, attempting fallback', e, stackTrace);
      
      // Try to use a simpler notification method as fallback
      await _showBasicNotification(task, setting, notificationId);
    }
  }

  Future<void> _verifyNotificationScheduled(int notificationId) async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final isScheduled = pendingNotifications.any((notification) => notification.id == notificationId);
      
      if (isScheduled) {
        await _logger.logInfo('Verified notification is scheduled: ID=$notificationId');
      } else {
        await _logger.logWarning('Notification not found in pending list: ID=$notificationId');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error verifying notification schedule', e, stackTrace);
    }
  }
  
  Future<void> _showBasicNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
    int notificationId,
  ) async {
    if (await _isNotificationPluginInitialized()) {
      try {
        final currentTime = DateTime.now();
        final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
        
        await _logger.logInfo(
          'Showing basic notification as fallback: Time=$formattedTime, TaskID=${task.id}, '
          'Title="${task.title}", NotificationID=$notificationId'
        );
        
        await _flutterLocalNotificationsPlugin.show(
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
              playSound: true,
              enableVibration: true,
            ),
            iOS: flutter_notifications.DarwinNotificationDetails(),
          ),
          payload: task.title, // Add task title as payload
        );
        
        await _logger.logInfo(
          'Basic notification used as fallback: TaskID=${task.id}, SettingID=${setting.id}, '
          'NotificationID=$notificationId'
        );
      } catch (innerError, innerStackTrace) {
        await _logger.logError('Error showing basic notification', innerError, innerStackTrace);
        // Don't rethrow here - let the task be saved even if notification fails
      }
    } else {
      await _logger.logWarning('Cannot show fallback notification: plugin not initialized');
    }
  }

  Future<bool> _isNotificationPluginInitialized() async {
    try {
      // Try to get pending notifications to test if plugin is working
      await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return true;
    } catch (e) {
      await _logger.logWarning('Notification plugin not properly initialized: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      await _logger.logInfo('Notification cancelled: ID=$notificationId');
    } catch (e, stackTrace) {
      await _logger.logError('Error cancelling notification', e, stackTrace);
    }
  }

  Future<void> cancelTaskNotifications(task_model.Task task) async {
    try {
      // Cancel all possible notifications for this task
      for (int i = 0; i < notification_model.NotificationTimeOption.values.length; i++) {
        final notificationId = (task.id ?? 0) * 1000 + i;
        await _flutterLocalNotificationsPlugin.cancel(notificationId);
      }
      await _logger.logInfo('All notifications cancelled for task: ID=${task.id}');
    } catch (e, stackTrace) {
      await _logger.logError('Error cancelling task notifications', e, stackTrace);
    }
  }
}