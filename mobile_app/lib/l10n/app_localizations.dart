import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Todo App'**
  String get appName;

  /// Filter option for all tasks
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTasks;

  /// Filter option for completed tasks
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// Filter option for incomplete tasks
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incompleteTasks;

  /// Filter option for today's tasks
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTasks;

  /// Filter option for upcoming tasks
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTasks;

  /// Label for tasks section
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// Label for categories section
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Label for statistics section
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Label for settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Button to add a new task
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// Button to edit a task
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// Button to delete a task
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// Label for task title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// Label for task description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskDescription;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for priority field
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// Label for due date field
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// Label for due time field
  ///
  /// In en, this message translates to:
  /// **'Due Time'**
  String get dueTime;

  /// Label for reminder field
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Message when no tasks are found
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// Description when no tasks are found
  ///
  /// In en, this message translates to:
  /// **'Add your first task to get started!'**
  String get noTasksDescription;

  /// Message when no categories are found
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// Description when no categories are found
  ///
  /// In en, this message translates to:
  /// **'Create a category to organize your tasks'**
  String get noCategoriesDescription;

  /// Confirmation message for deleting a task
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirmation;

  /// Confirmation message for deleting a category
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteCategoryConfirmation;

  /// Message shown when a task is deleted
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// Message shown when a task is added
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get taskAdded;

  /// Message shown when a task is updated
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdated;

  /// Message shown when a category is added
  ///
  /// In en, this message translates to:
  /// **'Category added'**
  String get categoryAdded;

  /// Message shown when a category is updated
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get categoryUpdated;

  /// Message shown when a category is deleted
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// Label for category name field
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// Label for category color field
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// Button to add a category
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// Button to edit a category
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// High priority label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// Medium priority label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// Low priority label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// None option label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Title for task details screen
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// Button to mark task as complete
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get markAsComplete;

  /// Button to mark task as incomplete
  ///
  /// In en, this message translates to:
  /// **'Mark as Incomplete'**
  String get markAsIncomplete;

  /// Label when no category is selected
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// Label when no priority is selected
  ///
  /// In en, this message translates to:
  /// **'No Priority'**
  String get noPriority;

  /// Label when no due date is set
  ///
  /// In en, this message translates to:
  /// **'No Due Date'**
  String get noDueDate;

  /// Label when no reminder is set
  ///
  /// In en, this message translates to:
  /// **'No Reminder'**
  String get noReminder;

  /// Hint text for task title field
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get enterTaskTitle;

  /// Hint text for task description field
  ///
  /// In en, this message translates to:
  /// **'Enter task description (optional)'**
  String get enterTaskDescription;

  /// Hint text for category name field
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get enterCategoryName;

  /// Label for category selection
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Label for priority selection
  ///
  /// In en, this message translates to:
  /// **'Select Priority'**
  String get selectPriority;

  /// Label for date selection
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Label for time selection
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Title for statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// Label for tasks summary section
  ///
  /// In en, this message translates to:
  /// **'Tasks Summary'**
  String get tasksSummary;

  /// Label for total tasks count
  ///
  /// In en, this message translates to:
  /// **'Total Tasks'**
  String get totalTasks;

  /// Label for completed tasks count
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasksCount;

  /// Label for incomplete tasks count
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incompleteTasksCount;

  /// Label for tasks by category chart
  ///
  /// In en, this message translates to:
  /// **'Tasks by Category'**
  String get tasksByCategory;

  /// Label for tasks by priority chart
  ///
  /// In en, this message translates to:
  /// **'Tasks by Priority'**
  String get tasksByPriority;

  /// Label for completion rate
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// Label for weekly progress
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgress;

  /// Title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for general settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Label for security setting
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Label for about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Label for app version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Label for license information
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// Label for time format setting
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// 24-hour time format option
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get twentyFourHour;

  /// 12-hour time format option
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get twelveHour;

  /// European time format option
  ///
  /// In en, this message translates to:
  /// **'European'**
  String get european;

  /// Label for log viewer
  ///
  /// In en, this message translates to:
  /// **'Log Viewer'**
  String get logViewer;

  /// Button to view logs
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// Button to export logs
  ///
  /// In en, this message translates to:
  /// **'Export Logs'**
  String get exportLogs;

  /// Button to clear logs
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// Message when no logs are found
  ///
  /// In en, this message translates to:
  /// **'No logs found'**
  String get noLogsFound;

  /// Label for shopping lists section
  ///
  /// In en, this message translates to:
  /// **'Shopping Lists'**
  String get shoppingLists;

  /// Button to add a shopping list
  ///
  /// In en, this message translates to:
  /// **'Add Shopping List'**
  String get addShoppingList;

  /// Button to edit a shopping list
  ///
  /// In en, this message translates to:
  /// **'Edit Shopping List'**
  String get editShoppingList;

  /// Button to delete a shopping list
  ///
  /// In en, this message translates to:
  /// **'Delete Shopping List'**
  String get deleteShoppingList;

  /// Label for shopping list name
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get listName;

  /// Label for shopping item name
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// Label for quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Label for unit
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// Button to add an item
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// Label for shopping mode
  ///
  /// In en, this message translates to:
  /// **'Shopping Mode'**
  String get shoppingMode;

  /// Label for security settings
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// Label for password protection
  ///
  /// In en, this message translates to:
  /// **'Password Protection'**
  String get passwordProtection;

  /// Label for PIN protection
  ///
  /// In en, this message translates to:
  /// **'PIN Protection'**
  String get pinProtection;

  /// Label for biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuthentication;

  /// Button to change password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Button to change PIN
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePIN;

  /// Hint for password field
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// Hint for PIN field
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPIN;

  /// Label for confirm password field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Label for confirm PIN field
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPIN;

  /// Title for unlock screen
  ///
  /// In en, this message translates to:
  /// **'Unlock App'**
  String get unlockApp;

  /// Label for sync settings
  ///
  /// In en, this message translates to:
  /// **'Sync Settings'**
  String get syncSettings;

  /// Label for server address field
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get serverAddress;

  /// Label for port field
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// Label for username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Label for password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Button to connect to server
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Button to disconnect from server
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Button to sync now
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Label for last sync time
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSyncTime;

  /// Label for sync status
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// Status: connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// Status: disconnected
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// Status: syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// Message: sync complete
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get syncComplete;

  /// Message: sync failed
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// Label for widget settings
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get widgetSettings;

  /// Label for widget management
  ///
  /// In en, this message translates to:
  /// **'Widget Management'**
  String get widgetManagement;

  /// Button to create a widget
  ///
  /// In en, this message translates to:
  /// **'Create Widget'**
  String get createWidget;

  /// Button to edit a widget
  ///
  /// In en, this message translates to:
  /// **'Edit Widget'**
  String get editWidget;

  /// Button to delete a widget
  ///
  /// In en, this message translates to:
  /// **'Delete Widget'**
  String get deleteWidget;

  /// Label for widget name
  ///
  /// In en, this message translates to:
  /// **'Widget Name'**
  String get widgetName;

  /// Label for widget size
  ///
  /// In en, this message translates to:
  /// **'Widget Size'**
  String get widgetSize;

  /// Small size option
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// Large size option
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// Option to show completed tasks
  ///
  /// In en, this message translates to:
  /// **'Show Completed'**
  String get showCompleted;

  /// Option to show categories
  ///
  /// In en, this message translates to:
  /// **'Show Categories'**
  String get showCategories;

  /// Option to show priority
  ///
  /// In en, this message translates to:
  /// **'Show Priority'**
  String get showPriority;

  /// Label for maximum tasks to display
  ///
  /// In en, this message translates to:
  /// **'Max Tasks'**
  String get maxTasks;

  /// General error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get generalErrorMessage;

  /// Network error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkErrorMessage;

  /// Database error message
  ///
  /// In en, this message translates to:
  /// **'Database error. Please restart the app.'**
  String get databaseErrorMessage;

  /// Sync network error message
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection.'**
  String get syncNetworkError;

  /// Sync authentication error message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please log in again.'**
  String get syncAuthError;

  /// Sync server error message
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get syncServerError;

  /// Sync conflict error message
  ///
  /// In en, this message translates to:
  /// **'Some items had conflicts and were resolved automatically.'**
  String get syncConflictError;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Hint for search tasks field
  ///
  /// In en, this message translates to:
  /// **'Search tasks'**
  String get searchTasks;

  /// Filter label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort label
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Sort option: date created
  ///
  /// In en, this message translates to:
  /// **'Date Created'**
  String get dateCreated;

  /// Sort option: date modified
  ///
  /// In en, this message translates to:
  /// **'Date Modified'**
  String get dateModified;

  /// Sort option: alphabetical
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get alphabetical;

  /// Reminder option: at time
  ///
  /// In en, this message translates to:
  /// **'At Time'**
  String get atTime;

  /// Reminder option: 15 minutes before
  ///
  /// In en, this message translates to:
  /// **'15 Minutes Before'**
  String get fifteenMinutesBefore;

  /// Reminder option: 30 minutes before
  ///
  /// In en, this message translates to:
  /// **'30 Minutes Before'**
  String get thirtyMinutesBefore;

  /// Reminder option: 1 hour before
  ///
  /// In en, this message translates to:
  /// **'1 Hour Before'**
  String get oneHourBefore;

  /// Reminder option: 1 day before
  ///
  /// In en, this message translates to:
  /// **'1 Day Before'**
  String get oneDayBefore;

  /// Custom option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
