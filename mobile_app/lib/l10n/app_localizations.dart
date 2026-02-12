// Generated file. Do not edit manually.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  String get appName;
  String get allTasks;
  String get completedTasks;
  String get incompleteTasks;
  String get todayTasks;
  String get upcomingTasks;
  String get tasks;
  String get categories;
  String get statistics;
  String get settings;
  String get addTask;
  String get editTask;
  String get deleteTask;
  String get taskTitle;
  String get taskDescription;
  String get category;
  String get priority;
  String get dueDate;
  String get dueTime;
  String get reminder;
  String get save;
  String get cancel;
  String get delete;
  String get ok;
  String get yes;
  String get no;
  String get noTasksFound;
  String get noTasksDescription;
  String get noCategoriesFound;
  String get noCategoriesDescription;
  String get deleteTaskConfirmation;
  String get deleteCategoryConfirmation;
  String get taskDeleted;
  String get taskAdded;
  String get taskUpdated;
  String get categoryAdded;
  String get categoryUpdated;
  String get categoryDeleted;
  String get categoryName;
  String get categoryColor;
  String get addCategory;
  String get editCategory;
  String get high;
  String get medium;
  String get low;
  String get none;
  String get taskDetails;
  String get markAsComplete;
  String get markAsIncomplete;
  String get noCategory;
  String get noPriority;
  String get noDueDate;
  String get noReminder;
  String get enterTaskTitle;
  String get enterTaskDescription;
  String get enterCategoryName;
  String get selectCategory;
  String get selectPriority;
  String get selectDate;
  String get selectTime;
  String get statisticsTitle;
  String get tasksSummary;
  String get totalTasks;
  String get completedTasksCount;
  String get incompleteTasksCount;
  String get tasksByCategory;
  String get tasksByPriority;
  String get completionRate;
  String get weeklyProgress;
  String get settingsTitle;
  String get general;
  String get theme;
  String get language;
  String get notifications;
  String get security;
  String get about;
  String get version;
  String get license;
  String get lightTheme;
  String get darkTheme;
  String get systemTheme;
  String get timeFormat;
  String get twentyFourHour;
  String get twelveHour;
  String get european;
  String get logViewer;
  String get viewLogs;
  String get exportLogs;
  String get clearLogs;
  String get noLogsFound;
  String get shoppingLists;
  String get addShoppingList;
  String get editShoppingList;
  String get deleteShoppingList;
  String get listName;
  String get itemName;
  String get quantity;
  String get unit;
  String get addItem;
  String get shoppingMode;
  String get securitySettings;
  String get passwordProtection;
  String get pinProtection;
  String get biometricAuthentication;
  String get changePassword;
  String get changePIN;
  String get enterPassword;
  String get enterPIN;
  String get confirmPassword;
  String get confirmPIN;
  String get unlockApp;
  String get syncSettings;
  String get serverAddress;
  String get port;
  String get username;
  String get password;
  String get connect;
  String get disconnect;
  String get syncNow;
  String get lastSyncTime;
  String get syncStatus;
  String get connected;
  String get disconnected;
  String get syncing;
  String get syncComplete;
  String get syncFailed;
  String get widgetSettings;
  String get widgetManagement;
  String get createWidget;
  String get editWidget;
  String get deleteWidget;
  String get widgetName;
  String get widgetSize;
  String get small;
  String get large;
  String get showCompleted;
  String get showCategories;
  String get showPriority;
  String get maxTasks;
  String get generalErrorMessage;
  String get networkErrorMessage;
  String get databaseErrorMessage;
  String get syncNetworkError;
  String get syncAuthError;
  String get syncServerError;
  String get syncConflictError;
  String get search;
  String get searchTasks;
  String get filter;
  String get sort;
  String get sortBy;
  String get dateCreated;
  String get dateModified;
  String get alphabetical;
  String get atTime;
  String get fifteenMinutesBefore;
  String get thirtyMinutesBefore;
  String get oneHourBefore;
  String get oneDayBefore;
  String get custom;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
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
    'that was used.'
  );
}
