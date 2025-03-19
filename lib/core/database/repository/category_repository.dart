import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/categories/models/category.dart' as category_model;

class CategoryRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();

  Future<int> insertCategory(category_model.Category category) async {
    final db = await _databaseHelper.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(category_model.Category category) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<category_model.Category?> getCategory(int id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return category_model.Category.fromMap(maps.first);
    }
    return null;
  }

  Future<List<category_model.Category>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final maps = await db.query('categories');

    return List.generate(maps.length, (i) {
      return category_model.Category.fromMap(maps[i]);
    });
  }
}
