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
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/widgets/screens/widget_creation_screen.dart';
import 'dart:io';

// Global navigator key to handle navigation from widget actions
final mat.GlobalKey<mat.NavigatorState> navigatorKey = mat.GlobalKey<mat.NavigatorState>();

// Global app state notifier to trigger refreshes
final mat.ValueNotifier<bool> globalDataChangeNotifier = mat.ValueNotifier<bool>(false);

void main() async {
  // Initialize logger first for error reporting
  final logger = LoggerService();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack, logger);
  };
  
  runZonedGuarded<Future<void>>(() async {
    try {
      await logger.logInfo('===== APPLICATION STARTUP BEGINNING =====');
      await logger.logInfo('Platform: ${Platform.operatingSystem}');
      await logger.logInfo('Platform version: ${Platform.operatingSystemVersion}');
      await logger.logInfo('Flutter binding initialization...');
      
      mat.WidgetsFlutterBinding.ensureInitialized();
      await logger.logInfo('Flutter binding initialized successfully');
      
      await logger.logInfo('Logger service initialization...');
      await logger.init();
      await logger.logInfo('Logger service initialized successfully');
      
      await logger.logInfo('Database configuration initialization...');
      await DatabaseConfig.initDatabaseFactory();
      await logger.logInfo('Database configuration initialized successfully');
      
      await logger.logInfo('Setting device orientation preferences...');
      await services.SystemChrome.setPreferredOrientations([
        services.DeviceOrientation.portraitUp,
        services.DeviceOrientation.portraitDown,
      ]);
      await logger.logInfo('Device orientation preferences set successfully');
      
      await logger.logInfo('Setting system UI overlay style...');
      services.SystemChrome.setSystemUIOverlayStyle(
        const services.SystemUiOverlayStyle(
          statusBarColor: mat.Colors.transparent,
          statusBarIconBrightness: services.Brightness.dark,
          statusBarBrightness: services.Brightness.light,
        ),
      );
      await logger.logInfo('System UI overlay style set successfully');
      
      await logger.logInfo('Processing completed tasks auto-deletion...');
      final autoDeleteService = AutoDeleteService();
      await autoDeleteService.processCompletedTasks();
      await logger.logInfo('Completed tasks auto-deletion processed successfully');
      
      // Initialize widget service and set up widget action handling
      await logger.logInfo('=== WIDGET SERVICE INITIALIZATION ===');
      final widgetService = WidgetService();
      await widgetService.init();
      await logger.logInfo('Widget service initialized successfully');
      
      // CRITICAL: Always ensure a default widget exists and update it
      await logger.logInfo('Ensuring default widget configuration exists...');
      await _ensureDefaultWidget(widgetService, logger);
      await logger.logInfo('Default widget configuration ensured');
      
      await logger.logInfo('Setting up widget action handling...');
      _setupWidgetActionHandling(widgetService, logger);
      await logger.logInfo('Widget action handling setup complete');
      
      await logger.logInfo('===== APPLICATION STARTUP COMPLETE =====');
      await logger.logInfo('Launching TodoApp...');
      
      mat.runApp(app.TodoApp(navigatorKey: navigatorKey));
      
      await logger.logInfo('TodoApp launched successfully');
    } catch (e, stackTrace) {
      await logger.logError('CRITICAL ERROR during app startup', e, stackTrace);
      await logger.logError('Startup error details: ${e.toString()}');
      await logger.logError('Startup error stack trace: ${stackTrace.toString()}');
      rethrow;
    }
  }, (error, stackTrace) {
    _reportError(error, stackTrace, logger);
  });
}

