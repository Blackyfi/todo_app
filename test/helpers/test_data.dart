import 'package:flutter/material.dart';
import 'package:todo_app/features/tasks/models/task.dart';
import 'package:todo_app/features/categories/models/category.dart';
import 'package:todo_app/core/notifications/models/notification_settings.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';

/// Contains test data for use across test files
class TestData {
  static final DateTime baseDate = DateTime(2024, 12, 25, 14, 30);

  // Test Categories
  static final Category workCategory = Category(
    id: 1,
    name: 'Work',
    color: Colors.blue,
  );

  static final Category personalCategory = Category(
    id: 2,
    name: 'Personal',
    color: Colors.green,
  );

  static final Category shoppingCategory = Category(
    id: 3,
    name: 'Shopping',
    color: Colors.orange,
  );

  static final Category healthCategory = Category(
    id: 4,
    name: 'Health',
    color: Colors.red,
  );

  static final Category studyCategory = Category(
    id: 5,
    name: 'Study',
    color: Colors.purple,
  );

  static List<Category> get testCategories => [
    workCategory,
    personalCategory,
    shoppingCategory,
    healthCategory,
    studyCategory,
  ];

  // Test Tasks
  static final Task completedWorkTask = Task(
    id: 1,
    title: 'Complete project proposal',
    description: 'Finish writing the Q4 project proposal document',
    dueDate: baseDate.subtract(const Duration(days: 1)),
    isCompleted: true,
    completedAt: baseDate.subtract(const Duration(hours: 2)),
    categoryId: workCategory.id,
    priority: Priority.high,
  );

  static final Task incompletePersonalTask = Task(
    id: 2,
    title: 'Call dentist',
    description: 'Schedule annual checkup appointment',
    dueDate: baseDate.add(const Duration(days: 3)),
    isCompleted: false,
    categoryId: personalCategory.id,
    priority: Priority.medium,
  );

  static final Task todayShoppingTask = Task(
    id: 3,
    title: 'Buy groceries',
    description: 'Milk, bread, eggs, vegetables for this week',
    dueDate: baseDate.add(const Duration(hours: 2)),
    isCompleted: false,
    categoryId: shoppingCategory.id,
    priority: Priority.low,
  );

  static final Task overdueHealthTask = Task(
    id: 4,
    title: 'Exercise routine',
    description: 'Complete 30-minute workout',
    dueDate: baseDate.subtract(const Duration(days: 2)),
    isCompleted: false,
    categoryId: healthCategory.id,
    priority: Priority.medium,
  );

  static final Task futureStudyTask = Task(
    id: 5,
    title: 'Study Flutter testing',
    description: 'Learn unit and widget testing patterns',
    dueDate: baseDate.add(const Duration(days: 7)),
    isCompleted: false,
    categoryId: studyCategory.id,
    priority: Priority.high,
  );

  static final Task noCategoryTask = Task(
    id: 6,
    title: 'Uncategorized task',
    description: 'A task without a category',
    dueDate: baseDate.add(const Duration(days: 1)),
    isCompleted: false,
    categoryId: null,
    priority: Priority.low,
  );

  static final Task noDescriptionTask = Task(
    id: 7,
    title: 'Task without description',
    dueDate: baseDate.add(const Duration(hours: 5)),
    isCompleted: false,
    categoryId: workCategory.id,
    priority: Priority.medium,
  );

  static final Task noDueDateTask = Task(
    id: 8,
    title: 'Task without due date',
    description: 'This task has no specific deadline',
    isCompleted: false,
    categoryId: personalCategory.id,
    priority: Priority.low,
  );

  static List<Task> get testTasks => [
    completedWorkTask,
    incompletePersonalTask,
    todayShoppingTask,
    overdueHealthTask,
    futureStudyTask,
    noCategoryTask,
    noDescriptionTask,
    noDueDateTask,
  ];

  static List<Task> get completedTasks => testTasks.where((task) => task.isCompleted).toList();
  static List<Task> get incompleteTasks => testTasks.where((task) => !task.isCompleted).toList();
  static List<Task> get highPriorityTasks => testTasks.where((task) => task.priority == Priority.high).toList();
  static List<Task> get tasksWithCategories => testTasks.where((task) => task.categoryId != null).toList();

  // Test Notification Settings
  static final NotificationSetting exactTimeNotification = NotificationSetting(
    id: 1,
    taskId: completedWorkTask.id!,
    timeOption: NotificationTimeOption.exactTime,
  );

  static final NotificationSetting fifteenMinutesBeforeNotification = NotificationSetting(
    id: 2,
    taskId: incompletePersonalTask.id!,
    timeOption: NotificationTimeOption.fifteenMinutesBefore,
  );

