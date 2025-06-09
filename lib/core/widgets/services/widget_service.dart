import 'package:flutter/material.dart';
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

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('WidgetService already initialized');
      return;
    }

    try {
      await _logger.logInfo('Initializing WidgetService');
      await HomeWidget.setAppGroupId('group.com.example.todo_app');
      _isInitialized = true;
      await _logger.logInfo('WidgetService initialized successfully');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing WidgetService', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isWidgetSupported() async {
    try {
      // Check if the platform supports widgets
      const isSupported = true; // Assume supported for now
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
      
      // Save widget configuration to database
      final configWithTimestamp = config.copyWith(
        createdAt: DateTime.now(),
      );
      final widgetId = await _widgetConfigRepository.insertWidgetConfig(configWithTimestamp);
      
      // Update widget data
      await updateWidget(widgetId);
      
      // Register the widget with the system
      await HomeWidget.updateWidget(
        name: 'TodoWidgetProvider',
        androidName: 'TodoWidgetProvider',
        iOSName: 'TodoWidget',
        qualifiedAndroidName: 'com.example.todo_app.TodoWidgetProvider',
      );
      
      await _logger.logInfo('Widget created successfully: ID=$widgetId');
    } catch (e, stackTrace) {
      await _logger.logError('Error creating widget', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateWidget(int widgetId) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _logger.logInfo('Updating widget: ID=$widgetId');
      
      final config = await _widgetConfigRepository.getWidgetConfig(widgetId);
      if (config == null) {
        await _logger.logWarning('Widget config not found for update: ID=$widgetId');
        return;
      }

      // Get tasks based on configuration
      final tasks = await _getTasksForWidget(config);
      final categories = await _categoryRepository.getAllCategories();
      
      // Prepare widget data
      final widgetData = await _prepareWidgetData(config, tasks, categories);
      
      // Send data to widget
      await HomeWidget.saveWidgetData<String>('widget_data', jsonEncode(widgetData));
      await HomeWidget.saveWidgetData<String>('widget_config', jsonEncode(config.toMap()));
      
      // Update the widget
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
      
      for (final config in configs) {
        if (config.id != null) {
          await updateWidget(config.id!);
        }
      }
      
      await _logger.logInfo('All widgets updated: Count=${configs.length}');
    } catch (e, stackTrace) {
      await _logger.logError('Error updating all widgets', e, stackTrace);
    }
  }

  Future<void> deleteWidget(int widgetId) async {
    try {
      await _logger.logInfo('Deleting widget: ID=$widgetId');
      
      await _widgetConfigRepository.deleteWidgetConfig(widgetId);
      
      // Clear widget data
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
      // Get category ID from name
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

    // Filter by completion status
    if (!config.showCompleted) {
      tasks = tasks.where((task) => !task.isCompleted).toList();
    }

    // Sort by priority and due date
    tasks.sort((a, b) {
      // First sort by completion status (incomplete first)
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // Then by priority (high first)
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      
      // Then by due date (soonest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      
      return 0;
    });

    // Limit to max tasks
    if (tasks.length > config.maxTasks) {
      tasks = tasks.take(config.maxTasks).toList();
    }

    return tasks;
  }

  Future<Map<String, dynamic>> _prepareWidgetData(
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

  // Method to handle widget button presses
  Future<void> handleWidgetAction(String action, int? widgetId) async {
    try {
      await _logger.logInfo('Handling widget action: $action for widget: $widgetId');
      
      switch (action) {
        case 'refresh':
          if (widgetId != null) {
            await updateWidget(widgetId);
          } else {
            await updateAllWidgets();
          }
          break;
        case 'add_task':
          // This would typically open the add task screen
          // Implementation depends on how you want to handle navigation from widgets
          await _logger.logInfo('Add task action triggered from widget');
          break;
        case 'settings':
          // This would typically open widget settings
          await _logger.logInfo('Settings action triggered from widget');
          break;
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling widget action', e, stackTrace);
    }
  }
}