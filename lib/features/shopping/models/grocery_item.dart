class GroceryItem {
  final int? id;
  final int shoppingListId;
  final String name;
  final double quantity;
  final String unit; // 'pieces', 'kg', 'g', 'L', 'mL', etc.
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime? purchasedAt;
  final int displayOrder;

  GroceryItem({
    this.id,
    required this.shoppingListId,
    required this.name,
    this.quantity = 1.0,
    this.unit = 'pieces',
    this.isPurchased = false,
    DateTime? createdAt,
    this.purchasedAt,
    this.displayOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shoppingListId': shoppingListId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isPurchased': isPurchased ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'purchasedAt': purchasedAt?.millisecondsSinceEpoch,
      'displayOrder': displayOrder,
    };
  }

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id'] as int?,
      shoppingListId: map['shoppingListId'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as double,
      unit: map['unit'] as String,
      isPurchased: map['isPurchased'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      purchasedAt: map['purchasedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['purchasedAt'] as int)
          : null,
      displayOrder: map['displayOrder'] as int,
    );
  }

  GroceryItem copyWith({
    int? id,
    int? shoppingListId,
    String? name,
    double? quantity,
    String? unit,
    bool? isPurchased,
    DateTime? createdAt,
    DateTime? purchasedAt,
    int? displayOrder,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  String get quantityDisplay {
    if (quantity == quantity.toInt()) {
      return '${quantity.toInt()} $unit';
    }
    return '$quantity $unit';
  }
}
