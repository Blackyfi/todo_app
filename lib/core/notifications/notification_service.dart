import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final LoggerService _logger = LoggerService();
  final flutter_notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      flutter_notifications.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      await _logger.logInfo('Initializing NotificationService');
      tz_data.initializeTimeZones();

      const android = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOS = flutter_notifications.DarwinInitializationSettings();
      const initSettings = flutter_notifications.InitializationSettings(android: android, iOS: iOS);

      await flutterLocalNotificationsPlugin.initialize(initSettings);
      await _logger.logInfo('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService', e, stackTrace);
      rethrow;
    }
  }

  Future<void> scheduleTaskNotification(
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
      
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
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
          uiLocalNotificationDateInterpretation:
              flutter_notifications.UILocalNotificationDateInterpretation.absoluteTime,
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
        
        // Fall back to a simple notification if zonedSchedule is not available
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
        
        await _logger.logInfo(
          'Basic notification used as fallback: TaskID=${task.id}, SettingID=${setting.id}, '
          'NotificationID=$notificationId'
        );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error scheduling task notification', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      await _logger.logInfo('Notification canceled: ID=$id');
    } catch (e, stackTrace) {
      await _logger.logError('Error canceling notification', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      await _logger.logInfo('All notifications canceled');
    } catch (e, stackTrace) {
      await _logger.logError('Error canceling all notifications', e, stackTrace);
      rethrow;
    }
  }
}