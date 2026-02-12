import 'package:flutter/material.dart' as mat;

class Category {
  final int? id;
  final String name;
  final mat.Color color;

  Category({
    this.id,
    required this.name,
    required this.color,
  });

  Category copyWith({
    int? id,
    String? name,
    mat.Color? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: mat.Color(map['color']),
    );
  }

  static List<Category> defaultCategories = [
    Category(id: 1, name: 'Work', color: mat.Colors.blue),
    Category(id: 2, name: 'Personal', color: mat.Colors.green),
    Category(id: 3, name: 'Shopping', color: mat.Colors.orange),
    Category(id: 4, name: 'Health', color: mat.Colors.red),
    Category(id: 5, name: 'Education', color: mat.Colors.purple),
  ];
}
