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
        matchDateTimeComponents:
            flutter_notifications.DateTimeComponents.dateAndTime,
        payload: task.title,
      );
      
      await _logger.logInfo(
        'Notification scheduled successfully: TaskID=${task.id}, SettingID=${setting.id}, '
        'NotificationID=$notificationId, NotificationTime=${notificationTime.toIso8601String()}, '
        'TimeOption=${setting.timeOption.name}'
      );
    } catch (e, stackTrace) {
      await _logger.logError(
        'Failed to schedule notification for TaskID=${task.id}. '
        'Notification scheduling may not be supported on this platform.',
        e,
        stackTrace
      );
      
      // Do NOT show immediate notification as fallback
      // Just log the failure and continue
      await _logger.logWarning(
        'Notification scheduling failed for TaskID=${task.id}. '
        'Task saved but no notification will be shown.'
      );
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