# Todo App

A full-featured task management application built with Flutter.

## Features

- **Task Management**: Create, edit, and delete tasks with titles, descriptions, due dates, and priority levels
- **Categories**: Organize tasks by customizable categories with color coding
- **Priority Levels**: Assign High, Medium, or Low priority to tasks
- **Notifications**: Set reminders with flexible notification timing options
- **Statistics**: View task completion statistics and progress tracking
- **Dark/Light Mode**: Supports system theme preference

## Getting Started

### Prerequisites

- Flutter SDK (^3.7.2)
- Dart SDK (^3.7.2)

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/todo_app.git
   ```

2. Navigate to the project directory
   ```
   cd todo_app
   ```

3. Get dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Project Structure

The app follows a feature-based architecture with clear separation of concerns:

- `lib/common`: Shared components, constants, themes, and widgets
- `lib/core`: Core functionality like database handling and notifications
- `lib/features`: Feature modules (tasks, categories, statistics)

## Dependencies

- sqflite: ^2.3.2
- flutter_local_notifications: ^16.0.1
- intl: ^0.19.0
- fl_chart: ^0.66.2
- shared_preferences: ^2.2.2

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Commands

flutter build apk --release

flutter build windows --release
