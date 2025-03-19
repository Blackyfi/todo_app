import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final flutter_notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      flutter_notifications.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = flutter_notifications.DarwinInitializationSettings();
    const initSettings = flutter_notifications.InitializationSettings(android: android, iOS: iOS);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> scheduleTaskNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
  ) async {
    if (task.dueDate == null) return;

    final notificationTime = setting.timeOption.calculateNotificationTime(
      task.dueDate!,
      setting.customTime,
    );

    // Don't schedule if the notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      setting.id ?? task.id!.hashCode + setting.timeOption.index,
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
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