  static final NotificationSetting customTimeNotification = NotificationSetting(
    id: 3,
    taskId: todayShoppingTask.id!,
    timeOption: NotificationTimeOption.custom,
    customTime: baseDate.subtract(const Duration(minutes: 45)),
  );

  static List<NotificationSetting> get testNotificationSettings => [
    exactTimeNotification,
    fifteenMinutesBeforeNotification,
    customTimeNotification,
  ];

  // Test Auto Delete Settings
  static final AutoDeleteSettings defaultAutoDeleteSettings = AutoDeleteSettings(
    id: 1,
    deleteImmediately: false,
    deleteAfterDays: 7,
  );

  static final AutoDeleteSettings immediateDeleteSettings = AutoDeleteSettings(
    id: 2,
    deleteImmediately: true,
    deleteAfterDays: 1,
  );

  // Test Widget Config
  static final WidgetConfig defaultWidgetConfig = WidgetConfig(
    id: 1,
    widgetId: 'widget_1',
    categoryId: workCategory.id,
    showCompletedTasks: false,
    maxTasksCount: 5,
    fontSize: 14.0,
    showDueDates: true,
    showCategories: true,
  );

  static final WidgetConfig customWidgetConfig = WidgetConfig(
    id: 2,
    widgetId: 'widget_2',
    categoryId: null, // All categories
    showCompletedTasks: true,
    maxTasksCount: 10,
    fontSize: 16.0,
    showDueDates: false,
    showCategories: false,
  );

  static List<WidgetConfig> get testWidgetConfigs => [
    defaultWidgetConfig,
    customWidgetConfig,
  ];

  // Helper methods for creating test data variations
  static Task createTaskWithId(int id) {
    return Task(
      id: id,
      title: 'Test Task $id',
      description: 'Description for task $id',
      dueDate: baseDate.add(Duration(days: id)),
      isCompleted: id % 2 == 0,
      categoryId: (id % testCategories.length) + 1,
      priority: Priority.values[id % Priority.values.length],
    );
  }

  static Category createCategoryWithId(int id) {
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple];
    return Category(
      id: id,
      name: 'Category $id',
      color: colors[id % colors.length],
    );
  }

  static List<Task> createTaskList(int count) {
    return List.generate(count, (index) => createTaskWithId(index + 1));
  }

  static List<Category> createCategoryList(int count) {
    return List.generate(count, (index) => createCategoryWithId(index + 1));
  }

  // Edge case data
  static final Task taskWithLongTitle = Task(
    id: 100,
    title: 'This is a very long task title that should be truncated when displayed in UI components to prevent overflow issues',
    description: 'Normal description',
    dueDate: baseDate,
    isCompleted: false,
    categoryId: workCategory.id,
    priority: Priority.medium,
  );

  static final Task taskWithLongDescription = Task(
    id: 101,
    title: 'Task with long description',
    description: 'This is a very long task description that contains multiple sentences and should be handled properly by the UI components. It includes various details about the task and its requirements. The description goes on to explain more about what needs to be done and why it is important to complete this task in a timely manner.',
    dueDate: baseDate,
    isCompleted: false,
    categoryId: personalCategory.id,
    priority: Priority.high,
  );

  static final Task taskWithSpecialCharacters = Task(
    id: 102,
    title: 'Task with émojis 🚀 and spéciàl characters!',
    description: 'Testing unicode: ñáéíóú, symbols: @#\$%^&*(), and emojis: 🎉🔥💪',
    dueDate: baseDate,
    isCompleted: false,
    categoryId: studyCategory.id,
    priority: Priority.low,
  );

  static final Category categoryWithLongName = Category(
    id: 100,
    name: 'This is a very long category name that might cause UI issues',
    color: Colors.deepPurple,
  );

  // Date-related test data
  static DateTime get today => DateTime.now();
  static DateTime get yesterday => today.subtract(const Duration(days: 1));
  static DateTime get tomorrow => today.add(const Duration(days: 1));
  static DateTime get nextWeek => today.add(const Duration(days: 7));
  static DateTime get lastWeek => today.subtract(const Duration(days: 7));

  // Time-related test data
  static const TimeOfDay morningTime = TimeOfDay(hour: 9, minute: 0);
  static const TimeOfDay afternoonTime = TimeOfDay(hour: 14, minute: 30);
  static const TimeOfDay eveningTime = TimeOfDay(hour: 18, minute: 45);
  static const TimeOfDay nightTime = TimeOfDay(hour: 22, minute: 15);
  static const TimeOfDay midnightTime = TimeOfDay(hour: 0, minute: 0);
  static const TimeOfDay noonTime = TimeOfDay(hour: 12, minute: 0);
}