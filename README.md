# Todo App

A comprehensive, feature-rich task management application built with Flutter that helps you organize, track, and complete your daily tasks with advanced productivity features.

## 🚀 Features

### 📋 Advanced Task Management

- **Smart Task Creation**: Create tasks with titles, descriptions, due dates, and flexible time scheduling
- **Priority System**: Three-level priority system (High/Medium/Low) with visual indicators
- **Real-time Status Updates**: Task cards automatically update to show overdue status and time remaining
- **Flexible Categorization**: Optional category assignment with custom colors and visual organization
- **Completion Tracking**: Automatic timestamp recording and progress monitoring

### 🔔 Intelligent Notification System

- **Multiple Reminder Options**: Set reminders at exact time, 15/30 minutes before, 1 hour/day before, or custom times
- **Timezone Awareness**: Accurate scheduling across time zones with automatic daylight saving adjustments
- **Cross-platform Notifications**: Native notification support on Android, iOS, and desktop platforms
- **Permission Management**: Automated Android 13+ exact alarm permission handling with user guidance
- **Fallback Support**: Graceful degradation when advanced notification features aren't available

### 🎨 Modern Material Design 3 UI

- **Dynamic Theming**: Automatic adaptation to system dark/light mode preferences
- **Responsive Design**: Optimized layouts for phones, tablets, and desktop screens
- **Real-time Clock**: Live time display in the app bar with European/American format options
- **Visual Indicators**: Color-coded priority badges, category chips, and status indicators
- **Smooth Animations**: Fluid transitions and interactions for enhanced user experience

### 📊 Comprehensive Analytics & Statistics

- **Visual Charts**: Task completion rates, priority distribution, and category breakdowns using interactive fl_chart visualizations
- **Productivity Insights**: Weekly completion trends, overdue task tracking, and performance metrics
- **Summary Dashboard**: Real-time statistics with completion percentages and progress indicators
- **Data Visualization**: Pie charts for completion status, bar charts for priority analysis, and weekly task previews

### 🗂️ Advanced Category Management

- **Custom Categories**: Create unlimited categories with personalized names and color coding
- **Default Categories**: Pre-configured Work, Personal, Shopping, Health, and Education categories
- **Visual Organization**: Color-coded category chips for easy task identification
- **Task Counting**: Real-time display of task counts per category with management tools
- **Flexible Assignment**: Tasks can exist without categories or be reassigned at any time

### ⚙️ Comprehensive Settings & Customization

- **Time Format Options**: Choose between European (24-hour) and American (12-hour) time formats
- **Auto-Delete Configuration**: Configurable cleanup of completed tasks (immediate or after N days)
- **Theme Management**: System-based or manual theme selection with Material 3 support
- **Notification Controls**: Direct access to system notification settings and permission management
- **Advanced Debugging**: Built-in log viewer with export capabilities for troubleshooting

### 🛠️ Professional Error Logging & Debugging

- **Multi-level Logging**: ERROR, WARNING, and INFO severity levels with automatic file organization
- **Daily Log Rotation**: Automatic creation of daily log files with comprehensive error tracking
- **Advanced Log Viewer**: In-app log browsing with search, export, and sharing capabilities
- **Multiple Export Formats**: Plain text and JSON export options for analysis and support
- **Global Error Handling**: Comprehensive capture of unhandled exceptions with detailed stack traces

## 🏗️ Technical Architecture

### Cross-Platform Database

- **SQLite Integration**: Local database with cross-platform support (Android/iOS/Desktop)
- **Repository Pattern**: Clean data access layer with comprehensive error handling
- **Foreign Key Support**: Proper relational database design with cascade operations
- **Performance Optimization**: Strategic indexing and query optimization for fast operations

### Advanced State Management

- **Provider Pattern**: Efficient state management for time format preferences and real-time updates
- **Repository Layer**: Separation of business logic and data access with comprehensive logging
- **Real-time Updates**: Automatic UI updates for time-sensitive information like overdue status
- **Memory Optimization**: Proper resource management and cleanup for smooth performance

### Production-Ready Features

- **Comprehensive Error Handling**: Global error capture with user-friendly recovery mechanisms
- **Performance Monitoring**: Operation timing and resource usage tracking
- **Security Best Practices**: Input validation, SQL injection prevention, and secure data handling
- **Accessibility Support**: Screen reader compatibility and high contrast color schemes

## 📱 Platform Support

- **Android**: API 21+ with Material Design 3 and notification channel support
- **iOS**: iOS 12+ with native notification integration and proper permission handling
- **Windows**: Full Windows 10+ support with native window management
- **macOS**: Native macOS experience with proper system integration
- **Linux**: Ubuntu and other distributions with adaptive theming
- **Web**: Progressive web app capabilities with offline support

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: ^3.7.2 or higher
- **Dart SDK**: ^3.7.2 or higher
- **Platform-specific requirements**:
  - Android: Android Studio with SDK 21+
  - iOS: Xcode 12+ with iOS 12+ deployment target
  - Desktop: Platform-specific development tools

### Installation & Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/todo_app.git
   cd todo_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup**

   ```bash
   flutter doctor
   ```

