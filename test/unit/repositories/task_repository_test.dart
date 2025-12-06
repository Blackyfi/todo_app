import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/features/tasks/models/task.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TaskRepository Tests', () {
    late TaskRepository repository;

    setUp(() {
      repository = TaskRepository();
    });

    group('Task CRUD Operations', () {
      test('should insert and retrieve a task', () async {
        final task = Task(
          title: 'Test Task',
          description: 'Test Description',
          priority: Priority.high,
          isCompleted: false,
        );

        final id = await repository.insertTask(task);
        expect(id, isPositive);

        final retrievedTask = await repository.getTask(id);
        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Test Task'));
        expect(retrievedTask.description, equals('Test Description'));
        expect(retrievedTask.priority, equals(Priority.high));
        expect(retrievedTask.isCompleted, isFalse);

        // Cleanup
        await repository.deleteTask(id);
      });

      test('should update an existing task', () async {
        final task = Task(
          title: 'Original Task',
          description: 'Original Description',
          priority: Priority.medium,
        );

        final id = await repository.insertTask(task);

        final updatedTask = task.copyWith(
          id: id,
          title: 'Updated Task',
          description: 'Updated Description',
          priority: Priority.high,
        );

        await repository.updateTask(updatedTask);

        final retrievedTask = await repository.getTask(id);
        expect(retrievedTask!.title, equals('Updated Task'));
        expect(retrievedTask.description, equals('Updated Description'));
        expect(retrievedTask.priority, equals(Priority.high));

        // Cleanup
        await repository.deleteTask(id);
      });

      test('should delete a task', () async {
        final task = Task(
          title: 'Task to Delete',
          description: 'This will be deleted',
          priority: Priority.low,
        );

        final id = await repository.insertTask(task);
        await repository.deleteTask(id);

        final retrievedTask = await repository.getTask(id);
        expect(retrievedTask, isNull);
      });

      test('should get all tasks', () async {
        // Insert multiple tasks
        final task1 = Task(title: 'Task 1', priority: Priority.high);
        final task2 = Task(title: 'Task 2', priority: Priority.medium);
        final task3 = Task(title: 'Task 3', priority: Priority.low);

        final id1 = await repository.insertTask(task1);
        final id2 = await repository.insertTask(task2);
        final id3 = await repository.insertTask(task3);

        final allTasks = await repository.getAllTasks();
        expect(allTasks.length, greaterThanOrEqualTo(3));

        // Verify our tasks are in the list
        final ourTasks = allTasks.where((t) =>
          t.title == 'Task 1' || t.title == 'Task 2' || t.title == 'Task 3'
        ).toList();
        expect(ourTasks.length, equals(3));

        // Cleanup
        await repository.deleteTask(id1);
        await repository.deleteTask(id2);
        await repository.deleteTask(id3);
      });
    });

    group('Task Completion', () {
      test('should toggle task completion from incomplete to complete', () async {
        final task = Task(
          title: 'Task to Complete',
          priority: Priority.medium,
          isCompleted: false,
        );

        final id = await repository.insertTask(task);

        // Toggle to completed
        await repository.toggleTaskCompletion(id, true);

        final completedTask = await repository.getTask(id);
        expect(completedTask!.isCompleted, isTrue);
        expect(completedTask.completedAt, isNotNull);

        // Cleanup
        await repository.deleteTask(id);
      });

      test('should toggle task completion from complete to incomplete', () async {
        final task = Task(
          title: 'Completed Task',
          priority: Priority.low,
          isCompleted: true,
          completedAt: DateTime.now(),
        );

        final id = await repository.insertTask(task);

        // Toggle to incomplete
        await repository.toggleTaskCompletion(id, false);

        final incompleteTask = await repository.getTask(id);
        expect(incompleteTask!.isCompleted, isFalse);
        expect(incompleteTask.completedAt, isNull);

        // Cleanup
        await repository.deleteTask(id);
      });

      test('should preserve completedAt timestamp when marking as complete', () async {
        final task = Task(
          title: 'Task',
          priority: Priority.medium,
        );

        final id = await repository.insertTask(task);
        final beforeToggle = DateTime.now();

        await repository.toggleTaskCompletion(id, true);

        final completedTask = await repository.getTask(id);
        expect(completedTask!.completedAt, isNotNull);
        expect(
          completedTask.completedAt!.isAfter(beforeToggle.subtract(const Duration(seconds: 5))),
          isTrue,
        );

        // Cleanup
        await repository.deleteTask(id);
      });
    });

    group('Task Categories', () {
      test('should filter tasks by category', () async {
        // Create tasks with different categories
        final task1 = Task(title: 'Work Task', categoryId: 1, priority: Priority.high);
        final task2 = Task(title: 'Personal Task', categoryId: 2, priority: Priority.medium);
        final task3 = Task(title: 'Another Work Task', categoryId: 1, priority: Priority.low);

        final id1 = await repository.insertTask(task1);
        final id2 = await repository.insertTask(task2);
        final id3 = await repository.insertTask(task3);

        final workTasks = await repository.getTasksByCategory(1);

        expect(workTasks.any((t) => t.title == 'Work Task'), isTrue);
        expect(workTasks.any((t) => t.title == 'Another Work Task'), isTrue);
        expect(workTasks.any((t) => t.title == 'Personal Task'), isFalse);

        // Cleanup
        await repository.deleteTask(id1);
        await repository.deleteTask(id2);
        await repository.deleteTask(id3);
      });

      test('should handle tasks without categories', () async {
        final task = Task(
          title: 'Task Without Category',
          categoryId: null,
          priority: Priority.medium,
        );

        final id = await repository.insertTask(task);
        final retrievedTask = await repository.getTask(id);

        expect(retrievedTask!.categoryId, isNull);

        // Cleanup
        await repository.deleteTask(id);
      });
    });

    group('Task Priority', () {
      test('should preserve task priority correctly', () async {
        final highPriorityTask = Task(title: 'High', priority: Priority.high);
        final mediumPriorityTask = Task(title: 'Medium', priority: Priority.medium);
        final lowPriorityTask = Task(title: 'Low', priority: Priority.low);

        final id1 = await repository.insertTask(highPriorityTask);
        final id2 = await repository.insertTask(mediumPriorityTask);
        final id3 = await repository.insertTask(lowPriorityTask);

        final task1 = await repository.getTask(id1);
        final task2 = await repository.getTask(id2);
        final task3 = await repository.getTask(id3);

        expect(task1!.priority, equals(Priority.high));
        expect(task2!.priority, equals(Priority.medium));
        expect(task3!.priority, equals(Priority.low));

        // Cleanup
        await repository.deleteTask(id1);
        await repository.deleteTask(id2);
        await repository.deleteTask(id3);
      });
    });

    group('Task Due Dates', () {
      test('should handle tasks with due dates', () async {
        final dueDate = DateTime.now().add(const Duration(days: 7));
        final task = Task(
          title: 'Task with Due Date',
          dueDate: dueDate,
          priority: Priority.high,
        );

        final id = await repository.insertTask(task);
        final retrievedTask = await repository.getTask(id);

        expect(retrievedTask!.dueDate, isNotNull);
        expect(
          retrievedTask.dueDate!.difference(dueDate).inSeconds.abs(),
          lessThan(1),
        );

        // Cleanup
        await repository.deleteTask(id);
      });

      test('should handle tasks without due dates', () async {
        final task = Task(
          title: 'Task without Due Date',
          dueDate: null,
          priority: Priority.medium,
        );

        final id = await repository.insertTask(task);
        final retrievedTask = await repository.getTask(id);

        expect(retrievedTask!.dueDate, isNull);

        // Cleanup
        await repository.deleteTask(id);
      });
    });
  });
}
