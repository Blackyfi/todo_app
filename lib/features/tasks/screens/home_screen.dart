import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/empty_state.dart' as empty_state;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/features/tasks/widgets/task_card.dart' as task_card;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;

class HomeScreen extends mat.StatefulWidget {
  const HomeScreen({mat.Key? key}) : super(key: key);

  @override
  mat.State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends mat.State<HomeScreen> with mat.SingleTickerProviderStateMixin {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  
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
      final tasks = await _taskRepository.getAllTasks();
      final categories = await _categoryRepository.getAllCategories();
      
      setState(() {
        _tasks = tasks;
        _categories = categories;
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
  
  Future<void> _toggleTaskCompletion(task_model.Task task) async {
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _taskRepository.updateTask(updatedTask);
      await _loadData();
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
  
  Future<void> _deleteTask(int taskId) async {
    try {
      await _taskRepository.deleteTask(taskId);
      await _loadData();
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text('Task deleted'),
          ),
        );
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
  
  category_model.Category _getCategoryForTask(task_model.Task task) {
    return _categories.firstWhere(
      (category) => category.id == task.categoryId,
      orElse: () => category_model.Category(
        id: 0,
        name: 'Unknown',
        color: mat.Colors.grey,
      ),
    );
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
                            category: category,
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