import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;

class PriorityBadge extends mat.StatelessWidget {
  final task_model.Priority priority;
  final double size;

  const PriorityBadge({
    mat.Key? key,
    required this.priority,
    this.size = 12.0,
  }) : super(key: key);

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Container(
      width: size * 6,
      height: size * 2,
      decoration: mat.BoxDecoration(
        color: priority.color.withOpacity(0.2),
        borderRadius: mat.BorderRadius.circular(size),
        border: mat.Border.all(
          color: priority.color,
          width: 1.5,
        ),
      ),
      child: mat.Center(
        child: mat.Text(
          priority.label,
          style: mat.TextStyle(
            color: priority.color,
            fontSize: size * 0.9,
            fontWeight: mat.FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
