import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';
import 'dart:async';
import 'package:todo_app/core/security/services/security_service.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  final WidgetConfigRepository _widgetConfigRepository = WidgetConfigRepository();
  final task_repository.TaskRepository _taskRepository = task_repository.TaskRepository();
  final category_repository.CategoryRepository _categoryRepository = category_repository.CategoryRepository();
  final LoggerService _logger = LoggerService();
  final SecurityService _securityService = SecurityService();

  bool _isInitialized = false;
  static const platform = MethodChannel('com.example.todo_app/widget');
  Timer? _commandPoller;

  // Use consistent data keys
  static const String widgetDataKey = 'widget_data';
  static const String widgetConfigKey = 'widget_config';

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('WidgetService already initialized, skipping initialization');
      return;
    }

    try {
      await _logger.logInfo('=== Starting WidgetService Initialization ===');
      
      // Set up method channel handler
      platform.setMethodCallHandler(_handleMethodCall);
      
      // Initialize home widget
      try {
        await HomeWidget.setAppGroupId('group.com.example.todo_app');
      } catch (e) {
        await _logger.logWarning('App group not supported on this platform: $e');
      }
      
      // Initialize with default data
      await _initializeDefaultWidgetData();
      
      // Start command polling to listen for widget actions
      _startCommandPolling();
      
      _isInitialized = true;
      await _logger.logInfo('=== WidgetService Initialization Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== WidgetService Initialization Failed ===', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeDefaultWidgetData() async {
    try {
      await _logger.logInfo('Initializing default widget data');
      
      final defaultConfig = {
        'name': 'Todo Tasks',
        'maxTasks': 3,
        'showCompleted': false,
        'showCategories': true,
        'showPriority': true,
      };
      
      final defaultData = {
        'tasks': [],
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'taskCount': 0,
        'completedCount': 0,
        'overdueCount': 0,
      };
      
      // Save to multiple SharedPreferences locations for maximum compatibility
      await _saveWidgetDataSafely(widgetConfigKey, jsonEncode(defaultConfig));
      await _saveWidgetDataSafely(widgetDataKey, jsonEncode(defaultData));
      
      // Force widget update
      await _updateWidgetDisplay();
      
      await _logger.logInfo('Default widget data initialized and widget updated');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing default widget data', e, stackTrace);
    }
  }

  Future<void> _saveWidgetDataSafely(String key, String data) async {
    try {
      await _logger.logInfo('Saving widget data with key: $key, length: ${data.length}');
      
      // Save to HomeWidget plugin
      await HomeWidget.saveWidgetData<String>(key, data);
      await HomeWidget.saveWidgetData<String>('flutter.$key', data);
      
      // Also save to regular SharedPreferences for Android widget direct access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, data);
      await prefs.setString('flutter.$key', data);
      
      await _logger.logInfo('Widget data saved successfully for key: $key');
    } catch (e, stackTrace) {
      await _logger.logError('Error saving widget data for key: $key', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _updateWidgetDisplay() async {
    try {
      await _logger.logInfo('Updating widget display');
      
      await HomeWidget.updateWidget(
        name: 'TodoWidgetProvider',
        androidName: 'TodoWidgetProvider',
        iOSName: 'TodoWidget',
        qualifiedAndroidName: 'com.example.todo_app.TodoWidgetProvider',
      );
      
      await _logger.logInfo('Widget display update triggered');
    } catch (e, stackTrace) {
      await _logger.logError('Error updating widget display', e, stackTrace);
    }
  }

  // CRITICAL: Command polling to handle widget actions
  // Optimized to 2 seconds to reduce battery usage while maintaining responsiveness
  void _startCommandPolling() {
    _commandPoller?.cancel();
    _commandPoller = Timer.periodic(const Duration(seconds: 2), (_) => _checkForWidgetCommands());
    _logger.logInfo('Started widget command polling (2 second interval for battery optimization)');
  }

  Future<void> _checkForWidgetCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check both normal and flutter-prefixed keys
      final command = prefs.getString('command') ?? prefs.getString('flutter.command');

      if (command != null) {
        final taskId = prefs.getInt('task_id') ?? prefs.getInt('flutter.task_id') ?? -1;
        final widgetId = prefs.getInt('widget_id') ?? prefs.getInt('flutter.widget_id') ?? 1;
        final timestamp = prefs.getInt('timestamp') ?? prefs.getInt('flutter.timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final age = now - timestamp;

        await _logger.logInfo('>>> FOUND WIDGET COMMAND: $command');
        await _logger.logInfo('>>> TaskID: $taskId, WidgetID: $widgetId');
        await _logger.logInfo('>>> Timestamp: $timestamp, Current: $now, Age: ${age}ms');

        // Only process recent commands (within last 60 seconds to handle slow startups)
        if (age < 60000) {
          await _logger.logInfo('=== PROCESSING WIDGET COMMAND: $command ===');
          await _logger.logInfo('TaskID: $taskId, WidgetID: $widgetId, Timestamp: $timestamp');

          switch (command) {
            case 'toggle_task':
              await _logger.logInfo('>>> Calling _handleTaskToggle for taskId=$taskId');
              await _handleTaskToggle(taskId);
              await _logger.logInfo('>>> _handleTaskToggle completed');
              break;
            default:
              await _logger.logWarning('>>> Unknown command: $command');
          }

          // Clear both sets of command keys after processing
          await prefs.remove('command');
          await prefs.remove('task_id');
          await prefs.remove('widget_id');
          await prefs.remove('timestamp');
          await prefs.remove('flutter.command');
          await prefs.remove('flutter.task_id');
          await prefs.remove('flutter.widget_id');
          await prefs.remove('flutter.timestamp');

          await _logger.logInfo('=== WIDGET COMMAND PROCESSED AND CLEARED ===');
        } else {
          await _logger.logWarning('>>> Command timestamp too old, ignoring: $command (age: ${age}ms)');
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('>>> Error checking widget commands', e, stackTrace);
    }
  }

  Future<void> _handleTaskToggle(int taskId) async {
    try {
      await _logger.logInfo('Handling task toggle from widget: TaskID=$taskId');
      
      final task = await _taskRepository.getTask(taskId);
      if (task != null) {
        await _taskRepository.toggleTaskCompletion(taskId, !task.isCompleted);
        await _logger.logInfo('Task toggled: TaskID=$taskId, NewState=${!task.isCompleted}');
        
        // Immediately update widget with new data
        await updateAllWidgets();
      } else {
        await _logger.logWarning('Task not found for toggle: TaskID=$taskId');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling task toggle from widget', e, stackTrace);
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    await _logger.logInfo('Widget method call received: ${call.method}');
    
    try {
      switch (call.method) {
        case 'handleWidgetAction':
          final String action = call.arguments['action'];
          final Map<dynamic, dynamic> data = call.arguments['data'] ?? {};
          await handleWidgetAction(action, data);
          break;
        default:
          throw PlatformException(
            code: 'UNIMPLEMENTED',
            details: 'Method ${call.method} not implemented',
          );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling widget method call', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isSecurityEnabled() async {
    try {
      return await _securityService.isSecurityEnabled();
    } catch (e) {
      await _logger.logError('Error checking security status', e);
      return false;
    }
  }

  Future<void> disableAllWidgets() async {
    try {
      await _logger.logInfo('=== Disabling All Widgets (Security Enabled) ===');

      // Delete all widget configurations from database
      final configs = await _widgetConfigRepository.getAllWidgetConfigs();
      for (final config in configs) {
        await _widgetConfigRepository.deleteWidgetConfig(config.id!);
      }

      // Clear widget data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(widgetDataKey);
      await prefs.remove(widgetConfigKey);
      await prefs.remove('flutter.$widgetDataKey');
      await prefs.remove('flutter.$widgetConfigKey');

      // Clear widget data from HomeWidget plugin
      await HomeWidget.saveWidgetData<String>(widgetDataKey, null);
      await HomeWidget.saveWidgetData<String>(widgetConfigKey, null);
      await HomeWidget.saveWidgetData<String>('flutter.$widgetDataKey', null);
      await HomeWidget.saveWidgetData<String>('flutter.$widgetConfigKey', null);

      // Update widget display to show empty/disabled state
      await _updateWidgetDisplay();

      await _logger.logInfo('=== All Widgets Disabled ===');
    } catch (e, stackTrace) {
      await _logger.logError('Error disabling widgets', e, stackTrace);
    }
  }

  Future<void> createWidget(WidgetConfig config) async {
    if (!_isInitialized) {
      await init();
    }

    // Check if security is enabled
    if (await isSecurityEnabled()) {
      await _logger.logWarning('Widget creation blocked: Security is enabled');
      throw Exception('Widgets are disabled when password protection is enabled. Please disable password protection in Settings to use widgets.');
    }

    try {
      await _logger.logInfo('=== Creating Widget ===');
      await _logger.logInfo('Config: ${config.name}, Size: ${config.size.label}, MaxTasks: ${config.maxTasks}');

      final configWithTimestamp = config.copyWith(createdAt: DateTime.now());
      final widgetId = await _widgetConfigRepository.insertWidgetConfig(configWithTimestamp);

      await _logger.logInfo('Widget config inserted with ID: $widgetId');
      await _prepareWidgetData(widgetId);
      await _logger.logInfo('=== Widget Creation Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Widget Creation Failed ===', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateWidget(int widgetId) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _logger.logInfo('=== Updating Widget ID: $widgetId ===');
      await _prepareWidgetData(widgetId);
      await _logger.logInfo('=== Widget Update Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Widget Update Failed ===', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _prepareWidgetData(int widgetId) async {
    try {
      await _logger.logInfo('--- Preparing Widget Data for ID: $widgetId ---');
      
      final config = await _widgetConfigRepository.getWidgetConfig(widgetId);
      if (config == null) {
        await _logger.logError('Widget config not found: ID=$widgetId');
        return;
      }

      final tasks = await _getTasksForWidget(config);
      final categories = await _categoryRepository.getAllCategories();
      
      final widgetData = await _buildWidgetData(config, tasks, categories);
      
      // Save data with proper keys
      final dataJson = jsonEncode(widgetData);
      final configJson = jsonEncode(config.toMap());
      
      await _saveWidgetDataSafely(widgetDataKey, dataJson);
      await _saveWidgetDataSafely(widgetConfigKey, configJson);
      
      // CRITICAL: Force immediate widget refresh
      await _updateWidgetDisplay();
      
      await _logger.logInfo('--- Widget Data Preparation Complete for ID: $widgetId ---');
    } catch (e, stackTrace) {
      await _logger.logError('--- Widget Data Preparation Failed ---', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> _getTasksForWidget(WidgetConfig config) async {
    try {
      await _logger.logInfo('--- Getting Tasks for Widget: ${config.name} ---');
      List<task_model.Task> tasks;
      
      // Apply category filter
      if (config.categoryFilter != null) {
        final categories = await _categoryRepository.getAllCategories();
        final category = categories.firstWhere(
          (cat) => cat.name == config.categoryFilter,
          orElse: () => category_model.Category(id: -1, name: '', color: const Color(0xFF000000)),
        );
        
        if (category.id != null && category.id! > 0) {
          tasks = await _taskRepository.getTasksByCategory(category.id!);
        } else {
          tasks = await _taskRepository.getAllTasks();
        }
      } else {
        tasks = await _taskRepository.getAllTasks();
      }

      // Apply completion filter
      if (!config.showCompleted) {
        tasks = tasks.where((task) => !task.isCompleted).toList();
      }

      // Sort tasks by priority and due date
      tasks.sort((a, b) {
        // Completed tasks go to bottom
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        
        // Sort by priority (high = 0, medium = 1, low = 2)
        if (a.priority != b.priority) {
          return a.priority.index.compareTo(b.priority.index);
        }
        
        // Sort by due date (earliest first)
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }
        
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

      // Limit to maxTasks
      if (tasks.length > config.maxTasks) {
        tasks = tasks.take(config.maxTasks).toList();
      }

      await _logger.logInfo('Final task count for widget: ${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks for widget', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _buildWidgetData(
    WidgetConfig config,
    List<task_model.Task> tasks,
    List<category_model.Category> categories,
  ) async {
    try {
      await _logger.logInfo('--- Building Widget Data Structure ---');
      
      final tasksData = <Map<String, dynamic>>[];
      
      for (final task in tasks) {
        category_model.Category? category;
        if (task.categoryId != null) {
          category = categories.firstWhere(
            (cat) => cat.id == task.categoryId,
            orElse: () => category_model.Category(
              id: 0,
              name: 'Unknown',
              color: const Color(0xFF9E9E9E),
            ),
          );
        }

        // Format due date
        String? formattedDueDate;
        if (task.dueDate != null) {
          try {
            final dateFormat = intl.DateFormat('MMM d, yyyy');
            final timeFormat = intl.DateFormat('h:mm a');
            formattedDueDate = '${dateFormat.format(task.dueDate!)} · ${timeFormat.format(task.dueDate!)}';
          } catch (e) {
            formattedDueDate = 'Invalid Date';
          }
        }

        final taskData = {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'isCompleted': task.isCompleted,
          'priority': task.priority.index,
          'priorityLabel': task.priority.label,
          'priorityColor': task.priority.color.toARGB32(),
          'dueDate': task.dueDate?.millisecondsSinceEpoch,
          'formattedDueDate': formattedDueDate,
          'category': category != null ? {
            'name': category.name,
            'color': category.color.toARGB32(),
          } : null,
          'completedAt': task.completedAt?.millisecondsSinceEpoch,
        };
        
        tasksData.add(taskData);
      }

      final widgetData = {
        'config': config.toMap(),
        'tasks': tasksData,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'taskCount': tasksData.length,
        'completedCount': tasksData.where((task) => task['isCompleted'] == true).length,
        'overdueCount': tasksData.where((task) {
          final dueDate = task['dueDate'];
          return dueDate != null && 
                  dueDate < DateTime.now().millisecondsSinceEpoch && 
                  task['isCompleted'] != true;
        }).length,
      };

      await _logger.logInfo('Widget data structure complete: ${tasksData.length} tasks');
      return widgetData;
    } catch (e, stackTrace) {
      await _logger.logError('Error building widget data structure', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAllWidgets() async {
    try {
      await _logger.logInfo('=== Updating All Widgets ===');
      final configs = await _widgetConfigRepository.getAllWidgetConfigs();

      if (configs.isEmpty) {
        await _logger.logInfo('No widgets found, creating default widget');
        final defaultConfig = WidgetConfig(
          name: 'Todo Tasks',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
          createdAt: DateTime.now(),
        );
        await createWidget(defaultConfig);
        return;
      }

      // IMPORTANT: Always use the first widget's config for now (single widget support)
      // But save data without widget ID so all Android widgets can read it
      if (configs.isNotEmpty && configs.first.id != null) {
        await _prepareWidgetData(configs.first.id!);
      }

      await _logger.logInfo('=== All Widgets Updated: ${configs.length} widgets ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Update All Widgets Failed ===', e, stackTrace);
      rethrow;
    }
  }

  Future<void> handleWidgetAction(String action, Map<dynamic, dynamic> data) async {
    try {
      await _logger.logInfo('=== Handling Widget Action: $action ===');
      
      switch (action) {
        case 'add_task':
          await _logger.logInfo('Add task action triggered from widget');
          // App will stay open for task creation
          break;
          
        case 'widget_settings':
          await _logger.logInfo('Widget settings action triggered');
          // App will stay open for settings
          break;
          
        case 'background_sync':
          await _logger.logInfo('Background sync requested');
          await forceWidgetUpdate();
          break;
          
        case 'background_toggle_task':
        case 'silent_background_toggle_task':
          final taskId = data['taskId'] as int?;
          if (taskId != null) {
            await _handleTaskToggle(taskId);
          }
          break;
      }
      
      await _logger.logInfo('=== Widget Action Handled: $action ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Widget Action Failed: $action ===', e, stackTrace);
    }
  }

  Future<void> forceWidgetUpdate() async {
    try {
      await _logger.logInfo('=== Force Widget Update ===');
      
      final configs = await _widgetConfigRepository.getAllWidgetConfigs();
      if (configs.isNotEmpty && configs.first.id != null) {
        await _prepareWidgetData(configs.first.id!);
      } else {
        await _initializeDefaultWidgetData();
      }
      
      await _logger.logInfo('=== Force Widget Update Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Force Widget Update Failed ===', e, stackTrace);
    }
  }

  Future<List<WidgetConfig>> getAllWidgetConfigs() async {
    try {
      final configs = await _widgetConfigRepository.getAllWidgetConfigs();
      await _logger.logInfo('Retrieved ${configs.length} widget configurations');
      return configs;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting widget configurations', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isWidgetSupported() async {
    try {
      return true;
    } catch (e, stackTrace) {
      await _logger.logError('Error checking widget support', e, stackTrace);
      return false;
    }
  }

  Future<void> deleteWidget(int widgetId) async {
    try {
      await _logger.logInfo('=== Deleting Widget ID: $widgetId ===');
      
      await _widgetConfigRepository.deleteWidgetConfig(widgetId);
      await HomeWidget.saveWidgetData<String>(widgetDataKey, null);
      await HomeWidget.saveWidgetData<String>(widgetConfigKey, null);
      
      await _logger.logInfo('=== Widget Deletion Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Widget Deletion Failed ===', e, stackTrace);
      rethrow;
    }
  }

  void dispose() {
    _commandPoller?.cancel();
    _commandPoller = null;
  }
}