import 'dart:async';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/services.dart' as services;
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/app.dart' as app;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/database/database_config.dart';
import 'package:todo_app/core/settings/services/auto_delete_service.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/widgets/screens/widget_creation_screen.dart';
import 'package:todo_app/core/security/services/security_service.dart';

// Global navigator key to handle navigation from widget actions
final mat.GlobalKey<mat.NavigatorState> navigatorKey = mat.GlobalKey<mat.NavigatorState>();

// Global app state notifier to trigger refreshes
final mat.ValueNotifier<bool> globalDataChangeNotifier = mat.ValueNotifier<bool>(false);

void main() async {
  // Ensure Flutter is initialized
  mat.WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  final logger = LoggerService();
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack, logger);
  };
  
  runZonedGuarded<Future<void>>(() async {
    try {
      await logger.logInfo('===== APPLICATION STARTUP BEGINNING =====');
      
      // Initialize logger
      await logger.init();
      await logger.logInfo('Logger initialized');
      
      // Initialize database
      await DatabaseConfig.initDatabaseFactory();
      await logger.logInfo('Database initialized');
      
      // Set preferred orientations
      await services.SystemChrome.setPreferredOrientations([
        services.DeviceOrientation.portraitUp,
        services.DeviceOrientation.portraitDown,
      ]);
      
      // Set system UI
      services.SystemChrome.setSystemUIOverlayStyle(
        const services.SystemUiOverlayStyle(
          statusBarColor: mat.Colors.transparent,
          statusBarIconBrightness: services.Brightness.dark,
          statusBarBrightness: services.Brightness.light,
        ),
      );
      
      // Initialize services
      await _initializeServices(logger);
      
      await logger.logInfo('===== APPLICATION STARTUP COMPLETE =====');

      // Launch app with Riverpod ProviderScope for reactive state management
      mat.runApp(
        ProviderScope(
          child: app.TodoApp(navigatorKey: navigatorKey),
        ),
      );
      
    } catch (e, stackTrace) {
      await logger.logError('CRITICAL ERROR during app startup', e, stackTrace);
      // Launch basic app even if initialization fails
      mat.runApp(const _BasicApp());
    }
  }, (error, stackTrace) {
    _reportError(error, stackTrace, logger);
  });
}

Future<void> _initializeServices(LoggerService logger) async {
  try {
    // Initialize security service
    final securityService = SecurityService();
    await securityService.initialize();
    await logger.logInfo('Security service initialized');

    // Auto-delete service
    final autoDeleteService = AutoDeleteService();
    await autoDeleteService.processCompletedTasks();
    await logger.logInfo('Auto-delete service initialized');

    // Widget service
    final widgetService = WidgetService();
    await widgetService.init();
    await logger.logInfo('Widget service initialized');

    // Check if security is enabled and disable widgets if necessary
    if (await securityService.isSecurityEnabled()) {
      await widgetService.disableAllWidgets();
      await logger.logInfo('Widgets disabled due to active security');
    } else {
      // Ensure default widget only if security is not enabled
      await _ensureDefaultWidget(widgetService, logger);
    }

    // Setup widget action handling
    _setupWidgetActionHandling(widgetService, logger);

  } catch (e, stackTrace) {
    await logger.logError('Error initializing services', e, stackTrace);
    // Continue without services
  }
}

Future<void> _ensureDefaultWidget(WidgetService widgetService, LoggerService logger) async {
  try {
    final widgetConfigRepository = WidgetConfigRepository();
    final existingConfigs = await widgetConfigRepository.getAllWidgetConfigs();
    
    if (existingConfigs.isEmpty) {
      final defaultConfig = WidgetConfig(
        name: 'Todo Tasks',
        size: WidgetSize.medium,
        showCompleted: false,
        showCategories: true,
        showPriority: true,
        maxTasks: 5,
        createdAt: DateTime.now(),
      );
      
      await widgetService.createWidget(defaultConfig);
      await logger.logInfo('Default widget created');
    } else {
      await widgetService.updateAllWidgets();
      await logger.logInfo('Existing widgets updated');
    }
  } catch (e, stackTrace) {
    await logger.logError('Error setting up default widget', e, stackTrace);
  }
}

void _setupWidgetActionHandling(WidgetService widgetService, LoggerService logger) {
  const platform = services.MethodChannel('com.example.todo_app/widget');
  
  platform.setMethodCallHandler((services.MethodCall call) async {
    try {
      if (call.method == 'handleWidgetAction') {
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        final String action = args['action'] as String;
        final Map<dynamic, dynamic> data = args['data'] as Map<dynamic, dynamic>? ?? {};
        
        switch (action) {
          case 'add_task':
            // First, navigate to home route to ensure we're on the home screen
            // Use popUntil to remove all routes except home if needed
            navigatorKey.currentState?.popUntil((route) => route.isFirst);

            // Store a flag to indicate we should navigate to the home tab
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('navigate_to_home_tab', true);

            // Then navigate to add task route
            navigatorKey.currentState?.pushNamed(app_constants.AppConstants.addTaskRoute).then((_) {
              // Trigger global data refresh after returning from task creation
              globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
            });
            break;
          case 'widget_settings':
            final widgetConfigRepository = WidgetConfigRepository();
            final configs = await widgetConfigRepository.getAllWidgetConfigs();
            
            if (configs.isNotEmpty) {
              final widgetConfig = configs.first;
              navigatorKey.currentState?.push(
                mat.MaterialPageRoute(
                  builder: (_) => WidgetCreationScreen(existingConfig: widgetConfig),
                ),
              );
            } else {
              navigatorKey.currentState?.push(
                mat.MaterialPageRoute(
                  builder: (_) => const WidgetCreationScreen(),
                ),
              );
            }
            break;
          case 'background_sync':
          case 'background_toggle_task':
          case 'silent_background_toggle_task':
            await widgetService.handleWidgetAction(action, data);
            globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
            break;
        }
      }
    } catch (e, stackTrace) {
      await logger.logError('Widget action error', e, stackTrace);
    }
  });
}

void _reportError(dynamic error, StackTrace? stackTrace, LoggerService logger) async {
  try {
    await logger.logError('Uncaught exception', error, stackTrace);
    debugPrint('ERROR: $error');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: $stackTrace');
    }
  } catch (logError) {
    debugPrint('LOGGER FAILED: $logError');
    debugPrint('ORIGINAL ERROR: $error');
  }
}

// Basic fallback app
class _BasicApp extends mat.StatelessWidget {
  const _BasicApp();

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.MaterialApp(
      title: 'Todo App',
      theme: mat.ThemeData(
        colorScheme: mat.ColorScheme.fromSeed(seedColor: mat.Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _BasicHomeScreen(),
    );
  }
}

class _BasicHomeScreen extends mat.StatelessWidget {
  const _BasicHomeScreen();

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: const mat.Text('Todo App'),
        backgroundColor: mat.Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const mat.Center(
        child: mat.Column(
          mainAxisAlignment: mat.MainAxisAlignment.center,
          children: [
            mat.Icon(
              mat.Icons.task_alt,
              size: 100,
              color: mat.Colors.deepPurple,
            ),
            mat.SizedBox(height: 20),
            mat.Text(
              'Todo App',
              style: mat.TextStyle(fontSize: 24, fontWeight: mat.FontWeight.bold),
            ),
            mat.SizedBox(height: 10),
            mat.Text('Loading...'),
          ],
        ),
      ),
    );
  }
}