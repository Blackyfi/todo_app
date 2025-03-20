import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/core/logger/logger_service.dart';

class TaskRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  Future<int> insertTask(task_model.Task task) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('tasks', task.toMap());
      await _logger.logInfo('Task inserted: ID=$id, Title=${task.title}');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error inserting task', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateTask(task_model.Task task) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      await _logger.logInfo('Task updated: ID=${task.id}, Title=${task.title}, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error updating task', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _logger.logInfo('Task deleted: ID=$id, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting task', e, stackTrace);
      rethrow;
    }
  }

  Future<task_model.Task?> getTask(int id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        await _logger.logInfo('Task retrieved: ID=$id');
        return task_model.Task.fromMap(maps.first);
      }
      await _logger.logWarning('Task not found: ID=$id');
      return null;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting task', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> getAllTasks() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('tasks');
      
      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved all tasks: Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting all tasks', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> getTasksByCategory(int categoryId) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved tasks by category: CategoryID=$categoryId, Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks by category', e, stackTrace);
      rethrow;
    }
  }
  
  // New method to get tasks without a category
  Future<List<task_model.Task>> getTasksWithoutCategory() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'categoryId IS NULL',
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved tasks without category: Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks without category', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> getTasksByPriority(task_model.Priority priority) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'priority = ?',
        whereArgs: [priority.index],
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved tasks by priority: Priority=${priority.name}, Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks by priority', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> getTasksByCompletionStatus(bool isCompleted) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'tasks',
        where: 'isCompleted = ?',
        whereArgs: [isCompleted ? 1 : 0],
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved tasks by completion status: Completed=$isCompleted, Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks by completion status', e, stackTrace);
      rethrow;
    }
  }

  Future<List<task_model.Task>> getTasksByDueDate(DateTime date) async {
    try {
      final db = await _databaseHelper.database;
      
      final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;
      
      final maps = await db.query(
        'tasks',
        where: 'dueDate >= ? AND dueDate <= ?',
        whereArgs: [startOfDay, endOfDay],
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved tasks by due date: Date=${date.toIso8601String()}, Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting tasks by due date', e, stackTrace);
      rethrow;
    }
  }
  
  Future<List<task_model.Task>> getUpcomingTasks() async {
    try {
      final db = await _databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final maps = await db.query(
        'tasks',
        where: 'dueDate >= ? AND isCompleted = 0',
        whereArgs: [now],
        orderBy: 'dueDate ASC',
      );

      final tasks = List.generate(maps.length, (i) {
        return task_model.Task.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved upcoming tasks: Count=${tasks.length}');
      return tasks;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting upcoming tasks', e, stackTrace);
      rethrow;
    }
  }
}