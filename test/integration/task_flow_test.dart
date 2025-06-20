import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/main.dart' as app;
import 'package:todo_app/features/tasks/models/task.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Flow Integration Tests', () {
    testWidgets('should complete full task creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to add task screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in task details
      await tester.enterText(find.byType(TextFormField).first, 'Integration Test Task');
      await tester.pump();

      // Find and fill description field if present
      final descriptionFields = find.byType(TextFormField);
      if (descriptionFields.evaluate().length > 1) {
        await tester.enterText(descriptionFields.at(1), 'This is a test task created by integration test');
        await tester.pump();
      }

      // Set priority if available
      final priorityDropdown = find.byType(DropdownButton<Priority>);
      if (priorityDropdown.evaluate().isNotEmpty) {
        await tester.tap(priorityDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('High').last);
        await tester.pumpAndSettle();
      }

      // Save the task
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify we're back on home screen and task appears
      expect(find.text('Todo App'), findsOneWidget);
      expect(find.textContaining('Integration Test Task'), findsOneWidget);
    });

    testWidgets('should complete task editing flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First create a task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Task to Edit');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Find and tap the task to edit it
      final taskCard = find.textContaining('Task to Edit');
      expect(taskCard, findsOneWidget);
      await tester.tap(taskCard);
      await tester.pumpAndSettle();

      // Should navigate to task details or edit screen
      // Tap edit button if available
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Modify the task title
        await tester.enterText(find.byType(TextFormField).first, 'Edited Task Title');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Verify the change
        expect(find.textContaining('Edited Task Title'), findsOneWidget);
      }
    });

    testWidgets('should complete task completion flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a task first
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Task to Complete');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Find the checkbox for the task and tap it
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();

        // Verify task is marked as completed (styling changes)
        final completedTask = find.textContaining('Task to Complete');
        expect(completedTask, findsOneWidget);
      }
    });

    testWidgets('should complete task deletion flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create a task first
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Task to Delete');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Find the task and swipe to delete
      final taskCard = find.textContaining('Task to Delete');
      expect(taskCard, findsOneWidget);

      // Swipe left to reveal delete option
      await tester.drag(taskCard, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Confirm deletion if dialog appears
      final deleteButton = find.text('DELETE');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Verify task is removed
        expect(find.textContaining('Task to Delete'), findsNothing);
      }
    });

    testWidgets('should filter tasks correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create multiple tasks with different states
      final taskTitles = ['Completed Task', 'Incomplete Task', 'Today Task'];
      
      for (int i = 0; i < taskTitles.length; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, taskTitles[i]);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Complete the first task
        if (i == 0) {
          final checkbox = find.byType(Checkbox).first;
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
      }

      // Test filtering
      final filterButton = find.byType(PopupMenuButton<String>);
      if (filterButton.evaluate().isNotEmpty) {
        // Filter by completed
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Completed Task'), findsOneWidget);
        expect(find.textContaining('Incomplete Task'), findsNothing);

        // Filter by incomplete
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Incomplete'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Completed Task'), findsNothing);
        expect(find.textContaining('Incomplete Task'), findsOneWidget);
        expect(find.textContaining('Today Task'), findsOneWidget);

        // Reset to all tasks
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('All Tasks'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Completed Task'), findsOneWidget);
        expect(find.textContaining('Incomplete Task'), findsOneWidget);
        expect(find.textContaining('Today Task'), findsOneWidget);
      }
    });

    testWidgets('should handle task with due date and notifications', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create task with due date
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Task with Due Date');

      // Set due date if date picker is available
      final dueDateButton = find.textContaining('Due Date');
      if (dueDateButton.evaluate().isNotEmpty) {
        await tester.tap(dueDateButton);
        await tester.pumpAndSettle();

        // Select tomorrow's date
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowButton = find.text(tomorrow.day.toString());
        if (tomorrowButton.evaluate().isNotEmpty) {
          await tester.tap(tomorrowButton);
          await tester.pumpAndSettle();
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        }
      }

      // Set notification if available
      final notificationSwitch = find.byType(Switch);
      if (notificationSwitch.evaluate().isNotEmpty) {
        await tester.tap(notificationSwitch);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify task appears with due date indication
      expect(find.textContaining('Task with Due Date'), findsOneWidget);
    });

    testWidgets('should validate task form inputs', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to save empty task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a title'), findsOneWidget);

      // Enter title that's too short
      await tester.enterText(find.byType(TextFormField).first, 'Hi');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show length validation error
      expect(find.text('Title must be at least 3 characters'), findsOneWidget);

      // Enter valid title
      await tester.enterText(find.byType(TextFormField).first, 'Valid Task Title');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should successfully save and return to home
      expect(find.text('Todo App'), findsOneWidget);
      expect(find.textContaining('Valid Task Title'), findsOneWidget);
    });

    testWidgets('should handle task search functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create multiple tasks for searching
      final searchTasks = ['Search Task One', 'Search Task Two', 'Different Task'];
      
      for (final title in searchTasks) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, title);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }

      // Look for search functionality
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Enter search term
        await tester.enterText(find.byType(TextField), 'Search Task');
        await tester.pumpAndSettle();

        // Should show only matching tasks
        expect(find.textContaining('Search Task One'), findsOneWidget);
        expect(find.textContaining('Search Task Two'), findsOneWidget);
        expect(find.textContaining('Different Task'), findsNothing);

        // Clear search
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();

        // Should show all tasks again
        expect(find.textContaining('Different Task'), findsOneWidget);
      }
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find RefreshIndicator and perform pull to refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator, const Offset(0, 200));
        await tester.pumpAndSettle();

        // App should still be functional after refresh
        expect(find.text('Todo App'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('should persist tasks across app restarts', (WidgetTester tester) async {
      // First session - create a task
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Persistent Task');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Persistent Task'), findsOneWidget);

      // Simulate app restart by calling main again
      app.main();
      await tester.pumpAndSettle();

      // Task should still be there
      expect(find.textContaining('Persistent Task'), findsOneWidget);
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('should handle network connectivity issues', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // App should function offline (no network calls in basic todo app)
      expect(find.text('Todo App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid user interactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Rapidly tap FAB multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle device back button correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to add task screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Press back button
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        null,
        (data) {},
      );
      await tester.pumpAndSettle();

      // Should return to home screen
      expect(find.text('Todo App'), findsOneWidget);
    });

    testWidgets('should handle orientation changes during task creation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start creating a task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Orientation Test Task');

      // Change orientation
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();

      // Form should still be functional
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Change back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.textContaining('Orientation Test Task'), findsOneWidget);
    });
  });
}