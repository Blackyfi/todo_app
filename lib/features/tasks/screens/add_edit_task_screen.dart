import 'package:flutter/material.dart';
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

class AddEditTaskScreen extends StatefulWidget {
  final task_model.Task? task;

  const AddEditTaskScreen({
    Key? key,
    this.task,
  }) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(app_constants.AppConstants.databaseErrorMessage),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Future<void> _selectDueDate() async {
    final pickedDate = await showDatePicker(
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
    final pickedTime = await showTimePicker(
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
    final pickedTime = await showTimePicker(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
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
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'Add Task'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter task title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter task description (optional)',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Due Date & Time',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDueDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDueTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
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
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Category',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
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
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Priority',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<task_model.Priority>(
                      segments: [
                        ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.low,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('Low'),
                            ],
                          ),
                        ),
                        ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.medium,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('Medium'),
                            ],
                          ),
                        ),
                        ButtonSegment<task_model.Priority>(
                          value: task_model.Priority.high,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('High'),
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
                      const SizedBox(height: 16),
                      Text(
                        'Reminders',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: notification_model.NotificationTimeOption.values.map((option) {
                          final isSelected = _selectedNotificationOptions.contains(option);
                          return FilterChip(
                            label: Text(option.label),
                            selected: isSelected,
                            onSelected: (_) => _toggleNotificationOption(option),
                            avatar: isSelected
                                ? const Icon(Icons.notifications_active, size: 18)
                                : const Icon(Icons.notifications_none, size: 18),
                          );
                        }).toList(),
                      ),
                      
                      if (_selectedNotificationOptions.contains(notification_model.NotificationTimeOption.custom) &&
                          _customNotificationTime != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectCustomNotificationTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Custom Time: ${intl.DateFormat('h:mm a').format(_customNotificationTime!)}',
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.edit,
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saveTask,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _isEditMode ? 'Update Task' : 'Create Task',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
