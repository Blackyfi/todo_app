import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/theme/app_theme.dart' as app_theme;
import 'package:todo_app/routes.dart' as routes;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:todo_app/core/logger/logger_service.dart';

class TodoApp extends mat.StatefulWidget {
  const TodoApp({super.key});

  @override
  mat.State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends mat.State<TodoApp> {
  final _notificationService = notification_service.NotificationService();
  final _loggerService = LoggerService();
  final mat.ThemeMode _themeMode = mat.ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loggerService.init();
      await _loggerService.logInfo('Application initialization started');
      
      await _notificationService.init();
      await _loggerService.logInfo('Notification service initialized');
      
      // Initialize theme preference from SharedPreferences if needed
      // You can add that functionality later
      
      await _loggerService.logInfo('Application initialized successfully');
    } catch (e, stackTrace) {
      await _loggerService.logError('Error during app initialization', e, stackTrace);
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.MaterialApp(
      title: app_constants.AppConstants.appName,
      theme: app_theme.AppTheme.lightTheme,
      darkTheme: app_theme.AppTheme.darkTheme,
      themeMode: _themeMode,
      onGenerateRoute: routes.AppRouter.generateRoute,
      initialRoute: app_constants.AppConstants.homeRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}