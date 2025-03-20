import 'package:flutter/material.dart';

/// Helper methods for task form functionality
class TaskFormHelpers {
  /// Combines date and time into a single DateTime object
  /// Returns null if date is null
  static DateTime? combineDateAndTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    
    final timeOfDay = time ?? TimeOfDay.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
  }

  /// Shows time picker dialog to select a custom notification time
  /// Returns a DateTime object with the current date and selected time
  static Future<DateTime?> selectCustomNotificationTime(
    BuildContext context, {
    DateTime? initialTime,
  }) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime != null
          ? TimeOfDay.fromDateTime(initialTime)
          : TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
    
    return null;
  }

  /// Validates a task title
  /// Returns an error message if title is invalid, null otherwise
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    
    return null;
  }

  /// Checks if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Checks if date is in the past
  static bool isInPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Formats a TimeOfDay object to a string in 12-hour format (e.g. "3:30 PM")
  static String formatTimeOfDay(TimeOfDay timeOfDay, BuildContext context) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Creates a readable string description of when a notification will occur
  static String getNotificationTimeDescription(
    DateTime taskDueDate,
    TimeOfDay taskDueTime,
    TimeOfDay notificationTime,
  ) {
    final taskDateTime = combineDateAndTime(taskDueDate, taskDueTime)!;
    final notificationDateTime = combineDateAndTime(
      taskDueDate,
      notificationTime,
    )!;
    
    final difference = taskDateTime.difference(notificationDateTime);
    
    if (difference.inMinutes == 0) {
      return 'At task time';
    } else if (difference.inMinutes == 15) {
      return '15 minutes before';
    } else if (difference.inMinutes == 30) {
      return '30 minutes before';
    } else if (difference.inMinutes == 60) {
      return '1 hour before';
    } else if (difference.inDays == 1) {
      return '1 day before';
    } else {
      return '${difference.inMinutes} minutes before';
    }
  }
}