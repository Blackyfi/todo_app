todo_app/
├── ...
├── lib/
│   ├── main.dart                  # App entry point
│   ├── app.dart                   # App configuration
│   ├── common/                    # Common utilities and widgets
│   │   ├── constants/             # App constants
│   │   ├── theme/                 # Theme configuration
│   │   └── widgets/               # Reusable widgets
│   ├── core/                      # Core functionality
│   │   ├── database/              # Database implementation
│   │   │   └── repository/        # Repository implementations
│   │   └── notifications/         # Notification system
│   ├── features/                  # App features
│   │   ├── tasks/                 # Task management
│   │   │   ├── models/            # Task data models
│   │   │   ├── screens/           # UI screens for tasks
│   │   │   ├── widgets/           # Task-specific widgets
│   │   │   └── services/          # Task services
│   │   ├── categories/            # Category management
│   │   │   ├── models/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── statistics/            # Statistics and reporting
│   │       ├── models/
│   │       ├── screens/
│   │       └── widgets/
│   └── routes.dart                # App navigation routes
├── test/                          # Test files
│   ├── unit/                      # Unit tests
│   ├── widget/                    # Widget tests
│   └── integration/               # Integration tests
├── ...
└── associative_table.md           # Database schema documentation