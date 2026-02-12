import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/features/sync/models/sync_queue_item.dart'
    as queue_model;
import 'package:todo_app/common/constants/app_constants.dart'
    as app_constants;

/// Repository for managing the offline sync queue.
class SyncQueueRepository {
  static final SyncQueueRepository _instance =
      SyncQueueRepository._internal();
  factory SyncQueueRepository() => _instance;
  SyncQueueRepository._internal();

  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  /// Add an operation to the sync queue.
  Future<int> enqueue(queue_model.SyncQueueItem item) async {
    try {
      final db = await _databaseHelper.database;
      final map = item.toMap();
      map.remove('id');
      final id = await db.insert('syncQueue', map);
      await _logger.logInfo(
        'Queued sync: ${item.operation} ${item.entityType} #${item.entityId}',
      );
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error enqueueing sync item', e, stackTrace);
      rethrow;
    }
  }

  /// Get all pending queue items, oldest first.
  Future<List<queue_model.SyncQueueItem>> getPending() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'syncQueue',
        where: 'retryCount < ?',
        whereArgs: [app_constants.AppConstants.maxSyncRetries],
        orderBy: 'timestamp ASC',
      );
      return maps.map(queue_model.SyncQueueItem.fromMap).toList();
    } catch (e, stackTrace) {
      await _logger.logError('Error getting pending queue', e, stackTrace);
      rethrow;
    }
  }

  /// Get the count of pending items.
  Future<int> getPendingCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM syncQueue WHERE retryCount < ?',
        [app_constants.AppConstants.maxSyncRetries],
      );
      return result.first['cnt'] as int? ?? 0;
    } catch (e, stackTrace) {
      await _logger.logError('Error counting queue items', e, stackTrace);
      return 0;
    }
  }

  /// Remove a successfully processed item from the queue.
  Future<void> remove(int id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('syncQueue', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      await _logger.logError('Error removing queue item', e, stackTrace);
    }
  }

  /// Increment retry count and store the error message.
  Future<void> markRetry(int id, String error) async {
    try {
      final db = await _databaseHelper.database;
      await db.rawUpdate(
        'UPDATE syncQueue SET retryCount = retryCount + 1, '
        'lastError = ? WHERE id = ?',
        [error, id],
      );
      await _logger.logWarning('Sync queue item #$id retry: $error');
    } catch (e, stackTrace) {
      await _logger.logError('Error marking retry', e, stackTrace);
    }
  }

  /// Clear the entire queue.
  Future<void> clearAll() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('syncQueue');
      await _logger.logInfo('Sync queue cleared');
    } catch (e, stackTrace) {
      await _logger.logError('Error clearing sync queue', e, stackTrace);
      rethrow;
    }
  }
}
