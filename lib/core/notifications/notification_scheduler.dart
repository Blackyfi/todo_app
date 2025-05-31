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

      final notificationId = setting.id ?? task.id!.hashCode + setting.timeOption.index;
      
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
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Task Reminder: ${task.title}',
        task.description.isNotEmpty ? task.description : 'This task is due soon.',
        tz.TZDateTime.from(notificationTime, tz.local),
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
        androidScheduleMode: flutter_notifications.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: flutter_notifications.UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.title, // Add the task title as the payload
      );
      
      await _logger.logInfo(
        'Notification scheduled: TaskID=${task.id}, SettingID=${setting.id}, '
        'NotificationID=$notificationId, NotificationTime=${notificationTime.toIso8601String()}, '
        'TimeOption=${setting.timeOption.name}'
      );
    } catch (e) {
      // Handle case when zonedSchedule is not implemented
      await _logger.logWarning(
        'Advanced notification scheduling not available on this platform. '
        'Using basic notification instead for TaskID=${task.id}'
      );
      
      // Try to use a simpler notification method as fallback
      await _showBasicNotification(task, setting, notificationId);
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
          'Showing basic notification: Time=$formattedTime, TaskID=${task.id}, '
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
      // Try to access the platform instance - this will throw if not initialized
      final isInitialized = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>() !=
          null;
      return isInitialized;
    } catch (e) {
      await _logger.logWarning('Notification plugin not initialized: $e');
      return false;
    }
  }
}