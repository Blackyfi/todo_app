import 'package:todo_app/core/database/database_helper.dart' as db_helper;

/// Builds JSON payloads for uploading local data to the sync server.
class SyncUploadBuilder {
  final db_helper.DatabaseHelper _dbHelper = db_helper.DatabaseHelper();

  /// Get categories changed since [sinceMs] (milliseconds), or all.
  Future<List<Map<String, dynamic>>> getCategories(int? sinceMs) async {
    final db = await _dbHelper.database;
    final rows = sinceMs != null
        ? await db.query(
            'categories',
            where: 'updatedAt > ?',
            whereArgs: [sinceMs],
          )
        : await db.query('categories');

    return rows
        .map((r) => {
              'client_id': r['id'],
              'name': r['name'],
              'color': r['color'],
              'updated_at': _msToSec(r['updatedAt'] as int?),
              'deleted': 0,
            })
        .toList();
  }

  /// Get tasks changed since [sinceMs] (milliseconds), or all.
  Future<List<Map<String, dynamic>>> getTasks(int? sinceMs) async {
    final db = await _dbHelper.database;
    final rows = sinceMs != null
        ? await db.query(
            'tasks',
            where: 'updatedAt > ?',
            whereArgs: [sinceMs],
          )
        : await db.query('tasks');

    return rows
        .map((r) => {
              'client_id': r['id'],
              'title': r['title'],
              'description': r['description'] ?? '',
              'due_date': _msToSec(r['dueDate'] as int?),
              'is_completed': r['isCompleted'],
              'completed_at': _msToSec(r['completedAt'] as int?),
              'category_id': r['categoryId'],
              'priority': r['priority'],
              'updated_at': _msToSec(r['updatedAt'] as int?),
              'deleted': 0,
            })
        .toList();
  }

  int? _msToSec(int? ms) => ms != null ? ms ~/ 1000 : null;
}
