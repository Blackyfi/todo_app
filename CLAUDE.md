# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a monorepo containing:
- **mobile_app/**: Flutter-based cross-platform task management application (main component)
- **server/**: Currently empty placeholder for future backend services

The primary codebase is the Flutter mobile app supporting Android, iOS, Windows, macOS, Linux, and Web platforms.

## Development Commands

### Setup & Dependencies
```bash
cd mobile_app
flutter pub get                          # Install dependencies
flutter pub deps                         # Check dependency tree
```

### Running the Application
```bash
cd mobile_app
flutter run                              # Run on default device
flutter run -d android                   # Run on Android
flutter run -d ios                       # Run on iOS
flutter run -d windows                   # Run on Windows
flutter run -d macos                     # Run on macOS
flutter run -d linux                     # Run on Linux
flutter run -d chrome                    # Run as web app
```

### Build for Production
```bash
cd mobile_app
flutter build apk --release              # Android APK
flutter build appbundle --release        # Android App Bundle (Play Store)
flutter build ios --release              # iOS (requires Xcode)
flutter build windows --release          # Windows executable
flutter build macos --release            # macOS application
flutter build linux --release            # Linux executable
flutter build web --release              # Web application
```

### Code Quality & Testing
```bash
cd mobile_app
flutter analyze                          # Static analysis
flutter format .                         # Format code
flutter test                             # Run all tests
flutter test test/unit/                  # Run unit tests only
flutter test test/integration/           # Run integration tests only
flutter test test/unit/services/widget_service_test.dart  # Run specific test

# Code generation for Riverpod
flutter packages pub run build_runner build              # Generate once
flutter packages pub run build_runner build --delete-conflicting-outputs  # Force rebuild
flutter packages pub run build_runner watch              # Watch mode
```

### Maintenance
```bash
cd mobile_app
flutter clean && flutter pub get         # Clean build artifacts and reinstall
flutter doctor                           # Check Flutter installation
flutter pub outdated                     # Check for package updates
```

## Architecture Overview

### State Management
- **Provider**: Used for app-wide state (TimeFormatProvider, SecurityProvider)
- **Riverpod**: Enhanced reactive state management for widgets (widget_providers.dart)
- **Repository Pattern**: Data access layer isolating business logic from database operations

### Database Layer
- **SQLite**: Local database (sqflite for mobile, sqflite_common_ffi for desktop)
- **Database File**: `todo_app.db` with tables: `tasks`, `categories`, `notificationSettings`, `shoppingItems`, `widgetConfigs`, `autoDeleteSettings`
- **Repositories**: Separate repository classes for each domain (TaskRepository, CategoryRepository, NotificationRepository, ShoppingRepository, WidgetConfigRepository, AutoDeleteSettingsRepository)
- **DatabaseHelper**: Singleton pattern managing database lifecycle and schema creation
- **Foreign Keys**: Enabled with cascade operations (tasks reference categories)

### Core Services (Singletons)
All core services follow the singleton pattern:
- **LoggerService**: Multi-level logging (ERROR, WARNING, INFO) with daily log rotation
- **NotificationService**: Cross-platform notifications with timezone support and Android 13+ permission handling
- **SecurityService**: AES-256-GCM encryption, PBKDF2 key derivation, biometric auth
- **WidgetService**: Home screen widget management with platform channels
- **AutoDeleteService**: Configurable cleanup of completed tasks
- **SharingManager/SecureSharing**: Task import/export with QR codes

### Feature Organization
Features follow a modular structure with screens/widgets/models/utils:
- **tasks/**: Core task management (home screen, task details, add/edit forms)
- **categories/**: Category management with color coding
- **statistics/**: Analytics dashboard with fl_chart visualizations
- **security/**: Password/PIN protection, biometric unlock, encryption info screens
- **settings/**: User preferences, log viewer, notification settings
- **widgets/**: Home screen widget creation and management
- **shopping/**: Shopping list feature

### Navigation
- Global navigator key in main.dart for programmatic navigation
- Route definitions in routes.dart
- Deep linking support for widget actions

### Platform Channels
- **Method Channel**: `com.example.todo_app/widget` for bidirectional widget communication
- **Event Channel**: `com.example.todo_app/widget_events` for real-time widget updates
- iOS/Android native code handles widget rendering and user interactions

## Key Technical Patterns

### Security Implementation
- Password protection uses AES-256-GCM with PBKDF2 (100,000 iterations)
- Credentials stored in iOS Keychain / Android KeyStore
- Widgets automatically disabled when security is enabled
- Biometric auth (fingerprint/face) available as quick unlock

### Notification Scheduling
- Uses timezone package for accurate cross-timezone scheduling
- Android 13+ requires exact alarm permissions (handled by PermissionHandler)
- Fallback to approximate timing when exact alarms unavailable
- Multiple reminder options: at time, 15/30 min before, 1 hour/day before, custom

### Widget System
- home_widget package for cross-platform widget support
- workmanager for background widget updates
- Widget configs stored in database and synchronized via SharedPreferences
- Widgets disabled automatically when app security is enabled
- Real-time updates via EventChannel (primary) with polling fallback

### Error Handling
- Global error catching in main.dart with runZonedGuarded
- All repository methods have comprehensive try-catch with logging
- Error stack traces logged to daily files in app documents directory
- User-facing error dialogs with recovery options

## Important Files & Paths

### Entry Points
- `mobile_app/lib/main.dart`: Application entry with error handling setup
- `mobile_app/lib/app.dart`: Main app widget with providers and theme configuration
- `mobile_app/lib/app_initializer.dart`: Centralized initialization logic
- `mobile_app/lib/routes.dart`: Named route definitions

### Core Infrastructure
- `mobile_app/lib/core/database/database_helper.dart`: Database singleton and schema
- `mobile_app/lib/core/logger/logger_service.dart`: Logging infrastructure
- `mobile_app/lib/core/notifications/notification_service.dart`: Notification handling
- `mobile_app/lib/core/security/services/security_service.dart`: Encryption and auth
- `mobile_app/lib/core/widgets/services/widget_service.dart`: Widget lifecycle management

### Models
- `mobile_app/lib/features/tasks/models/task.dart`: Task model with Priority enum
- `mobile_app/lib/features/categories/models/category.dart`: Category model
- `mobile_app/lib/core/notifications/models/notification_settings.dart`: Reminder configuration
- `mobile_app/lib/core/widgets/models/widget_config.dart`: Widget appearance settings

### Theme & Constants
- `mobile_app/lib/common/theme/app_theme.dart`: Material 3 theme configuration
- `mobile_app/lib/common/constants/app_constants.dart`: App-wide constants

## Platform-Specific Considerations

### Android
- Minimum SDK: API 21 (Android 5.0)
- Notification channels required for API 26+
- Exact alarm permission required for API 31+ (Android 12+)
- Widget implementation in android/app/src/main/kotlin/

### iOS
- Minimum deployment: iOS 12
- App groups required for widget data sharing: `group.com.example.todo_app`
- Widget implementation in ios/WidgetExtension/
- Keychain used for secure credential storage

### Desktop (Windows/macOS/Linux)
- Uses sqflite_common_ffi for database operations
- desktop_notifications package for system notifications
- Platform-specific initialization in DatabaseConfig

### Web
- Limited notification support (browser permissions required)
- No widget support
- Local storage for preferences

## Testing Strategy

### Unit Tests
- Repository tests: Mock database operations, verify CRUD logic
- Model tests: Serialization/deserialization, copyWith methods
- Service tests: Mock dependencies, test business logic
- Provider tests: State change verification
- Widget tests: UI component behavior

### Integration Tests
- End-to-end task flow: create → update → complete → delete
- Widget integration: creation, updates, deletion flows
- App initialization and lifecycle

### Running Tests
Tests require generated code from build_runner:
```bash
cd mobile_app
flutter packages pub run build_runner build
flutter test
```

## Code Style & Linting

- Follows flutter_lints with relaxed rules (see analysis_options.yaml)
- Import aliasing used for clarity (e.g., `as mat` for material, `as sql` for sqflite)
- Generated files (*.g.dart, *.freezed.dart) excluded from analysis
- use_build_context_synchronously disabled (app uses async navigation patterns)

## Common Development Workflows

### Adding a New Feature
1. Create feature directory under `lib/features/[feature_name]/`
2. Add models, screens, widgets subdirectories as needed
3. Create repository in `lib/core/database/repository/` if database access needed
4. Update database schema in DatabaseHelper if new tables required
5. Add route to routes.dart
6. Register providers in app.dart if needed

### Adding Database Tables
1. Increment database version in DatabaseHelper
2. Add table creation SQL in _createDb or create onUpgrade handler
3. Create model class with toMap/fromMap methods
4. Create repository class extending base repository pattern
5. Add repository to relevant features

### Debugging Issues
1. Check logs: Settings → View Logs in app
2. Export logs for analysis: JSON or plain text format
3. Check logger output for ERROR/WARNING severity
4. Verify database operations in repository logs
5. For widget issues: check native platform logs (logcat/Xcode console)

## Dependencies Overview

**Core**: flutter, cupertino_icons, provider, flutter_riverpod
**Database**: sqflite, sqflite_common_ffi, sqflite_sqlcipher, path
**Notifications**: flutter_local_notifications, desktop_notifications, timezone
**UI/Charts**: fl_chart, intl
**Storage**: shared_preferences, path_provider, flutter_secure_storage
**Security**: crypto, local_auth
**Widgets**: home_widget, workmanager, permission_handler
**Sharing**: share_plus, file_picker
**Utilities**: package_info_plus, app_settings

**Dev Dependencies**: flutter_test, integration_test, flutter_lints, mockito, build_runner, riverpod_generator, riverpod_lint
