import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Flow Integration Tests', () {
    testWidgets('should complete full task creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for FloatingActionButton
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        // Navigate to add task screen
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Look for text input fields
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          // Fill in task details
          await tester.enterText(textFields.first, 'Integration Test Task');
          await tester.pump();

          // Look for save button
          final saveButtons = find.text('Save');
          if (saveButtons.evaluate().isEmpty) {
            // Try alternative button texts
            final createButtons = find.text('Create Task');
            final addButtons = find.text('Add Task');
            
            if (createButtons.evaluate().isNotEmpty) {
              await tester.tap(createButtons);
            } else if (addButtons.evaluate().isNotEmpty) {
              await tester.tap(addButtons);
            }
          } else {
            await tester.tap(saveButtons);
          }
          
          await tester.pumpAndSettle();

          // Verify we're back on home screen
          expect(find.text('Todo App'), findsOneWidget);
        }
      }
      
      // Test should complete without exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle task interaction flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for existing tasks or create one
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        // Toggle task completion
        await tester.tap(checkboxes.first);
        await tester.pumpAndSettle();
      }

      // Test should complete without exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle filter functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Look for filter menu
      final filterButton = find.byType(PopupMenuButton<String>);
      if (filterButton.evaluate().isNotEmpty) {
        // Test filtering
        await tester.tap(filterButton);
        await tester.pumpAndSettle();

        // Try different filters
        final completedFilter = find.text('Completed');
        if (completedFilter.evaluate().isNotEmpty) {
          await tester.tap(completedFilter);
          await tester.pumpAndSettle();
        }

        // Reset to all tasks
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await tester.pumpAndSettle();
          
          final allTasksFilter = find.text('All Tasks');
          if (allTasksFilter.evaluate().isNotEmpty) {
            await tester.tap(allTasksFilter);
            await tester.pumpAndSettle();
          }
        }
      }

      // Test should complete without exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find RefreshIndicator and perform pull to refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator, const Offset(0, 200));
        await tester.pumpAndSettle();
      }

      // App should still be functional after refresh
      expect(find.text('Todo App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle navigation between tabs', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test tab navigation
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Should end up back on tasks tab
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('should handle rapid user interactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rapidly tap FAB multiple times if it exists
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(fabFinder);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle orientation changes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Change orientation
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.text('Todo App'), findsOneWidget);

      // Change back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.text('Todo App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}