import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;

class TaskRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();

  Future<int> insertTask(task_model.Task task) async {
    final db = await _databaseHelper.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(task_model.Task task) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<task_model.Task?> getTask(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return task_model.Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<task_model.Task>> getAllTasks() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }

  Future<List<task_model.Task>> getTasksByCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }

  Future<List<task_model.Task>> getTasksByPriority(task_model.Priority priority) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'priority = ?',
      whereArgs: [priority.index],
    );

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }

  Future<List<task_model.Task>> getTasksByCompletionStatus(bool isCompleted) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [isCompleted ? 1 : 0],
    );

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }

  Future<List<task_model.Task>> getTasksByDueDate(DateTime date) async {
    final db = await _databaseHelper.database;
    
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
    
    final maps = await db.query(
      'tasks',
      where: 'dueDate >= ? AND dueDate <= ?',
      whereArgs: [startOfDay, endOfDay],
    );

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }
  
  Future<List<task_model.Task>> getUpcomingTasks() async {
    final db = await _databaseHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final maps = await db.query(
      'tasks',
      where: 'dueDate >= ? AND isCompleted = 0',
      whereArgs: [now],
      orderBy: 'dueDate ASC',
    );

    return List.generate(maps.length, (i) {
      return task_model.Task.fromMap(maps[i]);
    });
  }
}
