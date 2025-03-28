import 'package:flutter/material.dart' as mat;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:intl/intl.dart' as intl;

class TaskDetailReminders extends mat.StatelessWidget {
  final List<notification_model.NotificationSetting> settings;

  const TaskDetailReminders({
    super.key,
    required this.settings,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Text(
          'Reminders',
          style: theme.textTheme.titleLarge,
        ),
        const mat.SizedBox(height: 8),
        ...List.generate(settings.length, (index) {
          return _buildReminderItem(settings[index], theme);
        }),
      ],
    );
  }

  mat.Widget _buildReminderItem(
    notification_model.NotificationSetting setting,
    mat.ThemeData theme,
  ) {
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
  }
}