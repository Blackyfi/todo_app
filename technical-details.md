# ToDo App - Technical Details

## Architecture

### Project Structure
The app follows a feature-based architecture pattern with clear separation of concerns:
- `lib/common`: Shared components, constants, themes, and widgets
- `lib/core`: Core functionality like database handling and notifications
- `lib/features`: Feature modules (tasks, categories, statistics)

### State Management
- Stateful widgets for screen-level state management
- Repository pattern for data access

## Code Standards

### Import Conventions
All imports follow a strict aliasing pattern to prevent name conflicts and improve readability:
```dart
import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
```

Absolute limit of 200 lines of code per .dart file.

### Naming Conventions
- Files: snake_case.dart
- Classes: PascalCase
- Variables and methods: camelCase
- Constants: SCREAMING_SNAKE_CASE or camelCase within constant classes

## Database Implementation

### SQLite Integration
- Uses `sqflite` package for local database operations
- Database operations are abstracted through repository pattern:
  - `CategoryRepository`
  - `TaskRepository`
  - `NotificationRepository`

### Data Models
Core data models with corresponding database tables:
- `Task`: Represents a to-do item with properties like title, description, due date, priority
- `Category`: Represents task categories with name and color
- `NotificationSetting`: Stores notification preferences for tasks

### Repository Pattern
Each entity has a dedicated repository that handles:
- CRUD operations
- Custom queries (by category, priority, date, etc.)
- Data transformation between database and application models

## UI Framework

### Material Design 3
- Implemented using Flutter's Material 3 components
- Dynamic color theming based on system preference
- Support for light and dark themes

### Custom Components
- `CategoryChip`: Visual representation of categories
- `PriorityBadge`: Visual indicator for task priority
- `TaskCard`: Comprehensive card view for tasks
- `EmptyState`: Consistent empty state representation

## Notifications

### Local Notifications
- Using `flutter_local_notifications` package
- Support for scheduled notifications based on task due dates
- Multiple notification settings per task

### Notification Scheduling
- Timezone-aware scheduling
- Calculation of notification times based on user preferences
- Automatic cancellation when tasks are deleted

## Performance Optimizations

### Database Efficiency
- Use of indices for frequently queried fields
- Batch operations for bulk updates
- Proper transaction handling

### UI Rendering
- Efficient list rendering with proper keys
- Minimizing unnecessary rebuilds
- Responsive layouts for different screen sizes

## Dependencies

### Core Dependencies
- **sqflite (^2.3.2)**: Local SQLite database
- **flutter_local_notifications (^16.0.1)**: Push notifications
- **intl (^0.19.0)**: Localization and date formatting
- **fl_chart (^0.66.2)**: Chart visualizations for statistics
- **shared_preferences (^2.2.2)**: Simple data persistence
- **timezone (^0.9.2)**: Timezone handling for notifications

### Development Dependencies
- **flutter_lints (^5.0.0)**: Linting rules for code quality