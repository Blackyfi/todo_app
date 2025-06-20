import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:intl/intl.dart' as intl;
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

  // CRITICAL: Use consistent data keys
  static const String WIDGET_DATA_KEY = 'widget_data';
  static const String WIDGET_CONFIG_KEY = 'widget_config';

  Future<void> init() async {
    if (_isInitialized) {
      await _logger.logInfo('WidgetService already initialized, skipping initialization');
      return;
    }

    try {
      await _logger.logInfo('=== Starting WidgetService Initialization ===');
      
      // Set up method channel handler for widget actions
      platform.setMethodCallHandler(_handleMethodCall);
      
      // Initialize home widget - try with and without app group
      try {
        await HomeWidget.setAppGroupId('group.com.example.todo_app');
      } catch (e) {
        await _logger.logWarning('App group not supported on this platform: $e');
      }
      
      // CRITICAL: Initialize with default data immediately
      await _initializeDefaultWidgetData();
      
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
      
      // Create minimal default data to prevent null errors
      final defaultConfig = {
        'name': 'Todo App',
        'maxTasks': 3, // Reduced for widget stability
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
      
      // CRITICAL: Save with consistent keys and multiple attempts
      await _saveWidgetDataSafely(WIDGET_CONFIG_KEY, jsonEncode(defaultConfig));
      await _saveWidgetDataSafely(WIDGET_DATA_KEY, jsonEncode(defaultData));
      
      // CRITICAL: Force widget update after setting data
      await _updateWidgetDisplay();
      
      await _logger.logInfo('Default widget data initialized and widget updated');
    } catch (e, stackTrace) {
      await _logger.logError('Error initializing default widget data', e, stackTrace);
    }
  }

  Future<void> _saveWidgetDataSafely(String key, String data) async {
    try {
      await _logger.logInfo('Saving widget data with key: $key, length: ${data.length}');
      
      // Save with the direct key
      await HomeWidget.saveWidgetData<String>(key, data);
      await _logger.logInfo('Saved widget data with key: $key');
      
      // Also try saving with flutter. prefix as fallback
      await HomeWidget.saveWidgetData<String>('flutter.$key', data);
      await _logger.logInfo('Saved widget data with key: flutter.$key');
      
      // Verify the data was saved
      final retrieved = await HomeWidget.getWidgetData<String>(key);
      if (retrieved != null) {
        await _logger.logInfo('Verified saved data for key: $key, length: ${retrieved.length}');
      } else {
        await _logger.logWarning('Could not verify saved data for key: $key');
      }
      
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

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    await _logger.logInfo('Widget method call received: ${call.method} with arguments: ${call.arguments}');
    
    try {
      switch (call.method) {
        case 'handleWidgetAction':
          final String action = call.arguments['action'];
          final Map<dynamic, dynamic> data = call.arguments['data'] ?? {};
          await _logger.logInfo('Processing widget action: $action with data: $data');
          await handleWidgetAction(action, data);
          await _logger.logInfo('Widget action processed successfully: $action');
          break;
        default:
        await _logger.logWarning('Unimplemented widget method called: ${call.method}');
          throw PlatformException(
            code: 'UNIMPLEMENTED',
            details: 'Method ${call.method} not implemented',
          );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling widget method call: ${call.method}', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isWidgetSupported() async {
    try {
      await _logger.logInfo('Checking widget support on this platform');
      const isSupported = true;
      await _logger.logInfo('Widget support check result: $isSupported');
      return isSupported;
    } catch (e, stackTrace) {
      await _logger.logError('Error checking widget support', e, stackTrace);
      return false;
    }
  }

  Future<void> createWidget(WidgetConfig config) async {
    if (!_isInitialized) {
      await _logger.logWarning('WidgetService not initialized, initializing now for widget creation');
      await init();
    }

    try {
      await _logger.logInfo('=== Starting Widget Creation ===');
      await _logger.logInfo('Creating widget with config: Name=${config.name}, Size=${config.size.label}, MaxTasks=${config.maxTasks}');
      await _logger.logInfo('Widget display options: ShowCompleted=${config.showCompleted}, ShowCategories=${config.showCategories}, ShowPriority=${config.showPriority}');
      if (config.categoryFilter != null) {
        await _logger.logInfo('Widget category filter: ${config.categoryFilter}');
      }
      
      final configWithTimestamp = config.copyWith(
        createdAt: DateTime.now(),
      );
      
      await _logger.logInfo('Inserting widget config into database');
      final widgetId = await _widgetConfigRepository.insertWidgetConfig(configWithTimestamp);
      await _logger.logInfo('Widget config inserted with ID: $widgetId');
      
      await _logger.logInfo('Preparing widget data for display');
      await _prepareWidgetData(widgetId);
      
      await _logger.logInfo('=== Widget Creation Complete: ID=$widgetId ===');
    } catch (e, stackTrace) {
      await _logger.logError('=== Widget Creation Failed ===', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _prepareWidgetData(int widgetId) async {
    try {
      await _logger.logInfo('--- Preparing Widget Data for ID: $widgetId ---');
      
      final config = await _widgetConfigRepository.getWidgetConfig(widgetId);
      if (config == null) {
        await _logger.logError('Widget config not found for data preparation: ID=$widgetId');
        return;
      }
      await _logger.logInfo('Widget config loaded: ${config.name}');

      await _logger.logInfo('Loading tasks for widget with filters');
      final tasks = await _getTasksForWidget(config);
      await _logger.logInfo('Loaded ${tasks.length} tasks for widget after filtering');
      
      await _logger.logInfo('Loading all categories for widget data');
final categories = await _categoryRepository.getAllCategories();
     await _logger.logInfo('Loaded ${categories.length} categories for widget');
     
     await _logger.logInfo('Building widget data structure');
     final widgetData = await _buildWidgetData(config, tasks, categories);
     await _logger.logInfo('Widget data structure built with ${(widgetData['tasks'] as List).length} tasks');
     
     await _logger.logInfo('Saving widget data to home widget plugin');
     final dataJson = jsonEncode(widgetData);
     await _logger.logInfo('Widget data JSON size: ${dataJson.length} characters');
     await _saveWidgetDataSafely(WIDGET_DATA_KEY, dataJson);
     await _logger.logInfo('Widget data saved successfully');
     
     final configJson = jsonEncode(config.toMap());
     await _logger.logInfo('Widget config JSON size: ${configJson.length} characters');
     await _saveWidgetDataSafely(WIDGET_CONFIG_KEY, configJson);
     await _logger.logInfo('Widget config saved successfully');
     
     await _updateWidgetDisplay();
     
     await _logger.logInfo('--- Widget Data Preparation Complete for ID: $widgetId ---');
   } catch (e, stackTrace) {
     await _logger.logError('--- Widget Data Preparation Failed for ID: $widgetId ---', e, stackTrace);
     rethrow;
   }
 }

 Future<void> updateWidget(int widgetId) async {
   if (!_isInitialized) {
     await _logger.logWarning('WidgetService not initialized, initializing now for widget update');
     await init();
   }

   try {
     await _logger.logInfo('=== Starting Widget Update for ID: $widgetId ===');
     
     await _logger.logInfo('Preparing updated widget data');
     await _prepareWidgetData(widgetId);
     
     await _logger.logInfo('=== Widget Update Complete for ID: $widgetId ===');
   } catch (e, stackTrace) {
     await _logger.logError('=== Widget Update Failed for ID: $widgetId ===', e, stackTrace);
     rethrow;
   }
 }

 Future<void> updateAllWidgets() async {
   try {
     await _logger.logInfo('=== Starting Update of All Widgets ===');
     final configs = await _widgetConfigRepository.getAllWidgetConfigs();
     await _logger.logInfo('Found ${configs.length} widget configurations to update');
     
     if (configs.isEmpty) {
        await _logger.logInfo('No widgets to update, creating default widget...');
        // Create a default widget if none exists
        final defaultConfig = WidgetConfig(
          name: 'Todo Tasks',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 3, // Reduced for widget stability
          createdAt: DateTime.now(),
        );
       await createWidget(defaultConfig);
       return;
     }
     
     for (int i = 0; i < configs.length; i++) {
       final config = configs[i];
       await _logger.logInfo('Updating widget ${i + 1}/${configs.length}: ${config.name} (ID: ${config.id})');
       
       if (config.id != null) {
         try {
           await _prepareWidgetData(config.id!);
           await _logger.logInfo('Widget ${i + 1}/${configs.length} data prepared successfully');
         } catch (e) {
           await _logger.logError('Failed to prepare data for widget ${i + 1}/${configs.length}: ${config.name}', e);
         }
       } else {
         await _logger.logWarning('Widget ${i + 1}/${configs.length} has no ID, skipping: ${config.name}');
       }
     }
     
     await _logger.logInfo('Triggering native update for all widgets');
     await _updateWidgetDisplay();
     await _logger.logInfo('Native update triggered for all widgets');
     
     await _logger.logInfo('=== All Widgets Update Complete: ${configs.length} widgets processed ===');
   } catch (e, stackTrace) {
     await _logger.logError('=== All Widgets Update Failed ===', e, stackTrace);
     rethrow;
   }
 }

 Future<void> deleteWidget(int widgetId) async {
   try {
     await _logger.logInfo('=== Starting Widget Deletion for ID: $widgetId ===');
     
     await _logger.logInfo('Deleting widget config from database');
     await _widgetConfigRepository.deleteWidgetConfig(widgetId);
     await _logger.logInfo('Widget config deleted from database');
     
     await _logger.logInfo('Clearing widget data from home widget plugin');
     await HomeWidget.saveWidgetData<String>(WIDGET_DATA_KEY, null);
     await HomeWidget.saveWidgetData<String>(WIDGET_CONFIG_KEY, null);
     await _logger.logInfo('Widget data cleared from plugin');
     
     await _logger.logInfo('=== Widget Deletion Complete for ID: $widgetId ===');
   } catch (e, stackTrace) {
     await _logger.logError('=== Widget Deletion Failed for ID: $widgetId ===', e, stackTrace);
     rethrow;
   }
 }

 Future<List<task_model.Task>> _getTasksForWidget(WidgetConfig config) async {
   try {
     await _logger.logInfo('--- Getting Tasks for Widget: ${config.name} ---');
     List<task_model.Task> tasks;
     
     if (config.categoryFilter != null) {
       await _logger.logInfo('Applying category filter: ${config.categoryFilter}');
       final categories = await _categoryRepository.getAllCategories();
       final category = categories.firstWhere(
         (cat) => cat.name == config.categoryFilter,
         orElse: () => category_model.Category(id: -1, name: '', color: const Color(0xFF000000)),
       );
       
       if (category.id != null && category.id! > 0) {
         await _logger.logInfo('Found category for filter: ${category.name} (ID: ${category.id})');
         tasks = await _taskRepository.getTasksByCategory(category.id!);
         await _logger.logInfo('Retrieved ${tasks.length} tasks for category: ${category.name}');
       } else {
         await _logger.logWarning('Category not found for filter: ${config.categoryFilter}, using all tasks');
         tasks = await _taskRepository.getAllTasks();
         await _logger.logInfo('Retrieved ${tasks.length} tasks (all categories)');
       }
     } else {
       await _logger.logInfo('No category filter applied, getting all tasks');
       tasks = await _taskRepository.getAllTasks();
       await _logger.logInfo('Retrieved ${tasks.length} tasks (all categories)');
     }

     final initialTaskCount = tasks.length;
     
     if (!config.showCompleted) {
       await _logger.logInfo('Filtering out completed tasks');
       tasks = tasks.where((task) => !task.isCompleted).toList();
       await _logger.logInfo('After completion filter: ${tasks.length} tasks (removed ${initialTaskCount - tasks.length} completed)');
     }

     await _logger.logInfo('Sorting tasks by completion, priority, and due date');
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
         return -1; // Tasks with due dates come first
       } else if (b.dueDate != null) {
         return 1;
       }
       
       // Finally sort by ID if everything else is equal
       return (a.id ?? 0).compareTo(b.id ?? 0);
     });
     await _logger.logInfo('Tasks sorted successfully');

     if (tasks.length > config.maxTasks) {
       await _logger.logInfo('Limiting tasks to ${config.maxTasks} (was ${tasks.length})');
       tasks = tasks.take(config.maxTasks).toList();
       await _logger.logInfo('Tasks limited to ${tasks.length}');
     }

     await _logger.logInfo('--- Final task count for widget: ${tasks.length} ---');
     return tasks;
   } catch (e, stackTrace) {
     await _logger.logError('--- Error getting tasks for widget ---', e, stackTrace);
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
     await _logger.logInfo('Processing ${tasks.length} tasks and ${categories.length} categories');
     
     final tasksData = <Map<String, dynamic>>[];
     
     for (int i = 0; i < tasks.length; i++) {
       final task = tasks[i];
       await _logger.logInfo('Processing task ${i + 1}/${tasks.length}: ${task.title} (ID: ${task.id})');
       
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
         await _logger.logInfo('Task category: ${category.name} (ID: ${category.id})');
       } else {
         await _logger.logInfo('Task has no category assigned');
       }

       // Format due date for display
       String? formattedDueDate;
       if (task.dueDate != null) {
         try {
           final dateFormat = intl.DateFormat('MMM d, yyyy');
           final timeFormat = intl.DateFormat('h:mm a');
           formattedDueDate = '${dateFormat.format(task.dueDate!)} · ${timeFormat.format(task.dueDate!)}';
         } catch (e) {
           await _logger.logWarning('Error formatting due date for task ${task.id}: $e');
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
         // Add completion timestamp for sorting
         'completedAt': task.completedAt?.millisecondsSinceEpoch,
       };
       
       tasksData.add(taskData);
     }

     final widgetData = {
       'config': config.toMap(),
       'tasks': tasksData,
       'updatedAt': DateTime.now().millisecondsSinceEpoch,
       'taskCount': tasksData.length,
       // Add summary statistics
       'completedCount': tasksData.where((task) => task['isCompleted'] == true).length,
       'overdueCount': tasksData.where((task) {
         final dueDate = task['dueDate'];
         return dueDate != null && 
                dueDate < DateTime.now().millisecondsSinceEpoch && 
                task['isCompleted'] != true;
       }).length,
     };

     await _logger.logInfo('Widget data structure complete: ${tasksData.length} tasks processed');
     await _logger.logInfo('Summary: ${widgetData['completedCount']} completed, ${widgetData['overdueCount']} overdue');
     await _logger.logInfo('--- Widget Data Structure Built Successfully ---');
     
     return widgetData;
   } catch (e, stackTrace) {
     await _logger.logError('--- Error building widget data structure ---', e, stackTrace);
     rethrow;
   }
 }

 Future<List<WidgetConfig>> getAllWidgetConfigs() async {
   try {
     await _logger.logInfo('Getting all widget configurations from database');
     final configs = await _widgetConfigRepository.getAllWidgetConfigs();
     await _logger.logInfo('Retrieved ${configs.length} widget configurations');
     return configs;
   } catch (e, stackTrace) {
     await _logger.logError('Error getting widget configurations', e, stackTrace);
     rethrow;
   }
 }

 Future<void> handleWidgetAction(String action, Map<dynamic, dynamic> data) async {
   try {
     await _logger.logInfo('=== Handling Widget Action: $action ===');
     await _logger.logInfo('Action data: $data');
     
     switch (action) {
       case 'background_sync':
         await _logger.logInfo('Background sync requested - forcing widget update');
         await forceWidgetUpdate();
         break;
         
       case 'add_task':
         final widgetId = data['widgetId'] as int?;
         await _logger.logInfo('Add task action triggered from widget: $widgetId');
         // The app will stay open for task creation
         break;
         
       case 'widget_settings':
         final widgetId = data['widgetId'] as int?;
         await _logger.logInfo('Widget settings action triggered for widget: $widgetId');
         // The app will stay open for settings
         break;
         
       case 'background_toggle_task':
         final taskId = data['taskId'] as int?;
         await _logger.logInfo('Background task toggle requested for TaskID=$taskId');
         
         if (taskId != null) {
           await _toggleTaskCompletion(taskId);
           // Force widget update after toggle
           await forceWidgetUpdate();
         }
         break;
     }
     
     await _logger.logInfo('=== Widget Action Handled Successfully: $action ===');
   } catch (e, stackTrace) {
     await _logger.logError('=== Widget Action Failed: $action ===', e, stackTrace);
   }
 }

 Future<void> _toggleTaskCompletion(int taskId) async {
   try {
     await _logger.logInfo('--- Toggling Task Completion: TaskID=$taskId ---');
     
     final task = await _taskRepository.getTask(taskId);
     if (task != null) {
       final newCompletionState = !task.isCompleted;
       await _logger.logInfo('Task found: ${task.title}, Current state: ${task.isCompleted}, New state: $newCompletionState');
       
       await _taskRepository.toggleTaskCompletion(taskId, newCompletionState);
       await _logger.logInfo('Task completion toggled successfully from widget: TaskID=$taskId, NewState=$newCompletionState');
     } else {
       await _logger.logWarning('Task not found for completion toggle: TaskID=$taskId');
     }
     
     await _logger.logInfo('--- Task Completion Toggle Complete: TaskID=$taskId ---');
   } catch (e, stackTrace) {
     await _logger.logError('--- Error toggling task completion from widget: TaskID=$taskId ---', e, stackTrace);
     rethrow;
   }
 }

 Future<void> forceWidgetUpdate() async {
   try {
     await _logger.logInfo('=== Forcing Widget Update ===');
     
     // Get the first available widget config or use default ID 1
     final configs = await _widgetConfigRepository.getAllWidgetConfigs();
     if (configs.isNotEmpty && configs.first.id != null) {
       await _prepareWidgetData(configs.first.id!);
     } else {
       // Fallback: create and update a default widget
       await _logger.logInfo('No widget configs found, creating default widget data');
       await _initializeDefaultWidgetData();
     }
     
     await _logger.logInfo('=== Force Widget Update Complete ===');
   } catch (e, stackTrace) {
     await _logger.logError('=== Force Widget Update Failed ===', e, stackTrace);
   }
 }
}