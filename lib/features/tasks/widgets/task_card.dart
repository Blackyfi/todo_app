import 'package:flutter/material.dart' as mat;
import 'dart:ui';
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

class TaskCard extends mat.StatelessWidget {
  final task_model.Task task;
  final category_model.Category? category; // Now nullable
  final VoidCallback onTap;
  final Function(bool?) onCompletedChanged;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.category, // Now optional
    required this.onTap,
    required this.onCompletedChanged,
    this.onDelete,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);
    
    // Use theme primary color if no category is selected
    final categoryColor = category?.color ?? theme.colorScheme.primary;
    
    return mat.Dismissible(
      key: mat.Key('task-${task.id}'),
      direction: mat.DismissDirection.endToStart,
      background: mat.Container(
        alignment: mat.Alignment.centerRight,
        padding: const mat.EdgeInsets.only(right: 20.0),
        color: colorScheme.error,
        child: mat.Icon(
          mat.Icons.delete,
          color: colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        if (onDelete == null) return false;
        
        final confirmed = await mat.showDialog<bool>(
          context: context,
          builder: (context) => mat.AlertDialog(
            title: const mat.Text('Delete Task'),
            content: const mat.Text('Are you sure you want to delete this task?'),
            actions: [
              mat.TextButton(
                onPressed: () => mat.Navigator.of(context).pop(false),
                child: const mat.Text('CANCEL'),
              ),
              mat.TextButton(
                onPressed: () => mat.Navigator.of(context).pop(true),
                child: mat.Text(
                  'DELETE',
                  style: mat.TextStyle(color: colorScheme.error),
                ),
              ),
            ],
          ),
        );
        
        return confirmed ?? false;
      },
      onDismissed: (direction) => onDelete?.call(),
      child: mat.Card(
        margin: const mat.EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: mat.InkWell(
          onTap: onTap,
          borderRadius: mat.BorderRadius.circular(16),
          child: mat.Stack(
            children: [
              // Background indicator for overdue/days left
              if (task.dueDate != null && !task.isCompleted)
                _buildBackgroundIndicator(task.dueDate!, theme),
              
              // Main card content
              mat.Padding(
                padding: const mat.EdgeInsets.all(16.0),
                child: mat.Row(
                  crossAxisAlignment: mat.CrossAxisAlignment.start,
                  children: [
                    mat.Checkbox(
                      value: task.isCompleted,
                      onChanged: onCompletedChanged,
                      shape: const mat.CircleBorder(),
                      activeColor: categoryColor, // Use category color or default
                    ),
                    const mat.SizedBox(width: 8),
                    mat.Expanded(
                      child: mat.Column(
                        crossAxisAlignment: mat.CrossAxisAlignment.start,
                        children: [
                          mat.Row(
                            children: [
                              mat.Expanded(
                                child: mat.Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: task.isCompleted
                                        ? mat.TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? theme.colorScheme.onSurface.withAlpha(128)
                                        : null,
                                    fontWeight: mat.FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: mat.TextOverflow.ellipsis,
                                ),
                              ),
                              priority_badge.PriorityBadge(priority: task.priority),
                            ],
                          ),
                          if (task.description.isNotEmpty) ...[
                            const mat.SizedBox(height: 8),
                            mat.Text(
                              task.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: task.isCompleted
                                    ? theme.colorScheme.onSurface.withAlpha(128)
                                    : null,
                                decoration: task.isCompleted
                                    ? mat.TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 2,
                              overflow: mat.TextOverflow.ellipsis,
                            ),
                          ],
                          const mat.SizedBox(height: 8),
                          mat.Row(
                            children: [
                              // Only show category if one is assigned
                              if (category != null) 
                                mat.Container(
                                  padding: const mat.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: mat.BoxDecoration(
                                    color: category!.color.withAlpha(51),
                                    borderRadius: mat.BorderRadius.circular(8),
                                  ),
                                  child: mat.Text(
                                    category!.name,
                                    style: mat.TextStyle(
                                      color: category!.color,
                                      fontSize: 12,
                                      fontWeight: mat.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (category != null && task.dueDate != null)
                                const mat.SizedBox(width: 8),
                              if (task.dueDate != null) ...[
                                mat.Icon(
                                  mat.Icons.access_time,
                                  size: 14,
                                  color: _getDueDateColor(task.dueDate!, theme),
                                ),
                                const mat.SizedBox(width: 4),
                                mat.Text(
                                  _formatDueDate(task.dueDate!, timeFormatProvider.isEuropean),
                                  style: mat.TextStyle(
                                    color: _getDueDateColor(task.dueDate!, theme),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  mat.Widget _buildBackgroundIndicator(DateTime dueDate, mat.ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    String text;
    mat.Color color;
    
    if (taskDate.isBefore(today)) {
      // Task is overdue
      text = 'OVERDUE';
      color = mat.Colors.red.withAlpha(51); // 20% opacity
    } else if (taskDate.isAtSameMomentAs(today)) {
      // Task is due today
      text = 'TODAY';
      color = mat.Colors.red.withAlpha(51); // 20% opacity
    } else {
      // Task is in the future - calculate days left
      final daysLeft = taskDate.difference(today).inDays;
      text = '$daysLeft DAYS LEFT';
      
      if (daysLeft <= 5) {
        color = mat.Colors.yellow.withAlpha(51); // 20% opacity
      } else {
        color = mat.Colors.green.withAlpha(51); // 20% opacity
      }
    }
    
    return mat.Positioned.fill(
      child: mat.Container(
        alignment: mat.Alignment.center,
        child: mat.Transform.rotate(
          angle: -0.1, // Slight rotation for visual effect
          child: mat.Text(
            text,
            style: mat.TextStyle(
              fontSize: 24,
              fontWeight: mat.FontWeight.bold,
              color: color.withAlpha(77), // More faded for background effect
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate, bool isEuropean) {
    final dateFormat = intl.DateFormat('MMM d, yyyy');
    final timeFormat = isEuropean 
        ? intl.DateFormat('HH:mm')
        : intl.DateFormat('h:mm a');
    
    return '${dateFormat.format(dueDate)} · ${timeFormat.format(dueDate)}';
  }

  mat.Color _getDueDateColor(DateTime dueDate, mat.ThemeData theme) {
    final now = DateTime.now();
    
    // If the task is completed, use a muted color
    if (task.isCompleted) {
      return theme.colorScheme.onSurface.withAlpha(128);
    }
    
    // If the due date is today
    if (dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day) {
      return task.priority == task_model.Priority.high
          ? mat.Colors.red
          : mat.Colors.orange;
    }
    
    // If the due date is in the past
    if (dueDate.isBefore(now)) {
      return mat.Colors.red;
    }
    
    // If the due date is tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (dueDate.year == tomorrow.year && dueDate.month == tomorrow.month && dueDate.day == tomorrow.day) {
      return mat.Colors.orange;
    }
    
    // If the due date is within the next 3 days
    final threeDaysLater = now.add(const Duration(days: 3));
    if (dueDate.isBefore(threeDaysLater)) {
      return theme.colorScheme.secondary;
    }
    
    // Otherwise, use the default text color
    return theme.colorScheme.onSurface.withAlpha(179); // Equivalent to 70% opacity
  }
}