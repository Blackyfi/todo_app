import 'package:sqflite/sqflite.dart';
import '../../../features/shopping/models/grocery_item.dart';
import '../../../features/shopping/models/shopping_list.dart';
import '../database_helper.dart';

class ShoppingRepository {
  static final ShoppingRepository _instance = ShoppingRepository._internal();
  factory ShoppingRepository() => _instance;
  ShoppingRepository._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Shopping List CRUD Operations

  Future<int> insertShoppingList(ShoppingList list) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      'shoppingLists',
      list.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateShoppingList(ShoppingList list) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'shoppingLists',
      list.copyWith(lastModifiedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<int> deleteShoppingList(int id) async {
    final db = await _databaseHelper.database;
    // Items will be deleted automatically due to CASCADE
    return await db.delete(
      'shoppingLists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ShoppingList?> getShoppingList(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shoppingLists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final list = ShoppingList.fromMap(maps.first);
    final stats = await getShoppingListStats(id);
    return list.copyWith(
      totalItems: stats['total'],
      purchasedItems: stats['purchased'],
    );
  }

  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'shoppingLists',
      orderBy: 'lastModifiedAt DESC, createdAt DESC',
    );

    final lists = <ShoppingList>[];
    for (var map in maps) {
      final list = ShoppingList.fromMap(map);
      final stats = await getShoppingListStats(list.id!);
      lists.add(list.copyWith(
        totalItems: stats['total'],
        purchasedItems: stats['purchased'],
      ));
    }
    return lists;
  }

  Future<Map<String, int>> getShoppingListStats(int listId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN isPurchased = 1 THEN 1 ELSE 0 END) as purchased
      FROM groceryItems
      WHERE shoppingListId = ?
    ''', [listId]);

    return {
      'total': result.first['total'] as int,
      'purchased': result.first['purchased'] as int? ?? 0,
    };
  }

  // Grocery Item CRUD Operations

  Future<int> insertGroceryItem(GroceryItem item) async {
    final db = await _databaseHelper.database;
    final id = await db.insert(
      'groceryItems',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update list's lastModifiedAt
    await _updateListModificationTime(item.shoppingListId);
    return id;
  }

  Future<int> updateGroceryItem(GroceryItem item) async {
    final db = await _databaseHelper.database;
    final result = await db.update(
      'groceryItems',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Update list's lastModifiedAt
    await _updateListModificationTime(item.shoppingListId);
    return result;
  }

  Future<int> deleteGroceryItem(int id) async {
    final db = await _databaseHelper.database;

    // Get the item first to know which list to update
    final item = await getGroceryItem(id);

    final result = await db.delete(
      'groceryItems',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (item != null) {
      await _updateListModificationTime(item.shoppingListId);
    }

    return result;
  }

  Future<GroceryItem?> getGroceryItem(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'groceryItems',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return GroceryItem.fromMap(maps.first);
  }

  Future<List<GroceryItem>> getGroceryItemsByList(int shoppingListId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'groceryItems',
      where: 'shoppingListId = ?',
      whereArgs: [shoppingListId],
      orderBy: 'isPurchased ASC, displayOrder ASC, createdAt ASC',
    );

    return List.generate(maps.length, (i) => GroceryItem.fromMap(maps[i]));
  }

  Future<List<GroceryItem>> getUnpurchasedItems(int shoppingListId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'groceryItems',
      where: 'shoppingListId = ? AND isPurchased = 0',
      whereArgs: [shoppingListId],
      orderBy: 'displayOrder ASC, createdAt ASC',
    );

    return List.generate(maps.length, (i) => GroceryItem.fromMap(maps[i]));
  }

  Future<List<GroceryItem>> getPurchasedItems(int shoppingListId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'groceryItems',
      where: 'shoppingListId = ? AND isPurchased = 1',
      whereArgs: [shoppingListId],
      orderBy: 'purchasedAt DESC',
    );

    return List.generate(maps.length, (i) => GroceryItem.fromMap(maps[i]));
  }

  Future<int> toggleItemPurchased(int itemId, bool isPurchased) async {
    final db = await _databaseHelper.database;

    final item = await getGroceryItem(itemId);
    if (item == null) return 0;

    final result = await db.update(
      'groceryItems',
      {
        'isPurchased': isPurchased ? 1 : 0,
        'purchasedAt': isPurchased ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );

    await _updateListModificationTime(item.shoppingListId);
    return result;
  }

  Future<void> _updateListModificationTime(int listId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'shoppingLists',
      {'lastModifiedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<int> clearPurchasedItems(int shoppingListId) async {
    final db = await _databaseHelper.database;
    final result = await db.delete(
      'groceryItems',
      where: 'shoppingListId = ? AND isPurchased = 1',
      whereArgs: [shoppingListId],
    );

    await _updateListModificationTime(shoppingListId);
    return result;
  }

  Future<int> resetAllItems(int shoppingListId) async {
    final db = await _databaseHelper.database;
    final result = await db.update(
      'groceryItems',
      {
        'isPurchased': 0,
        'purchasedAt': null,
      },
      where: 'shoppingListId = ?',
      whereArgs: [shoppingListId],
    );

    await _updateListModificationTime(shoppingListId);
    return result;
  }
}
