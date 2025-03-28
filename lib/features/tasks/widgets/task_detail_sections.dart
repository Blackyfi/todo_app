import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/features/tasks/widgets/task_detail_header.dart';
import 'package:todo_app/features/tasks/widgets/task_detail_category.dart';
import 'package:todo_app/features/tasks/widgets/task_detail_datetime.dart';
import 'package:todo_app/features/tasks/widgets/task_detail_status.dart';
import 'package:todo_app/features/tasks/widgets/task_detail_description.dart';
import 'package:todo_app/features/tasks/widgets/task_detail_reminders.dart';

// This file acts as a coordinator for all the detail sections

class TaskDetailContent extends mat.StatelessWidget {
  final task_model.Task task;
  final category_model.Category? category;
  final List<notification_model.NotificationSetting> notificationSettings;

  const TaskDetailContent({
    super.key,
    required this.task,
    this.category,
    required this.notificationSettings,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        TaskDetailHeader(task: task),
        const mat.SizedBox(height: 16),
        if (category != null) 
          TaskDetailCategory(category: category!),
        if (task.dueDate != null) 
          TaskDetailDateTime(dueDate: task.dueDate!),
        TaskDetailStatus(isCompleted: task.isCompleted),
        const mat.SizedBox(height: 24),
        TaskDetailDescription(description: task.description),
        if (notificationSettings.isNotEmpty) ...[
          const mat.SizedBox(height: 24),
          TaskDetailReminders(settings: notificationSettings),
        ],
      ],
    );
  }
}