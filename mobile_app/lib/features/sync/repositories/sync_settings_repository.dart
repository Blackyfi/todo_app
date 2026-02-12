import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;

/// Repository for sync settings CRUD operations.
class SyncSettingsRepository {
  static final SyncSettingsRepository _instance =
      SyncSettingsRepository._internal();
  factory SyncSettingsRepository() => _instance;
  SyncSettingsRepository._internal();

  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  /// Get the current sync settings (single row).
  Future<settings_model.SyncSettings> getSettings() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('syncSettings', limit: 1);

      if (maps.isNotEmpty) {
        await _logger.logInfo('Sync settings loaded');
        return settings_model.SyncSettings.fromMap(maps.first);
      }

      await _logger.logInfo('No sync settings found, returning defaults');
      return settings_model.SyncSettings();
    } catch (e, stackTrace) {
      await _logger.logError('Error loading sync settings', e, stackTrace);
      rethrow;
    }
  }

  /// Insert or update sync settings.
  Future<int> saveSettings(settings_model.SyncSettings settings) async {
    try {
      final db = await _databaseHelper.database;
      final map = settings.toMap();
      map.remove('id');

      if (settings.id != null) {
        final rows = await db.update(
          'syncSettings',
          map,
          where: 'id = ?',
          whereArgs: [settings.id],
        );
        await _logger.logInfo('Sync settings updated: ID=${settings.id}');
        return rows;
      }

      // Check if a row already exists
      final existing = await db.query('syncSettings', limit: 1);
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        final rows = await db.update(
          'syncSettings',
          map,
          where: 'id = ?',
          whereArgs: [existingId],
        );
        await _logger.logInfo('Sync settings updated: ID=$existingId');
        return rows;
      }

      final id = await db.insert('syncSettings', map);
      await _logger.logInfo('Sync settings created: ID=$id');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error saving sync settings', e, stackTrace);
      rethrow;
    }
  }

  /// Update only the last sync timestamp.
  Future<void> updateLastSyncTimestamp(int timestamp) async {
    try {
      final db = await _databaseHelper.database;
      final existing = await db.query('syncSettings', limit: 1);

      if (existing.isNotEmpty) {
        await db.update(
          'syncSettings',
          {'lastSyncTimestamp': timestamp},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
      await _logger.logInfo('Last sync timestamp updated: $timestamp');
    } catch (e, stackTrace) {
      await _logger.logError(
        'Error updating last sync timestamp',
        e,
        stackTrace,
      );
    }
  }

  /// Clear all sync settings (used for logout).
  Future<void> clearSettings() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('syncSettings');
      await _logger.logInfo('Sync settings cleared');
    } catch (e, stackTrace) {
      await _logger.logError('Error clearing sync settings', e, stackTrace);
      rethrow;
    }
  }
}