Future<void> _ensureDefaultWidget(WidgetService widgetService, LoggerService logger) async {
  try {
    await logger.logInfo('--- Ensuring Default Widget Configuration ---');
    
    final widgetConfigRepository = WidgetConfigRepository();
    await logger.logInfo('Widget config repository created');
    
    await logger.logInfo('Fetching existing widget configurations...');
    final existingConfigs = await widgetConfigRepository.getAllWidgetConfigs();
    await logger.logInfo('Found ${existingConfigs.length} existing widget configurations');
    
    if (existingConfigs.isEmpty) {
      await logger.logInfo('No widget configurations found, creating default widget');
      
      final defaultConfig = WidgetConfig(
        name: 'Todo Tasks',
        size: WidgetSize.medium,
        showCompleted: false,
        showCategories: true,
        showPriority: true,
        maxTasks: 5,
        createdAt: DateTime.now(),
      );
      
      await logger.logInfo('Default widget config created: ${defaultConfig.toMap()}');
      
      await logger.logInfo('Creating default widget through widget service...');
      await widgetService.createWidget(defaultConfig);
      await logger.logInfo('Default widget configuration created successfully');
    } else {
      await logger.logInfo('Found ${existingConfigs.length} existing widget configurations');
      for (int i = 0; i < existingConfigs.length; i++) {
        final config = existingConfigs[i];
        await logger.logInfo('  Config ${i + 1}: ID=${config.id}, Name="${config.name}", Size=${config.size.label}');
      }
      
      // CRITICAL: Always update all widgets with current data on startup
      await logger.logInfo('Force updating existing widgets with current data...');
      await widgetService.updateAllWidgets();
      await logger.logInfo('All existing widgets updated successfully');
    }
    
    await logger.logInfo('--- Default Widget Configuration Ensured ---');
  } catch (e, stackTrace) {
    await logger.logError('--- Error Setting Up Default Widget ---', e, stackTrace);
    await logger.logError('Widget setup error details: ${e.toString()}');
    
    // Try to provide more context
    try {
      await logger.logInfo('Attempting widget support check after error...');
      final isSupported = await widgetService.isWidgetSupported();
      await logger.logInfo('Widget support check result: $isSupported');
    } catch (supportError) {
      await logger.logError('Widget support check also failed', supportError);
    }
    
    // Don't rethrow - app should still work without widgets
    await logger.logWarning('Continuing app startup despite widget setup error');
  }
}

void _setupWidgetActionHandling(WidgetService widgetService, LoggerService logger) {
  const platform = services.MethodChannel('com.example.todo_app/widget');
  
  logger.logInfo('Setting up method channel handler for widget actions');
  
  platform.setMethodCallHandler((services.MethodCall call) async {
    await logger.logInfo('=== WIDGET ACTION METHOD CALL RECEIVED ===');
    await logger.logInfo('Method: ${call.method}');
    await logger.logInfo('Arguments: ${call.arguments}');
    await logger.logInfo('Arguments type: ${call.arguments.runtimeType}');
    
    try {
      if (call.method == 'handleWidgetAction') {
        if (call.arguments == null) {
          await logger.logError('Widget action called with null arguments');
          throw services.PlatformException(
            code: 'NULL_ARGUMENTS',
            message: 'Widget action arguments cannot be null',
          );
        }
        
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        await logger.logInfo('Parsed arguments: $args');
        
        if (!args.containsKey('action')) {
          await logger.logError('Widget action missing required "action" key');
          throw services.PlatformException(
            code: 'MISSING_ACTION',
            message: 'Action key is required in widget action arguments',
          );
        }
        
        final String action = args['action'] as String;
        final Map<dynamic, dynamic> data = args['data'] as Map<dynamic, dynamic>? ?? {};
        
        await logger.logInfo('Processing widget action: $action');
        await logger.logInfo('Action data: $data');
        
        switch (action) {
          case 'add_task':
            await logger.logInfo('--- Processing Add Task Action ---');
            final int? widgetId = data['widgetId'] as int?;
            await logger.logInfo('Widget ID: $widgetId');
            
            // Navigate to add task screen
            await logger.logInfo('Navigating to add task screen...');
            await navigatorKey.currentState?.pushNamed(app_constants.AppConstants.addTaskRoute);
            await logger.logInfo('Navigation to add task screen initiated');
            
            // CRITICAL: Trigger data refresh when returning from add task
            await logger.logInfo('Scheduling data refresh notification...');
            Future.delayed(const Duration(milliseconds: 500), () {
              logger.logInfo('Triggering global data change notification');
              globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
            });
            await logger.logInfo('Data refresh notification scheduled');
            break;
            
          case 'widget_settings':
            await logger.logInfo('--- Processing Widget Settings Action ---');
            final int? widgetId = data['widgetId'] as int?;
            await logger.logInfo('Widget settings requested for widgetId: $widgetId');
            
            try {
              final widgetConfigRepository = WidgetConfigRepository();
              // Get all configs and use the first one (or create one if none exist)
              final configs = await widgetConfigRepository.getAllWidgetConfigs();
              
              if (configs.isNotEmpty) {
                final widgetConfig = configs.first;
                await logger.logInfo('Found widget config: ${widgetConfig.name}');
                await logger.logInfo('Config details: ${widgetConfig.toMap()}');
                
                // Navigate to widget settings screen with existing config
                await logger.logInfo('Navigating to widget creation screen with existing config...');
                navigatorKey.currentState?.push(
                  mat.MaterialPageRoute(
                    builder: (_) => WidgetCreationScreen(existingConfig: widgetConfig),
                  ),
                );
                await logger.logInfo('Navigation to widget settings initiated');
              } else {
                await logger.logError('No widget configs found');
                await logger.logInfo('Creating new widget creation screen as fallback...');
                
                // Create and navigate to a new widget creation screen
                navigatorKey.currentState?.push(
                  mat.MaterialPageRoute(
                    builder: (_) => const WidgetCreationScreen(),
                  ),
                );
                await logger.logInfo('Navigation to new widget creation initiated');
              }
            } catch (e, stackTrace) {
              await logger.logError('Error loading widget config for settings', e, stackTrace);
              await logger.logInfo('Using fallback: navigate to new widget creation');
              
              // Fallback: navigate to new widget creation
              navigatorKey.currentState?.push(
                mat.MaterialPageRoute(
                  builder: (_) => const WidgetCreationScreen(),
                ),
              );
            }
            break;
            
          case 'background_sync':
            await logger.logInfo('--- Processing Background Sync Action ---');
            final int? widgetId = data['widgetId'] as int?;
            await logger.logInfo('Background sync for widget ID: $widgetId');
            
            // Handle background sync without showing UI
            await logger.logInfo('Calling widget service to handle background sync...');
            await widgetService.handleWidgetAction('background_sync', data);
            await logger.logInfo('Widget service background sync completed');
            
            // Trigger refresh notification for any listening components
            await logger.logInfo('Triggering global data change notification...');
            globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
            await logger.logInfo('Global data change notification triggered');
            break;
            
          case 'background_toggle_task':
            await logger.logInfo('--- Processing Background Toggle Task Action ---');
            final int? taskId = data['taskId'] as int?;
            final int? widgetId = data['widgetId'] as int?;
            await logger.logInfo('Background toggle for task ID: $taskId, widget ID: $widgetId');
            
            if (taskId == null) {
              await logger.logError('Background toggle task called with null task ID');
              throw services.PlatformException(
                code: 'NULL_TASK_ID',
                message: 'Task ID is required for toggle action',
              );
            }
            
            // Handle background task toggle without showing UI
            await logger.logInfo('Calling widget service to handle background task toggle...');
            await widgetService.handleWidgetAction('background_toggle_task', data);
            await logger.logInfo('Widget service background task toggle completed');
            
            // Trigger refresh notification for any listening components
            await logger.logInfo('Triggering global data change notification...');
            globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
            await logger.logInfo('Global data change notification triggered');
            break;
            
          default:
            await logger.logWarning('Unknown widget action received: $action');
            throw services.PlatformException(
              code: 'UNKNOWN_ACTION',
              message: 'Unknown widget action: $action',
            );
        }
        
        await logger.logInfo('=== Widget Action Processed Successfully: $action ===');
      } else {
        await logger.logWarning('Unknown method called on widget channel: ${call.method}');
        throw services.PlatformException(
          code: 'UNKNOWN_METHOD',
          message: 'Unknown method: ${call.method}',
        );
      }
    } catch (e, stackTrace) {
      await logger.logError('=== Widget Action Processing Failed ===', e, stackTrace);
      await logger.logError('Failed method: ${call.method}');
      await logger.logError('Failed arguments: ${call.arguments}');
      rethrow;
    }
  });
  
logger.logInfo('Widget action method channel handler setup complete');
}

