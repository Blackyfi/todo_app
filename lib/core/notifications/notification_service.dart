import 'dart:io';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;
import 'package:timezone/data/latest.dart' as tz_data;
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

  Future<void> init() async {
    try {
      await _logger.logInfo('Initializing NotificationService');
      
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      _permissionHandler = PermissionHandler(_logger, flutterLocalNotificationsPlugin);
      _scheduler = NotificationScheduler(_logger, flutterLocalNotificationsPlugin);

      // Create notification channels
      await _createNotificationChannels();

      // Configure platform-specific settings
      await _initializePluginSettings();
      
      await _logger.logInfo('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializePluginSettings() async {
    const androidSettings = flutter_notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iOSSettings = flutter_notifications.DarwinInitializationSettings(
      requestAlertPermission: false,
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
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    if (!(success ?? false)) {
      await _logger.logWarning('NotificationService initialization failed');
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

  /// New method to open app settings directly
  Future<void> openAppSettings() async {
    await _permissionHandler.openAppSettings();
  }

  Future<void> scheduleTaskNotification(
    task_model.Task task,
    notification_model.NotificationSetting setting,
  ) async {
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