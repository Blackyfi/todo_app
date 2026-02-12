import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/database/repository/category_repository.dart';
import 'package:todo_app/features/categories/models/category.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CategoryRepository Tests', () {
    late CategoryRepository repository;

    setUp(() {
      repository = CategoryRepository();
    });

    group('Category CRUD Operations', () {
      test('should insert and retrieve a category', () async {
        final category = Category(
          name: 'Test Category',
          color: Colors.blue,
        );

        final id = await repository.insertCategory(category);
        expect(id, isPositive);

        final retrievedCategory = await repository.getCategory(id);
        expect(retrievedCategory, isNotNull);
        expect(retrievedCategory!.name, equals('Test Category'));
        expect(retrievedCategory.color.toARGB32(), equals(Colors.blue.toARGB32()));

        // Cleanup
        await repository.deleteCategory(id);
      });

      test('should update an existing category', () async {
        final category = Category(
          name: 'Original Category',
          color: Colors.green,
        );

        final id = await repository.insertCategory(category);

        final updatedCategory = category.copyWith(
          id: id,
          name: 'Updated Category',
          color: Colors.red,
        );

        await repository.updateCategory(updatedCategory);

        final retrievedCategory = await repository.getCategory(id);
        expect(retrievedCategory!.name, equals('Updated Category'));
        expect(retrievedCategory.color.toARGB32(), equals(Colors.red.toARGB32()));

        // Cleanup
        await repository.deleteCategory(id);
      });

      test('should delete a category', () async {
        final category = Category(
          name: 'Category to Delete',
          color: Colors.orange,
        );

        final id = await repository.insertCategory(category);
        await repository.deleteCategory(id);

        final retrievedCategory = await repository.getCategory(id);
        expect(retrievedCategory, isNull);
      });

      test('should get all categories', () async {
        final allCategories = await repository.getAllCategories();

        // Default categories should exist
        expect(allCategories.length, greaterThanOrEqualTo(5));

        // Check for default categories
        expect(allCategories.any((c) => c.name == 'Work'), isTrue);
        expect(allCategories.any((c) => c.name == 'Personal'), isTrue);
        expect(allCategories.any((c) => c.name == 'Shopping'), isTrue);
      });
    });

    group('Category Colors', () {
      test('should preserve color values correctly', () async {
        final colors = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
        ];

        final ids = <int>[];

        for (final color in colors) {
          final category = Category(
            name: 'Color Test ${color.toARGB32()}',
            color: color,
          );
          final id = await repository.insertCategory(category);
          ids.add(id);
        }

        // Verify colors are preserved
        for (var i = 0; i < ids.length; i++) {
          final category = await repository.getCategory(ids[i]);
          expect(category!.color.toARGB32(), equals(colors[i].toARGB32()));
        }

        // Cleanup
        for (final id in ids) {
          await repository.deleteCategory(id);
        }
      });

      test('should handle custom color values', () async {
        const customColor = Color(0xFF123456);
        final category = Category(
          name: 'Custom Color',
          color: customColor,
        );

        final id = await repository.insertCategory(category);
        final retrieved = await repository.getCategory(id);

        expect(retrieved!.color.toARGB32(), equals(customColor.toARGB32()));

        // Cleanup
        await repository.deleteCategory(id);
      });
    });

    group('Category Name Validation', () {
      test('should handle categories with special characters', () async {
        final category = Category(
          name: 'Test & Category #1 (Special)',
          color: Colors.teal,
        );

        final id = await repository.insertCategory(category);
        final retrieved = await repository.getCategory(id);

        expect(retrieved!.name, equals('Test & Category #1 (Special)'));

        // Cleanup
        await repository.deleteCategory(id);
      });

      test('should handle categories with unicode characters', () async {
        final category = Category(
          name: '日本語 Category 🎯',
          color: Colors.amber,
        );

        final id = await repository.insertCategory(category);
        final retrieved = await repository.getCategory(id);

        expect(retrieved!.name, equals('日本語 Category 🎯'));

        // Cleanup
        await repository.deleteCategory(id);
      });
    });

    group('Default Categories', () {
      test('should have all default categories after initialization', () async {
        final categories = await repository.getAllCategories();

        final defaultCategoryNames = ['Work', 'Personal', 'Shopping', 'Health', 'Education'];

        for (final name in defaultCategoryNames) {
          expect(categories.any((c) => c.name == name), isTrue,
              reason: 'Default category "$name" should exist');
        }
      });

      test('default Work category should have blue color', () async {
        final categories = await repository.getAllCategories();
        final workCategory = categories.firstWhere((c) => c.name == 'Work');

        // Default Work category is blue (0xFF2196F3)
        expect(workCategory.color.toARGB32(), equals(0xFF2196F3));
      });
    });
  });
}
