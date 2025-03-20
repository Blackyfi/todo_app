import 'package:flutter/material.dart';
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/features/tasks/utils/task_form_helpers.dart';
import 'package:intl/intl.dart' as intl;

class NotificationOptionPicker extends StatelessWidget {
  final List<notification_model.NotificationTimeOption> selectedOptions;
  final DateTime? customTime;
  final Function(notification_model.NotificationTimeOption) onOptionToggled;
  final Function(DateTime?) onCustomTimeChanged;

  const NotificationOptionPicker({
    Key? key,
    required this.selectedOptions,
    this.customTime,
    required this.onOptionToggled,
    required this.onCustomTimeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Reminders',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildNotificationOptions(context),
        
        if (selectedOptions.contains(notification_model.NotificationTimeOption.custom) &&
            customTime != null) ...[
          const SizedBox(height: 8),
          _buildCustomTimeSelector(context, theme),
        ],
      ],
    );
  }

  Widget _buildNotificationOptions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: notification_model.NotificationTimeOption.values.map((option) {
        final isSelected = selectedOptions.contains(option);
        return FilterChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (_) => onOptionToggled(option),
          avatar: isSelected
              ? const Icon(Icons.notifications_active, size: 18)
              : const Icon(Icons.notifications_none, size: 18),
        );
      }).toList(),
    );
  }

  Widget _buildCustomTimeSelector(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final newTime = await TaskFormHelpers.selectCustomNotificationTime(
          context,
          initialTime: customTime,
        );
        if (newTime != null) {
          onCustomTimeChanged(newTime);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(76),
          borderRadius: BorderRadius.circular(12),
            border: Border.all(
            color: theme.colorScheme.outline.withAlpha(128),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom Time: ${intl.DateFormat('h:mm a').format(customTime!)}',
            ),
            const Spacer(),
            Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}