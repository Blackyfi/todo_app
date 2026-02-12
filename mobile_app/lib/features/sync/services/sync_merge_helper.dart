import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/sync/utils/sync_conflict_resolver.dart'
    as resolver;

/// Handles merging of downloaded server entities into the local database.
class SyncMergeHelper {
  final db_helper.DatabaseHelper _dbHelper = db_helper.DatabaseHelper();

  /// Merge server categories into local database.
  Future<resolver.MergeResult> mergeCategories(
    List<Map<String, dynamic>> serverCats,
  ) async {
    final db = await _dbHelper.database;

    return resolver.SyncConflictResolver.mergeEntities(
      serverEntities: serverCats,
      entityType: 'category',
      findLocal: (clientId) async {
        final rows = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [clientId],
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      insertLocal: (entity) async {
        await db.insert('categories', {
          'name': entity['name'],
          'color': entity['color'],
          'updatedAt': _secToMs(entity['updated_at'] as int?),
        });
      },
      updateLocal: (entity) async {
        final clientId = entity['client_id'] as int;
        await db.update(
          'categories',
          {
            'name': entity['name'],
            'color': entity['color'],
            'updatedAt': _secToMs(entity['updated_at'] as int?),
          },
          where: 'id = ?',
          whereArgs: [clientId],
        );
      },
      deleteLocal: (clientId) async {
        await db.delete(
          'categories',
          where: 'id = ?',
          whereArgs: [clientId],
        );
      },
    );
  }

  /// Merge server tasks into local database.
  Future<resolver.MergeResult> mergeTasks(
    List<Map<String, dynamic>> serverTasks,
  ) async {
    final db = await _dbHelper.database;

    return resolver.SyncConflictResolver.mergeEntities(
      serverEntities: serverTasks,
      entityType: 'task',
      findLocal: (clientId) async {
        final rows = await db.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [clientId],
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      insertLocal: (entity) async {
        await db.insert('tasks', {
          'title': entity['title'],
          'description': entity['description'] ?? '',
          'dueDate': _secToMs(entity['due_date'] as int?),
          'isCompleted': entity['is_completed'] ?? 0,
          'completedAt': _secToMs(entity['completed_at'] as int?),
          'categoryId': entity['category_id'],
          'priority': entity['priority'] ?? 1,
          'updatedAt': _secToMs(entity['updated_at'] as int?),
        });
      },
      updateLocal: (entity) async {
        final clientId = entity['client_id'] as int;
        await db.update(
          'tasks',
          {
            'title': entity['title'],
            'description': entity['description'] ?? '',
            'dueDate': _secToMs(entity['due_date'] as int?),
            'isCompleted': entity['is_completed'] ?? 0,
            'completedAt': _secToMs(entity['completed_at'] as int?),
            'categoryId': entity['category_id'],
            'priority': entity['priority'] ?? 1,
            'updatedAt': _secToMs(entity['updated_at'] as int?),
          },
          where: 'id = ?',
          whereArgs: [clientId],
        );
      },
      deleteLocal: (clientId) async {
        await db.delete('tasks', where: 'id = ?', whereArgs: [clientId]);
      },
    );
  }

  int? _secToMs(int? sec) => sec != null ? sec * 1000 : null;
}
