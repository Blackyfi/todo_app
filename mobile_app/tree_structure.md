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
│   ├── .gitignore
│   ├── build.gradle.kts           # Project-level Gradle build script
│   ├── gradle.properties          # Gradle configuration properties
│   ├── settings.gradle.kts        # Gradle settings with Flutter plugin
│   ├── todo_app_android.iml       # Android module configuration
│   ├── app/                       # Android app module
│   │   ├── build.gradle.kts       # App-level Gradle build script with API 35 support
│   │   └── src/                   # Android source code
│   │       ├── debug/
│   │       │   └── AndroidManifest.xml # Debug manifest with internet permission
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml # Main manifest with notification permissions
│   │       │   ├── kotlin/com/example/todo_app/
│   │       │   │   └── MainActivity.kt  # Main Android activity
│   │       │   └── res/            # Android resources
│   │       │       ├── drawable/   # Launch background drawables
│   │       │       ├── drawable-v21/
│   │       │       └── values/     # Themes and styles
│   │       └── profile/
│   │           └── AndroidManifest.xml # Profile manifest
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties # Gradle wrapper configuration
├── lib/                           # Source code
│   ├── main.dart                  # Application entry point with error handling
│   ├── app.dart                   # Main app configuration with providers
│   ├── app_initializer.dart       # Application initialization service
│   ├── routes.dart                # Navigation routes
│   ├── common/                    # Common utilities and widgets
│   │   ├── constants/
│   │   │   └── app_constants.dart # Application constants and routes
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Material 3 theme configuration
│   │   └── widgets/               # Reusable widgets
│   │       ├── app_bar_with_time.dart # Custom app bar with time display
│   │       ├── category_chip.dart     # Category display widget
│   │       ├── current_time_display.dart # Real-time clock widget
│   │       ├── empty_state.dart       # Empty state widget
│   │       └── priority_badge.dart    # Priority indicator widget
│   ├── core/                      # Core functionality
│   │   ├── database/              # Database implementation
│   │   │   ├── database_config.dart   # Cross-platform database configuration
│   │   │   ├── database_helper.dart   # Database initialization with logging
│   │   │   └── repository/            # Data access repositories
│   │   │       ├── category_repository.dart    # Category CRUD operations
│   │   │       ├── notification_repository.dart # Notification settings CRUD
│   │   │       └── task_repository.dart        # Task CRUD with advanced queries
│   │   ├── logger/
│   │   │   └── logger_service.dart    # Comprehensive error logging service
│   │   ├── notifications/             # Advanced notification system
│   │   │   ├── models/
│   │   │   │   └── notification_settings.dart # Notification time options model
│   │   │   ├── notification_scheduler.dart     # Timezone-aware scheduling
│   │   │   ├── notification_service.dart       # Main service with fallback support
│   │   │   ├── notification_service_fallback.dart # Compatibility fallback
│   │   │   └── permission_handler.dart         # Android 13+ permission management
│   │   ├── providers/
│   │   │   └── time_format_provider.dart # European/American time format provider
│   │   └── settings/              # Application settings
│   │       ├── models/
│   │       │   └── auto_delete_settings.dart  # Auto-deletion configuration model
│   │       ├── repository/
│   │       │   └── auto_delete_settings_repository.dart # Settings persistence
│   │       └── services/
│   │           └── auto_delete_service.dart    # Automatic task cleanup service
│   └── features/                  # App features
│       ├── tasks/                 # Task management
│       │   ├── models/
│       │   │   └── task.dart      # Task model with priority and completion tracking
│       │   ├── screens/
│       │   │   ├── add_edit_task_screen.dart   # Task creation/editing with notifications
│       │   │   ├── home_screen.dart            # Main task list with filtering
│       │   │   └── task_details_screen.dart    # Detailed task view
│       │   ├── utils/
│       │   │   └── task_form_helpers.dart      # Form validation and utilities
│       │   └── widgets/
│       │       ├── notification_option_picker.dart # Notification timing selection
│       │       ├── task_card.dart              # Real-time updating task cards
│       │       ├── task_detail_category.dart   # Task category display
│       │       ├── task_detail_datetime.dart   # Due date/time display
│       │       ├── task_detail_description.dart # Task description display
│       │       ├── task_detail_header.dart     # Task title and priority
│       │       ├── task_detail_reminders.dart  # Notification settings display
│       │       ├── task_detail_sections.dart   # Unified detail view
│       │       ├── task_detail_status.dart     # Completion status display
│       │       └── task_form_fields.dart       # Form components
│       ├── categories/            # Category management
│       │   ├── models/
│       │   │   └── category.dart  # Category model with color support
│       │   ├── screens/
│       │   │   └── categories_screen.dart # Category management interface
│       │   └── widgets/
│       │       ├── category_dialog.dart   # Category creation/editing dialog
│       │       └── category_list_item.dart # Dismissible category list items
│       ├── settings/              # Settings management
│       │   └── screens/
│       │       ├── log_viewer_screen.dart # Comprehensive log viewing interface
│       │       └── settings_screen.dart   # App settings with notification controls
│       └── statistics/            # Statistics and reporting
│           ├── screens/
│           │   └── statistics_screen.dart # Statistics dashboard with charts
│           ├── utils/
│           │   └── statistics_helpers.dart # Statistical calculations
│           └── widgets/
│               ├── chart_cards.dart           # Chart components export
│               ├── completion_chart.dart      # Task completion pie chart
│               ├── priority_chart.dart        # Priority distribution bar chart
│               ├── category_chart.dart        # Category distribution pie chart
│               ├── weekly_tasks_card.dart     # Weekly tasks preview
│               ├── weekly_completion_chart.dart # Weekly completion bar chart
│               └── summary_card.dart          # Statistics summary
```

## Key Components

### Core Modules

- **Database Layer**: Cross-platform SQLite implementation with repository pattern
  - `DatabaseHelper`: Central database configuration with comprehensive logging
  - `DatabaseConfig`: Platform-specific database setup (Android/iOS/Desktop)
  - Repositories: Entity-specific data access with error handling and logging

- **Notification System**: Advanced local notification implementation
  - `NotificationService`: Main service with proper initialization and fallback support
  - `NotificationScheduler`: Timezone-aware scheduling with exact alarm permissions
  - `PermissionHandler`: Android 13+ compatible permission management with app settings
  - `NotificationSetting`: Flexible notification timing options including custom times

- **Logger System**: Production-ready error logging
  - `LoggerService`: Multi-level logging (ERROR/WARNING/INFO) with daily file rotation
  - Log viewer with sharing, copying, and JSON export capabilities

- **Settings Management**: Comprehensive application configuration
  - `TimeFormatProvider`: European (24h) vs American (12h) time format preferences
  - `AutoDeleteService`: Configurable cleanup of completed tasks

### Feature Modules

- **Tasks**: Complete task lifecycle management
  - Models: Task data with priority levels, categories, and completion tracking
  - Screens: Home screen with filtering, detailed task view, creation/editing interface
  - Widgets: Real-time updating task cards with overdue indicators
  - Utils: Form validation and date/time handling utilities

- **Categories**: Visual task organization
  - Models: Categories with customizable colors
  - Screens: Category management with task count display
  - Widgets: Color-coded category chips and dismissible list items

- **Statistics**: Data visualization and insights
  - Screens: Dashboard with multiple chart types
  - Utils: Statistical calculations and data aggregation
  - Widgets: Pie charts, bar charts, and summary cards using fl_chart

- **Settings**: User preferences and debugging tools
  - Enhanced settings interface with notification management
  - Comprehensive log viewer with export capabilities
  - Theme and time format preferences

### Common Elements

- **Constants**: Centralized application configuration and route definitions
- **Theme**: Material 3 design system implementation with dark/light mode support
- **Widgets**: Reusable components including real-time clock display and priority badges

### Platform Support

- **Android**: API 35 support with exact alarm permissions and notification channels
- **iOS**: Native notification support with proper permission handling
- **Desktop**: Cross-platform database support via sqflite_common_ffi

## Architecture Overview

The Todo App follows a feature-based architecture with clear separation of concerns:

1. **Presentation Layer**: Screens and widgets with proper state management
2. **Business Logic Layer**: Models, utilities, and service classes
3. **Data Access Layer**: Repository pattern with comprehensive error handling
4. **Core Infrastructure**: Cross-platform services and shared functionality

### Key Features

- **Real-time UI Updates**: Task cards update automatically for overdue status
- **Comprehensive Notification System**: Multiple timing options with fallback support
- **Advanced Filtering**: Tasks can be filtered by status, date, category, and priority
- **Data Visualization**: Statistical insights with interactive charts
- **Robust Error Handling**: Comprehensive logging with user-friendly error recovery
- **Cross-platform Compatibility**: Runs on Android, iOS, and desktop platforms
- **Accessibility**: Proper semantic markup and contrast considerations

This organization ensures:

- Maintainable and scalable codebase
- Clear component responsibilities
- Comprehensive error handling and logging
- Excellent user experience across platforms
- Easy debugging and troubleshooting capabilities

## Key Changes That were made

### Widget Layout Fixes

- **android/app/src/main/res/layout/todo_widget.xml**: Removed ScrollView (not supported in widgets), simplified layout
- **android/app/src/main/res/layout/widget_task_item.xml**: Simplified task item layout for better widget compatibility
- **android/app/src/main/kotlin/.../TodoWidgetProvider.kt**: Added better error handling and simplified task rendering
- **lib/core/widgets/models/widget_config.dart**: Reduced default maxTasks from 5 to 3 for better stability
- **lib/core/widgets/services/widget_service.dart**: Updated default configurations to use fewer tasks
- **lib/main.dart**: Updated default widget creation to use maxTasks = 3

### Critical Issues Fixed

1. **ScrollView Removal**: ScrollView is not allowed in Android widgets - replaced with simple LinearLayout
2. **Simplified Task Items**: Reduced complexity of task items to prevent widget crashes
3. **Reduced Task Count**: Limited to 3 tasks maximum for better widget performance
4. **Enhanced Error Handling**: Added comprehensive error handling in TodoWidgetProvider
5. **Layout Compatibility**: Ensured all layouts use only widget-supported views

### Next Steps

1. **Rebuild and install** the app completely
2. **Clear any existing widgets** from your home screen
3. **Add the widget again** to test the new layout
4. **Use the test button** in the app to verify widget updates
5. **Check logs** to ensure no more ScrollView errors
