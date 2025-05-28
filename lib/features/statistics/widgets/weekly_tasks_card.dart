import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:intl/intl.dart' as intl;

class WeeklyTasksCard extends mat.StatelessWidget {
  final List<task_model.Task> tasks;
  final List<category_model.Category> categories;

  const WeeklyTasksCard({
    super.key,
    required this.tasks,
    required this.categories,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks Due This Week',
              style: theme.textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 8),
            if (tasks.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              ...tasks.map((task) => _buildTaskItem(task, theme)),
            ],
          ],
        ),
      ),
    );
  }

  mat.Widget _buildEmptyState() {
    return const mat.Column(
      children: [
        mat.SizedBox(height: 40),
        mat.Center(
          child: mat.Text('No tasks due this week'),
        ),
        mat.SizedBox(height: 40),
      ],
    );
  }

  mat.Widget _buildTaskItem(task_model.Task task, mat.ThemeData theme) {
    final category = _getCategoryForTask(task);
    
    return mat.Padding(
      padding: const mat.EdgeInsets.only(bottom: 8),
      child: mat.ListTile(
        contentPadding: const mat.EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 0,
        ),
        leading: _buildCategoryIcon(category),
        title: mat.Text(
          task.title,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: mat.TextOverflow.ellipsis,
        ),
        subtitle: task.dueDate != null
            ? mat.Text(
                intl.DateFormat('E, MMM d').format(task.dueDate!),
                style: mat.TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: _buildPriorityBadge(task, theme),
      ),
    );
  }

  mat.Widget _buildCategoryIcon(category_model.Category category) {
    return mat.Container(
      width: 40,
      height: 40,
      decoration: mat.BoxDecoration(
        color: category.color.withAlpha((0.2 * 255).toInt()),
        borderRadius: mat.BorderRadius.circular(8),
      ),
      child: mat.Center(
        child: mat.Icon(
          mat.Icons.calendar_today,
          color: category.color,
          size: 20,
        ),
      ),
    );
  }

  mat.Widget _buildPriorityBadge(task_model.Task task, mat.ThemeData theme) {
    return mat.Container(
      padding: const mat.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: mat.BoxDecoration(
        color: task.priority.color.withAlpha((0.2 * 255).toInt()),
        borderRadius: mat.BorderRadius.circular(4),
      ),
      child: mat.Text(
        task.priority.label,
        style: mat.TextStyle(
          color: task.priority.color,
          fontSize: 12,
          fontWeight: mat.FontWeight.bold,
        ),
      ),
    );
  }

  category_model.Category _getCategoryForTask(task_model.Task task) {
    return categories.firstWhere(
      (cat) => cat.id == task.categoryId,
      orElse: () => category_model.Category(
        id: 0,
        name: 'Unknown',
        color: mat.Colors.grey,
      ),
    );
  }
}