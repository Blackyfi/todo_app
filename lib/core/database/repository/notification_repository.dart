import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/logger/logger_service.dart';

class NotificationRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  Future<int> insertNotificationSetting(notification_model.NotificationSetting setting) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('notificationSettings', setting.toMap());
      await _logger.logInfo('Notification setting inserted: ID=$id, TaskID=${setting.taskId}, TimeOption=${setting.timeOption.name}');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error inserting notification setting', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateNotificationSetting(notification_model.NotificationSetting setting) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'notificationSettings',
        setting.toMap(),
        where: 'id = ?',
        whereArgs: [setting.id],
      );
      await _logger.logInfo('Notification setting updated: ID=${setting.id}, TaskID=${setting.taskId}, TimeOption=${setting.timeOption.name}, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error updating notification setting', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteNotificationSetting(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'notificationSettings',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _logger.logInfo('Notification setting deleted: ID=$id, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting notification setting', e, stackTrace);
      rethrow;
    }
  }

  Future<List<notification_model.NotificationSetting>> getNotificationSettingsForTask(int taskId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'notificationSettings',
        where: 'taskId = ?',
        whereArgs: [taskId],
      );

      final settings = List.generate(maps.length, (i) {
        return notification_model.NotificationSetting.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved notification settings for task: TaskID=$taskId, Count=${settings.length}');
      return settings;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting notification settings for task', e, stackTrace);
      rethrow;
    }
  }

  Future<List<notification_model.NotificationSetting>> getAllNotificationSettings() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('notificationSettings');

      final settings = List.generate(maps.length, (i) {
        return notification_model.NotificationSetting.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved all notification settings: Count=${settings.length}');
      return settings;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting all notification settings', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteNotificationSettingsForTask(int taskId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'notificationSettings',
        where: 'taskId = ?',
        whereArgs: [taskId],
      );
      
      await _logger.logInfo('Deleted notification settings for task: TaskID=$taskId, Count=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting notification settings for task', e, stackTrace);
      rethrow;
    }
  }
}