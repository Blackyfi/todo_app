# Todo App Project Structure

```bash
todo_app/
├── .gitignore                     # Git ignore file
├── .metadata                      # Flutter metadata
├── ERROR_LOGGING.md               # Error logging system documentation
├── LICENSE                        # MIT License
├── README.md                      # Project overview
├── analysis_options.yaml          # Dart analysis options
├── associative-table.md           # Database schema documentation
├── features.md                    # Feature specifications
├── pubspec.yaml                   # Package dependencies
├── technical-details.md           # Technical implementation details
├── todo_app.iml                   # IntelliJ module file
├── tree_structure.md              # Project structure documentation
├── android/                       # Android platform configuration
│   └── app/src/main/
│       └── AndroidManifest.xml    # Android permissions and configuration
├── lib/                           # Source code
│   ├── main.dart                  # Application entry point
│   ├── app.dart                   # Main app configuration
│   ├── app_initializer.dart       # App initialization logic
│   ├── routes.dart                # Navigation routes
│   ├── common/                    # Common utilities and widgets
│   │   ├── constants/
│   │   │   └── app_constants.dart # Application constants
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Theme configuration
│   │   └── widgets/               # Reusable widgets
│   │       ├── app_bar_with_time.dart # Custom app bar with time display
│   │       ├── category_chip.dart # Category display widget
│   │       ├── current_time_display.dart # Current time widget
│   │       ├── empty_state.dart   # Empty state widget
│   │       └── priority_badge.dart# Priority indicator widget
│   ├── core/                      # Core functionality
│   │   ├── database/              # Database implementation
│   │   │   ├── database_config.dart # Database platform configuration
│   │   │   ├── database_helper.dart # Database initialization
│   │   │   └── repository/        # Data access repositories
│   │   │       ├── category_repository.dart
│   │   │       ├── notification_repository.dart
│   │   │       └── task_repository.dart
│   │   ├── logger/
│   │   │   └── logger_service.dart # Error logging service
│   │   ├── notifications/         # Notification system
│   │   │   ├── models/
│   │   │   │   └── notification_settings.dart
│   │   │   ├── notification_service.dart # Main notification service
│   │   │   ├── notification_scheduler.dart # Notification scheduling logic
│   │   │   └── permission_handler.dart # Permission management
│   │   ├── providers/
│   │   │   └── time_format_provider.dart # Time format state management
│   │   └── settings/              # Application settings
│   │       ├── models/
│   │       │   └── auto_delete_settings.dart
│   │       ├── repository/
│   │       │   └── auto_delete_settings_repository.dart
│   │       └── services/
│   │           └── auto_delete_service.dart
│   └── features/                  # App features
│       ├── tasks/                 # Task management
│       │   ├── models/
│       │   │   └── task.dart      # Task data model
│       │   ├── screens/
│       │   │   ├── add_edit_task_screen.dart # Task creation/editing
│       │   │   ├── home_screen.dart          # Main task list
│       │   │   └── task_details_screen.dart  # Task details
│       │   ├── utils/
│       │   │   └── task_form_helpers.dart    # Helper functions for task forms
│       │   └── widgets/
│       │       ├── notification_option_picker.dart # Notification selection UI
│       │       ├── task_card.dart             # Task list item
│       │       ├── task_detail_sections.dart  # Task detail UI components
│       │       └── task_form_fields.dart      # Form fields for task creation/editing
│       ├── categories/            # Category management
│       │   ├── models/
│       │   │   └── category.dart  # Category data model
│       │   ├── screens/
│       │   │   └── categories_screen.dart # Category management screen
│       │   └── widgets/
│       │       ├── category_dialog.dart   # Dialog for adding/editing categories
│       │       └── category_list_item.dart # Category list item
│       ├── settings/              # Settings management
│       │   └── screens/
│       │       ├── log_viewer_screen.dart # Log viewing interface
│       │       └── settings_screen.dart   # App settings screen with notification testing
│       └── statistics/            # Statistics and reporting
│           ├── screens/
│           │   └── statistics_screen.dart # Statistics dashboard
│           ├── utils/
│           │   └── statistics_helpers.dart # Helper functions for statistics
│           └── widgets/
│               ├── chart_cards.dart       # Chart components
│               ├── completion_chart.dart  # Completion statistics chart
│               ├── priority_chart.dart    # Priority distribution chart
│               ├── category_chart.dart    # Category distribution chart
│               ├── weekly_tasks_card.dart # Weekly tasks overview
│               ├── weekly_completion_chart.dart # Weekly completion trends
│               └── summary_card.dart      # Summary statistics card
└── packages/                     # Local package dependencies
    └── flutter_local_notifications-16.3.3/ # Local notifications package
```

## Key Components

### Core Modules

- **Database Layer**: SQLite implementation with repository pattern
  - `DatabaseHelper`: Central database configuration
  - `DatabaseConfig`: Platform-specific database setup
  - Repositories: Entity-specific data access (Task, Category, Notification)

- **Notification System**: Enhanced local notification implementation
  - `NotificationService`: Handles scheduling and management with proper initialization
  - `NotificationScheduler`: Precise notification scheduling with timezone support
  - `PermissionHandler`: Comprehensive permission management for Android 13+
  - `NotificationSetting`: Model for notification preferences

- **Logger System**: Comprehensive error logging functionality
  - `LoggerService`: Centralized logging with multiple severity levels
  - Log file management and viewer interface

- **Settings Management**: Application settings and preferences
  - `TimeFormatProvider`: Time format preference management
  - `AutoDeleteService`: Management of completed task cleanup

### Feature Modules

- **Tasks**: Complete task management functionality
  - Models: Data structures for tasks
  - Screens: UI for task listing, creation, editing, and viewing
  - Widgets: Reusable task-specific components
  - Utils: Helper functions for task operations

- **Categories**: Category management
  - Models: Data structures for categories
  - Screens: UI for category management
  - Widgets: Reusable category-specific components

- **Statistics**: Analytics and reporting with enhanced chart components
  - Screens: Dashboard with charts and metrics
  - Utils: Helper functions for statistics calculations
  - Widgets: Individual chart components and summary cards

- **Settings**: Enhanced application settings management
  - Settings configuration interface
  - Log viewer and management
  - Time format and theme preferences
  - **NEW**: Notification testing and debugging tools

### Common Elements

- **Constants**: Application-wide constants and configuration values
- **Theme**: Styling and appearance configuration with Material 3 support
- **Widgets**: Shared UI components used across multiple features

### Navigation

- **Routes**: Centralized navigation configuration with named routes

## Architecture Overview

The Todo App follows a feature-based architecture with a clear separation of concerns:

1. **Presentation Layer**: Screens and widgets (`features/*/screens`, `features/*/widgets`)
2. **Business Logic Layer**: Models and utilities (`features/*/models`, `features/*/utils`)
3. **Data Access Layer**: Repositories and services (`core/database/repository`, `core/services`)
4. **Core Infrastructure**: Shared functionality and configuration (`core/*`, `common/*`)

### Recent Enhancements

- **Enhanced Notification System**: Proper timezone handling, exact alarm permissions, comprehensive error handling
- **Debugging Tools**: Test notification functionality and pending notification viewer
- **Permission Management**: Android 13+ compatibility with exact alarm permissions
- **Error Recovery**: Fallback mechanisms for notification scheduling failures

This organization allows for:

- Easy navigation of the codebase
- Clear component responsibilities
- Scalable feature development
- Maintainable and testable code structure
- **Enhanced debugging capabilities for notification issues**