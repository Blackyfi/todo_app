import 'dart:async';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:todo_app/app.dart' as app;
import 'package:todo_app/core/logger/logger_service.dart';

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
    
    mat.runApp(const app.TodoApp());
  }, (error, stackTrace) {
    _reportError(error, stackTrace);
  });
}

void _reportError(dynamic error, StackTrace? stackTrace) async {
  final logger = LoggerService();
  await logger.logError('Uncaught exception', error, stackTrace);
}