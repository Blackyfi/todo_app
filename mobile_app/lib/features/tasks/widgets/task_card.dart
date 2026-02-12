import 'package:flutter/material.dart' as mat;
import 'dart:ui';
import 'dart:async';
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

class TaskCard extends mat.StatefulWidget {
  final task_model.Task task;
  final category_model.Category? category;
  final VoidCallback onTap;
  final Function(bool?) onCompletedChanged;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    required this.onCompletedChanged,
    this.onDelete,
  });

  @override
  mat.State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends mat.State<TaskCard> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Only start timer if task has a due date and is not completed
    if (widget.task.dueDate != null && !widget.task.isCompleted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          final now = DateTime.now();
          final previousTime = _currentTime;
          _currentTime = now;
          
          // Check if we need to update the UI
          if (_shouldUpdateUI(previousTime, now)) {
            setState(() {});
          }
        }
      });
    }
  }

  bool _shouldUpdateUI(DateTime previousTime, DateTime currentTime) {
    if (widget.task.dueDate == null) return false;
    
    final dueDate = widget.task.dueDate!;
    
    // Check if we crossed the due time boundary
    final wasOverdue = previousTime.isAfter(dueDate);
    final isNowOverdue = currentTime.isAfter(dueDate);
    
    // Update if overdue status changed
    if (wasOverdue != isNowOverdue) {
      return true;
    }
    
    // Check if we crossed a day boundary that affects the display
    final previousDay = DateTime(previousTime.year, previousTime.month, previousTime.day);
    final currentDay = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    // Update if the day changed (for day counter updates)
    if (previousDay != currentDay) {
      return true;
    }
    
    return false;
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Restart timer if task properties changed
    if (oldWidget.task.dueDate != widget.task.dueDate ||
        oldWidget.task.isCompleted != widget.task.isCompleted) {
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);
    
    // Use theme primary color if no category is selected
    final categoryColor = widget.category?.color ?? theme.colorScheme.primary;
    
    return mat.Dismissible(
      key: mat.Key('task-${widget.task.id}'),
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
        if (widget.onDelete == null) return false;
        
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
      onDismissed: (direction) => widget.onDelete?.call(),
      child: mat.Card(
        margin: const mat.EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: mat.InkWell(
          onTap: widget.onTap,
          borderRadius: mat.BorderRadius.circular(16),
          child: mat.Stack(
            children: [
              // Background indicator for overdue/days left
              if (widget.task.dueDate != null && !widget.task.isCompleted)
                _buildBackgroundIndicator(widget.task.dueDate!, theme, _currentTime),
              
              // Main card content
              mat.Padding(
                padding: const mat.EdgeInsets.all(16.0),
                child: mat.Row(
                  crossAxisAlignment: mat.CrossAxisAlignment.start,
                  children: [
                    mat.Checkbox(
                      value: widget.task.isCompleted,
                      onChanged: widget.onCompletedChanged,
                      shape: const mat.CircleBorder(),
                      activeColor: categoryColor,
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
                                  widget.task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: widget.task.isCompleted
                                        ? mat.TextDecoration.lineThrough
                                        : null,
                                    color: widget.task.isCompleted
                                        ? theme.colorScheme.onSurface.withAlpha(128)
                                        : null,
                                    fontWeight: mat.FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: mat.TextOverflow.ellipsis,
                                ),
                              ),
                              priority_badge.PriorityBadge(priority: widget.task.priority),
                            ],
                          ),
                          if (widget.task.description.isNotEmpty) ...[
                            const mat.SizedBox(height: 8),
                            mat.Text(
                              widget.task.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.task.isCompleted
                                    ? theme.colorScheme.onSurface.withAlpha(128)
                                    : null,
                                decoration: widget.task.isCompleted
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
                              if (widget.category != null) 
                                mat.Container(
                                  padding: const mat.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: mat.BoxDecoration(
                                    color: widget.category!.color.withAlpha(51),
                                    borderRadius: mat.BorderRadius.circular(8),
                                  ),
                                  child: mat.Text(
                                    widget.category!.name,
                                    style: mat.TextStyle(
                                      color: widget.category!.color,
                                      fontSize: 12,
                                      fontWeight: mat.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (widget.category != null && widget.task.dueDate != null)
                                const mat.SizedBox(width: 8),
                              if (widget.task.dueDate != null) ...[
                                mat.Icon(
                                  mat.Icons.access_time,
                                  size: 14,
                                  color: _getDueDateColor(widget.task.dueDate!, theme, _currentTime),
                                ),
                                const mat.SizedBox(width: 4),
                                mat.Text(
                                  _formatDueDate(widget.task.dueDate!, timeFormatProvider.isEuropean),
                                  style: mat.TextStyle(
                                    color: _getDueDateColor(widget.task.dueDate!, theme, _currentTime),
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

  mat.Widget _buildBackgroundIndicator(DateTime dueDate, mat.ThemeData theme, DateTime currentTime) {
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    String text;
    mat.Color color;
    
    if (taskDate.isBefore(today)) {
      // Task is overdue (date is in the past)
      text = 'OVERDUE';
      color = mat.Colors.red.withAlpha(51);
    } else if (taskDate.isAtSameMomentAs(today)) {
      // Task is due today - check if the time has passed
      if (dueDate.isBefore(currentTime)) {
        // Time has passed, task is overdue
        text = 'OVERDUE';
        color = mat.Colors.red.withAlpha(51);
      } else {
        // Time hasn't passed yet, task is due today
        text = 'TODAY';
        color = mat.Colors.red.withAlpha(51);
      }
    } else {
      // Task is in the future - calculate days left
      final daysLeft = taskDate.difference(today).inDays;
      text = '$daysLeft DAYS LEFT';
      
      if (daysLeft <= 5) {
        color = mat.Colors.yellow.withAlpha(51);
      } else {
        color = mat.Colors.green.withAlpha(51);
      }
    }
    
    return mat.Positioned.fill(
      child: mat.Container(
        alignment: mat.Alignment.center,
        child: mat.Transform.rotate(
          angle: -0.1,
          child: mat.Text(
            text,
            style: mat.TextStyle(
              fontSize: 24,
              fontWeight: mat.FontWeight.bold,
              color: color.withAlpha(77),
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

  mat.Color _getDueDateColor(DateTime dueDate, mat.ThemeData theme, DateTime currentTime) {
    // If the task is completed, use a muted color
    if (widget.task.isCompleted) {
      return theme.colorScheme.onSurface.withAlpha(128);
    }
    
    // If the due date is today
    if (dueDate.year == currentTime.year && dueDate.month == currentTime.month && dueDate.day == currentTime.day) {
      return widget.task.priority == task_model.Priority.high
          ? mat.Colors.red
          : mat.Colors.orange;
    }
    
    // If the due date is in the past
    if (dueDate.isBefore(currentTime)) {
      return mat.Colors.red;
    }
    
    // If the due date is tomorrow
    final tomorrow = currentTime.add(const Duration(days: 1));
    if (dueDate.year == tomorrow.year && dueDate.month == tomorrow.month && dueDate.day == tomorrow.day) {
      return mat.Colors.orange;
    }
    
    // If the due date is within the next 3 days
    final threeDaysLater = currentTime.add(const Duration(days: 3));
    if (dueDate.isBefore(threeDaysLater)) {
      return theme.colorScheme.secondary;
    }
    
    // Otherwise, use the default text color
    return theme.colorScheme.onSurface.withAlpha(179);
  }
}