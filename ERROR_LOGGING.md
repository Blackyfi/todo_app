# Error Logging System

The Todo App includes a comprehensive, production-ready error logging system that captures and stores runtime errors, warnings, and informational messages for debugging and monitoring purposes. This document explains how the error logging system works and how to use it effectively.

## Overview

The error logging system consists of several integrated components:

1. **LoggerService**: A singleton service that handles writing logs to files with different severity levels
2. **Global Error Handling**: Captures unhandled exceptions across the entire application
3. **Repository Logging**: Tracks database operations, successes, and errors with detailed context
4. **Notification Logging**: Monitors notification scheduling and delivery with timing information
5. **Log Viewer**: A comprehensive UI for viewing, sharing, and managing log files
6. **Application Lifecycle Logging**: Tracks app initialization, service startup, and shutdown events

## Log Levels & Severity

The system supports three log levels with specific use cases:

| Level | Color Code | Description | Usage Examples |
|-------|------------|-------------|----------------|
| **ERROR** | 🔴 Red | Critical issues that prevent functionality from working correctly | Database failures, API errors, crash reports, initialization failures |
| **WARNING** | 🟡 Yellow | Potential issues that don't prevent core functionality but may indicate problems | Edge cases, deprecations, permission issues, fallback usage |
| **INFO** | 🟢 Green | Informational messages about normal app operation | Initialization steps, user actions, state changes, successful operations |

### Log Level Guidelines

#### ERROR Level Usage

```dart
// Database connection failure
await _logger.logError('Database initialization failed', e, stackTrace);

// Critical service failure
await _logger.logError('Notification service failed to initialize', error, stackTrace);

// Unhandled exceptions
await _logger.logError('Uncaught exception in main application', error, stackTrace);
```

#### WARNING Level Usage

```dart
// Notification scheduling failed but task was saved
await _logger.logWarning('Notification scheduling failed, task saved without reminders');

// Permission not granted
await _logger.logWarning('Notification permissions not granted, reminders disabled');

// Fallback behavior triggered
await _logger.logWarning('Using fallback notification method due to platform limitations');
```

#### INFO Level Usage

```dart
// Successful initialization
await _logger.logInfo('Application initialized successfully');

// User actions
await _logger.logInfo('Task created: ID=$taskId, Title=$title');

// Normal operations
await _logger.logInfo('Database query completed: ${tasks.length} tasks retrieved');
```

## Advanced Log File Format

Log entries are stored in structured text files with comprehensive information:

```bash
[YYYY-MM-DD HH:MM:SS.mmm] LEVEL: Message
[Optional Stack Trace]
[Context Information]
```

### Enhanced Log Entry Examples

```bash
[2025-06-09 15:30:45.123] INFO: ===== Application Started =====
[2025-06-09 15:30:45.234] INFO: Initializing NotificationService
[2025-06-09 15:30:46.345] ERROR: Database initialization error: No such table: tasks
[2025-06-09 15:30:46.345] STACK: #0 DatabaseHelper._initDatabase (file:///app/lib/core/database/database_helper.dart:35:7)
    #1 DatabaseHelper.database (file:///app/lib/core/database/database_helper.dart:18:5)
    #2 TaskRepository.getAllTasks (file:///app/lib/core/database/repository/task_repository.dart:42:3)
[2025-06-09 15:30:47.456] WARNING: Notification permissions not granted, reminders will not work
[2025-06-09 15:30:48.567] INFO: Task created: ID=123, Title="Complete project documentation"
[2025-06-09 15:30:49.678] INFO: Notification scheduled: TaskID=123, NotificationID=12345, ScheduledFor=2025-06-10T09:00:00.000Z
```

## Intelligent Log File Management

### Dynamic File Organization

Log files are automatically organized with intelligent naming and rotation:

```bash
app_log_2025_06_09.log    # Today's log file
app_log_2025_06_08.log    # Yesterday's log file
app_log_2025_06_07.log    # Previous day's log file
```

#### File Rotation Features

- **Daily Rotation**: New log file created each day automatically
- **Size Management**: Large log files are properly handled without performance impact
- **Automatic Cleanup**: Old log files can be manually cleared through the UI
- **Cross-Platform Storage**: Consistent storage location across all platforms

### Platform-Specific Log Locations

