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
import 'package:todo_app/features/categories/widgets/category_list_item.dart';
import 'package:todo_app/features/categories/widgets/category_dialog.dart';
import 'package:todo_app/features/statistics/widgets/summary_card.dart' as summary_card;
import 'package:todo_app/features/statistics/widgets/chart_cards.dart' as chart_cards;
import 'package:todo_app/features/statistics/utils/statistics_helpers.dart' as statistics_helpers;

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
  Map<int, int> _taskCountsByCategory = {};
  String _currentFilter = app_constants.AppConstants.allTasks;
  bool _isLoading = true;
  
  late mat.TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = mat.TabController(length: 3, vsync: this);
    _loadData();
    
    // Check for notification permissions after a short delay to ensure the UI is built
    Future.delayed(const Duration(milliseconds: 500), () {
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
      
      // Calculate task counts by category
      final taskCountsByCategory = <int, int>{};
      for (final category in categories) {
        if (category.id != null) {
          final categoryTasks = await _taskRepository.getTasksByCategory(category.id!);
          taskCountsByCategory[category.id!] = categoryTasks.length;
        }
      }
      
      setState(() {
        _tasks = tasks;
        _categories = categories;
        _taskCountsByCategory = taskCountsByCategory;
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
      final hasPermissions = await notificationService.areNotificationPermissionsGranted();
      
      if (!hasPermissions && mounted) {
        await notificationService.showNotificationPermissionDialog(context);
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error checking notification permissions', e, stackTrace);
    }
  }

  Future<void> _showAddEditCategoryDialog([category_model.Category? category]) async {
    final isEditing = category != null;
    
    final result = await showCategoryDialog(
      context: context,
      category: category,
    );
    
    if (result != null) {
      try {
        if (isEditing) {
          final updatedCategory = category.copyWith(
            name: result['name'],
            color: result['color'],
          );
          await _categoryRepository.updateCategory(updatedCategory);
        } else {
          final newCategory = category_model.Category(
            name: result['name'],
            color: result['color'],
          );
          await _categoryRepository.insertCategory(newCategory);
        }
        
        await _loadData();
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
  }
  
  Future<void> _deleteCategory(category_model.Category category) async {
    final taskCount = _taskCountsByCategory[category.id] ?? 0;
    
    final confirmed = await mat.showDialog<bool>(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: const mat.Text('Delete Category'),
        content: mat.Text(
          taskCount > 0
              ? 'This category contains $taskCount task(s). Deleting it will also delete all associated tasks. Are you sure?'
              : 'Are you sure you want to delete this category?',
        ),
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
    
    if (confirmed == true && category.id != null) {
      try {
        await _categoryRepository.deleteCategory(category.id!);
        await _loadData();
        
        if (mounted) {
          mat.ScaffoldMessenger.of(context).showSnackBar(
            const mat.SnackBar(
              content: mat.Text('Category deleted'),
            ),
          );
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
                
                // Categories Tab - Direct content display
                _categories.isEmpty
                    ? empty_state.EmptyState(
                        message: 'No categories found',
                        icon: mat.Icons.category,
                        actionLabel: 'Add Category',
                        onActionPressed: () => _showAddEditCategoryDialog(),
                      )
                    : mat.ListView.builder(
                        itemCount: _categories.length,
                        padding: const mat.EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final taskCount = _taskCountsByCategory[category.id] ?? 0;
                          
                          return CategoryListItem(
                            category: category,
                            taskCount: taskCount,
                            onEdit: () => _showAddEditCategoryDialog(category),
                            onDelete: () => _deleteCategory(category),
                          );
                        },
                      ),
                
                // Statistics Tab - Direct content display
                mat.SingleChildScrollView(
                  physics: const mat.AlwaysScrollableScrollPhysics(),
                  padding: const mat.EdgeInsets.all(16),
                  child: mat.Column(
                    crossAxisAlignment: mat.CrossAxisAlignment.start,
                    children: [
                      summary_card.SummaryCard(tasks: _tasks),
                      const mat.SizedBox(height: 16),
                      chart_cards.CompletionChart(
                        stats: statistics_helpers.getCompletionStats(_tasks),
                      ),
                      const mat.SizedBox(height: 16),
                      chart_cards.PriorityChart(
                        stats: statistics_helpers.getPriorityStats(_tasks),
                      ),
                      const mat.SizedBox(height: 16),
                      chart_cards.CategoryChart(
                        stats: statistics_helpers.getCategoryStats(_tasks, _categories),
                        categories: _categories,
                      ),
                      const mat.SizedBox(height: 16),
                      chart_cards.WeeklyTasksCard(
                        tasks: statistics_helpers.getTasksDueThisWeek(_tasks),
                        categories: _categories,
                      ),
                      const mat.SizedBox(height: 16),
                      chart_cards.WeeklyCompletionChart(
                        stats: statistics_helpers.getTasksCompletedByDay(_tasks),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? mat.FloatingActionButton(
              onPressed: _navigateToAddTask,
              child: const mat.Icon(mat.Icons.add),
            )
          : _tabController.index == 1
              ? mat.FloatingActionButton(
                  onPressed: () => _showAddEditCategoryDialog(),
                  child: const mat.Icon(mat.Icons.add),
                )
              : null,
    );
  }
}