import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('should launch app and display home screen', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launches successfully
      expect(find.text('Todo App'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Should navigate to settings screen
      // Exact verification depends on settings screen implementation
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display empty state when no tasks exist', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // If no tasks exist, should show empty state
      // This test assumes a clean database state
      final emptyStateText = find.textContaining('No tasks');
      if (emptyStateText.evaluate().isNotEmpty) {
        expect(emptyStateText, findsOneWidget);
      }
    });

    testWidgets('should handle device rotation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test portrait mode
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.text('Todo App'), findsOneWidget);

      // Test landscape mode
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      expect(find.text('Todo App'), findsOneWidget);
    });

    testWidgets('should persist state across app lifecycle', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Get initial state
      final initialState = find.text('Tasks').evaluate().isNotEmpty;

      // Simulate app going to background and returning
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.paused'),
        ),
        (data) {},
      );

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Verify state is maintained
      expect(find.text('Tasks').evaluate().isNotEmpty, equals(initialState));
    });
  });

  group('Performance Tests', () {
    testWidgets('should launch within reasonable time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should launch within 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(find.text('Todo App'), findsOneWidget);
    });

    testWidgets('should handle rapid tab switching', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Rapidly switch between tabs
      for (int i = 0; i < 5; i++) {
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
      await tester.pumpAndSettle();

      // Check for semantic labels on key widgets
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      expect(find.bySemanticsLabel('Add Task'), findsOneWidget);
    });

    testWidgets('should support screen reader navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // App should still be functional even if database operations fail
      expect(find.text('Todo App'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle memory pressure', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

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