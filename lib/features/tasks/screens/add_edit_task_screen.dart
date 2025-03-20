import 'package:flutter/material.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/notification_repository.dart' as notification_repository;
import 'package:todo_app/core/notifications/models/notification_settings.dart' as notification_model;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:todo_app/features/tasks/widgets/task_form_fields.dart';
import 'package:todo_app/features/tasks/widgets/notification_option_picker.dart';
import 'package:todo_app/features/tasks/utils/task_form_helpers.dart';

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
        } else {
          _selectedCategoryId = null;
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
  
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final dueDateTime = TaskFormHelpers.combineDateAndTime(_dueDate, _dueTime);
    
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
          categoryId: _selectedCategoryId,
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
              categoryId: _selectedCategoryId,
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
                    // Basic task information
                    TaskFormFields(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      dueDate: _dueDate,
                      dueTime: _dueTime,
                      onDateSelected: (date) => setState(() => _dueDate = date),
                      onTimeSelected: (time) => setState(() => _dueTime = time),
                      categories: _categories,
                      selectedCategoryId: _selectedCategoryId,
                      onCategorySelected: (categoryId) => setState(() => _selectedCategoryId = categoryId),
                      priority: _priority,
                      onPriorityChanged: (priority) => setState(() => _priority = priority),
                    ),
                    
                    // Notification options
                    if (_dueDate != null && _dueTime != null)
                      NotificationOptionPicker(
                        selectedOptions: _selectedNotificationOptions,
                        customTime: _customNotificationTime,
                        onOptionToggled: (option) {
                          setState(() {
                            if (_selectedNotificationOptions.contains(option)) {
                              _selectedNotificationOptions.remove(option);
                              if (option == notification_model.NotificationTimeOption.custom) {
                                _customNotificationTime = null;
                              }
                            } else {
                              _selectedNotificationOptions.add(option);
                              if (option == notification_model.NotificationTimeOption.custom) {
                                TaskFormHelpers.selectCustomNotificationTime(context).then((time) {
                                  if (time != null) {
                                    setState(() => _customNotificationTime = time);
                                  }
                                });
                              }
                            }
                          });
                        },
                        onCustomTimeChanged: (dateTime) => setState(() => _customNotificationTime = dateTime),
                      ),
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