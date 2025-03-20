# Error Logging System

The Todo App includes a comprehensive error logging system that captures and stores runtime errors, warnings, and informational messages for debugging purposes. This document explains how the error logging system works and how to use it.

## Overview

The error logging system consists of several components:

1. **LoggerService**: A singleton service that handles writing logs to files with different severity levels
2. **Global Error Handling**: Captures unhandled exceptions across the app
3. **Repository Logging**: Tracks database operations and errors
4. **Log Viewer**: A UI for viewing, sharing, and managing log files

## Log Levels

The system supports three log levels:

- **ERROR**: Critical issues that prevent functionality from working correctly
- **WARNING**: Potential issues that don't prevent core functionality but may indicate problems
- **INFO**: Informational messages about normal app operation

## Log File Format

Log entries are stored in text files with the following format:

```
[YYYY-MM-DD HH:MM:SS] LEVEL: Message
```

For example:
```
[2025-03-20 15:30:45] INFO: Application initialization started
[2025-03-20 15:30:46] ERROR: Database initialization error: No such table: tasks
[2025-03-20 15:30:46] STACK: #0 DatabaseHelper._initDatabase (file:///app/lib/core/database/database_helper.dart:35:7)
```

## Log File Storage

Log files are stored in the application's documents directory under a `logs` subfolder. A new log file is created each day with the naming pattern:

```
app_log_YYYY_MM_DD.log
```

This ensures that logs are organized by date, making it easier to track issues over time.

## Accessing Logs

### In-App Log Viewer

The app includes a built-in Log Viewer that can be accessed from the Settings screen. The Log Viewer provides the following functionality:

1. View a list of all available log files
2. Read the contents of each log file
3. Share log files via standard share options (email, messaging, etc.)
4. Clear all log files

To access the Log Viewer:
1. Tap the gear icon (⚙️) in the top-right corner of the Home screen to open Settings
2. In the Settings screen, under the "Debugging" section, tap "View Logs"

### Finding Log Files Manually

For developers who need direct access to the log files:

1. On Android: Logs are stored in `/data/data/com.yourcompany.todo_app/app_flutter/logs/`
2. On iOS: Logs are stored in the app's Documents directory under `logs/`

Note that accessing these directories may require a jailbroken/rooted device or using Android Debug Bridge (ADB) for Android.

## Implementation Details

### LoggerService

The `LoggerService` class provides the following methods:

- `logError(String message, [dynamic error, StackTrace? stackTrace])`: Logs an error with optional error object and stack trace
- `logWarning(String message)`: Logs a warning
- `logInfo(String message)`: Logs an informational message
- `getLogFiles()`: Returns a list of all log files
- `clearLogs()`: Deletes all log files

### Global Error Handling

The app uses Flutter's error handling mechanisms to capture unhandled exceptions:

1. `FlutterError.onError` captures errors in the Flutter framework
2. `runZonedGuarded` catches errors outside of the Flutter framework

These mechanisms ensure that any unhandled exception is logged properly before the app crashes.

### Repository Logging

All repository classes (TaskRepository, CategoryRepository, NotificationRepository) include comprehensive logging for:

- Every database operation (create, read, update, delete)
- Success results with relevant data
- Error states with full stack traces

### Using Logs for Debugging

When a user reports an issue:

1. Ask them to navigate to the Log Viewer
2. Have them share the relevant log file via email or other sharing method
3. Analyze the logs to identify the issue
4. Look for ERROR entries and their corresponding stack traces

## Security Considerations

The log files may contain sensitive information like task titles and descriptions. The logs are stored in the app's private storage area and are not accessible to other apps without special permissions.

When implementing additional logging, be mindful of privacy concerns and avoid logging sensitive personal information.

## Adding More Logging

When extending the app with new features, follow these guidelines for logging:

1. Use the appropriate log level (error, warning, info)
2. Include relevant context in log messages (e.g., IDs, operation names)
3. Always catch exceptions and log them with their stack traces
4. Log the beginning and successful completion of important operations

Example:

```dart
try {
  await _logger.logInfo('Starting important operation');
  // ... perform operation ...
  await _logger.logInfo('Successfully completed operation');
} catch (e, stackTrace) {
  await _logger.logError('Failed to perform operation', e, stackTrace);
  // Handle error
}
```