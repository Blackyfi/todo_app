import 'package:flutter/material.dart' as mat;
import 'package:intl/intl.dart' as intl;

class TaskDetailDateTime extends mat.StatelessWidget {
  final DateTime dueDate;

  const TaskDetailDateTime({
    super.key,
    required this.dueDate,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
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
              'Due Date: ${intl.DateFormat('EEEE, MMMM d, yyyy').format(dueDate)}',
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
              'Due Time: ${intl.DateFormat('h:mm a').format(dueDate)}',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const mat.SizedBox(height: 16),
      ],
    );
  }
}