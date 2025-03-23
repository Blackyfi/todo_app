import 'dart:async';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails, debugPrint;
import 'package:todo_app/app.dart' as app;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/database/database_config.dart';
import 'package:todo_app/core/settings/services/auto_delete_service.dart';

void main() async {
  // Capture Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack);
  };
  
  // Capture zone errors
  runZonedGuarded<Future<void>>(() async {
    mat.WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize logger
    final logger = LoggerService();
    await logger.init();
    
    // Initialize database factory for the appropriate platform
    await DatabaseConfig.initDatabaseFactory();
    
    // Set preferred orientations
    await services.SystemChrome.setPreferredOrientations([
      services.DeviceOrientation.portraitUp,
      services.DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    services.SystemChrome.setSystemUIOverlayStyle(
      const services.SystemUiOverlayStyle(
        statusBarColor: mat.Colors.transparent,
        statusBarIconBrightness: services.Brightness.dark,
        statusBarBrightness: services.Brightness.light,
      ),
    );
    
    // Process auto-delete for completed tasks
    final autoDeleteService = AutoDeleteService();
    await autoDeleteService.processCompletedTasks();
    
    mat.runApp(const app.TodoApp());
  }, (error, stackTrace) {
    _reportError(error, stackTrace);
  });
}

void _reportError(dynamic error, StackTrace? stackTrace) async {
  // Create a new logger each time to ensure it's initialized
  final logger = LoggerService();
  try {
    await logger.init();
    await logger.logError('Uncaught exception', error, stackTrace);
    
    // Print to console as well for immediate debugging
    debugPrint('ERROR: $error');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: $stackTrace');
    }
  } catch (logError) {
    // If logging fails, at least print to console
    debugPrint('Failed to log error: $logError');
    debugPrint('Original error: $error');
    if (stackTrace != null) {
      debugPrint('Original stack trace: $stackTrace');
    }
  }
}