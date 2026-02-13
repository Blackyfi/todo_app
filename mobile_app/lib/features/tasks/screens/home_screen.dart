// Add this to your existing HomeScreen.dart - modifications to integrate with widgets

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
import 'package:todo_app/features/categories/screens/categories_screen.dart';
import 'package:todo_app/features/statistics/screens/statistics_screen.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart' show globalDataChangeNotifier;
import 'package:todo_app/l10n/app_localizations.dart';
import 'package:todo_app/core/sharing/models/share_data.dart';
import 'package:todo_app/core/sharing/widgets/share_dialog.dart';
import 'package:todo_app/common/widgets/priority_badge.dart' as priority_badge;
import 'package:intl/intl.dart' as intl;

class HomeScreen extends mat.StatefulWidget {
  const HomeScreen({super.key});

  @override
  mat.State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends mat.State<HomeScreen> with mat.SingleTickerProviderStateMixin, mat.WidgetsBindingObserver {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  final _logger = LoggerService();
  final _autoDeleteSettingsRepository = AutoDeleteSettingsRepository();
  final _widgetService = WidgetService();
  
  List<task_model.Task> _tasks = [];
  List<category_model.Category> _categories = [];
  String _currentFilter = app_constants.AppConstants.allTasks;
  bool _isLoading = true;
  
  // Selection mode state
  bool _isSelectionMode = false;
  final Set<int> _selectedTaskIds = {};
  
  late mat.TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = mat.TabController(length: 3, vsync: this);

    // Add observer to listen for app lifecycle changes
    mat.WidgetsBinding.instance.addObserver(this);

    // Listen to global data change notifications from widget actions
    globalDataChangeNotifier.addListener(_onGlobalDataChange);

    _loadData();

    // CRITICAL: Sync pending widget toggles when app starts
    _syncPendingWidgetToggles();

    // Setup widget command handling
    _setupWidgetCommandHandling();

    // Check if we need to navigate to home tab (from widget action)
    _checkNavigateToHomeTab();

    // Check for notification permissions after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkNotificationPermissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Remove observer when disposing
    mat.WidgetsBinding.instance.removeObserver(this);
    // Remove global data change listener
    globalDataChangeNotifier.removeListener(_onGlobalDataChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(mat.AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == mat.AppLifecycleState.resumed) {
      _logger.logInfo('App resumed - refreshing data and updating widgets');
      // IMMEDIATE data refresh when app resumes
      _loadData();
      // Also update widgets when app resumes
      _widgetService.updateAllWidgets();
    }
  }

  // Callback for global data change notifications (e.g., from widget actions)
  void _onGlobalDataChange() {
    _logger.logInfo('Global data change notification received - refreshing HomeScreen data');
    _loadData();
  }

  // CRITICAL: Sync pending widget toggles when app starts
  Future<void> _syncPendingWidgetToggles() async {
    try {
      await _logger.logInfo('=== Syncing Pending Widget Toggles ===');
      
      // Get pending toggles from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final command = prefs.getString('command') ?? prefs.getString('flutter.command');
      
      if (command == 'toggle_task') {
        final taskId = prefs.getInt('task_id') ?? prefs.getInt('flutter.task_id') ?? -1;
        final timestamp = prefs.getInt('timestamp') ?? prefs.getInt('flutter.timestamp') ?? 0;
        
        // Only process recent commands (within last 60 seconds)
        if (DateTime.now().millisecondsSinceEpoch - timestamp < 60000) {
          await _logger.logInfo('Found pending toggle for task: $taskId');
          
          if (taskId > 0) {
            final task = await _taskRepository.getTask(taskId);
            if (task != null) {
              await _taskRepository.toggleTaskCompletion(taskId, !task.isCompleted);
              await _logger.logInfo('Synced toggle for task: $taskId, new state: ${!task.isCompleted}');
            }
          }
        }
        
        // Clear the command after processing (both key formats)
        await prefs.remove('command');
        await prefs.remove('task_id');
        await prefs.remove('widget_id');
        await prefs.remove('timestamp');
        await prefs.remove('flutter.command');
        await prefs.remove('flutter.task_id');
        await prefs.remove('flutter.widget_id');
        await prefs.remove('flutter.timestamp');
        
        await _logger.logInfo('Cleared pending toggle command');
      } else {
        await _logger.logInfo('No pending toggles to sync');
      }
      
      await _logger.logInfo('=== Pending Widget Toggles Sync Complete ===');
    } catch (e, stackTrace) {
      await _logger.logError('Error syncing pending widget toggles', e, stackTrace);
    }
  }

  // CRITICAL: Setup widget command handling
  void _setupWidgetCommandHandling() {
    // The widget service handles commands via polling automatically
    // We ensure widgets are updated when data changes in _loadData()
    _logger.logInfo('Widget command handling setup complete - using widget service polling');
  }

  // Check if we need to navigate to home tab (from widget action)
  Future<void> _checkNavigateToHomeTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldNavigateToHomeTab = prefs.getBool('navigate_to_home_tab') ?? false;

      if (shouldNavigateToHomeTab) {
        await _logger.logInfo('Navigate to home tab flag detected - switching to Tasks tab');

        // Navigate to the Tasks tab (index 0)
        _tabController.animateTo(0);

        // Clear the flag
        await prefs.setBool('navigate_to_home_tab', false);

        await _logger.logInfo('Navigated to Tasks tab and cleared flag');
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error checking navigate to home tab flag', e, stackTrace);
    }
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
      
      // CRITICAL: Update widgets whenever data changes
      await _updateWidgetsAfterDataChange();
      
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
      if (task.id != null) {
        await _taskRepository.toggleTaskCompletion(task.id!, !task.isCompleted);
        await _loadData(); // This will also update widgets
        
        // Show completion feedback
        if (!task.isCompleted) {
          final autoDeleteSettings = await _autoDeleteSettingsRepository.getSettings();
          if (autoDeleteSettings.deleteImmediately) {
            if (mounted) {
              mat.ScaffoldMessenger.of(context).showSnackBar(
                const mat.SnackBar(
                  content: mat.Text('Task completed and will be deleted immediately'),
                ),
              );
            }
          } else {
            if (mounted) {
              mat.ScaffoldMessenger.of(context).showSnackBar(
                mat.SnackBar(
                  content: mat.Text(
                    'Task completed and will be deleted after ${autoDeleteSettings.deleteAfterDays} day(s)'
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
      await _loadData(); // This will also update widgets
      
      await _logger.logInfo('Task deleted: ID=$taskId');
      
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        mat.ScaffoldMessenger.of(context).showSnackBar(
          mat.SnackBar(content: mat.Text(l10n.taskDeleted)),
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
  
  Future<void> _navigateToAddTask() async {
    await _logger.logInfo('Navigating to add task screen');
    
    if (!mounted) return;
    await mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.addTaskRoute,
    );
    
    if (!mounted) return;
    await _logger.logInfo('Returned from add task screen, refreshing data');
    
    // Always refresh data and widgets when returning from add task screen
    await _loadData(); // This will also update widgets
    
    await _logger.logInfo('Data and widgets refreshed after task creation');
  }

  // CRITICAL: Update widgets after any data change
  Future<void> _updateWidgetsAfterDataChange() async {
    try {
      await _widgetService.updateAllWidgets();
      await _logger.logInfo('Widgets updated after data change');
    } catch (e, stackTrace) {
      await _logger.logError('Error updating widgets after data change', e, stackTrace);
      // Don't show error to user - widgets are secondary functionality
    }
  }

  // Enhanced test function for debugging
  Future<void> _testWidgetData() async {
    try {
      await _logger.logInfo('=== TESTING WIDGET DATA FROM HOME SCREEN ===');
      
      // Force immediate widget update
      await _widgetService.forceWidgetUpdate();
      
      // Verify data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final widgetData = prefs.getString('widget_data');
      final widgetConfig = prefs.getString('widget_config');
      
      await _logger.logInfo('Widget data length: ${widgetData?.length ?? 0}');
      await _logger.logInfo('Widget config length: ${widgetConfig?.length ?? 0}');
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text('Widget test completed - check logs for details'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error testing widget data', e, stackTrace);
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          const mat.SnackBar(
            content: mat.Text('Widget test failed - check logs'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredTasks = _getFilteredTasks();
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: _isSelectionMode 
            ? mat.Text('${_selectedTaskIds.length} selected')
            : mat.Text(l10n.appName),
        leading: _isSelectionMode 
            ? mat.IconButton(
                icon: const mat.Icon(mat.Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode ? [
          // Selection mode actions
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.select_all),
            onPressed: _selectedTaskIds.length == _getFilteredTasks().length 
                ? _deselectAllTasks 
                : _selectAllTasks,
            tooltip: _selectedTaskIds.length == _getFilteredTasks().length 
                ? 'Deselect All' 
                : 'Select All',
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.share),
            onPressed: _shareSelectedTasks,
            tooltip: 'Share Selected',
          ),
        ] : _tabController.index == 0 ? [
          mat.PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share_all') {
                _shareAllTasks();
              } else if (value == 'select_tasks') {
                _toggleSelectionMode();
              } else {
                setState(() {
                  _currentFilter = value;
                });
              }
            },
            itemBuilder: (context) => [
              mat.PopupMenuItem(
                value: app_constants.AppConstants.allTasks,
                child: mat.Text(l10n.allTasks),
              ),
              mat.PopupMenuItem(
                value: app_constants.AppConstants.completedTasks,
                child: mat.Text(l10n.completedTasks),
              ),
              mat.PopupMenuItem(
                value: app_constants.AppConstants.incompleteTasks,
                child: mat.Text(l10n.incompleteTasks),
              ),
              mat.PopupMenuItem(
                value: app_constants.AppConstants.todayTasks,
                child: mat.Text(l10n.todayTasks),
              ),
              mat.PopupMenuItem(
                value: app_constants.AppConstants.upcomingTasks,
                child: mat.Text(l10n.upcomingTasks),
              ),
              const mat.PopupMenuDivider(),
              const mat.PopupMenuItem(
                value: 'select_tasks',
                child: mat.Row(
                  children: [
                    mat.Icon(mat.Icons.checklist),
                    mat.SizedBox(width: 8),
                    mat.Text('Select Tasks'),
                  ],
                ),
              ),
              const mat.PopupMenuItem(
                value: 'share_all',
                child: mat.Row(
                  children: [
                    mat.Icon(mat.Icons.share),
                    mat.SizedBox(width: 8),
                    mat.Text('Share All Tasks'),
                  ],
                ),
              ),
            ],
          ),
          // Enhanced test button with better feedback
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.widgets),
            onPressed: _testWidgetData,
            tooltip: 'Test Widget Update',
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.shopping_cart),
            onPressed: _navigateToShoppingLists,
            tooltip: l10n.shoppingLists,
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: l10n.settings,
          ),
        ] : [
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.shopping_cart),
            onPressed: _navigateToShoppingLists,
            tooltip: l10n.shoppingLists,
          ),
          mat.IconButton(
            icon: const mat.Icon(mat.Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: l10n.settings,
          ),
        ],
        bottom: mat.TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {}); // Refresh to update app bar actions
          },
          tabs: [
            mat.Tab(text: l10n.tasks),
            mat.Tab(text: l10n.categories),
            mat.Tab(text: l10n.statistics),
          ],
        ),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.TabBarView(
              controller: _tabController,
              children: [
                // Tasks Tab
                mat.RefreshIndicator(
                  onRefresh: _loadData,
                  child: filteredTasks.isEmpty
                      ? empty_state.EmptyState(
                          message: l10n.noTasksFound,
                          icon: mat.Icons.task_alt,
                          actionLabel: l10n.addTask,
                          onActionPressed: _navigateToAddTask,
                        )
                      : mat.ListView.builder(
                          itemCount: filteredTasks.length,
                          padding: const mat.EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final category = _getCategoryForTask(task);
                            
                            if (_isSelectionMode) {
                              // In selection mode, show card with checkbox
                              return _buildSelectableTaskCard(task, category);
                            } else {
                              // Normal mode - regular task card
                              return task_card.TaskCard(
                                task: task,
                                category: category, // Can be null now
                                onTap: () => _navigateToTaskDetails(task),
                                onCompletedChanged: (_) => _toggleTaskCompletion(task),
                                onDelete: () => _deleteTask(task.id!),
                              );
                            }
                          },
                        ),
                ),
                
                // Categories Tab - directly embed the screen
                const CategoriesScreen(),
                
                // Statistics Tab - directly embed the screen
                const StatisticsScreen(),
              ],
            ),
      floatingActionButton: _tabController.index == 0 ? mat.FloatingActionButton(
        onPressed: _navigateToAddTask,
        child: const mat.Icon(mat.Icons.add),
      ) : null,
    );
  }

  void _navigateToTaskDetails(task_model.Task task) {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.taskDetailsRoute,
      arguments: task,
    ).then((_) => _loadData());
  }
  
  void _navigateToSettings() {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.settingsRoute,
    );
  }

  void _navigateToShoppingLists() {
    mat.Navigator.of(context).pushNamed(
      app_constants.AppConstants.shoppingListsRoute,
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

  // ============================================================================
  // SELECTION MODE METHODS
  // ============================================================================

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTaskIds.clear();
      }
    });
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _selectAllTasks() {
    final filteredTasks = _getFilteredTasks();
    setState(() {
      _selectedTaskIds.clear();
      _selectedTaskIds.addAll(filteredTasks.map((t) => t.id!));
    });
  }

  void _deselectAllTasks() {
    setState(() {
      _selectedTaskIds.clear();
    });
  }

  bool _isTaskSelected(int taskId) {
    return _selectedTaskIds.contains(taskId);
  }

  // ============================================================================
  // SHARING METHODS
  // ============================================================================

  Future<void> _shareSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) {
      mat.ScaffoldMessenger.of(context).showSnackBar(
        const mat.SnackBar(
          content: mat.Text('Please select at least one task to share'),
        ),
      );
      return;
    }

    final selectedTasks = _tasks.where((task) => _selectedTaskIds.contains(task.id)).toList();
    final shareData = ShareData.fromTaskList(selectedTasks);

    await mat.showDialog(
      context: context,
      builder: (context) => ShareDialog(
        shareData: shareData,
        title: 'Share ${selectedTasks.length} Task${selectedTasks.length > 1 ? "s" : ""}',
      ),
    );

    // Exit selection mode after sharing
    _toggleSelectionMode();
  }

  Future<void> _shareAllTasks() async {
    if (_tasks.isEmpty) {
      mat.ScaffoldMessenger.of(context).showSnackBar(
        const mat.SnackBar(
          content: mat.Text('No tasks to share'),
        ),
      );
      return;
    }

    final shareData = ShareData.fromAllTasks(_tasks);

    await mat.showDialog(
      context: context,
      builder: (context) => ShareDialog(
        shareData: shareData,
        title: 'Share All Tasks (${_tasks.length})',
      ),
    );
  }

  // ============================================================================
  // WIDGET BUILDERS
  // ============================================================================

  mat.Widget _buildSelectableTaskCard(task_model.Task task, category_model.Category? category) {
    final theme = mat.Theme.of(context);
    final isSelected = _isTaskSelected(task.id!);
    final categoryColor = category?.color ?? theme.colorScheme.primary;

    return mat.Card(
      margin: const mat.EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: mat.InkWell(
        onTap: () => _toggleTaskSelection(task.id!),
        borderRadius: mat.BorderRadius.circular(16),
        child: mat.Padding(
          padding: const mat.EdgeInsets.all(16.0),
          child: mat.Row(
            crossAxisAlignment: mat.CrossAxisAlignment.start,
            children: [
              mat.Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTaskSelection(task.id!),
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
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: task.isCompleted
                                  ? mat.TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                                  : null,
                              fontWeight: mat.FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: mat.TextOverflow.ellipsis,
                          ),
                        ),
                        priority_badge.PriorityBadge(priority: task.priority),
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const mat.SizedBox(height: 8),
                      mat.Text(
                        task.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: task.isCompleted
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : null,
                          decoration: task.isCompleted
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
                        if (category != null) 
                          mat.Container(
                            padding: const mat.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: mat.BoxDecoration(
                              color: category.color.withOpacity(0.2),
                              borderRadius: mat.BorderRadius.circular(8),
                            ),
                            child: mat.Text(
                              category.name,
                              style: mat.TextStyle(
                                color: category.color,
                                fontSize: 12,
                                fontWeight: mat.FontWeight.bold,
                              ),
                            ),
                          ),
                        if (category != null && task.dueDate != null)
                          const mat.SizedBox(width: 8),
                        if (task.dueDate != null) ...[
                          mat.Icon(
                            mat.Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const mat.SizedBox(width: 4),
                          mat.Text(
                            _formatDueDate(task.dueDate!),
                            style: mat.TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      ),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final dateFormat = intl.DateFormat('MMM d, yyyy');
    final timeFormat = intl.DateFormat('h:mm a');
    return '${dateFormat.format(dueDate)} · ${timeFormat.format(dueDate)}';
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
}