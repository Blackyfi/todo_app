# Todo App - Technical Details

## Architecture Overview

The Todo App follows a feature-based architecture with a clean separation of concerns. This architecture is designed to be maintainable, testable, and scalable as the application grows.

### Project Structure

The application is organized by feature rather than by type:

```bash
lib/
├── common/       # Shared components, constants, themes, widgets
├── core/         # Core functionality (database, notifications, logging)
└── features/     # Feature modules (tasks, categories, statistics)
```

Each feature contains its own:

- Models (data structures)
- Screens (UI components)
- Widgets (reusable UI elements)
- Utils (helper functions)

### Design Patterns

The app employs several design patterns:

1. **Repository Pattern**: Abstracts data access logic
2. **Singleton Pattern**: Used for services that should have only one instance
3. **Factory Pattern**: Used for creating instances of models from different data sources
4. **Observer Pattern**: Used with ChangeNotifier for state management

### State Management

The application uses a pragmatic approach to state management:

- **Stateful Widgets**: For local UI state
- **Provider**: For time format preferences
- **Repository Pattern**: For data access and persistence

## Code Standards & Conventions

### Import Conventions

All imports follow a strict aliasing pattern to prevent name conflicts and improve readability:

```dart
import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
```

### Code Organization

- Absolute limit of 200 lines of code per .dart file
- Each class has a single responsibility
- Related functionality is grouped together
- Private methods and variables are prefixed with underscore

### Naming Conventions

- **Files**: snake_case.dart
- **Classes**: PascalCase
- **Variables and methods**: camelCase
- **Constants**:
  - SCREAMING_SNAKE_CASE for top-level constants
  - camelCase within constant classes

## Database Implementation

### SQLite Integration

The app uses SQLite for local data storage through the `sqflite` package:

- **Database Version**: 1
- **Database Name**: todo_app.db
- **Foreign Key Support**: Enabled

### Database Schema

The database consists of four main tables:

1. **categories**: Stores category information
2. **tasks**: Stores task information
3. **notificationSettings**: Stores notification preferences
4. **autoDeleteSettings**: Stores settings for automatic deletion of completed tasks

### Repository Pattern

Each entity has a dedicated repository that handles:

- CRUD operations (Create, Read, Update, Delete)
- Custom queries (filter by category, priority, date, etc.)
- Data transformation between database and application models
- Error handling and logging

Example repositories:

- `TaskRepository`
- `CategoryRepository`
- `NotificationRepository`

## UI Framework

### Material Design 3

The app implements Material Design 3 principles:

- **Dynamic Color**: Colors adapt based on device theme
- **Component Styling**: Updated Material 3 component designs
- **Typography**: Material 3 type scale
- **Elevation**: Updated elevation system with container surfaces

### Responsive Design

The UI adapts to different screen sizes:

- Responsive layouts with flexible widgets
- Size-aware components
- Appropriate spacing and padding for different form factors
- Appropriate spacing and padding for different form factors

### Custom Components

The app features several custom reusable UI components:

- `CategoryChip`: Visual representation of categories
- `PriorityBadge`: Visual indicator for task priority levels
- `TaskCard`: Card view for task items in lists
- `EmptyState`: Consistent empty state UI pattern
- `AppBarWithTime`: Custom app bar with current time display

## Notification System

### Local Notifications

The app uses `flutter_local_notifications` package to manage notifications:

- **Channel Creation**: Platform-specific notification channels
- **Scheduling**: Time-based notification scheduling
- **Permissions**: Automated permission handling

### Notification Features

- **Multiple Settings**: Each task can have multiple notification settings
- **Flexible Timing**: Options like "15 minutes before", "1 day before", etc.
- **Custom Time**: Option to set a custom notification time

### Scheduling Logic

- **Timezone Handling**: Using the timezone package for accurate scheduling
- **Auto-Calculation**: Times are calculated based on due date and notification preference
- **Error Handling**: Robust error handling for scheduling failures

## Performance Optimizations

### Database Efficiency

- **Indexing**: Key fields are indexed for faster queries
- **Transactions**: Used for operations that require multiple changes
- **Batch Operations**: For bulk inserts or updates
- **Query Optimization**: Specific queries to minimize data transfer

### UI Performance

- **Widget Keys**: Proper use of keys for efficient list updates
- **Lazy Loading**: Load on demand where appropriate
- **Minimal Rebuilds**: Careful state management to avoid unnecessary rebuilds

### Memory Management

- **Image Optimization**: Appropriate image resolutions and formats
- **Proper Disposal**: Resources are properly disposed when no longer needed
- **Widget Tree Optimization**: Minimize unnecessary widget nesting

## Error Handling & Logging

### Global Error Handling

- **Unhandled Exceptions**: Captured using FlutterError.onError and runZonedGuarded
- **Error Recovery**: Attempt to recover from non-fatal errors
- **User Feedback**: Appropriate error messages for users

### Comprehensive Logging

- **LoggerService**: Centralized logging service
- **Log Levels**: ERROR, WARNING, INFO
- **Structured Logs**: Timestamps, severity levels, and contextual information
- **Log Files**: Daily log files for easier debugging

## Testing Strategy

### Unit Tests

- Repository methods
- Model transformations
- Utility functions

### Widget Tests

- Form validation
- UI component behavior
- Navigation logic

### Integration Tests

- End-to-end task creation and management
- Database operations
- Notification scheduling

## Dependencies

### Core Dependencies

- **sqflite (^2.3.2)**: Local SQLite database
- **sqflite_common_ffi (^2.3.2+1)**: SQLite support for desktop platforms
- **flutter_local_notifications (^16.0.1)**: Push notifications
- **intl (^0.20.2)**: Localization and date formatting
- **fl_chart (^0.70.2)**: Chart visualizations for statistics
- **shared_preferences (^2.2.2)**: Simple data persistence
- **timezone (^0.9.2)**: Timezone handling for notifications
- **path_provider (^2.1.2)**: File system path access
- **provider (^6.1.1)**: Simple state management
- **share_plus (^10.1.4)**: Content sharing functionality

### Development Dependencies

- **flutter_lints (^5.0.0)**: Linting rules for code quality

## Platform Support

The application is designed to run on multiple platforms:

- **Mobile**: Android and iOS
- **Desktop**: Windows, macOS, and Linux
Each platform has specific optimizations and configurations to ensure the best user experience.

Each platform has specific optimizations and configurations to ensure the best user experience.
