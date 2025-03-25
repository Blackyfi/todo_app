import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart' as mat;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final LoggerService _logger = LoggerService();
  final flutter_notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      flutter_notifications.FlutterLocalNotificationsPlugin();
  
  static const String _notificationPermissionRequestedKey = 'notification_permission_requested';

  Future<void> init() async {
    try {
      await _logger.logInfo('Initializing NotificationService');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Create notification channels
      await _createNotificationChannels();

      // Configure platform-specific settings more explicitly
      const androidSettings = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const iOSSettings = flutter_notifications.DarwinInitializationSettings(
        requestAlertPermission: false,  // We'll request permissions manually
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: false,
        defaultPresentBadge: false,
        defaultPresentSound: false,
      );
      
      const initSettings = flutter_notifications.InitializationSettings(
        android: androidSettings, 
        iOS: iOSSettings
      );

      final success = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        // Add this onDidReceiveNotificationResponse callback
        onDidReceiveNotificationResponse: (flutter_notifications.NotificationResponse response) async {
          final currentTime = DateTime.now();
          final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
          await _logger.logInfo('Notification displayed and interacted with: Time=$formattedTime, ID=${response.id}, Title=${response.payload ?? "No title"}');
        },
      );
      
      if (success ?? false) {
        await _logger.logInfo('NotificationService initialized successfully');
        await requestPermissions(); // Call the new method here
      } else {
        await _logger.logWarning('NotificationService initialization failed');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> _isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_notificationPermissionRequestedKey);
  }

  Future<void> _markPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPermissionRequestedKey, true);
  }

  Future<void> requestNotificationPermission() async {
    try {
      final isFirstRun = await _isFirstRun();
      
      if (!isFirstRun) {
        await _logger.logInfo('Notification permissions already requested in the past');
        return;
      }
      
      await _logger.logInfo('Requesting notification permissions');
      
      if (Platform.isIOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
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
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestPermission();
          await _logger.logInfo('Android notification permission request result: $granted');
        }
      }
      
      await _markPermissionRequested();
      
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting notification permissions', e, stackTrace);
    }
  }

  Future<bool> areNotificationPermissionsGranted() async {
    try {
      if (Platform.isIOS) {
        final settings = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                flutter_notifications.IOSFlutterLocalNotificationsPlugin>()
            ?.getNotificationAppLaunchDetails();
        return settings?.notificationResponse != null;
      } else if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
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
  
  Future<void> showNotificationPermissionDialog(mat.BuildContext context) async {
    try {
      final result = await mat.showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => mat.AlertDialog(
          title: const mat.Text('Enable Notifications'),
          content: const mat.Text(
            'To get reminders for your tasks, please allow notifications. '
            'Without this permission, you won\'t receive any task reminders.',
          ),
          actions: [
            mat.TextButton(
              onPressed: () => mat.Navigator.of(context).pop(false),
              child: const mat.Text('Not Now'),
            ),
            mat.FilledButton(
              onPressed: () => mat.Navigator.of(context).pop(true),
              child: const mat.Text('Enable'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await requestNotificationPermission();
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error showing notification permission dialog', e, stackTrace);
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      final iOSPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        await iOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Android-specific permissions can be handled here if needed
      }
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
      
      // Check if plugin is properly initialized before trying to use it
      if (!await _isNotificationPluginInitialized()) {
        await _logger.logWarning('Notification plugin not properly initialized. Trying to initialize...');
        await init();
        
        // Check again after initialization attempt
        if (!await _isNotificationPluginInitialized()) {
          await _logger.logError('Failed to initialize notification plugin after retry');
          return;
        }
      }
      
      try {
        final currentTime = DateTime.now();
        final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
        
        await _logger.logInfo(
          'Scheduling notification: Time=$formattedTime, TaskID=${task.id}, Title="${task.title}", '
          'NotificationID=$notificationId, ScheduledFor=${notificationTime.toIso8601String()}'
        );
        
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
        if (await _isNotificationPluginInitialized()) {
          try {
            final currentTime = DateTime.now();
            final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
            
            await _logger.logInfo(
              'Showing basic notification: Time=$formattedTime, TaskID=${task.id}, '
              'Title="${task.title}", NotificationID=$notificationId'
            );
            
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
    } catch (e, stackTrace) {
      await _logger.logError('Error scheduling task notification', e, stackTrace);
      // Don't rethrow here - we want task saving to proceed even if notification fails
    }
  }

  // Add this helper method to check if the notification plugin is initialized
  Future<bool> _isNotificationPluginInitialized() async {
    try {
      // Try to access the platform instance - this will throw if not initialized
      final isInitialized = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>() !=
          null;
      return isInitialized;
    } catch (e) {
      await _logger.logWarning('Notification plugin not initialized: $e');
      return false;
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
      }
          
      await _logger.logInfo('Notification channel created for Android');
    }
  }
}