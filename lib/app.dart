import 'package:flutter/material.dart' as mat;
import 'package:provider/provider.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/theme/app_theme.dart' as app_theme;
import 'package:todo_app/routes.dart' as routes;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/app_initializer.dart';
import 'package:todo_app/main.dart' show globalDataChangeNotifier;

class TodoApp extends mat.StatefulWidget {
  final mat.GlobalKey<mat.NavigatorState> navigatorKey;
  
  const TodoApp({super.key, required this.navigatorKey});

  @override
  mat.State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends mat.State<TodoApp> with mat.WidgetsBindingObserver {
  final _notificationService = notification_service.NotificationService();
  final _loggerService = LoggerService();
  final mat.ThemeMode _themeMode = mat.ThemeMode.system;
  final _timeFormatProvider = TimeFormatProvider();
  final _appInitializer = AppInitializer();

  @override
  void initState() {
    super.initState();
    
    // Add app lifecycle observer
    mat.WidgetsBinding.instance.addObserver(this);
    
    _appInitializer.initialize(
      _loggerService,
      _notificationService,
      _timeFormatProvider,
    );
  }

  @override
  void dispose() {
    mat.WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(mat.AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == mat.AppLifecycleState.resumed) {
      _loggerService.logInfo('App resumed at application level - triggering global data change notification');
      // Trigger global data change notification when app resumes
      globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _timeFormatProvider,
      child: mat.MaterialApp(
        navigatorKey: widget.navigatorKey,
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