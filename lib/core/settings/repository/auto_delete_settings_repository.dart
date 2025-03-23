import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';
import 'package:todo_app/core/logger/logger_service.dart';

class AutoDeleteSettingsRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  Future<AutoDeleteSettings> getSettings() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('autoDeleteSettings');
      
      if (maps.isNotEmpty) {
        await _logger.logInfo('Auto-delete settings retrieved');
        return AutoDeleteSettings.fromMap(maps.first);
      }
      
      // If no settings exist, create default settings
      final defaultSettings = AutoDeleteSettings();
      final id = await insertSettings(defaultSettings);
      
      return defaultSettings.copyWith(id: id);
    } catch (e, stackTrace) {
      await _logger.logError('Error getting auto-delete settings', e, stackTrace);
      rethrow;
    }
  }

  Future<int> insertSettings(AutoDeleteSettings settings) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('autoDeleteSettings', settings.toMap());
      await _logger.logInfo('Auto-delete settings inserted: ID=$id');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error inserting auto-delete settings', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateSettings(AutoDeleteSettings settings) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'autoDeleteSettings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id],
      );
      await _logger.logInfo('Auto-delete settings updated: ID=${settings.id}, DeleteImmediately=${settings.deleteImmediately}, DeleteAfterDays=${settings.deleteAfterDays}');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error updating auto-delete settings', e, stackTrace);
      rethrow;
    }
  }
}