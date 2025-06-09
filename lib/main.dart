import 'dart:async';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails, debugPrint;
import 'package:todo_app/app.dart' as app;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/database/database_config.dart';
import 'package:todo_app/core/settings/services/auto_delete_service.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;

// Global navigator key to handle navigation from widget actions
final mat.GlobalKey<mat.NavigatorState> navigatorKey = mat.GlobalKey<mat.NavigatorState>();

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack);
  };
  
  runZonedGuarded<Future<void>>(() async {
    mat.WidgetsFlutterBinding.ensureInitialized();
    
    final logger = LoggerService();
    await logger.init();
    
    await DatabaseConfig.initDatabaseFactory();
    
    await services.SystemChrome.setPreferredOrientations([
      services.DeviceOrientation.portraitUp,
      services.DeviceOrientation.portraitDown,
    ]);
    
    services.SystemChrome.setSystemUIOverlayStyle(
      const services.SystemUiOverlayStyle(
        statusBarColor: mat.Colors.transparent,
        statusBarIconBrightness: services.Brightness.dark,
        statusBarBrightness: services.Brightness.light,
      ),
    );
    
    final autoDeleteService = AutoDeleteService();
    await autoDeleteService.processCompletedTasks();
    
    // Initialize widget service and set up widget action handling
    final widgetService = WidgetService();
    await widgetService.init();
    _setupWidgetActionHandling(widgetService, logger);
    
    mat.runApp(app.TodoApp(navigatorKey: navigatorKey));
  }, (error, stackTrace) {
    _reportError(error, stackTrace);
  });
}

void _setupWidgetActionHandling(WidgetService widgetService, LoggerService logger) {
  const platform = services.MethodChannel('com.example.todo_app/widget');
  
  platform.setMethodCallHandler((services.MethodCall call) async {
    if (call.method == 'handleWidgetAction') {
      final String action = call.arguments['action'];
      final Map<dynamic, dynamic> data = call.arguments['data'] ?? {};
      
      await logger.logInfo('Received widget action: $action with data: $data');
      
      switch (action) {
        case 'add_task':
          // Navigate to add task screen
          navigatorKey.currentState?.pushNamed(app_constants.AppConstants.addTaskRoute);
          break;
          
        case 'widget_settings':
          final int? widgetId = data['widgetId'];
          if (widgetId != null) {
            try {
              final widgetConfigRepository = WidgetConfigRepository();
              final widgetConfig = await widgetConfigRepository.getWidgetConfig(widgetId);
              if (widgetConfig != null) {
                // Navigate to edit screen with existing config
                navigatorKey.currentState?.pushNamed('/widget-settings', arguments: widgetConfig);
              } else {
                await logger.logError('Widget config not found for ID: $widgetId');
              }
            } catch (e) {
              await logger.logError('Error loading widget config for settings', e);
            }
          }
          break;
          
        case 'background_sync':
          // Handle background sync without showing UI
          final widgetId = data['widgetId'] as int?;
          if (widgetId != null) {
            await widgetService.updateWidget(widgetId);
          } else {
            await widgetService.updateAllWidgets();
          }
          break;
          
        case 'background_toggle_task':
          // Handle background task toggle without showing UI
          final taskId = data['taskId'] as int?;
          final widgetId = data['widgetId'] as int?;
          if (taskId != null) {
            await widgetService.handleWidgetAction('toggle_task', {
              'taskId': taskId,
              'widgetId': widgetId,
            });
          }
          break;
      }
    }
  });
}

void _reportError(dynamic error, StackTrace? stackTrace) async {
  final logger = LoggerService();
  try {
    await logger.init();
    await logger.logError('Uncaught exception', error, stackTrace);
    
    debugPrint('ERROR: $error');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: $stackTrace');
    }
  } catch (logError) {
    debugPrint('Failed to log error: $logError');
    debugPrint('Original error: $error');
    if (stackTrace != null) {
      debugPrint('Original stack trace: $stackTrace');
    }
  }
}