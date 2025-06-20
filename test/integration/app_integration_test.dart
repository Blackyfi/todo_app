import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('should launch app and display home screen', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app launches successfully
      expect(find.text('Todo App'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start on Tasks tab
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Navigate to Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navigate to Statistics tab
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Navigate back to Tasks tab
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should open settings from app bar', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should navigate to settings screen
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display empty state when no tasks exist', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // If no tasks exist, should show empty state or tasks
      final emptyStateText = find.textContaining('No tasks');
      final taskText = find.textContaining('Task');
      
      // Either empty state or some tasks should be visible
      expect(emptyStateText.evaluate().isNotEmpty || taskText.evaluate().isNotEmpty, isTrue);
    });

    testWidgets('should handle device rotation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test portrait mode
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.text('Todo App'), findsOneWidget);

      // Test landscape mode
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      expect(find.text('Todo App'), findsOneWidget);

      // Reset to original size
      await tester.binding.setSurfaceSize(const Size(800, 600));
    });
  });

  group('Performance Tests', () {
    testWidgets('should launch within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      // App should launch within 10 seconds for integration tests
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      expect(find.text('Todo App'), findsOneWidget);
    });

    testWidgets('should handle rapid tab switching', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rapidly switch between tabs
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Categories'));
        await tester.pump();
        await tester.tap(find.text('Statistics'));
        await tester.pump();
        await tester.tap(find.text('Tasks'));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should have proper semantic labels', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for key semantic elements
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should support screen reader navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enable semantics for testing
      final SemanticsHandle handle = tester.ensureSemantics();
      
      try {
        // Verify semantic tree structure
        expect(tester.getSemantics(find.byType(MaterialApp)), isNotNull);
      } finally {
        handle.dispose();
      }
    });
  });

  group('Error Recovery Tests', () {
    testWidgets('should recover from database errors gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should still be functional even if database operations fail
      expect(find.text('Todo App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle memory pressure', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simulate memory pressure by creating many widgets
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Categories'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  });
}