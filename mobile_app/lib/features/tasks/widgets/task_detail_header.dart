import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;

class TaskDetailHeader extends mat.StatelessWidget {
  final task_model.Task task;

  const TaskDetailHeader({
    super.key,
    required this.task,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
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
}