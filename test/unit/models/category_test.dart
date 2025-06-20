import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/features/categories/models/category.dart';

void main() {
  group('Category Model Tests', () {
    late Category testCategory;

    setUp(() {
      testCategory = Category(
        id: 1,
        name: 'Work',
        color: Colors.blue,
      );
    });

    test('should create a category with all properties', () {
      expect(testCategory.id, equals(1));
      expect(testCategory.name, equals('Work'));
      expect(testCategory.color, equals(Colors.blue));
    });

    test('should create a category without id', () {
      final newCategory = Category(
        name: 'Personal',
        color: Colors.green,
      );

      expect(newCategory.id, isNull);
      expect(newCategory.name, equals('Personal'));
      expect(newCategory.color, equals(Colors.green));
    });

    test('should copy category with new values', () {
      final copiedCategory = testCategory.copyWith(
        name: 'Updated Work',
        color: Colors.red,
      );

      expect(copiedCategory.id, equals(testCategory.id));
      expect(copiedCategory.name, equals('Updated Work'));
      expect(copiedCategory.color, equals(Colors.red));
    });

    test('should convert category to map correctly', () {
      final map = testCategory.toMap();

      expect(map['id'], equals(1));
      expect(map['name'], equals('Work'));
      expect(map['color'], equals(Colors.blue.toARGB32()));
    });

    test('should create category from map correctly', () {
      final map = {
        'id': 2,
        'name': 'Health',
        'color': Colors.red.toARGB32(),
      };

      final categoryFromMap = Category.fromMap(map);

      expect(categoryFromMap.id, equals(2));
      expect(categoryFromMap.name, equals('Health'));
      expect(categoryFromMap.color, equals(Colors.red));
    });

    test('should handle null id in fromMap', () {
      final map = {
        'name': 'Shopping',
        'color': Colors.orange.toARGB32(),
      };

      final categoryFromMap = Category.fromMap(map);

      expect(categoryFromMap.id, isNull);
      expect(categoryFromMap.name, equals('Shopping'));
      expect(categoryFromMap.color, equals(Colors.orange));
    });

    test('should have default categories', () {
      expect(Category.defaultCategories, isNotEmpty);
      expect(Category.defaultCategories.length, equals(5));
      
      final workCategory = Category.defaultCategories.first;
      expect(workCategory.name, equals('Work'));
      expect(workCategory.color, equals(Colors.blue));
    });

    test('should preserve color value when converting to/from map', () {
      const customColor = Color(0xFF123456);
      final category = Category(
        name: 'Custom',
        color: customColor,
      );

      final map = category.toMap();
      final reconstructed = Category.fromMap(map);

      expect(reconstructed.color.toARGB32(), equals(customColor.toARGB32()));
    });
  });
}