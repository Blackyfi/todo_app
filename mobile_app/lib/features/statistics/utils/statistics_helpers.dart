import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart' show Color; // Add this import

Map<String, int> getCompletionStats(List<task_model.Task> tasks) {
  final stats = <String, int>{
    'Completed': 0,
    'Incomplete': 0,
  };
  
  for (final task in tasks) {
    if (task.isCompleted) {
      stats['Completed'] = (stats['Completed'] ?? 0) + 1;
    } else {
      stats['Incomplete'] = (stats['Incomplete'] ?? 0) + 1;
    }
  }
  
  return stats;
}

Map<String, int> getPriorityStats(List<task_model.Task> tasks) {
  final stats = <String, int>{
    'High': 0,
    'Medium': 0,
    'Low': 0,
  };
  
  for (final task in tasks) {
    switch (task.priority) {
      case task_model.Priority.high:
        stats['High'] = (stats['High'] ?? 0) + 1;
        break;
      case task_model.Priority.medium:
        stats['Medium'] = (stats['Medium'] ?? 0) + 1;
        break;
      case task_model.Priority.low:
        stats['Low'] = (stats['Low'] ?? 0) + 1;
        break;
    }
  }
  
  return stats;
}

Map<String, int> getCategoryStats(
  List<task_model.Task> tasks,
  List<category_model.Category> categories,
) {
  final stats = <String, int>{};
  
  // Add a special entry for uncategorized tasks
  stats['No Category'] = 0;
  
  for (final task in tasks) {
    if (task.categoryId == null) {
      // Count tasks without categories
      stats['No Category'] = (stats['No Category'] ?? 0) + 1;
    } else {
      // For tasks with categories
      final category = categories.firstWhere(
        (cat) => cat.id == task.categoryId,
        orElse: () => category_model.Category(
          id: 0,
          name: 'Unknown',
          color: const Color(0xFF9E9E9E), // Fixed: Using the imported Color class
        ),
      );
      
      stats[category.name] = (stats[category.name] ?? 0) + 1;
    }
  }
  
  // Remove the "No Category" entry if there are no uncategorized tasks
  if (stats['No Category'] == 0) {
    stats.remove('No Category');
  }
  
  return stats;
}

List<task_model.Task> getTasksDueThisWeek(List<task_model.Task> tasks) {
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  
  return tasks.where((task) {
    if (task.dueDate == null) return false;
    return task.dueDate!.isAfter(startOfWeek) && 
           task.dueDate!.isBefore(endOfWeek) &&
           !task.isCompleted;
  }).toList();
}

Map<String, int> getTasksCompletedByDay(List<task_model.Task> tasks) {
  final stats = <String, int>{};
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  
  // Initialize days of the week
  for (int i = 0; i < 7; i++) {
    final day = startOfWeek.add(Duration(days: i));
    stats[intl.DateFormat('EEE').format(day)] = 0;
  }
  
  // Count completed tasks by day of the week
  for (final task in tasks) {
    if (task.isCompleted && task.dueDate != null) {
      final dayOfWeek = intl.DateFormat('EEE').format(task.dueDate!);
      stats[dayOfWeek] = (stats[dayOfWeek] ?? 0) + 1;
    }
  }
  
  return stats;
}

double getCompletionPercentage(List<task_model.Task> tasks) {
  if (tasks.isEmpty) return 0;
  
  final completedCount = tasks.where((task) => task.isCompleted).length;
  return (completedCount / tasks.length) * 100;
}