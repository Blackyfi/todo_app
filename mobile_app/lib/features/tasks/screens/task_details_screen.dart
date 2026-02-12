import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/notification_repository.dart' as notification_repository;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/features/tasks/widgets/task_detail_sections.dart';
import 'package:todo_app/core/sharing/models/share_data.dart';
import 'package:todo_app/core/sharing/widgets/share_dialog.dart';
import 'package:todo_app/l10n/app_localizations.dart';

class TaskDetailsScreen extends mat.StatefulWidget {
  final task_model.Task task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

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
          const mat.SnackBar(
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
      if (mounted) {
        mat.Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Future<void> _deleteTask() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await mat.showDialog<bool>(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: mat.Text(l10n.deleteTask),
        content: mat.Text(l10n.deleteTaskConfirmation),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(false),
            child: mat.Text(l10n.cancel),
          ),
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(true),
            child: mat.Text(
              l10n.delete,
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
          const mat.SnackBar(
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
    ).then((_) {
      if (mounted) {
        mat.Navigator.of(context).pop();
      }
    });
  }

  Future<void> _shareTask() async {
    final shareData = ShareData.fromTask(widget.task);

    await mat.showDialog(
      context: context,
      builder: (context) => ShareDialog(
        shareData: shareData,
        title: 'Share "${widget.task.title}"',
      ),
    );
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: mat.Text(l10n.taskDetails),
        actions: [
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.share),
            onPressed: _shareTask,
            tooltip: 'Share task',
          ),
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
              widget.task.isCompleted ? l10n.markAsIncomplete : l10n.markAsComplete,
              style: const mat.TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}