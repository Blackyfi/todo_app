class ShoppingList {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final int totalItems;
  final int purchasedItems;

  ShoppingList({
    this.id,
    required this.name,
    DateTime? createdAt,
    this.lastModifiedAt,
    this.totalItems = 0,
    this.purchasedItems = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModifiedAt': lastModifiedAt?.millisecondsSinceEpoch,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastModifiedAt: map['lastModifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModifiedAt'] as int)
          : null,
      totalItems: map['totalItems'] as int? ?? 0,
      purchasedItems: map['purchasedItems'] as int? ?? 0,
    );
  }

  ShoppingList copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    int? totalItems,
    int? purchasedItems,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      totalItems: totalItems ?? this.totalItems,
      purchasedItems: purchasedItems ?? this.purchasedItems,
    );
  }

  double get progress {
    if (totalItems == 0) return 0.0;
    return purchasedItems / totalItems;
  }

  bool get isCompleted => totalItems > 0 && purchasedItems == totalItems;
}
