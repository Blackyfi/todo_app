import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/features/tasks/models/task.dart';

void main() {
  group('Task Model Tests', () {
    late Task testTask;
    late DateTime testDueDate;

    setUp(() {
      testDueDate = DateTime(2024, 12, 25, 14, 30);
      testTask = Task(
        id: 1,
        title: 'Test Task',
        description: 'Test Description',
        dueDate: testDueDate,
        isCompleted: false,
        categoryId: 1,
        priority: Priority.high,
      );
    });

    test('should create a task with all properties', () {
      expect(testTask.id, equals(1));
      expect(testTask.title, equals('Test Task'));
      expect(testTask.description, equals('Test Description'));
      expect(testTask.dueDate, equals(testDueDate));
      expect(testTask.isCompleted, equals(false));
      expect(testTask.categoryId, equals(1));
      expect(testTask.priority, equals(Priority.high));
    });

    test('should create a task with default values', () {
      final defaultTask = Task(title: 'Simple Task');
      
      expect(defaultTask.id, isNull);
      expect(defaultTask.title, equals('Simple Task'));
      expect(defaultTask.description, equals(''));
      expect(defaultTask.dueDate, isNull);
      expect(defaultTask.isCompleted, equals(false));
      expect(defaultTask.categoryId, isNull);
      expect(defaultTask.priority, equals(Priority.medium));
      expect(defaultTask.completedAt, isNull);
    });

    test('should copy task with new values', () {
      final copiedTask = testTask.copyWith(
        title: 'Updated Task',
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      expect(copiedTask.id, equals(testTask.id));
      expect(copiedTask.title, equals('Updated Task'));
      expect(copiedTask.description, equals(testTask.description));
      expect(copiedTask.isCompleted, equals(true));
      expect(copiedTask.completedAt, isNotNull);
    });

    test('should convert task to map correctly', () {
      final map = testTask.toMap();

      expect(map['id'], equals(1));
      expect(map['title'], equals('Test Task'));
      expect(map['description'], equals('Test Description'));
      expect(map['dueDate'], equals(testDueDate.millisecondsSinceEpoch));
      expect(map['isCompleted'], equals(0));
      expect(map['categoryId'], equals(1));
      expect(map['priority'], equals(0)); // Priority.high.index
      expect(map['completedAt'], isNull);
    });

    test('should create task from map correctly', () {
      final map = {
        'id': 2,
        'title': 'Map Task',
        'description': 'From Map',
        'dueDate': testDueDate.millisecondsSinceEpoch,
        'isCompleted': 1,
        'categoryId': 2,
        'priority': 2, // Priority.low.index
        'completedAt': testDueDate.millisecondsSinceEpoch,
      };

      final taskFromMap = Task.fromMap(map);

      expect(taskFromMap.id, equals(2));
      expect(taskFromMap.title, equals('Map Task'));
      expect(taskFromMap.description, equals('From Map'));
      expect(taskFromMap.dueDate, equals(testDueDate));
      expect(taskFromMap.isCompleted, equals(true));
      expect(taskFromMap.categoryId, equals(2));
      expect(taskFromMap.priority, equals(Priority.low));
      expect(taskFromMap.completedAt, equals(testDueDate));
    });

    test('should handle null values in fromMap', () {
      final map = {
        'title': 'Minimal Task',
      };

      final taskFromMap = Task.fromMap(map);

      expect(taskFromMap.id, isNull);
      expect(taskFromMap.title, equals('Minimal Task'));
      expect(taskFromMap.description, equals(''));
      expect(taskFromMap.dueDate, isNull);
      expect(taskFromMap.isCompleted, equals(false));
      expect(taskFromMap.categoryId, isNull);
      expect(taskFromMap.priority, equals(Priority.medium));
      expect(taskFromMap.completedAt, isNull);
    });
  });

  group('Priority Enum Tests', () {
    test('should have correct colors', () {
      expect(Priority.high.color, equals(Colors.red));
      expect(Priority.medium.color, equals(Colors.orange));
      expect(Priority.low.color, equals(Colors.green));
    });

    test('should have correct labels', () {
      expect(Priority.high.label, equals('High'));
      expect(Priority.medium.label, equals('Medium'));
      expect(Priority.low.label, equals('Low'));
    });
  });
}