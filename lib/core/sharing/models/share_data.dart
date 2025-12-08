import 'dart:convert';
import '../../../features/tasks/models/task.dart';
import '../../../features/shopping/models/shopping_list.dart';
import '../../../features/shopping/models/grocery_item.dart';

/// Represents the type of data being shared
enum ShareDataType {
  task,
  taskList,
  shoppingList,
  shoppingListWithItems,
  allTasks,
  allShoppingLists,
}

/// Container for shareable data with metadata
class ShareData {
  final ShareDataType type;
  final String appVersion;
  final DateTime createdAt;
  final bool isEncrypted;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? metadata;

  ShareData({
    required this.type,
    required this.appVersion,
    DateTime? createdAt,
    this.isEncrypted = false,
    required this.data,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  // ============================================================================
  // FACTORY CONSTRUCTORS FOR DIFFERENT SHARE TYPES
  // ============================================================================

  /// Create share data for a single task
  factory ShareData.fromTask(Task task, {String appVersion = '1.0.0'}) {
    return ShareData(
      type: ShareDataType.task,
      appVersion: appVersion,
      data: {'task': task.toMap()},
    );
  }

  /// Create share data for multiple tasks
  factory ShareData.fromTaskList(List<Task> tasks, {String appVersion = '1.0.0'}) {
    return ShareData(
      type: ShareDataType.taskList,
      appVersion: appVersion,
      data: {
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'count': tasks.length,
      },
    );
  }

  /// Create share data for all tasks
  factory ShareData.fromAllTasks(List<Task> tasks, {String appVersion = '1.0.0'}) {
    return ShareData(
      type: ShareDataType.allTasks,
      appVersion: appVersion,
      data: {
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'count': tasks.length,
      },
      metadata: {
        'exportedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create share data for a shopping list (without items)
  factory ShareData.fromShoppingList(
    ShoppingList list, {
    String appVersion = '1.0.0',
  }) {
    return ShareData(
      type: ShareDataType.shoppingList,
      appVersion: appVersion,
      data: {'shoppingList': list.toMap()},
    );
  }

  /// Create share data for a shopping list with all its items
  factory ShareData.fromShoppingListWithItems(
    ShoppingList list,
    List<GroceryItem> items, {
    String appVersion = '1.0.0',
  }) {
    return ShareData(
      type: ShareDataType.shoppingListWithItems,
      appVersion: appVersion,
      data: {
        'shoppingList': list.toMap(),
        'items': items.map((i) => i.toMap()).toList(),
        'itemCount': items.length,
      },
    );
  }

  /// Create share data for all shopping lists with their items
  factory ShareData.fromAllShoppingLists(
    Map<ShoppingList, List<GroceryItem>> listsWithItems, {
    String appVersion = '1.0.0',
  }) {
    final lists = listsWithItems.keys.toList();
    final allData = lists.map((list) {
      final items = listsWithItems[list] ?? [];
      return {
        'list': list.toMap(),
        'items': items.map((i) => i.toMap()).toList(),
      };
    }).toList();

    return ShareData(
      type: ShareDataType.allShoppingLists,
      appVersion: appVersion,
      data: {
        'shoppingLists': allData,
        'count': lists.length,
      },
      metadata: {
        'exportedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // ============================================================================
  // SERIALIZATION
  // ============================================================================

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toMap());
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'appVersion': appVersion,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isEncrypted': isEncrypted,
      'data': data,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create from JSON string
  factory ShareData.fromJsonString(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ShareData.fromMap(map);
  }

  /// Create from Map
  factory ShareData.fromMap(Map<String, dynamic> map) {
    return ShareData(
      type: ShareDataType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ShareDataType.task,
      ),
      appVersion: map['appVersion'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      data: Map<String, dynamic>.from(map['data'] as Map),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  // ============================================================================
  // EXTRACTION METHODS
  // ============================================================================

  /// Extract single task from share data
  Task? extractTask() {
    if (type != ShareDataType.task) return null;
    final taskMap = data['task'] as Map<String, dynamic>?;
    return taskMap != null ? Task.fromMap(taskMap) : null;
  }

  /// Extract task list from share data
  List<Task> extractTaskList() {
    if (type != ShareDataType.taskList && type != ShareDataType.allTasks) {
      return [];
    }
    final tasksList = data['tasks'] as List<dynamic>?;
    if (tasksList == null) return [];

    return tasksList
        .map((t) => Task.fromMap(Map<String, dynamic>.from(t as Map)))
        .toList();
  }

  /// Extract shopping list from share data
  ShoppingList? extractShoppingList() {
    if (type != ShareDataType.shoppingList &&
        type != ShareDataType.shoppingListWithItems) {
      return null;
    }
    final listMap = data['shoppingList'] as Map<String, dynamic>?;
    return listMap != null ? ShoppingList.fromMap(listMap) : null;
  }

  /// Extract grocery items from share data
  List<GroceryItem> extractGroceryItems() {
    if (type != ShareDataType.shoppingListWithItems) return [];
    final itemsList = data['items'] as List<dynamic>?;
    if (itemsList == null) return [];

    return itemsList
        .map((i) => GroceryItem.fromMap(Map<String, dynamic>.from(i as Map)))
        .toList();
  }

  /// Extract all shopping lists with items
  Map<ShoppingList, List<GroceryItem>> extractAllShoppingLists() {
    if (type != ShareDataType.allShoppingLists) return {};

    final listsData = data['shoppingLists'] as List<dynamic>?;
    if (listsData == null) return {};

    final result = <ShoppingList, List<GroceryItem>>{};

    for (final listData in listsData) {
      final map = Map<String, dynamic>.from(listData as Map);
      final list = ShoppingList.fromMap(map['list'] as Map<String, dynamic>);
      final items = (map['items'] as List<dynamic>)
          .map((i) => GroceryItem.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList();

      result[list] = items;
    }

    return result;
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  /// Create a copy with encryption flag set
  ShareData copyWithEncryption(bool encrypted) {
    return ShareData(
      type: type,
      appVersion: appVersion,
      createdAt: createdAt,
      isEncrypted: encrypted,
      data: data,
      metadata: metadata,
    );
  }

  /// Get human-readable description
  String get description {
    switch (type) {
      case ShareDataType.task:
        return 'Single Task';
      case ShareDataType.taskList:
        final count = data['count'] ?? 0;
        return '$count Tasks';
      case ShareDataType.allTasks:
        final count = data['count'] ?? 0;
        return 'All Tasks ($count)';
      case ShareDataType.shoppingList:
        return 'Shopping List';
      case ShareDataType.shoppingListWithItems:
        final itemCount = data['itemCount'] ?? 0;
        return 'Shopping List ($itemCount items)';
      case ShareDataType.allShoppingLists:
        final count = data['count'] ?? 0;
        return 'All Shopping Lists ($count)';
    }
  }
}
