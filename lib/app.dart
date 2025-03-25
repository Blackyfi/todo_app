import 'package:flutter/material.dart' as mat;
import 'package:provider/provider.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/theme/app_theme.dart' as app_theme;
import 'package:todo_app/routes.dart' as routes;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

class TodoApp extends mat.StatefulWidget {
  const TodoApp({super.key});

  @override
  mat.State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends mat.State<TodoApp> {
  final _notificationService = notification_service.NotificationService();
  final _loggerService = LoggerService();
  final mat.ThemeMode _themeMode = mat.ThemeMode.system;
  final _timeFormatProvider = TimeFormatProvider();

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
      
      await _timeFormatProvider.init();
      await _loggerService.logInfo('Time format provider initialized');
      
      // Initialize theme preference from SharedPreferences if needed
      // You can add that functionality later
      
      await _loggerService.logInfo('Application initialized successfully');
      
      // We'll check for permissions in the first screen instead of here
    } catch (e, stackTrace) {
      await _loggerService.logError('Error during app initialization', e, stackTrace);
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timeFormatProvider,
      child: mat.MaterialApp(
        title: app_constants.AppConstants.appName,
        theme: app_theme.AppTheme.lightTheme,
        darkTheme: app_theme.AppTheme.darkTheme,
        themeMode: _themeMode,
        onGenerateRoute: routes.AppRouter.generateRoute,
        initialRoute: app_constants.AppConstants.homeRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}