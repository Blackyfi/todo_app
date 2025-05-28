# Todo App

A full-featured task management application built with Flutter that helps you organize and track your daily tasks.

## Features

- **Task Management**: Create, edit, and delete tasks with titles, descriptions, due dates, and priority levels
- **Categories**: Organize tasks by customizable categories with color coding
- **Priority Levels**: Assign High, Medium, or Low priority to tasks
- **Notifications**: Set reminders with flexible notification timing options
- **Statistics**: View task completion statistics and progress tracking
- **Dark/Light Mode**: Supports system theme preference
- **Cross-Platform**: Works on Android, iOS, Windows, macOS, Linux, and Web

## Screenshots

(Coming soon)

## Getting Started

### Prerequisites

- Flutter SDK (^3.7.2)
- Dart SDK (^3.7.2)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/todo_app.git
   ```

2. Navigate to the project directory
   ```bash
   cd todo_app
   ```

3. Get dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

## Project Structure

The app follows a feature-based architecture with clear separation of concerns:

- `lib/common`: Shared components, constants, themes, and widgets
- `lib/core`: Core functionality like database handling and notifications
- `lib/features`: Feature modules (tasks, categories, statistics)

## Architecture

This application uses a simple and effective architecture pattern:

- **Repository Pattern**: For data access
- **Feature-Based Organization**: Code is organized by feature rather than by type
- **Material Design 3**: Modern UI implementation

## Dependencies

- **sqflite**: ^2.3.2 - Local database storage
- **flutter_local_notifications**: ^16.0.1 - Scheduling and displaying notifications
- **intl**: ^0.19.0 - Date formatting and localization
- **fl_chart**: ^0.66.2 - Data visualization for statistics
- **shared_preferences**: ^2.2.2 - Lightweight persistent storage for settings

## Useful Commands

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Check Flutter setup
flutter doctor

# Analyze code
flutter analyze

# Update Flutter
flutter upgrade

# List connected devices
flutter devices

# Build for Android
flutter build apk --release

# Build for Windows
flutter build windows --release
```

## Usueal Development Commands
```bash
flutter clean
flutter upgrade
flutter doctor
flutter pub get
flutter analyze
flutter build windows --release
```


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.