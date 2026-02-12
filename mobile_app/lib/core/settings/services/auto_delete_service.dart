import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/logger/logger_service.dart';

class AutoDeleteService {
  final task_repository.TaskRepository _taskRepository = task_repository.TaskRepository();
  final AutoDeleteSettingsRepository _settingsRepository = AutoDeleteSettingsRepository();
  final LoggerService _logger = LoggerService();

  // Checks and deletes completed tasks according to settings
  Future<void> processCompletedTasks() async {
    try {
      await _logger.logInfo('Processing completed tasks for auto-deletion');
      
      final settings = await _settingsRepository.getSettings();
      
      if (settings.deleteImmediately) {
        // Delete immediately option is enabled - delete all completed tasks
        final completedTasks = await _taskRepository.getTasksByCompletionStatus(true);
        
        for (final task in completedTasks) {
          if (task.id != null) {
            await _taskRepository.deleteTask(task.id!);
          }
        }
        
        await _logger.logInfo('Deleted ${completedTasks.length} completed tasks immediately');
      } else {
        // Delete after specified days
        final duration = Duration(days: settings.deleteAfterDays);
        final deletedCount = await _taskRepository.deleteCompletedTasksOlderThan(duration);
        
        await _logger.logInfo('Deleted $deletedCount completed tasks older than ${settings.deleteAfterDays} days');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error processing completed tasks for auto-deletion', e, stackTrace);
    }
  }
}