| Platform | Log Directory Location |
|----------|------------------------|
| **Android** | `/data/data/com.example.todo_app/app_flutter/logs/` |
| **iOS** | App's Documents directory under `logs/` subdirectory |
| **Windows** | `%USERPROFILE%\Documents\todo_app\logs\` |
| **macOS** | `~/Documents/todo_app/logs/` |
| **Linux** | `~/.local/share/todo_app/logs/` |

## Comprehensive In-App Log Viewer

The built-in Log Viewer provides professional-grade log management capabilities:

### Core Features

1. **Multi-File Navigation**: Browse log files by date with easy switching
2. **Syntax Highlighting**: Color-coded log levels for easy identification
3. **Search Functionality**: Find specific entries across log files
4. **Export Options**: Multiple export formats for different use cases
5. **Sharing Integration**: Native sharing with email, messaging, and cloud services
6. **Clipboard Integration**: Copy log content for quick sharing
7. **Bulk Operations**: Clear all logs with confirmation dialogs

### Advanced Viewing Options

#### Log File List

- **Chronological Order**: Files listed from newest to oldest
- **File Size Display**: Shows approximate file sizes
- **Quick Selection**: Tap to switch between different log files
- **Auto-Load**: Most recent log file loads automatically

#### Content Display

- **Monospace Font**: Consistent formatting for easy reading
- **Selectable Text**: Copy specific log entries or ranges
- **Scroll Performance**: Optimized for large log files
- **Real-time Updates**: Live updates when viewing current day's log

### Export & Sharing Capabilities

#### Multiple Export Formats

1. **Plain Text**: Direct text sharing for immediate viewing
2. **JSON Export**: Structured data export for analysis tools
3. **Email Integration**: Direct email sharing with attachments
4. **Cloud Storage**: Share to Google Drive, Dropbox, OneDrive
5. **Messaging Apps**: Quick sharing via WhatsApp, Telegram, etc.

#### JSON Export Structure

```json
{
  "app_log_2025_06_09.log": "Log content as string...",
  "app_log_2025_06_08.log": "Log content as string...",
  "export_timestamp": "2025-06-09T15:30:45.123Z",
  "app_version": "1.0.0+1",
  "platform": "android"
}
```

## Accessing the Log Viewer

### Navigation Path

1. **Home Screen** → Tap the gear icon (⚙️) in the top-right corner
2. **Settings Screen** → Scroll to "Debugging" section
3. **View Logs** → Tap to open the comprehensive log viewer

### Quick Access Features

- **Direct Launch**: Settings screen provides immediate access
- **Error Context**: Error dialogs can link directly to relevant logs
- **Search Integration**: Find specific error messages across all files

## Comprehensive Implementation Details

### LoggerService Architecture

The `LoggerService` class provides a robust, thread-safe logging solution:

```dart
class LoggerService {
  // Singleton pattern for consistent logging
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  
  // Core logging methods with full error handling
  Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]);
  Future<void> logWarning(String message);
  Future<void> logInfo(String message);
  
  // File management methods
  Future<List<File>> getLogFiles();
  Future<void> clearLogs();
  Future<void> init(); // Automatic initialization
}
```

#### Thread Safety & Performance

- **Async Operations**: All logging operations are asynchronous to prevent UI blocking
- **Error Isolation**: Logging failures don't affect app functionality
- **Performance Optimized**: Minimal overhead for production use
- **Memory Efficient**: Proper resource management and cleanup

### Global Error Handling Integration

The app implements comprehensive error capture mechanisms:

#### Flutter Framework Errors

```dart
FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  _reportError(details.exception, details.stack);
};
```

#### Async Zone Errors

```dart
runZonedGuarded<Future<void>>(() async {
  // App initialization and execution
}, (error, stackTrace) {
  _reportError(error, stackTrace);
});
```

### Repository-Level Logging

All repository classes include comprehensive logging:

#### Task Repository Logging

```dart
Future<int> insertTask(Task task) async {
  try {
    final db = await _databaseHelper.database;
    final id = await db.insert('tasks', task.toMap());
    await _logger.logInfo('Task inserted: ID=$id, Title=${task.title}');
    return id;
  } catch (e, stackTrace) {
    await _logger.logError('Error inserting task', e, stackTrace);
    rethrow;
  }
}
```

#### Database Operation Logging

- **Operation Start**: Log the beginning of database operations
- **Success Results**: Log successful operations with relevant data
- **Error States**: Comprehensive error logging with full stack traces
- **Performance Tracking**: Operation timing for performance monitoring

### Notification System Logging

The notification system includes detailed logging for debugging:

#### Scheduling Events

```dart
await _logger.logInfo(
  'Scheduling notification: TaskID=${task.id}, NotificationID=$notificationId, '
  'ScheduledFor=${notificationTime.toIso8601String()}'
);
```

#### Permission Handling

```dart
await _logger.logWarning('Notification permissions not granted, TaskID=${task.id}');
```

#### Error Recovery

```dart
await _logger.logError('Notification scheduling failed, using fallback', e, stackTrace);
```

## Effective Usage for Debugging

### When Users Report Issues

1. **Immediate Access**: Guide users to Settings → View Logs
2. **Relevant Time Frame**: Ask users to share logs from the day the issue occurred
3. **Context Information**: Request specific error messages or timestamps
4. **Export Method**: Recommend JSON export for comprehensive analysis

### Developer Debugging Workflow

1. **Error Identification**: Search for ERROR level entries first
2. **Context Analysis**: Review INFO entries before and after errors
3. **Pattern Recognition**: Look for recurring WARNING messages
4. **Timeline Reconstruction**: Use timestamps to understand event sequences

### Log Analysis Best Practices

#### Error Investigation Process

1. **Locate Error**: Find the primary ERROR entry with stack trace
2. **Context Review**: Check surrounding INFO and WARNING entries
3. **Pattern Analysis**: Look for similar errors across different sessions
4. **Root Cause**: Trace the error back to the originating operation

#### Performance Monitoring

```bash
# Look for timing patterns
[2025-06-09 15:30:45.123] INFO: Database query started: getAllTasks
[2025-06-09 15:30:45.234] INFO: Database query completed: 1,234 tasks retrieved (111ms)