void _reportError(dynamic error, StackTrace? stackTrace, LoggerService logger) async {
 try {
   await logger.logError('=== UNCAUGHT EXCEPTION REPORTED ===', error, stackTrace);
   await logger.logError('Error type: ${error.runtimeType}');
   await logger.logError('Error details: ${error.toString()}');
   
   if (stackTrace != null) {
     await logger.logError('Full stack trace: ${stackTrace.toString()}');
   }
   
   // Log additional context if available
   try {
     await logger.logInfo('Current platform: ${Platform.operatingSystem}');
     await logger.logInfo('Platform version: ${Platform.operatingSystemVersion}');
   } catch (platformError) {
     await logger.logWarning('Could not get platform information: $platformError');
   }
   
   debugPrint('CRITICAL ERROR: $error');
   if (stackTrace != null) {
     debugPrint('STACK TRACE: $stackTrace');
   }
 } catch (logError) {
   debugPrint('LOGGER FAILED: $logError');
   debugPrint('ORIGINAL ERROR: $error');
   if (stackTrace != null) {
     debugPrint('ORIGINAL STACK TRACE: $stackTrace');
   }
   
   // Last resort - try to save to file directly
   try {
     final timestamp = DateTime.now().toIso8601String();
     final errorReport = '''
=== CRITICAL ERROR REPORT ===
Timestamp: $timestamp
Platform: ${Platform.operatingSystem}
Logger Error: $logError
Original Error: $error
Original Stack Trace: $stackTrace
==============================
''';
     
     final tempDir = Directory.systemTemp;
     final errorFile = File('${tempDir.path}/todo_app_critical_error_$timestamp.txt');
     await errorFile.writeAsString(errorReport);
     debugPrint('Error report saved to: ${errorFile.path}');
   } catch (fileError) {
     debugPrint('COULD NOT SAVE ERROR REPORT: $fileError');
   }
 }
}