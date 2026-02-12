import 'package:flutter/material.dart' as mat;

class TaskDetailStatus extends mat.StatelessWidget {
  final bool isCompleted;

  const TaskDetailStatus({
    super.key,
    required this.isCompleted,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Row(
      children: [
        mat.Icon(
          isCompleted
              ? mat.Icons.check_circle
              : mat.Icons.radio_button_unchecked,
          color: isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withAlpha(153), // 0.6 * 255 ≈ 153
          size: 20,
        ),
        const mat.SizedBox(width: 8),
        mat.Text(
          'Status: ${isCompleted ? 'Completed' : 'Incomplete'}',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}