# Monitor initialization times
[2025-06-09 15:30:45.000] INFO: Application initialization started
[2025-06-09 15:30:46.500] INFO: Application initialized successfully (1.5 seconds)
```

## Security & Privacy Considerations

### Data Protection

- **Local Storage Only**: Log files are stored in app's private directory
- **No Network Transmission**: Logs are never automatically transmitted
- **User Control**: Users control when and how logs are shared
- **Sensitive Data**: Personal information is not logged (task content is limited to titles only)

### Privacy Best Practices

- **Minimal Content**: Only essential information is logged
- **No Passwords**: Authentication information is never logged
- **User Consent**: Sharing logs requires explicit user action
- **Data Minimization**: Old logs can be cleared to free storage space

## Adding Comprehensive Logging to New Features

When extending the app with new features, follow these enhanced guidelines:

### Logging Strategy

1. **Entry Points**: Log the start of significant operations
2. **Success Paths**: Log successful completion with relevant metrics
3. **Error Paths**: Always log errors with full stack traces
4. **Context Information**: Include relevant IDs, parameters, and state information

### Implementation Examples

#### Service Initialization

```dart
Future<void> initializeService() async {
  try {
    await _logger.logInfo('MyService initialization started');
    // ... initialization logic ...
    await _logger.logInfo('MyService initialized successfully');
  } catch (e, stackTrace) {
    await _logger.logError('MyService initialization failed', e, stackTrace);
    rethrow;
  }
}
```

#### User Operations

```dart
Future<void> performUserAction(String actionType, Map<String, dynamic> parameters) async {
  try {
    await _logger.logInfo('User action started: $actionType');
    // ... operation logic ...
    await _logger.logInfo('User action completed: $actionType');
  } catch (e, stackTrace) {
    await _logger.logError('User action failed: $actionType', e, stackTrace);
    // Handle error appropriately
  }
}
```

## Best Practices for Production Logging

### Performance Considerations

1. **Async Logging**: Never block the UI thread for logging operations
2. **Error Isolation**: Logging failures should not affect app functionality
3. **Resource Management**: Properly dispose of logging resources
4. **Batch Operations**: Consider batching logs for high-frequency operations

### Content Guidelines

1. **Be Descriptive**: Log messages should provide clear context about operations
2. **Include IDs**: Always include relevant entity IDs for traceability
3. **Avoid Overlogging**: Balance detail with performance and storage considerations
4. **Consistent Format**: Use similar terminology and formatting across the app
5. **Respect Privacy**: Never log sensitive user information or authentication details

### Error Handling Integration

1. **Graceful Degradation**: App should continue functioning even if logging fails
2. **User Communication**: Provide appropriate user feedback without exposing technical details
3. **Recovery Strategies**: Implement fallback mechanisms for critical operations
4. **Monitoring**: Use logs to identify patterns and improve app reliability

The comprehensive error logging system ensures that the Todo App can be effectively debugged, monitored, and improved based on real-world usage patterns and error reports.
