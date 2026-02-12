import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/statistics/utils/statistics_helpers.dart' as statistics_helpers;

class SummaryCard extends mat.StatelessWidget {
  final List<task_model.Task> tasks;
  
  const SummaryCard({
    super.key,
    required this.tasks,
  });
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final completedCount = tasks.where((task) => task.isCompleted).length;
    final incompleteCount = tasks.length - completedCount;
    final overdueTasks = tasks.where((task) => 
      !task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now())
    ).length;
    
    final completionPercentage = statistics_helpers.getCompletionPercentage(tasks);
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Task Summary',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.Row(
              children: [
                _buildInfoItem(
                  context: context,
                  icon: mat.Icons.task_alt,
                  label: 'Total',
                  value: tasks.length.toString(),
                  color: mat.Theme.of(context).colorScheme.primary,
                ),
                _buildInfoItem(
                  context: context,
                  icon: mat.Icons.check_circle,
                  label: 'Completed',
                  value: completedCount.toString(),
                  color: mat.Colors.green,
                ),
                _buildInfoItem(
                  context: context,
                  icon: mat.Icons.pending_actions,
                  label: 'Pending',
                  value: incompleteCount.toString(),
                  color: mat.Colors.orange,
                ),
                _buildInfoItem(
                  context: context,
                  icon: mat.Icons.watch_later,
                  label: 'Overdue',
                  value: overdueTasks.toString(),
                  color: mat.Colors.red,
                ),
              ],
            ),
            const mat.SizedBox(height: 16),
            mat.Text(
              'Completion Rate: ${completionPercentage.toStringAsFixed(1)}%',
              style: mat.Theme.of(context).textTheme.titleMedium,
            ),
            const mat.SizedBox(height: 8),
            mat.LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: mat.Theme.of(context).colorScheme.surfaceContainerHighest,
              color: mat.Theme.of(context).colorScheme.primary,
              borderRadius: mat.BorderRadius.circular(8),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }
  
  mat.Widget _buildInfoItem({
    required mat.BuildContext context,
    required mat.IconData icon,
    required String label,
    required String value,
    required mat.Color color,
  }) {
    return mat.Expanded(
      child: mat.Column(
        children: [
          mat.Icon(icon, color: color, size: 28),
          const mat.SizedBox(height: 4),
          mat.Text(
            value,
            style: mat.TextStyle(
              fontSize: 18,
              fontWeight: mat.FontWeight.bold,
              color: color,
            ),
          ),
          mat.Text(
            label,
            style: mat.TextStyle(
              fontSize: 12,
              color: mat.Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}