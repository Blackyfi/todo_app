import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/notification_repository.dart' as notification_repository;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:intl/intl.dart' as intl;

class TaskDetailsScreen extends mat.StatefulWidget {
  final task_model.Task task;

  const TaskDetailsScreen({
    mat.Key? key,
    required this.task,
  }) : super(key: key);

  @override
  mat.State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends mat.State<TaskDetailsScreen> {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  final _notificationRepository = notification_repository.NotificationRepository();
  
  category_model.Category? _category;
  List<notification_model.NotificationSetting> _notificationSettings = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final category = await _categoryRepository.getCategory(widget.task.categoryId);
      final notificationSettings = await _notificationRepository.getNotificationSettingsForTask(widget.task.id!);
      
      setState(() {
        _category = category;
        _notificationSettings = notificationSettings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Future<void> _toggleTaskCompletion() async {
    try {
      final updatedTask = widget.task.copyWith(isCompleted: !widget.task.isCompleted);
      await _taskRepository.updateTask(updatedTask);
      mat.Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Future<void> _deleteTask() async {
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
              style: mat.TextStyle(color: mat.Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _taskRepository.deleteTask(widget.task.id!);
      if (mounted) {
        mat.Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  void _navigateToEditTask() {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.editTaskRoute,
      arguments: widget.task,
    ).then((_) => mat.Navigator.of(context).pop());
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: const mat.Text('Task Details'),
        actions: [
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.edit),
            onPressed: _navigateToEditTask,
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.SingleChildScrollView(
              padding: const mat.EdgeInsets.all(16),
              child: mat.Column(
                crossAxisAlignment: mat.CrossAxisAlignment.start,
                children: [
                  mat.Row(
                    children: [
                      mat.Expanded(
                        child: mat.Text(
                          widget.task.title,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      priority_badge.PriorityBadge(
                        priority: widget.task.priority,
                        size: 16,
                      ),
                    ],
                  ),
                  
                  const mat.SizedBox(height: 16),
                  
                  if (_category != null) ...[
                    mat.Row(
                      children: [
                        mat.Icon(
                          mat.Icons.category,
                          color: _category!.color,
                          size: 20,
                        ),
                        const mat.SizedBox(width: 8),
                        mat.Text(
                          'Category: ${_category!.name}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _category!.color,
                          ),
                        ),
                      ],
                    ),
                    const mat.SizedBox(height: 16),
                  ],
                  
                  if (widget.task.dueDate != null) ...[
                    mat.Row(
                      children: [
                        mat.Icon(
                          mat.Icons.event,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const mat.SizedBox(width: 8),
                        mat.Text(
                          'Due Date: ${intl.DateFormat('EEEE, MMMM d, yyyy').format(widget.task.dueDate!)}',
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
                          'Due Time: ${intl.DateFormat('h:mm a').format(widget.task.dueDate!)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const mat.SizedBox(height: 16),
                  ],
                  
                  mat.Row(
                    children: [
                      mat.Icon(
                        widget.task.isCompleted
                            ? mat.Icons.check_circle
                            : mat.Icons.radio_button_unchecked,
                        color: widget.task.isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      const mat.SizedBox(width: 8),
                      mat.Text(
                        'Status: ${widget.task.isCompleted ? 'Completed' : 'Incomplete'}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  
                  const mat.SizedBox(height: 24),
                  
                  mat.Text(
                    'Description',
                    style: theme.textTheme.titleLarge,
                  ),
                  const mat.SizedBox(height: 8),
                  mat.Container(
                    width: double.infinity,
                    padding: const mat.EdgeInsets.all(16),
                    decoration: mat.BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: mat.BorderRadius.circular(16),
                    ),
                    child: mat.Text(
                      widget.task.description.isEmpty
                          ? 'No description provided'
                          : widget.task.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: widget.task.description.isEmpty
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : null,
                      ),
                    ),
                  ),
                  
                  if (_notificationSettings.isNotEmpty) ...[
                    const mat.SizedBox(height: 24),
                    mat.Text(
                      'Reminders',
                      style: theme.textTheme.titleLarge,
                    ),
                    const mat.SizedBox(height: 8),
                    ...List.generate(_notificationSettings.length, (index) {
                      final setting = _notificationSettings[index];
                      return mat.Padding(
                        padding: const mat.EdgeInsets.only(bottom: 8),
                        child: mat.Container(
                          padding: const mat.EdgeInsets.all(12),
                          decoration: mat.BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                    }),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: mat.SafeArea(
        child: mat.Padding(
          padding: const mat.EdgeInsets.all(16),
          child: mat.FilledButton(
            onPressed: _toggleTaskCompletion,
            style: mat.FilledButton.styleFrom(
              padding: const mat.EdgeInsets.all(16),
              shape: mat.RoundedRectangleBorder(
                borderRadius: mat.BorderRadius.circular(16),
              ),
            ),
            child: mat.Text(
              widget.task.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
              style: const mat.TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
