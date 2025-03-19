import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;

class NotificationRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();

  Future<int> insertNotificationSetting(notification_model.NotificationSetting setting) async {
    final db = await _databaseHelper.database;
    return await db.insert('notificationSettings', setting.toMap());
  }

  Future<int> updateNotificationSetting(notification_model.NotificationSetting setting) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'notificationSettings',
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }

  Future<int> deleteNotificationSetting(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notificationSettings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<notification_model.NotificationSetting>> getNotificationSettingsForTask(int taskId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'notificationSettings',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    return List.generate(maps.length, (i) {
      return notification_model.NotificationSetting.fromMap(maps[i]);
    });
  }

  Future<List<notification_model.NotificationSetting>> getAllNotificationSettings() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('notificationSettings');

    return List.generate(maps.length, (i) {
      return notification_model.NotificationSetting.fromMap(maps[i]);
    });
  }

  Future<int> deleteNotificationSettingsForTask(int taskId) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'notificationSettings',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }
}
