import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/logger/logger_service.dart';

class CategoryRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  Future<int> insertCategory(category_model.Category category) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('categories', category.toMap());
      await _logger.logInfo('Category inserted: ID=$id, Name=${category.name}');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error inserting category', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateCategory(category_model.Category category) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      await _logger.logInfo('Category updated: ID=${category.id}, Name=${category.name}, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error updating category', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteCategory(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _logger.logInfo('Category deleted: ID=$id, Rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting category', e, stackTrace);
      rethrow;
    }
  }

  Future<category_model.Category?> getCategory(int id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        await _logger.logInfo('Category retrieved: ID=$id');
        return category_model.Category.fromMap(maps.first);
      }
      
      await _logger.logWarning('Category not found: ID=$id');
      return null;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting category', e, stackTrace);
      rethrow;
    }
  }

  Future<List<category_model.Category>> getAllCategories() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('categories');

      final categories = List.generate(maps.length, (i) {
        return category_model.Category.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved all categories: Count=${categories.length}');
      return categories;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting all categories', e, stackTrace);
      rethrow;
    }
  }
}