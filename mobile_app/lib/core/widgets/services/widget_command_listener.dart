import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';

class WidgetCommandListener {
  static final WidgetCommandListener _instance = WidgetCommandListener._internal();
  factory WidgetCommandListener() => _instance;
  WidgetCommandListener._internal();

  final LoggerService _logger = LoggerService();
  final WidgetService _widgetService = WidgetService();
  final TaskRepository _taskRepository = TaskRepository();
  
  Timer? _pollTimer;
  int _lastTimestamp = 0;
  bool _isListening = false;

  Future<void> startListening() async {
    if (_isListening) {
      await _logger.logInfo('Widget command listener already running');
      return;
    }

    try {
      await _logger.logInfo('Starting widget command listener');
      _isListening = true;
      
      // Get initial timestamp
      final prefs = await SharedPreferences.getInstance();
      _lastTimestamp = prefs.getInt('widget_commands.timestamp') ?? 0;
      
      // Poll for changes every 2 seconds
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkForCommands());
      
      await _logger.logInfo('Widget command listener started');
    } catch (e, stackTrace) {
      await _logger.logError('Error starting widget command listener', e, stackTrace);
    }
  }

  Future<void> stopListening() async {
    try {
      await _logger.logInfo('Stopping widget command listener');
      _isListening = false;
      _pollTimer?.cancel();
      _pollTimer = null;
      await _logger.logInfo('Widget command listener stopped');
    } catch (e, stackTrace) {
      await _logger.logError('Error stopping widget command listener', e, stackTrace);
    }
  }

  Future<void> _checkForCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('widget_commands.timestamp') ?? 0;
      
      // Check if there's a new command
      if (timestamp > _lastTimestamp) {
        _lastTimestamp = timestamp;
        
        final command = prefs.getString('widget_commands.command');
        await _logger.logInfo('Processing widget command: $command');
        
        switch (command) {
          case 'refresh_widget':
            await _handleRefreshWidget();
            break;
          case 'toggle_task':
            final taskId = prefs.getInt('widget_commands.task_id') ?? -1;
            final widgetId = prefs.getInt('widget_commands.widget_id') ?? 1;
            await _handleToggleTask(taskId, widgetId);
            break;
        }
        
        // Clear the command after processing
        await prefs.remove('widget_commands.command');
        await prefs.remove('widget_commands.task_id');
        await prefs.remove('widget_commands.widget_id');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error checking for widget commands', e, stackTrace);
    }
  }

  Future<void> _handleRefreshWidget() async {
    try {
      await _logger.logInfo('Handling widget refresh command');
      await _widgetService.updateAllWidgets();
      await _logger.logInfo('Widget refresh completed');
    } catch (e, stackTrace) {
      await _logger.logError('Error handling widget refresh', e, stackTrace);
    }
  }

  Future<void> _handleToggleTask(int taskId, int widgetId) async {
    try {
      await _logger.logInfo('Handling task toggle command: TaskID=$taskId, WidgetID=$widgetId');
      
      if (taskId > 0) {
        final task = await _taskRepository.getTask(taskId);
        if (task != null) {
          await _taskRepository.toggleTaskCompletion(taskId, !task.isCompleted);
          await _logger.logInfo('Task toggled successfully: TaskID=$taskId, NewState=${!task.isCompleted}');
          
          // Update widgets after toggle
          await _widgetService.updateAllWidgets();
          await _logger.logInfo('Widgets updated after task toggle');
        } else {
          await _logger.logWarning('Task not found for toggle: TaskID=$taskId');
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error handling task toggle', e, stackTrace);
    }
  }
}