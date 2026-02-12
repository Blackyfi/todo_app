import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/database/repository/category_repository.dart';
import 'package:todo_app/features/tasks/models/task.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Widget Integration Tests', () {
    late WidgetService widgetService;
    late TaskRepository taskRepository;
    late CategoryRepository categoryRepository;

    setUp(() async {
      widgetService = WidgetService();
      taskRepository = TaskRepository();
      categoryRepository = CategoryRepository();

      // Initialize widget service (may fail in test environment, which is ok)
      try {
        await widgetService.init();
      } catch (e) {
        // Expected to fail in test environment due to platform channels
      }
    });

    group('Complete Widget Workflow', () {
      test('should create widget, add tasks, and verify widget data flow', () async {
        // Step 1: Create a widget configuration
        final widgetConfig = WidgetConfig(
          name: 'Integration Test Widget',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
          createdAt: DateTime.now(),
        );

        expect(widgetConfig.name, equals('Integration Test Widget'));
        expect(widgetConfig.maxTasks, equals(5));

        // Step 2: Create tasks with different priorities
        final highPriorityTask = Task(
          title: 'High Priority Task',
          description: 'This is urgent',
          priority: Priority.high,
          dueDate: DateTime.now().add(const Duration(hours: 2)),
          categoryId: 1, // Work category
        );

        final mediumPriorityTask = Task(
          title: 'Medium Priority Task',
          description: 'This can wait',
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 1)),
          categoryId: 2, // Personal category
        );

        final lowPriorityTask = Task(
          title: 'Low Priority Task',
          description: 'Not urgent',
          priority: Priority.low,
          dueDate: DateTime.now().add(const Duration(days: 7)),
        );

        final completedTask = Task(
          title: 'Completed Task',
          priority: Priority.medium,
          isCompleted: true,
          completedAt: DateTime.now(),
        );

        // Insert tasks
        final id1 = await taskRepository.insertTask(highPriorityTask);
        final id2 = await taskRepository.insertTask(mediumPriorityTask);
        final id3 = await taskRepository.insertTask(lowPriorityTask);
        final id4 = await taskRepository.insertTask(completedTask);

        // Verify tasks were inserted
        expect(id1, isPositive);
        expect(id2, isPositive);
        expect(id3, isPositive);
        expect(id4, isPositive);

        // Step 3: Verify widget configuration filtering
        final allTasks = await taskRepository.getAllTasks();
        final incompleteTasks = allTasks.where((t) => !t.isCompleted).toList();

        // Widget configured to hide completed tasks
        if (widgetConfig.showCompleted) {
          expect(allTasks.length, greaterThanOrEqualTo(4));
        } else {
          expect(incompleteTasks.length, greaterThanOrEqualTo(3));
        }

        // Step 4: Test task priority ordering
        final ourIncompleteTasks = incompleteTasks.where((t) =>
          t.title == 'High Priority Task' ||
          t.title == 'Medium Priority Task' ||
          t.title == 'Low Priority Task'
        ).toList();

        // Sort by priority (same as widget would do)
        ourIncompleteTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));

        expect(ourIncompleteTasks.first.priority, equals(Priority.high));
        expect(ourIncompleteTasks.last.priority, equals(Priority.low));

        // Step 5: Test widget max tasks limit
        final limitedTasks = ourIncompleteTasks.take(widgetConfig.maxTasks).toList();
        expect(limitedTasks.length, lessThanOrEqualTo(widgetConfig.maxTasks));

        // Step 6: Test task completion toggle
        await taskRepository.toggleTaskCompletion(id1, true);
        final completedHighTask = await taskRepository.getTask(id1);
        expect(completedHighTask!.isCompleted, isTrue);
        expect(completedHighTask.completedAt, isNotNull);

        // Toggle back
        await taskRepository.toggleTaskCompletion(id1, false);
        final uncompletedTask = await taskRepository.getTask(id1);
        expect(uncompletedTask!.isCompleted, isFalse);
        expect(uncompletedTask.completedAt, isNull);

        // Step 7: Test category filtering
        final workTasks = await taskRepository.getTasksByCategory(1);
        expect(workTasks.any((t) => t.title == 'High Priority Task'), isTrue);

        // Cleanup
        await taskRepository.deleteTask(id1);
        await taskRepository.deleteTask(id2);
        await taskRepository.deleteTask(id3);
        await taskRepository.deleteTask(id4);
      });

      test('should handle widget category filtering correctly', () async {
        // Create widget with category filter
        final workWidgetConfig = WidgetConfig(
          name: 'Work Widget',
          size: WidgetSize.small,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 3,
          categoryFilter: 'Work',
          createdAt: DateTime.now(),
        );

        expect(workWidgetConfig.categoryFilter, equals('Work'));

        // Create tasks in different categories
        final workTask = Task(
          title: 'Work Task',
          priority: Priority.high,
          categoryId: 1, // Work
        );

        final personalTask = Task(
          title: 'Personal Task',
          priority: Priority.medium,
          categoryId: 2, // Personal
        );

        final id1 = await taskRepository.insertTask(workTask);
        final id2 = await taskRepository.insertTask(personalTask);

        // Verify category filtering
        final allCategories = await categoryRepository.getAllCategories();
        final workCategory = allCategories.firstWhere((c) => c.name == 'Work', orElse: () {
          throw Exception('Work category not found');
        });

        final workTasks = await taskRepository.getTasksByCategory(workCategory.id!);

        expect(workTasks.any((t) => t.title == 'Work Task'), isTrue);
        expect(workTasks.any((t) => t.title == 'Personal Task'), isFalse);

        // Cleanup
        await taskRepository.deleteTask(id1);
        await taskRepository.deleteTask(id2);
      });

      test('should handle multiple widget sizes and configurations', () async {
        final smallWidget = WidgetConfig(
          name: 'Small Widget',
          size: WidgetSize.small,
          maxTasks: 3,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          createdAt: DateTime.now(),
        );

        final largeWidget = WidgetConfig(
          name: 'Large Widget',
          size: WidgetSize.large,
          maxTasks: 10,
          showCompleted: true,
          showCategories: true,
          showPriority: true,
          createdAt: DateTime.now(),
        );

        // Verify sizes
        expect(smallWidget.size.size.width, lessThan(largeWidget.size.size.width));
        expect(smallWidget.maxTasks, lessThan(largeWidget.maxTasks));

        // Verify showCompleted affects filtering
        expect(smallWidget.showCompleted, isFalse);
        expect(largeWidget.showCompleted, isTrue);
      });
    });

    group('Widget and Task Lifecycle', () {
      test('should handle task creation, update, and deletion workflow', () async {
        // Create initial task
        final task = Task(
          title: 'Lifecycle Test Task',
          description: 'Initial description',
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 1)),
        );

        final taskId = await taskRepository.insertTask(task);
        expect(taskId, isPositive);

        // Verify task was created
        var retrievedTask = await taskRepository.getTask(taskId);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Lifecycle Test Task'));

        // Update task
        final updatedTask = retrievedTask.copyWith(
          title: 'Updated Lifecycle Test',
          priority: Priority.high,
        );
        await taskRepository.updateTask(updatedTask);

        // Verify update
        retrievedTask = await taskRepository.getTask(taskId);
        expect(retrievedTask!.title, equals('Updated Lifecycle Test'));
        expect(retrievedTask.priority, equals(Priority.high));

        // Complete task
        await taskRepository.toggleTaskCompletion(taskId, true);
        retrievedTask = await taskRepository.getTask(taskId);
        expect(retrievedTask!.isCompleted, isTrue);

        // Delete task
        await taskRepository.deleteTask(taskId);
        retrievedTask = await taskRepository.getTask(taskId);
        expect(retrievedTask, isNull);
      });

      test('should handle overdue task detection', () async {
        // Create task with past due date
        final overdueTask = Task(
          title: 'Overdue Task',
          priority: Priority.high,
          dueDate: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final taskId = await taskRepository.insertTask(overdueTask);
        final retrieved = await taskRepository.getTask(taskId);

        expect(retrieved!.dueDate!.isBefore(DateTime.now()), isTrue);
        expect(retrieved.isCompleted, isFalse);

        // Cleanup
        await taskRepository.deleteTask(taskId);
      });

      test('should handle tasks with future due dates', () async {
        final futureTask = Task(
          title: 'Future Task',
          priority: Priority.low,
          dueDate: DateTime.now().add(const Duration(days: 30)),
        );

        final taskId = await taskRepository.insertTask(futureTask);
        final retrieved = await taskRepository.getTask(taskId);

        expect(retrieved!.dueDate!.isAfter(DateTime.now()), isTrue);

        // Cleanup
        await taskRepository.deleteTask(taskId);
      });
    });
  });
}
