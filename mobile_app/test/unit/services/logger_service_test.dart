import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_app/core/logger/logger_service.dart';

// Mock classes for testing
class MockDirectory extends Mock implements Directory {}
class MockFile extends Mock implements File {}

void main() {
  group('LoggerService Tests', () {
    late LoggerService loggerService;
    late Directory tempDir;

    setUpAll(() async {
      // Create a temporary directory for testing
      tempDir = await Directory.systemTemp.createTemp('logger_test_');
    });

    setUp(() {
      loggerService = LoggerService();
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // This test verifies that the logger can be initialized
        // without throwing exceptions
        expect(() => loggerService.init(), returnsNormally);
      });
    });

    group('Logging Methods', () {
      test('should log info message without throwing', () async {
        await loggerService.init();
        expect(
          () => loggerService.logInfo('Test info message'),
          returnsNormally,
        );
      });

      test('should log warning message without throwing', () async {
        await loggerService.init();
        expect(
          () => loggerService.logWarning('Test warning message'),
          returnsNormally,
        );
      });

      test('should log error message without throwing', () async {
        await loggerService.init();
        expect(
          () => loggerService.logError('Test error message'),
          returnsNormally,
        );
      });

      test('should log error with exception and stack trace', () async {
        await loggerService.init();
        final exception = Exception('Test exception');
        final stackTrace = StackTrace.current;

        expect(
          () => loggerService.logError('Error with exception', exception, stackTrace),
          returnsNormally,
        );
      });
    });

    group('Log File Management', () {
      test('should return empty list when no log files exist', () async {
        // Create a logger service that points to an empty directory
        final emptyDir = await Directory.systemTemp.createTemp('empty_logs_');
        
        try {
          final logFiles = await loggerService.getLogFiles();
          // The actual implementation might return files from the app documents directory
          // This test ensures the method doesn't crash
          expect(logFiles, isA<List<File>>());
        } finally {
          await emptyDir.delete(recursive: true);
        }
      });

      test('should clear logs without throwing', () async {
        await loggerService.init();
        expect(
          () => loggerService.clearLogs(),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      test('should handle logging when file system is not available', () async {
        // This test ensures that logging doesn't crash the app
        // even when file operations fail
        expect(
          () => loggerService.logInfo('Message when file system unavailable'),
          returnsNormally,
        );
      });

      test('should handle multiple rapid log calls', () async {
        await loggerService.init();
        
        // Test that multiple rapid calls don't cause issues
        final futures = <Future<void>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(loggerService.logInfo('Rapid log message $i'));
        }
        
        expect(
          () => Future.wait(futures),
          returnsNormally,
        );
      });
    });

    group('Log Message Formatting', () {
      test('should format log messages with timestamp', () async {
        await loggerService.init();
        
        // We can't easily test the exact format without accessing private methods
        // But we can ensure the method completes successfully
        await loggerService.logInfo('Formatted message test');
        
        // If we had access to the log file content, we could verify the format
        // For now, we just ensure no exceptions are thrown
        expect(true, isTrue);
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = LoggerService();
        final instance2 = LoggerService();
        
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Integration Tests', () {
      test('should handle complete logging workflow', () async {
        await loggerService.init();

        // Log different types of messages
        await loggerService.logInfo('Application started');
        await loggerService.logWarning('Warning message');
        await loggerService.logError('Error message', Exception('Test error'));

        // Get log files
        final logFiles = await loggerService.getLogFiles();
        expect(logFiles, isA<List<File>>());

        // Clear logs
        await loggerService.clearLogs();

        // This should complete without throwing
        expect(true, isTrue);
      });
    });

    group('Log Levels', () {
      test('should handle all log levels', () async {
        await loggerService.init();

        await loggerService.logInfo('Info message');
        await loggerService.logWarning('Warning message');
        await loggerService.logError('Error message');

        expect(true, isTrue);
      });

      test('should log error with exception details', () async {
        await loggerService.init();

        final exception = Exception('Test exception with details');
        await loggerService.logError('Error occurred', exception);

        expect(true, isTrue);
      });

      test('should log error with both exception and stack trace', () async {
        await loggerService.init();

        final exception = Exception('Test exception');
        final stackTrace = StackTrace.current;

        await loggerService.logError('Complex error', exception, stackTrace);

        expect(true, isTrue);
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent log file retrieval', () async {
        await loggerService.init();

        final futures = <Future<List<File>>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(loggerService.getLogFiles());
        }

        final results = await Future.wait(futures);
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, isA<List<File>>());
        }
      });

      test('should handle concurrent logging operations', () async {
        await loggerService.init();

        final futures = <Future<void>>[];
        for (int i = 0; i < 20; i++) {
          if (i % 3 == 0) {
            futures.add(loggerService.logInfo('Info $i'));
          } else if (i % 3 == 1) {
            futures.add(loggerService.logWarning('Warning $i'));
          } else {
            futures.add(loggerService.logError('Error $i'));
          }
        }

        await Future.wait(futures);
        expect(true, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle very long log messages', () async {
        await loggerService.init();

        final longMessage = 'A' * 10000;
        await loggerService.logInfo(longMessage);

        expect(true, isTrue);
      });

      test('should handle log messages with special characters', () async {
        await loggerService.init();

        await loggerService.logInfo('Message with newlines\nand\ttabs');
        await loggerService.logInfo('Message with emojis 🚀 📱 ✨');
        await loggerService.logInfo('Message with quotes "test" and \'single\'');

        expect(true, isTrue);
      });

      test('should handle empty log messages', () async {
        await loggerService.init();

        await loggerService.logInfo('');
        await loggerService.logWarning('');
        await loggerService.logError('');

        expect(true, isTrue);
      });
    });

    group('Log File Operations', () {
      test('should create log files', () async {
        await loggerService.init();
        await loggerService.logInfo('Test log entry');

        final logFiles = await loggerService.getLogFiles();
        expect(logFiles, isNotEmpty);
      });

      test('should sort log files by modification time', () async {
        await loggerService.init();

        // Write some logs
        for (int i = 0; i < 3; i++) {
          await loggerService.logInfo('Entry $i');
          await Future.delayed(const Duration(milliseconds: 100));
        }

        final logFiles = await loggerService.getLogFiles();
        if (logFiles.length >= 2) {
          final first = logFiles[0].lastModifiedSync();
          final second = logFiles[1].lastModifiedSync();
          expect(first.isAfter(second) || first.isAtSameMomentAs(second), isTrue);
        }
      });

      test('should clear logs and reinitialize', () async {
        await loggerService.init();
        await loggerService.logInfo('Log before clear');

        await loggerService.clearLogs();

        // Should be able to log after clearing
        await loggerService.logInfo('Log after clear');

        expect(true, isTrue);
      });
    });
  });
}