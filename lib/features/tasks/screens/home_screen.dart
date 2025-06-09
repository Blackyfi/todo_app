import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/empty_state.dart' as empty_state;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/features/tasks/widgets/task_card.dart' as task_card;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;

class HomeScreen extends mat.StatefulWidget {
  const HomeScreen({super.key});

  @override
  mat.State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends mat.State<HomeScreen> with mat.SingleTickerProviderStateMixin {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  final _logger = LoggerService();
  final _autoDeleteSettingsRepository = AutoDeleteSettingsRepository();
  
  List<task_model.Task> _tasks = [];
  List<category_model.Category> _categories = [];
  String _currentFilter = app_constants.AppConstants.allTasks;
  bool _isLoading = true;
  
  late mat.TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = mat.TabController(length: 3, vsync: this);
    _loadData();
    
    // Check for notification permissions after a longer delay to ensure the UI is fully built
    Future.delayed(const Duration(milliseconds: 1500), () {
      _checkNotificationPermissions();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _logger.logInfo('Loading tasks and categories in HomeScreen');
      final tasks = await _taskRepository.getAllTasks();
      final categories = await _categoryRepository.getAllCategories();
      
      setState(() {
        _tasks = tasks;
        _categories = categories;
        _isLoading = false;
      });
      
      await _logger.logInfo('Loaded ${tasks.length} tasks and ${categories.length} categories');
    } catch (e, stackTrace) {
      await _logger.logError('Error loading data in HomeScreen', e, stackTrace);
      
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
  
  Future<void> _toggleTaskCompletion(task_model.Task task) async {
    try {
      // Instead of creating an updated task here, we'll use the repository method
      if (task.id != null) {
        await _taskRepository.toggleTaskCompletion(task.id!, !task.isCompleted);
        await _loadData();
        
        // If task was marked as completed, show a snackbar indicating it will be auto-deleted
        if (!task.isCompleted) {
          final autoDeleteSettings = await _autoDeleteSettingsRepository.getSettings();
          if (autoDeleteSettings.deleteImmediately) {
            if (mounted) {
              mat.ScaffoldMessenger.of(context).showSnackBar(
                const mat.SnackBar(
                  content: mat.Text('Task marked complete and will be deleted immediately'),
                ),
              );
            }
          } else {
            if (mounted) {
              mat.ScaffoldMessenger.of(context).showSnackBar(
                mat.SnackBar(
                  content: mat.Text(
                    'Task marked complete and will be deleted after ${autoDeleteSettings.deleteAfterDays} day(s)'
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error toggling task completion', e, stackTrace);
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Future<void> _deleteTask(int taskId) async {
    try {
      await _taskRepository.deleteTask(taskId);
      await _loadData();
      
      await _logger.logInfo('Task deleted: ID=$taskId');
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text('Task deleted'),
          ),
        );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting task', e, stackTrace);
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  void _navigateToTaskDetails(task_model.Task task) {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.taskDetailsRoute,
      arguments: task,
    ).then((_) => _loadData());
  }
  
  void _navigateToAddTask() {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.addTaskRoute,
    ).then((_) => _loadData());
  }
  
  void _navigateToSettings() {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.settingsRoute,
    );
  }
  
  List<task_model.Task> _getFilteredTasks() {
    switch (_currentFilter) {
      case app_constants.AppConstants.completedTasks:
        return _tasks.where((task) => task.isCompleted).toList();
      case app_constants.AppConstants.incompleteTasks:
        return _tasks.where((task) => !task.isCompleted).toList();
      case app_constants.AppConstants.todayTasks:
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return _tasks.where((task) => 
          task.dueDate != null && 
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day) == today
        ).toList();
      case app_constants.AppConstants.upcomingTasks:
        final now = DateTime.now();
        return _tasks.where((task) => 
          task.dueDate != null && 
          task.dueDate!.isAfter(now) &&
          !task.isCompleted
        ).toList();
      default:
        return _tasks;
    }
  }
  
  category_model.Category? _getCategoryForTask(task_model.Task task) {
    // If task has no category, return null
    if (task.categoryId == null) return null;
    
    return _categories.firstWhere(
      (category) => category.id == task.categoryId,
      orElse: () => category_model.Category(
        id: 0,
        name: 'Unknown',
        color: mat.Colors.grey,
      ),
    );
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final notificationService = notification_service.NotificationService();
      await notificationService.checkAndRequestPermissionsIfNeeded(context);
    } catch (e, stackTrace) {
      await _logger.logError('Error checking notification permissions', e, stackTrace);
    }
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: const mat.Text('Todo App'),
        actions: [
          mat.PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _currentFilter = value;
              });
            },
            itemBuilder: (context) => [
              const mat.PopupMenuItem(
                value: app_constants.AppConstants.allTasks,
                child: mat.Text('All Tasks'),
              ),
              const mat.PopupMenuItem(
                value: app_constants.AppConstants.completedTasks,
                child: mat.Text('Completed'),
              ),
              const mat.PopupMenuItem(
                value: app_constants.AppConstants.incompleteTasks,
                child: mat.Text('Incomplete'),
              ),
              const mat.PopupMenuItem(
                value: app_constants.AppConstants.todayTasks,
                child: mat.Text('Today'),
              ),
              const mat.PopupMenuItem(
                value: app_constants.AppConstants.upcomingTasks,
                child: mat.Text('Upcoming'),
              ),
            ],
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: mat.TabBar(
          controller: _tabController,
          tabs: const [
            mat.Tab(text: 'Tasks'),
            mat.Tab(text: 'Categories'),
            mat.Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.TabBarView(
              controller: _tabController,
              children: [
                // Tasks Tab
                filteredTasks.isEmpty
                    ? empty_state.EmptyState(
                        message: 'No tasks found',
                        icon: mat.Icons.task_alt,
                        actionLabel: 'Add Task',
                        onActionPressed: _navigateToAddTask,
                      )
                    : mat.ListView.builder(
                        itemCount: filteredTasks.length,
                        padding: const mat.EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          final category = _getCategoryForTask(task);
                          
                          return task_card.TaskCard(
                            task: task,
                            category: category, // Can be null now
                            onTap: () => _navigateToTaskDetails(task),
                            onCompletedChanged: (_) => _toggleTaskCompletion(task),
                            onDelete: () => _deleteTask(task.id!),
                          );
                        },
                      ),
                
                // Categories Tab
                mat.Center(
                  child: mat.TextButton(
                    onPressed: () {
                      mat.Navigator.of(context).pushNamed(
                        app_constants.AppConstants.categoriesRoute,
                      ).then((_) => _loadData());
                    },
                    child: const mat.Text('View All Categories'),
                  ),
                ),
                
                // Statistics Tab
                mat.Center(
                  child: mat.TextButton(
                    onPressed: () {
                      mat.Navigator.of(context).pushNamed(
                        app_constants.AppConstants.statisticsRoute,
                      );
                    },
                    child: const mat.Text('View Statistics'),
                  ),
                ),
              ],
            ),
      floatingActionButton: mat.FloatingActionButton(
        onPressed: _navigateToAddTask,
        child: const mat.Icon(mat.Icons.add),
      ),
    );
  }
}