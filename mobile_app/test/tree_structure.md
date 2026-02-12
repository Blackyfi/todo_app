# Test Structure

test/
├── tree_structure.md
├── unit/
│   ├── models/
│   │   ├── category_test.dart
│   │   ├── task_test.dart
│   │   ├── notification_settings_test.dart
│   │   ├── auto_delete_settings_test.dart
│   │   └── widget_config_test.dart
│   ├── services/
│   │   ├── auto_delete_service_test.dart
│   │   └── logger_service_test.dart
│   ├── providers/
│   │   └── time_format_provider_test.dart
│   ├── utils/
│   │   ├── statistics_helpers_test.dart
│   │   └── task_form_helpers_test.dart
│   └── widget/
│       ├── screens/
│       │   └── home_screen_test.dart
│       └── widgets/
│           └── task_card_test.dart
├── integration/
│   ├── app_integration_test.dart
│   └── task_flow_test.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_repositories.dart
    └── test_data.dart
