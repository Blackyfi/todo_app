class AppConstants {
  // App Information
  static const String appName = 'Todo App';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String homeRoute = '/';
  static const String taskDetailsRoute = '/task-details';
  static const String addTaskRoute = '/add-task';
  static const String editTaskRoute = '/edit-task';
  static const String categoriesRoute = '/categories';
  static const String statisticsRoute = '/statistics';
  static const String settingsRoute = '/settings';
  static const String logViewerRoute = '/log-viewer';

  // Shopping Routes
  static const String shoppingListsRoute = '/shopping-lists';
  static const String createShoppingListRoute = '/create-shopping-list';
  static const String editShoppingListRoute = '/edit-shopping-list';
  static const String shoppingModeRoute = '/shopping-mode';
  
  // Sync Routes
  static const String syncSettingsRoute = '/sync-settings';

  // Database
  static const String databaseName = 'todo_app.db';
  static const int databaseVersion = 2;
  
  // Shared Preferences Keys
  static const String themePreference = 'theme_preference';
  static const String firstLaunchKey = 'first_launch';
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const double cardElevation = 2.0;
  
  // Error Messages
  static const String generalErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String databaseErrorMessage = 'Database error. Please restart the app.';
  
  // Task List Filter Options
  static const String allTasks = 'All';
  static const String completedTasks = 'Completed';
  static const String incompleteTasks = 'Incomplete';
  static const String todayTasks = 'Today';
  static const String upcomingTasks = 'Upcoming';
  
  // Logging
  static const String logDirectoryName = 'logs';
  static const String logFilePrefix = 'app_log_';

  // Sync
  static const int defaultSyncPort = 8443;
  static const int httpTimeoutSeconds = 30;
  static const int uploadTimeoutSeconds = 60;
  static const int maxSyncRetries = 5;
  static const String syncTokenKey = 'sync_api_token';
  static const String syncDeviceIdKey = 'sync_device_id';

  // Sync Error Messages
  static const String syncNetworkError =
      'Unable to connect. Check your internet connection.';
  static const String syncAuthError =
      'Authentication failed. Please log in again.';
  static const String syncServerError =
      'Server error. Please try again later.';
  static const String syncConflictError =
      'Some items had conflicts and were resolved automatically.';
}