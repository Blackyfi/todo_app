import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/theme/app_theme.dart' as app_theme;
import 'package:todo_app/routes.dart' as routes;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;

class TodoApp extends mat.StatefulWidget {
  const TodoApp({super.key});

  @override
  mat.State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends mat.State<TodoApp> {
  final _notificationService = notification_service.NotificationService();
  mat.ThemeMode _themeMode = mat.ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.init();
    // Initialize theme preference from SharedPreferences if needed
    // You can add that functionality later
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
