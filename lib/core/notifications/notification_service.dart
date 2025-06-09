import 'dart:io';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/notifications/permission_handler.dart';
import 'package:todo_app/core/notifications/notification_scheduler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final LoggerService _logger = LoggerService();
  final flutter_notifications.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      flutter_notifications.FlutterLocalNotificationsPlugin();
  
  late final PermissionHandler _permissionHandler;
  late final NotificationScheduler _scheduler;
  
  static const String _notificationPermissionRequestedKey = 'notification_permission_requested';
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('NotificationService already initialized');
      return;
    }

    try {
      await _logger.logInfo('Initializing NotificationService');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Set local timezone
      final String timeZoneName = await _getLocalTimeZone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      await _logger.logInfo('Timezone set to: $timeZoneName');
      
      _permissionHandler = PermissionHandler(_logger, flutterLocalNotificationsPlugin);
      _scheduler = NotificationScheduler(_logger, flutterLocalNotificationsPlugin);

      // Initialize plugin settings first
      await _initializePluginSettings();
      
      // Create notification channels
      await _createNotificationChannels();
      
      _isInitialized = true;
      await _logger.logInfo('NotificationService initialized successfully');
      
      // Request permissions after initialization
      await requestPermissions();
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _getLocalTimeZone() async {
    try {
      // Try to get system timezone
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, use a default timezone or implement platform-specific code
        return 'UTC'; // You might want to use a location-based timezone
      } else {
        // For other platforms, use UTC as fallback
        return 'UTC';
      }
    } catch (e) {
      await _logger.logWarning('Could not determine local timezone, using UTC: $e');
      return 'UTC';
    }
  }

  Future<void> _initializePluginSettings() async {
    const androidSettings = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iOSSettings = flutter_notifications.DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = flutter_notifications.InitializationSettings(
      android: androidSettings, 
      iOS: iOSSettings
    );

    final success = await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    if (!(success ?? false)) {
      await _logger.logError('NotificationService initialization failed');
      throw Exception('Failed to initialize notification plugin');
    } else {
      await _logger.logInfo('Notification plugin initialized successfully');
    }
  }

  Future<void> _onNotificationResponse(
    flutter_notifications.NotificationResponse response
  ) async {
    final currentTime = DateTime.now();
    final formattedTime = intl.DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(currentTime);
    await _logger.logInfo(
      'Notification displayed and interacted with: Time=$formattedTime, ID=${response.id}, Title=${response.payload ?? "No title"}'
    );
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
    await _permissionHandler.requestPermission(
      _isFirstRun,
      _markPermissionRequested,
    );
  }

  Future<bool> areNotificationPermissionsGranted() async {
    return await _permissionHandler.arePermissionsGranted();
  }
  
  Future<void> showNotificationPermissionDialog(mat.BuildContext context) async {
    await _permissionHandler.showPermissionDialog(context);
  }

  Future<void> requestPermissions() async {
    await _permissionHandler.requestPermissions();
  }

  Future<void> scheduleTaskNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
  ) async {
    if (!_isInitialized) {
      await _logger.logError('NotificationService not initialized, cannot schedule notification');
      return;
    }

    await _scheduler.scheduleNotification(task, setting);
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
        playSound: true,
        enableVibration: true,
      );
      
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        await _logger.logInfo('Notification channel created for Android');
      } else {
        await _logger.logError('Could not get Android notification plugin');
      }
    }
  }

  // Method to test immediate notification
  Future<void> showTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999999, // Test notification ID
        'Test Notification',
        'This is a test notification to verify the system is working.',
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
      );
      await _logger.logInfo('Test notification shown');
    } catch (e, stackTrace) {
      await _logger.logError('Error showing test notification', e, stackTrace);
    }
  }

  Future<void> testNotificationPermissions() async {
    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final notificationsEnabled = await androidPlugin.areNotificationsEnabled();
        final exactAlarmsAllowed = await androidPlugin.canScheduleExactNotifications();
        
        await _logger.logInfo('Test notification shown');
        await _logger.logInfo('Notifications enabled: $notificationsEnabled');
        await _logger.logInfo('Exact alarms allowed: $exactAlarmsAllowed');
        
        // Show a test notification immediately
        await flutterLocalNotificationsPlugin.show(
          9999,
          'Permission Test',
          'If you see this, basic notifications work!',
          const flutter_notifications.NotificationDetails(
            android: flutter_notifications.AndroidNotificationDetails(
              'todo_app_channel',
              'Task Reminders',
              channelDescription: 'Notifications for task reminders',
              importance: flutter_notifications.Importance.high,
              priority: flutter_notifications.Priority.high,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error testing notification permissions', e, stackTrace);
    }
  }

  // Method to get pending notifications for debugging
  Future<List<flutter_notifications.PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      await _logger.logInfo('Found ${pending.length} pending notifications');
      return pending;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting pending notifications', e, stackTrace);
      return [];
    }
  }
}