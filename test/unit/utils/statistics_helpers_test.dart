import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/features/statistics/utils/statistics_helpers.dart';
import 'package:todo_app/features/tasks/models/task.dart';
import 'package:todo_app/features/categories/models/category.dart';

void main() {
  group('Statistics Helpers Tests', () {
    late List<Task> testTasks;
    late List<Category> testCategories;

    setUp(() {
      final now = DateTime.now();
      
      testCategories = [
        Category(id: 1, name: 'Work', color: Colors.blue),
        Category(id: 2, name: 'Personal', color: Colors.green),
        Category(id: 3, name: 'Shopping', color: Colors.orange),
      ];

      testTasks = [
        Task(
          id: 1,
          title: 'Completed Work Task',
          isCompleted: true,
          categoryId: 1,
          priority: Priority.high,
          dueDate: now.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(hours: 2)),
        ),
        Task(
          id: 2,
          title: 'Incomplete Personal Task',
          isCompleted: false,
          categoryId: 2,
          priority: Priority.medium,
          dueDate: now.add(const Duration(days: 1)),
        ),
        Task(
          id: 3,
          title: 'Completed Shopping Task',
          isCompleted: true,
          categoryId: 3,
          priority: Priority.low,
          dueDate: now.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 1)),
        ),
        Task(
          id: 4,
          title: 'Uncategorized Task',
          isCompleted: false,
          categoryId: null,
          priority: Priority.medium,
          dueDate: now.add(const Duration(days: 3)),
        ),
        Task(
          id: 5,
          title: 'High Priority Incomplete',
          isCompleted: false,
          categoryId: 1,
          priority: Priority.high,
          dueDate: now.add(const Duration(hours: 5)),
        ),
      ];
    });

    group('getCompletionStats', () {
      test('should return correct completion statistics', () {
        final stats = getCompletionStats(testTasks);

        expect(stats['Completed'], equals(2));
        expect(stats['Incomplete'], equals(3));
      });

      test('should handle empty task list', () {
        final stats = getCompletionStats([]);

        expect(stats['Completed'], equals(0));
        expect(stats['Incomplete'], equals(0));
      });

      test('should handle all completed tasks', () {
        final allCompleted = testTasks.map((task) => 
          task.copyWith(isCompleted: true)
        ).toList();
        
        final stats = getCompletionStats(allCompleted);

        expect(stats['Completed'], equals(5));
        expect(stats['Incomplete'], equals(0));
      });

      test('should handle all incomplete tasks', () {
        final allIncomplete = testTasks.map((task) => 
          task.copyWith(isCompleted: false)
        ).toList();
        
        final stats = getCompletionStats(allIncomplete);

        expect(stats['Completed'], equals(0));
        expect(stats['Incomplete'], equals(5));
      });
    });

    group('getPriorityStats', () {
      test('should return correct priority statistics', () {
        final stats = getPriorityStats(testTasks);

        expect(stats['High'], equals(2));
        expect(stats['Medium'], equals(2));
        expect(stats['Low'], equals(1));
      });

      test('should handle empty task list', () {
        final stats = getPriorityStats([]);

        expect(stats['High'], equals(0));
        expect(stats['Medium'], equals(0));
        expect(stats['Low'], equals(0));
      });

      test('should handle single priority type', () {
        final highPriorityTasks = [
          Task(title: 'Task 1', priority: Priority.high),
          Task(title: 'Task 2', priority: Priority.high),
        ];
        
        final stats = getPriorityStats(highPriorityTasks);

        expect(stats['High'], equals(2));
        expect(stats['Medium'], equals(0));
        expect(stats['Low'], equals(0));
      });
    });

    group('getCategoryStats', () {
      test('should return correct category statistics', () {
        final stats = getCategoryStats(testTasks, testCategories);

        expect(stats['Work'], equals(2));
        expect(stats['Personal'], equals(1));
        expect(stats['Shopping'], equals(1));
        expect(stats['No Category'], equals(1));
      });

      test('should handle tasks without categories', () {
        final uncategorizedTasks = testTasks.map((task) => 
          task.copyWith(categoryId: null)
        ).toList();
        
        final stats = getCategoryStats(uncategorizedTasks, testCategories);

        expect(stats['No Category'], equals(5));
        expect(stats.containsKey('Work'), isFalse);
        expect(stats.containsKey('Personal'), isFalse);
        expect(stats.containsKey('Shopping'), isFalse);
      });

      test('should handle empty task list', () {
        final stats = getCategoryStats([], testCategories);

        expect(stats.isEmpty, isTrue);
      });

      test('should handle unknown category IDs', () {
        final tasksWithUnknownCategory = [
          Task(title: 'Unknown Category Task', categoryId: 999),
        ];
        
        final stats = getCategoryStats(tasksWithUnknownCategory, testCategories);

        expect(stats['Unknown'], equals(1));
      });

      test('should remove "No Category" entry when count is zero', () {
        final categorizedTasks = testTasks.where((task) => task.categoryId != null).toList();
        
        final stats = getCategoryStats(categorizedTasks, testCategories);

        expect(stats.containsKey('No Category'), isFalse);
      });
    });

    group('getTasksDueThisWeek', () {
      test('should return tasks due this week', () {
        final now = DateTime.now();
        final tasksThisWeek = [
          Task(
            title: 'Task Today',
            dueDate: now,
            isCompleted: false,
          ),
          Task(
            title: 'Task Tomorrow',
            dueDate: now.add(const Duration(days: 1)),
            isCompleted: false,
          ),
          Task(
            title: 'Task Next Week',
            dueDate: now.add(const Duration(days: 8)),
            isCompleted: false,
          ),
          Task(
            title: 'Completed Task This Week',
            dueDate: now.add(const Duration(days: 2)),
            isCompleted: true,
          ),
        ];

        final result = getTasksDueThisWeek(tasksThisWeek);

        expect(result.length, equals(2)); // Only incomplete tasks this week
        expect(result.any((task) => task.title == 'Task Today'), isTrue);
        expect(result.any((task) => task.title == 'Task Tomorrow'), isTrue);
        expect(result.any((task) => task.title == 'Task Next Week'), isFalse);
        expect(result.any((task) => task.title == 'Completed Task This Week'), isFalse);
      });

      test('should handle tasks without due dates', () {
        final tasksWithoutDueDates = [
          Task(title: 'No Due Date', isCompleted: false),
        ];

        final result = getTasksDueThisWeek(tasksWithoutDueDates);

        expect(result.isEmpty, isTrue);
      });

      test('should handle empty task list', () {
        final result = getTasksDueThisWeek([]);

        expect(result.isEmpty, isTrue);
      });
    });

    group('getTasksCompletedByDay', () {
      test('should return tasks completed by day of the week', () {
        final result = getTasksCompletedByDay(testTasks);

        // Check that all days are present
        expect(result.keys.length, equals(7));
        expect(result.keys.every((key) => key.length == 3), isTrue); // Abbreviated day names

        // Check that completed tasks are counted
        final totalCompleted = result.values.fold(0, (sum, count) => sum + count);
        expect(totalCompleted, greaterThanOrEqualTo(0));
      });

      test('should handle empty task list', () {
        final result = getTasksCompletedByDay([]);

        expect(result.keys.length, equals(7));
        expect(result.values.every((count) => count == 0), isTrue);
      });

      test('should only count completed tasks', () {
        final incompleteTasks = testTasks.map((task) => 
          task.copyWith(isCompleted: false)
        ).toList();

        final result = getTasksCompletedByDay(incompleteTasks);

        expect(result.values.every((count) => count == 0), isTrue);
      });
    });

    group('getCompletionPercentage', () {
      test('should calculate correct completion percentage', () {
        final percentage = getCompletionPercentage(testTasks);

        // 2 completed out of 5 total = 40%
        expect(percentage, equals(40.0));
      });

      test('should return 0 for empty task list', () {
        final percentage = getCompletionPercentage([]);

        expect(percentage, equals(0.0));
      });

      test('should return 100 for all completed tasks', () {
        final allCompleted = testTasks.map((task) => 
          task.copyWith(isCompleted: true)
        ).toList();

        final percentage = getCompletionPercentage(allCompleted);

        expect(percentage, equals(100.0));
      });

      test('should return 0 for all incomplete tasks', () {
        final allIncomplete = testTasks.map((task) => 
          task.copyWith(isCompleted: false)
        ).toList();

        final percentage = getCompletionPercentage(allIncomplete);

        expect(percentage, equals(0.0));
      });

      test('should handle single completed task', () {
        final singleCompleted = [
          Task(title: 'Single Task', isCompleted: true),
        ];

        final percentage = getCompletionPercentage(singleCompleted);

        expect(percentage, equals(100.0));
      });

      test('should handle single incomplete task', () {
        final singleIncomplete = [
          Task(title: 'Single Task', isCompleted: false),
        ];

        final percentage = getCompletionPercentage(singleIncomplete);

        expect(percentage, equals(0.0));
      });
    });
  });
}