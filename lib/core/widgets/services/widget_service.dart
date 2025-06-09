import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'dart:convert';

class WidgetService {
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  final WidgetConfigRepository _widgetConfigRepository = WidgetConfigRepository();
  final task_repository.TaskRepository _taskRepository = task_repository.TaskRepository();
  final category_repository.CategoryRepository _categoryRepository = category_repository.CategoryRepository();
  final LoggerService _logger = LoggerService();

  bool _isInitialized = false;
  static const platform = MethodChannel('com.example.todo_app/widget');

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('WidgetService already initialized');
      return;
    }

    try {
      await _logger.logInfo('Initializing WidgetService');
      
      // Set up method channel handler for widget actions
      platform.setMethodCallHandler(_handleMethodCall);
      
      // Initialize home widget without app group for Android
      try {
        await HomeWidget.setAppGroupId('group.com.example.todo_app');
      } catch (e) {
        // Ignore app group errors on Android
        await _logger.logWarning('App group not supported on this platform: $e');
      }
      
      _isInitialized = true;
      await _logger.logInfo('WidgetService initialized successfully');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing WidgetService', e, stackTrace);
      rethrow;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
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
  }

  Future<bool> isWidgetSupported() async {
    try {
      const isSupported = true;
      await _logger.logInfo('Widget support check: $isSupported');
      return isSupported;
    } catch (e, stackTrace) {
      await _logger.logError('Error checking widget support', e, stackTrace);
      return false;
    }
  }

  Future<void> createWidget(WidgetConfig config) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _logger.logInfo('Creating widget: Name=${config.name}, Size=${config.size.label}');
      
      final configWithTimestamp = config.copyWith(
        createdAt: DateTime.now(),
      );
      final widgetId = await _widgetConfigRepository.insertWidgetConfig(configWithTimestamp);
      
      await _prepareWidgetData(widgetId);
      
      await _logger.logInfo('Widget created successfully: ID=$widgetId');
    } catch (e, stackTrace) {
      await _logger.logError('Error creating widget', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _prepareWidgetData(int widgetId) async {
    try {
      final config = await _widgetConfigRepository.getWidgetConfig(widgetId);
      if (config == null) {
        await _logger.logWarning('Widget config not found for data preparation: ID=$widgetId');
        return;
      }

      final tasks = await _getTasksForWidget(config);
      final categories = await _categoryRepository.getAllCategories();
      
      final widgetData = await _buildWidgetData(config, tasks, categories);
      
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(widgetData));
      await HomeWidget.saveWidgetData<String>('widget_config', jsonEncode(config.toMap()));
      
      await _logger.logInfo('Widget data prepared successfully: ID=$widgetId');
    } catch (e, stackTrace) {
      await _logger.logError('Error preparing widget data', e, stackTrace);
    }
  }

  Future<void> updateWidget(int widgetId) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _logger.logInfo('Updating widget: ID=$widgetId');
      
      await _prepareWidgetData(widgetId);
      
      await HomeWidget.updateWidget(
        name: 'TodoWidgetProvider',
        androidName: 'TodoWidgetProvider',
        iOSName: 'TodoWidget',
        qualifiedAndroidName: 'com.example.todo_app.TodoWidgetProvider',
      );
      
      await _logger.logInfo('Widget updated successfully: ID=$widgetId');
    } catch (e, stackTrace) {
      await _logger.logError('Error updating widget', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAllWidgets() async {
    try {
      await _logger.logInfo('Updating all widgets');
      final configs = await _widgetConfigRepository.getAllWidgetConfigs();
      
      if (configs.isEmpty) {
        await _logger.logInfo('No widgets to update');
        return;
      }
      
      for (final config in configs) {
        if (config.id != null) {
          await _prepareWidgetData(config.id!);
        }
      }
      
      await HomeWidget.updateWidget(
        name: 'TodoWidgetProvider',
        androidName: 'TodoWidgetProvider',
        iOSName: 'TodoWidget',
        qualifiedAndroidName: 'com.example.todo_app.TodoWidgetProvider',
      );
      
      await _logger.logInfo('All widgets updated: Count=${configs.length}');
    } catch (e, stackTrace) {
      await _logger.logError('Error updating all widgets', e, stackTrace);
    }
  }

  Future<void> deleteWidget(int widgetId) async {
    try {
      await _logger.logInfo('Deleting widget: ID=$widgetId');
      
      await _widgetConfigRepository.deleteWidgetConfig(widgetId);
      
      await HomeWidget.saveWidgetData<String>('widget_data_$widgetId', null);
      
      await _logger.logInfo('Widget deleted successfully: ID=$widgetId');
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting widget', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> _getTasksForWidget(WidgetConfig config) async {
    List<task_model.Task> tasks;
    
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

    if (!config.showCompleted) {
      tasks = tasks.where((task) => !task.isCompleted).toList();
    }

    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      
      return 0;
    });

    if (tasks.length > config.maxTasks) {
      tasks = tasks.take(config.maxTasks).toList();
    }

    return tasks;
  }

  Future<Map<String, dynamic>> _buildWidgetData(
    WidgetConfig config,
    List<task_model.Task> tasks,
    List<category_model.Category> categories,
  ) async {
    final tasksData = tasks.map((task) {
      final category = task.categoryId != null
          ? categories.firstWhere(
              (cat) => cat.id == task.categoryId,
              orElse: () => category_model.Category(id: 0, name: 'Unknown', color: const Color(0xFF9E9E9E)),
            )
          : null;

      return {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority.index,
        'priorityLabel': task.priority.label,
        'priorityColor': task.priority.color.value,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'category': category != null ? {
          'name': category.name,
          'color': category.color.value,
        } : null,
      };
    }).toList();

    return {
      'config': config.toMap(),
      'tasks': tasksData,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<List<WidgetConfig>> getAllWidgetConfigs() async {
    return await _widgetConfigRepository.getAllWidgetConfigs();
  }

  // Updated method to handle widget button presses and task toggles
  Future<void> handleWidgetAction(String action, Map<dynamic, dynamic> data) async {
    try {
      await _logger.logInfo('Handling widget action: $action with data: $data');
      
      switch (action) {
        case 'sync_widget':
          final widgetId = data['widgetId'] as int?;
          if (widgetId != null) {
            await updateWidget(widgetId);
          } else {
            await updateAllWidgets();
          }
          break;
          
        case 'add_task':
          final widgetId = data['widgetId'] as int?;
          await _logger.logInfo('Add task action triggered from widget: $widgetId');
          // Navigate to add task screen - this will be handled by the app router
          break;
          
        case 'widget_settings':
          final widgetId = data['widgetId'] as int?;
          await _logger.logInfo('Widget settings action triggered for widget: $widgetId');
          // Navigate to widget settings - this will be handled by the app router
          break;
          
        case 'toggle_task':
          final taskId = data['taskId'] as int?;
          final widgetId = data['widgetId'] as int?;
          if (taskId != null) {
            await _toggleTaskCompletion(taskId);
            // Update the specific widget after toggling
            if (widgetId != null) {
              await updateWidget(widgetId);
            } else {
              await updateAllWidgets();
            }
          }
          break;
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling widget action', e, stackTrace);
    }
  }

  Future<void> _toggleTaskCompletion(int taskId) async {
    try {
      final task = await _taskRepository.getTask(taskId);
      if (task != null) {
        await _taskRepository.toggleTaskCompletion(taskId, !task.isCompleted);
        await _logger.logInfo('Task completion toggled from widget: TaskID=$taskId, NewState=${!task.isCompleted}');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error toggling task completion from widget', e, stackTrace);
    }
  }
}