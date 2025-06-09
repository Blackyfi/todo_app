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
  static const String _exactAlarmPermissionRequestedKey = 'exact_alarm_permission_requested';

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
      
      // Automatically request permissions on first run
      await _autoRequestPermissionsOnFirstRun();
      
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing NotificationService', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _autoRequestPermissionsOnFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedBasic = prefs.getBool(_notificationPermissionRequestedKey) ?? false;
      final hasRequestedExact = prefs.getBool(_exactAlarmPermissionRequestedKey) ?? false;
      
      // Check current permission status
      final hasBasicPermissions = await _hasBasicNotificationPermissions();
      final hasExactPermissions = await _hasExactAlarmPermissions();
      
      await _logger.logInfo('Permission status - Basic: $hasBasicPermissions, Exact: $hasExactPermissions');
      await _logger.logInfo('Previously requested - Basic: $hasRequestedBasic, Exact: $hasRequestedExact');
      
      // Request basic notifications first if not granted and not previously requested
      if (!hasBasicPermissions && !hasRequestedBasic) {
        await _logger.logInfo('Auto-requesting basic notification permissions on first run');
        await _requestBasicNotificationPermissions();
        await prefs.setBool(_notificationPermissionRequestedKey, true);
      }
      
      // Then request exact alarm permissions if basic are granted but exact are not
      if (hasBasicPermissions && !hasExactPermissions && !hasRequestedExact) {
        await _logger.logInfo('Auto-requesting exact alarm permissions');
        await _requestExactAlarmPermissions();
        await prefs.setBool(_exactAlarmPermissionRequestedKey, true);
      }
      
    } catch (e, stackTrace) {
      await _logger.logError('Error in auto permission request', e, stackTrace);
    }
  }

  Future<bool> _hasBasicNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
    } else if (Platform.isIOS) {
      // For iOS, we can check if permissions were granted before
      // This is a simplified check - you might want to implement a more robust solution
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('ios_notifications_granted') ?? false;
    }
    return false;
  }

  Future<bool> _hasExactAlarmPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.canScheduleExactNotifications() ?? false;
      }
    }
    return true; // iOS doesn't need exact alarm permissions
  }

  Future<void> _requestBasicNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Android handles this automatically when the app tries to show notifications
        await _logger.logInfo('Basic notification permissions will be requested when showing first notification');
      } else if (Platform.isIOS) {
        final iosPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<flutter_notifications.IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
          // Store the result for future reference
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('ios_notifications_granted', granted ?? false);
          
          await _logger.logInfo('iOS basic notification permission granted: $granted');
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting basic notification permissions', e, stackTrace);
    }
  }

  Future<void> _requestExactAlarmPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<flutter_notifications.AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestExactAlarmsPermission();
          await _logger.logInfo('Android exact alarm permission granted: $granted');
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting exact alarm permissions', e, stackTrace);
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

  // Keep the existing manual permission request methods for settings screen
  Future<void> requestNotificationPermission() async {
    await _permissionHandler.requestPermission(
      _isFirstRun,
      _markPermissionRequested,
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

  Future<bool> areNotificationPermissionsGranted() async {
    return await _permissionHandler.arePermissionsGranted();
  }
  
  Future<void> showNotificationPermissionDialog(mat.BuildContext context) async {
    await _permissionHandler.showPermissionDialog(context);
  }

  Future<void> requestPermissions() async {
    await _permissionHandler.requestPermissions();
  }

  // Method to manually trigger permission requests (for settings or when user denies initially)
  Future<void> requestAllPermissions() async {
    try {
      await _logger.logInfo('Manually requesting all notification permissions');
      
      // Request basic permissions first
      await _requestBasicNotificationPermissions();
      
      // Then request exact alarm permissions
      await _requestExactAlarmPermissions();
      
      // Mark as requested
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPermissionRequestedKey, true);
      await prefs.setBool(_exactAlarmPermissionRequestedKey, true);
      
    } catch (e, stackTrace) {
      await _logger.logError('Error requesting all permissions manually', e, stackTrace);
    }
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

  // Method to check and show permission dialog if needed (call this from HomeScreen)
  Future<void> checkAndRequestPermissionsIfNeeded(mat.BuildContext context) async {
    try {
      final hasBasicPermissions = await _hasBasicNotificationPermissions();
      final hasExactPermissions = await _hasExactAlarmPermissions();
      
      if (!hasBasicPermissions || !hasExactPermissions) {
        await _logger.logInfo('Missing permissions detected, showing dialog');
        await showNotificationPermissionDialog(context);
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error checking permissions', e, stackTrace);
    }
  }
}