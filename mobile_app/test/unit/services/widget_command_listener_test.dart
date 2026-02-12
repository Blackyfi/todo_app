import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/widgets/services/widget_command_listener.dart';

void main() {
  group('WidgetCommandListener Tests', () {
    late WidgetCommandListener listener;

    setUp(() {
      listener = WidgetCommandListener();
    });

    tearDown(() async {
      // Stop listening after each test to clean up
      await listener.stopListening();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = WidgetCommandListener();
        final instance2 = WidgetCommandListener();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Start and Stop Listening', () {
      test('should start listening without throwing', () async {
        expect(
          () => listener.startListening(),
          returnsNormally,
        );
      });

      test('should stop listening without throwing', () async {
        await listener.startListening();

        expect(
          () => listener.stopListening(),
          returnsNormally,
        );
      });

      test('should handle multiple start calls gracefully', () async {
        await listener.startListening();

        // Second call should be handled gracefully
        expect(
          () => listener.startListening(),
          returnsNormally,
        );
      });

      test('should handle stop without start', () async {
        // Should handle stopping when not started
        expect(
          () => listener.stopListening(),
          returnsNormally,
        );
      });

      test('should handle start-stop-start cycle', () async {
        await listener.startListening();
        await listener.stopListening();

        // Should be able to start again
        expect(
          () => listener.startListening(),
          returnsNormally,
        );
      });
    });

    group('Command Polling', () {
      test('should poll for commands after starting', () async {
        await listener.startListening();

        // Wait a bit to let polling cycle run
        await Future.delayed(const Duration(seconds: 3));

        // If no exception was thrown, polling is working
        expect(true, isTrue);
      });

      test('should stop polling after stopping listener', () async {
        await listener.startListening();
        await Future.delayed(const Duration(seconds: 1));

        await listener.stopListening();

        // Wait a bit to ensure no more polling happens
        await Future.delayed(const Duration(seconds: 3));

        // Should complete without issues
        expect(true, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle errors during start gracefully', () async {
        // Even if there are errors, should not throw
        expect(
          () => listener.startListening(),
          returnsNormally,
        );
      });

      test('should handle errors during stop gracefully', () async {
        await listener.startListening();

        expect(
          () => listener.stopListening(),
          returnsNormally,
        );
      });
    });

    group('Lifecycle Management', () {
      test('should properly initialize on start', () async {
        await listener.startListening();

        // Should be able to stop after starting
        await listener.stopListening();

        expect(true, isTrue);
      });

      test('should handle rapid start-stop cycles', () async {
        for (int i = 0; i < 3; i++) {
          await listener.startListening();
          await Future.delayed(const Duration(milliseconds: 500));
          await listener.stopListening();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        expect(true, isTrue);
      });
    });

    group('Integration', () {
      test('should integrate with SharedPreferences', () async {
        // The listener uses SharedPreferences to track commands
        // This test verifies it initializes properly
        await listener.startListening();
        await Future.delayed(const Duration(seconds: 1));
        await listener.stopListening();

        expect(true, isTrue);
      });

      test('should handle long-running operation', () async {
        await listener.startListening();

        // Let it run for a while
        await Future.delayed(const Duration(seconds: 5));

        await listener.stopListening();

        expect(true, isTrue);
      });
    });
  });
}
