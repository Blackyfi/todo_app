import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/category_chip.dart' as category_chip;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/notification_repository.dart' as notification_repository;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:intl/intl.dart' as intl;

class AddEditTaskScreen extends mat.StatefulWidget {
  final task_model.Task? task;

  const AddEditTaskScreen({
    mat.Key? key,
    this.task,
  }) : super(key: key);

  @override
  mat.State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends mat.State<AddEditTaskScreen> {
  final _formKey = mat.GlobalKey<mat.FormState>();
  final _titleController = mat.TextEditingController();
  final _descriptionController = mat.TextEditingController();
  
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  final _notificationRepository = notification_repository.NotificationRepository();
  final _notificationService = notification_service.NotificationService();
  
  List<category_model.Category> _categories = [];
  int? _selectedCategoryId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  task_model.Priority _priority = task_model.Priority.medium;
  bool _isLoading = true;
  
  final List<notification_model.NotificationTimeOption> _selectedNotificationOptions = [];
  DateTime? _customNotificationTime;
  
  bool get _isEditMode => widget.task != null;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryRepository.getAllCategories();
      
      setState(() {
        _categories = categories;
        
        if (_isEditMode) {
          final task = widget.task!;
          _titleController.text = task.title;
          _descriptionController.text = task.description;
          _selectedCategoryId = task.categoryId;
          _priority = task.priority;
          
          if (task.dueDate != null) {
            _dueDate = DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            );
            _dueTime = TimeOfDay.fromDateTime(task.dueDate!);
          }
          
          _loadNotificationSettings();
        } else if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
        
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
  
  Future<void> _loadNotificationSettings() async {
    if (!_isEditMode || widget.task?.id == null) return;
    
    try {
      final settings = await _notificationRepository.getNotificationSettingsForTask(widget.task!.id!);
      
      setState(() {
        for (final setting in settings) {
          _selectedNotificationOptions.add(setting.timeOption);
          if (setting.timeOption == notification_model.NotificationTimeOption.custom) {
            _customNotificationTime = setting.customTime;
          }
        }
      });
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
  
  Future<void> _selectDueDate() async {
    final pickedDate = await mat.showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }
  
  Future<void> _selectDueTime() async {
    final pickedTime = await mat.showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    
    if (pickedTime != null && pickedTime != _dueTime) {
      setState(() {
        _dueTime = pickedTime;
      });
    }
  }
  
  Future<void> _selectCustomNotificationTime() async {
    final pickedTime = await mat.showTimePicker(
      context: context,
      initialTime: _customNotificationTime != null
          ? TimeOfDay.fromDateTime(_customNotificationTime!)
          : TimeOfDay.now(),
    );
    
    if (pickedTime != null) {
      final now = DateTime.now();
      setState(() {
        _customNotificationTime = DateTime(
          now.year,
          now.month,
          now.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
  
  void _toggleNotificationOption(notification_model.NotificationTimeOption option) {
    setState(() {
      if (_selectedNotificationOptions.contains(option)) {
        _selectedNotificationOptions.remove(option);
        if (option == notification_model.NotificationTimeOption.custom) {
          _customNotificationTime = null;
        }
      } else {
        _selectedNotificationOptions.add(option);
        if (option == notification_model.NotificationTimeOption.custom && _customNotificationTime == null) {
          _selectCustomNotificationTime();
        }
      }
    });
  }
  
  DateTime? _combineDateAndTime() {
    if (_dueDate == null) return null;
    final time = _dueTime ?? TimeOfDay.now();
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time.hour,
      time.minute,
    );
  }
  
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      mat.ScaffoldMessenger.of(context).showSnackBar(
        const mat.SnackBar(
          content: mat.Text('Please select a category'),
        ),
      );
      return;
    }
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final dueDateTime = _combineDateAndTime();
    
    try {
      int taskId;
      
      if (_isEditMode) {
        final updatedTask = widget.task!.copyWith(
          title: title,
          description: description,
          dueDate: dueDateTime,
          categoryId: _selectedCategoryId,
          priority: _priority,
        );
        
        await _taskRepository.updateTask(updatedTask);
        taskId = widget.task!.id!;
        
        // Delete existing notifications
        await _notificationRepository.deleteNotificationSettingsForTask(taskId);
      } else {
        final newTask = task_model.Task(
          title: title,
          description: description,
          dueDate: dueDateTime,
          categoryId: _selectedCategoryId!,
          priority: _priority,
        );
        
        taskId = await _taskRepository.insertTask(newTask);
      }
      
      // Save notification settings
      if (dueDateTime != null && _selectedNotificationOptions.isNotEmpty) {
        for (final option in _selectedNotificationOptions) {
          final setting = notification_model.NotificationSetting(
            taskId: taskId,
            timeOption: option,
            customTime: option == notification_model.NotificationTimeOption.custom
                ? _customNotificationTime
                : null,
          );
          
          final settingId = await _notificationRepository.insertNotificationSetting(setting);
          
          // Schedule notification
          await _notificationService.scheduleTaskNotification(
            task_model.Task(
              id: taskId,
              title: title,
              description: description,
              dueDate: dueDateTime,
              categoryId: _selectedCategoryId!,
            ),
            setting.copyWith(id: settingId),
          );
        }
      }
      
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
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: mat.Text(_isEditMode ? 'Edit Task' : 'Add Task'),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.Form(
              key: _formKey,
              child: mat.SingleChildScrollView(
                padding: const mat.EdgeInsets.all(16),
                child: mat.Column(
                  crossAxisAlignment: mat.CrossAxisAlignment.start,
                  children: [
                    mat.TextFormField(
                      controller: _titleController,
                      decoration: const mat.InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        prefixIcon: mat.Icon(mat.Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const mat.SizedBox(height: 16),
                    
                    mat.TextFormField(
                      controller: _descriptionController,
                      decoration: const mat.InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter task description (optional)',
                        prefixIcon: mat.Icon(mat.Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    
                    const mat.SizedBox(height: 16),
                    
                    mat.Text(
                      'Due Date & Time',
                      style: theme.textTheme.titleMedium,
                    ),
                    const mat.SizedBox(height: 8),
                    mat.Row(
                      children: [
                        mat.Expanded(
                          child: mat.InkWell(
                            onTap: _selectDueDate,
                            borderRadius: mat.BorderRadius.circular(12),
                            child: mat.Container(
                              padding: const mat.EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: mat.BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: mat.BorderRadius.circular(12),
                                border: mat.Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: mat.Row(
                                children: [
                                  mat.Icon(
                                    mat.Icons.calendar_today,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const mat.SizedBox(width: 8),
                                  mat.Expanded(
                                    child: mat.Text(
                                      _dueDate != null
                                          ? intl.DateFormat('MMM d, yyyy').format(_dueDate!)
                                          : 'Select Date',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const mat.SizedBox(width: 8),
                        mat.Expanded(
                          child: mat.InkWell(
                            onTap: _selectDueTime,
                            borderRadius: mat.BorderRadius.circular(12),
                            child: mat.Container(
                              padding: const mat.EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: mat.BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: mat.BorderRadius.circular(12),
                                border: mat.Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: mat.Row(
                                children: [
                                  mat.Icon(
                                    mat.Icons.access_time,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const mat.SizedBox(width: 8),
                                  mat.Expanded(
                                    child: mat.Text(
                                      _dueTime != null
                                          ? _dueTime!.format(context)
                                          : 'Select Time',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const mat.SizedBox(height: 16),
                    
                    mat.Text(
                      'Category',
                      style: theme.textTheme.titleMedium,
                    ),
                    const mat.SizedBox(height: 8),
                    mat.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        return category_chip.CategoryChip(
                          category: category,
                          isSelected: _selectedCategoryId == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    
                    const mat.SizedBox(height: 16),
                    
                    mat.Text(
                      'Priority',
                      style: theme.textTheme.titleMedium,
                    ),
                    const mat.SizedBox(height: 8),
                    mat.SegmentedButton<task_model.Priority>(
                      segments: [
                        mat.ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.low,
                          label: mat.Row(
                            mainAxisSize: mat.MainAxisSize.min,
                            children: [
                              mat.Container(
                                width: 12,
                                height: 12,
                                decoration: const mat.BoxDecoration(
                                  shape: mat.BoxShape.circle,
                                  color: mat.Colors.green,
                                ),
                              ),
                              const mat.SizedBox(width: 4),
                              const mat.Text('Low'),
                            ],
                          ),
                        ),
                        mat.ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.medium,
                          label: mat.Row(
                            mainAxisSize: mat.MainAxisSize.min,
                            children: [
                              mat.Container(
                                width: 12,
                                height: 12,
                                decoration: const mat.BoxDecoration(
                                  shape: mat.BoxShape.circle,
                                  color: mat.Colors.orange,
                                ),
                              ),
                              const mat.SizedBox(width: 4),
                              const mat.Text('Medium'),
                            ],
                          ),
                        ),
                        mat.ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.high,
                          label: mat.Row(
                            mainAxisSize: mat.MainAxisSize.min,
                            children: [
                              mat.Container(
                                width: 12,
                                height: 12,
                                decoration: const mat.BoxDecoration(
                                  shape: mat.BoxShape.circle,
                                  color: mat.Colors.red,
                                ),
                              ),
                              const mat.SizedBox(width: 4),
                              const mat.Text('High'),
                            ],
                          ),
                        ),
                      ],
                      selected: {_priority},
                      onSelectionChanged: (Set<task_model.Priority> selection) {
                        setState(() {
                          _priority = selection.first;
                        });
                      },
                    ),
                    
                    if (_dueDate != null && _dueTime != null) ...[
                      const mat.SizedBox(height: 16),
                      mat.Text(
                        'Reminders',
                        style: theme.textTheme.titleMedium,
                      ),
                      const mat.SizedBox(height: 8),
                      mat.Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: notification_model.NotificationTimeOption.values.map((option) {
                          final isSelected = _selectedNotificationOptions.contains(option);
                          return mat.FilterChip(
                            label: mat.Text(option.label),
                            selected: isSelected,
                            onSelected: (_) => _toggleNotificationOption(option),
                            avatar: isSelected
                                ? const mat.Icon(mat.Icons.notifications_active, size: 18)
                                : const mat.Icon(mat.Icons.notifications_none, size: 18),
                          );
                        }).toList(),
                      ),
                      
                      if (_selectedNotificationOptions.contains(notification_model.NotificationTimeOption.custom) &&
                          _customNotificationTime != null) ...[
                        const mat.SizedBox(height: 8),
                        mat.InkWell(
                          onTap: _selectCustomNotificationTime,
                          borderRadius: mat.BorderRadius.circular(12),
                          child: mat.Container(
                            padding: const mat.EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: mat.BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: mat.BorderRadius.circular(12),
                              border: mat.Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: mat.Row(
                              children: [
                                mat.Icon(
                                  mat.Icons.access_time,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const mat.SizedBox(width: 8),
                                mat.Text(
                                  'Custom Time: ${intl.DateFormat('h:mm a').format(_customNotificationTime!)}',
                                ),
                                const mat.Spacer(),
                                mat.Icon(
                                  mat.Icons.edit,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: mat.SafeArea(
        child: mat.Padding(
          padding: const mat.EdgeInsets.all(16),
          child: mat.FilledButton(
            onPressed: _saveTask,
            style: mat.FilledButton.styleFrom(
              padding: const mat.EdgeInsets.all(16),
              shape: mat.RoundedRectangleBorder(
                borderRadius: mat.BorderRadius.circular(16),
              ),
            ),
            child: mat.Text(
              _isEditMode ? 'Update Task' : 'Create Task',
              style: const mat.TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
                