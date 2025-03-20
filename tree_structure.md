# Todo App Project Structure

```
todo_app/
├── .gitignore                     # Git ignore file
├── .metadata                      # Flutter metadata
├── LICENSE                        # MIT License
├── README.md                      # Project overview
├── analysis_options.yaml          # Dart analysis options
├── associative-table.md           # Database schema documentation
├── features.md                    # Feature specifications
├── pubspec.yaml                   # Package dependencies
├── technical-details.md           # Technical implementation details
├── todo_app.iml                   # IntelliJ module file
├── tree_structure.md              # Project structure documentation
├── lib/                           # Source code
│   ├── main.dart                  # Application entry point
│   ├── app.dart                   # Main app configuration
│   ├── routes.dart                # Navigation routes
│   ├── common/                    # Common utilities and widgets
│   │   ├── constants/
│   │   │   └── app_constants.dart # Application constants
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Theme configuration
│   │   └── widgets/               # Reusable widgets
│   │       ├── category_chip.dart # Category display widget
│   │       ├── empty_state.dart   # Empty state widget
│   │       └── priority_badge.dart# Priority indicator widget
│   ├── core/                      # Core functionality
│   │   ├── database/              # Database implementation
│   │   │   ├── database_helper.dart# Database initialization
│   │   │   └── repository/        # Data access repositories
│   │   │       ├── category_repository.dart
│   │   │       ├── notification_repository.dart
│   │   │       └── task_repository.dart
│   │   └── notifications/         # Notification system
│   │       ├── models/
│   │       │   └── notification_settings.dart
│   │       └── notification_service.dart
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
│       └── statistics/            # Statistics and reporting
│           ├── screens/
│           │   └── statistics_screen.dart # Statistics dashboard
│           ├── utils/
│           │   └── statistics_helpers.dart # Helper functions for statistics
│           └── widgets/
│               ├── chart_cards.dart       # Chart components
│               └── summary_card.dart      # Summary statistics card
└── android/                      # Android platform code
    └── ...
└── ios/                          # iOS platform code
    └── ...
└── web/                          # Web platform code
    └── ...
└── linux/                        # Linux platform code
    └── ...
└── macos/                        # macOS platform code
    └── ...
└── windows/                      # Windows platform code
    └── ...
```

## Key Components

### Core Modules

- **Database Layer**: SQLite implementation with repository pattern
  - `DatabaseHelper`: Central database configuration
  - Repositories: Entity-specific data access (Task, Category, Notification)

- **Notification System**: Local notification implementation
  - `NotificationService`: Handles scheduling and management
  - `NotificationSetting`: Model for notification preferences

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

- **Statistics**: Analytics and reporting
  - Screens: Dashboard with charts and metrics
  - Utils: Helper functions for statistics calculations
  - Widgets: Chart and summary components

### Common Elements

- **Constants**: Application-wide constants
- **Theme**: Styling and appearance configuration
- **Widgets**: Shared UI components

### Navigation

- **Routes**: Centralized navigation configuration