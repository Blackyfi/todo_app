# Test Structure

test/
├── tree_structure.md
├── unit/
│   ├── models/
│   │   ├── category_test.dart
│   │   ├── task_test.dart
│   │   ├── auto_delete_settings_test.dart
│   │   └── widget_config_test.dart
│   ├── repositories/
│   │   ├── category_repository_test.dart
│   │   ├── task_repository_test.dart
│   │   └── widget_config_repository_test.dart
│   ├── services/
│   │   ├── auto_delete_service_test.dart
│   │   └── logger_service_test.dart
│   ├── providers/
│   │   └── time_format_provider_test.dart
│   └── utils/
│       ├── statistics_helpers_test.dart
│       └── task_form_helpers_test.dart
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   ├── add_edit_task_screen_test.dart
│   │   ├── task_details_screen_test.dart
│   │   ├── categories_screen_test.dart
│   │   ├── statistics_screen_test.dart
│   │   └── settings_screen_test.dart
│   ├── widgets/
│   │   ├── task_card_test.dart
│   │   ├── category_chip_test.dart
│   │   ├── priority_badge_test.dart
│   │   └── task_form_fields_test.dart
│   └── common/
│       ├── empty_state_test.dart
│       ├── current_time_display_test.dart
│       └── app_bar_with_time_test.dart
├── integration/
│   ├── app_integration_test.dart
│   ├── task_flow_test.dart
│   └── category_flow_test.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_repositories.dart
    └── test_data.dart