4. **Run the application**

   ```bash
   # For development
   flutter run

   # For specific platforms
   flutter run -d android
   flutter run -d ios
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires Xcode and developer account)
flutter build ios --release

# Windows executable
flutter build windows --release

# macOS application
flutter build macos --release

# Linux executable
flutter build linux --release

# Web application
flutter build web --release
```

## 🏛️ Project Structure

```md
lib/
├── main.dart                 # Application entry point with error handling
├── app.dart                  # Main app configuration with providers
├── routes.dart               # Navigation route definitions
├── common/                   # Shared utilities and components
│   ├── constants/            # App-wide constants and configuration
│   ├── theme/               # Material 3 theme implementation
│   └── widgets/             # Reusable UI components
├── core/                    # Core application services
│   ├── database/            # SQLite database implementation
│   ├── logger/              # Comprehensive logging system
│   ├── notifications/       # Advanced notification system
│   ├── providers/           # State management providers
│   └── settings/            # Application settings management
└── features/                # Feature-based modules
    ├── tasks/               # Task management functionality
    ├── categories/          # Category management
    ├── statistics/          # Analytics and reporting
    └── settings/            # User preferences and debugging
```

## 🔧 Development Workflow

### Essential Commands

```bash
# Clean project (run when facing build issues)
flutter clean && flutter pub get

# Analyze code quality
flutter analyze

# Run tests
flutter test

# Check for dependency updates
flutter pub deps

# Format code
flutter format .

# Generate app icons (if using flutter_launcher_icons)
flutter pub run flutter_launcher_icons:main
```

### Development Best Practices

- **Code Organization**: Follow the feature-based architecture with clear separation of concerns
- **Error Handling**: Always implement comprehensive error handling with logging
- **Testing**: Write unit tests for business logic and widget tests for UI components
- **Documentation**: Maintain inline documentation and update README for new features
- **Version Control**: Use semantic versioning and meaningful commit messages

## 📚 Architecture & Design Patterns

### Core Patterns

- **Repository Pattern**: Clean separation between data access and business logic
- **Singleton Pattern**: Shared services like Logger and Database helper
- **Factory Pattern**: Model creation from different data sources
- **Provider Pattern**: State management for reactive UI updates

### Key Principles

- **Single Responsibility**: Each class has one clear purpose
- **Dependency Injection**: Services are injected for better testability
- **Error Isolation**: Failures in one component don't affect others
- **Performance First**: Optimized for smooth 60fps performance

## 🔍 Debugging & Troubleshooting

### Built-in Debugging Tools

1. **Log Viewer**: Access via Settings → View Logs
   - Browse daily log files with syntax highlighting
   - Export logs in multiple formats for analysis
   - Copy specific entries to clipboard for quick sharing

2. **Error Tracking**: Comprehensive error logging with:
   - Full stack traces for debugging
   - Contextual information about failed operations
   - Automatic timestamp and severity classification

3. **Performance Monitoring**: Track:
   - App initialization time
   - Database operation performance
   - Notification scheduling success rates
   - Memory usage and resource allocation

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Notifications not working** | Check Settings → Notification Settings, ensure permissions are granted |
| **Tasks not saving** | Check logs for database errors, ensure sufficient storage space |
| **App crashes on startup** | Clear app data, check logs for initialization errors |
| **Performance issues** | Review logs for performance warnings, clear old data |

## 🚀 Advanced Features

### Notification System

- **Timezone Support**: Accurate scheduling across time zones
- **Multiple Reminders**: Set multiple notifications per task
- **Smart Permissions**: Automatic Android 13+ permission handling
- **Fallback Mechanisms**: Graceful degradation for unsupported features

### Data Management

- **Auto-Delete**: Configurable cleanup of completed tasks
- **Export Options**: Multiple formats for data portability
- **Backup Support**: Log export for troubleshooting and analysis
- **Cross-Platform Sync**: Architecture ready for cloud synchronization

### Analytics Dashboard

- **Real-time Charts**: Live updating statistics and trends
- **Multiple Visualizations**: Pie charts, bar charts, and progress indicators
- **Productivity Insights**: Weekly patterns and completion analysis
- **Export Capabilities**: Share statistics and reports

## 🤝 Contributing

We welcome contributions to make the Todo App even better! Here's how you can help:

### Getting Involved

1. **Fork the repository** and create your feature branch
2. **Follow the coding standards** and architectural patterns
3. **Add comprehensive tests** for new functionality
4. **Update documentation** including this README if needed
5. **Submit a pull request** with a clear description of changes

### Development Guidelines

- Follow the existing code style and naming conventions
- Add appropriate error handling and logging
- Write unit tests for business logic
- Update documentation for new features
- Test on multiple platforms when possible

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Material Design**: For the comprehensive design system
- **Community Contributors**: For helpful packages and inspiration
- **Open Source**: For making collaborative development possible

## 📞 Support & Feedback

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Join community discussions for questions and ideas
- **Documentation**: Check the `/docs` folder for detailed technical documentation
- **Logs**: Use the built-in log viewer for troubleshooting support

---

Built with ❤️ using Flutter and Material Design 3
