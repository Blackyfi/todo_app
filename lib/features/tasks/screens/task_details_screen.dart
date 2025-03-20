import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/notification_repository.dart' as notification_repository;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/features/tasks/widgets/task_detail_sections.dart';

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
      final category = widget.task.categoryId != null
          ? await _categoryRepository.getCategory(widget.task.categoryId!)
          : null;
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
              child: TaskDetailContent(
                task: widget.task,
                category: _category,
                notificationSettings: _notificationSettings,
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