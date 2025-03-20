import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:intl/intl.dart' as intl;

class TaskDetailContent extends mat.StatelessWidget {
  final task_model.Task task;
  final category_model.Category? category;
  final List<notification_model.NotificationSetting> notificationSettings;

  const TaskDetailContent({
    mat.Key? key,
    required this.task,
    this.category,
    required this.notificationSettings,
  }) : super(key: key);

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const mat.SizedBox(height: 16),
        if (category != null) 
          _buildCategorySection(theme),
        if (task.dueDate != null) 
          _buildDateTimeSection(theme),
        _buildStatusSection(theme),
        const mat.SizedBox(height: 24),
        _buildDescriptionSection(theme),
        if (notificationSettings.isNotEmpty) ...[
          const mat.SizedBox(height: 24),
          _buildRemindersSection(theme),
        ],
      ],
    );
  }

  mat.Widget _buildHeader(mat.ThemeData theme) {
    return mat.Row(
      children: [
        mat.Expanded(
          child: mat.Text(
            task.title,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        priority_badge.PriorityBadge(
          priority: task.priority,
          size: 16,
        ),
      ],
    );
  }

  mat.Widget _buildCategorySection(mat.ThemeData theme) {
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Row(
          children: [
            mat.Icon(
              mat.Icons.category,
              color: category!.color,
              size: 20,
            ),
            const mat.SizedBox(width: 8),
            mat.Text(
              'Category: ${category!.name}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: category!.color,
              ),
            ),
          ],
        ),
        const mat.SizedBox(height: 16),
      ],
    );
  }

  mat.Widget _buildDateTimeSection(mat.ThemeData theme) {
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Row(
          children: [
            mat.Icon(
              mat.Icons.event,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const mat.SizedBox(width: 8),
            mat.Text(
              'Due Date: ${intl.DateFormat('EEEE, MMMM d, yyyy').format(task.dueDate!)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const mat.SizedBox(height: 8),
        mat.Row(
          children: [
            mat.Icon(
              mat.Icons.access_time,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const mat.SizedBox(width: 8),
            mat.Text(
              'Due Time: ${intl.DateFormat('h:mm a').format(task.dueDate!)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const mat.SizedBox(height: 16),
      ],
    );
  }

  mat.Widget _buildStatusSection(mat.ThemeData theme) {
    return mat.Row(
      children: [
        mat.Icon(
          task.isCompleted
              ? mat.Icons.check_circle
              : mat.Icons.radio_button_unchecked,
          color: task.isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
          size: 20,
        ),
        const mat.SizedBox(width: 8),
        mat.Text(
          'Status: ${task.isCompleted ? 'Completed' : 'Incomplete'}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  mat.Widget _buildDescriptionSection(mat.ThemeData theme) {
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Text(
          'Description',
          style: theme.textTheme.titleLarge,
        ),
        const mat.SizedBox(height: 8),
        mat.Container(
          width: double.infinity,
          padding: const mat.EdgeInsets.all(16),
          decoration: mat.BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(77), // 0.3 * 255 ≈ 77
            borderRadius: mat.BorderRadius.circular(16),
          ),
          child: mat.Text(
            task.description.isEmpty
                ? 'No description provided'
                : task.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: task.description.isEmpty
                  ? theme.colorScheme.onSurface.withAlpha(153) // 0.6 * 255 ≈ 153
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  mat.Widget _buildRemindersSection(mat.ThemeData theme) {
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Text(
          'Reminders',
          style: theme.textTheme.titleLarge,
        ),
        const mat.SizedBox(height: 8),
        ...List.generate(notificationSettings.length, (index) {
          final setting = notificationSettings[index];
          return mat.Padding(
            padding: const mat.EdgeInsets.only(bottom: 8),
            child: mat.Container(
              padding: const mat.EdgeInsets.all(12),
              decoration: mat.BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(77), // 0.3 * 255 ≈ 77
                borderRadius: mat.BorderRadius.circular(12),
              ),
              child: mat.Row(
                children: [
                  mat.Icon(
                    mat.Icons.notifications_active,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const mat.SizedBox(width: 8),
                  mat.Expanded(
                    child: mat.Text(
                      setting.timeOption.label,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (setting.timeOption == notification_model.NotificationTimeOption.custom && 
                      setting.customTime != null) ...[
                    mat.Text(
                      intl.DateFormat('h:mm a').format(setting.customTime!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}