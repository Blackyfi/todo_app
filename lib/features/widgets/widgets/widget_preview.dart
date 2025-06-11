import 'package:flutter/material.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/common/widgets/priority_badge.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

class WidgetPreview extends StatefulWidget {
  final WidgetConfig config;

  const WidgetPreview({
    super.key,
    required this.config,
  });

  @override
  State<WidgetPreview> createState() => _WidgetPreviewState();
}

class _WidgetPreviewState extends State<WidgetPreview> {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  
  List<task_model.Task> _tasks = [];
  List<category_model.Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreviewData();
  }

  @override
  void didUpdateWidget(WidgetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _loadPreviewData();
    }
  }

  Future<void> _loadPreviewData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allTasks = await _taskRepository.getAllTasks();
      final categories = await _categoryRepository.getAllCategories();
      
      List<task_model.Task> filteredTasks = allTasks;

      // Apply category filter
      if (widget.config.categoryFilter != null) {
        final category = categories.firstWhere(
          (cat) => cat.name == widget.config.categoryFilter,
          orElse: () => category_model.Category(id: -1, name: '', color: const Color(0xFF000000)),
        );
        
        if (category.id != null && category.id! > 0) {
          filteredTasks = filteredTasks.where((task) => task.categoryId == category.id).toList();
        }
      }

      // Apply completion filter
      if (!widget.config.showCompleted) {
        filteredTasks = filteredTasks.where((task) => !task.isCompleted).toList();
      }

      // Sort tasks exactly like in the main app (same as task_card.dart logic)
      filteredTasks.sort((a, b) {
        // Completed tasks go to bottom
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        
        // Sort by priority (high = 0, medium = 1, low = 2)
        if (a.priority != b.priority) {
          return a.priority.index.compareTo(b.priority.index);
        }
        
        // Sort by due date (earliest first)
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1; // Tasks with due dates come first
        } else if (b.dueDate != null) {
          return 1;
        }
        
        return 0;
      });

      if (filteredTasks.length > widget.config.maxTasks) {
        filteredTasks = filteredTasks.take(widget.config.maxTasks).toList();
      }

      setState(() {
        _tasks = filteredTasks;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAddTaskPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add task button pressed - would open add task screen'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onRefreshPressed() {
    _loadPreviewData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onSettingsPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget settings button pressed - would open widget settings'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.config.size.size;
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);
    
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(128),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeaderBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildWidgetContent(timeFormatProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          // Widget name on the left
          Expanded(
            child: Text(
              widget.config.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Buttons on the right (in order: Add Task, Refresh, Settings)
          _buildHeaderButton(
            icon: Icons.add,
            onPressed: _onAddTaskPressed,
            tooltip: 'Add Task',
          ),
          const SizedBox(width: 4),
          _buildHeaderButton(
            icon: Icons.refresh,
            onPressed: _onRefreshPressed,
            tooltip: 'Refresh Widget',
          ),
          const SizedBox(width: 4),
          _buildHeaderButton(
            icon: Icons.settings,
            onPressed: _onSettingsPressed,
            tooltip: 'Widget Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(204),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(24, 24),
        ),
      ),
    );
  }

  Widget _buildWidgetContent(TimeFormatProvider timeFormatProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskCounter(),
        const SizedBox(height: 8),
        Expanded(
          child: _tasks.isEmpty
              ? _buildEmptyState()
              : _buildTaskList(timeFormatProvider),
        ),
      ],
    );
  }

  Widget _buildTaskCounter() {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final overdueCount = _tasks.where((task) {
      return task.dueDate != null && 
             task.dueDate!.isBefore(DateTime.now()) && 
             !task.isCompleted;
    }).length;
    
    return Row(
      children: [
        Icon(
          Icons.task_alt,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          '${_tasks.length} ${_tasks.length == 1 ? 'task' : 'tasks'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (completedCount > 0) ...[
          const Text(' • '),
          Text(
            '$completedCount completed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (overdueCount > 0) ...[
          const Text(' • '),
          Text(
            '$overdueCount overdue',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            color: Theme.of(context).colorScheme.primary.withAlpha(128),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No tasks',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TimeFormatProvider timeFormatProvider) {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskItem(task, timeFormatProvider);
      },
    );
  }

  Widget _buildTaskItem(task_model.Task task, TimeFormatProvider timeFormatProvider) {
    final category = task.categoryId != null
        ? _categories.firstWhere(
            (cat) => cat.id == task.categoryId,
            orElse: () => category_model.Category(id: 0, name: 'Unknown', color: Colors.grey),
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: task.dueDate != null && !task.isCompleted && task.dueDate!.isBefore(DateTime.now())
            ? Border.all(color: Colors.red.withAlpha(128), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main task row
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  color: task.isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
                child: task.isCompleted
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and priority row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                                  : null,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.config.showPriority)
                          PriorityBadge(
                            priority: task.priority,
                            size: 8,
                          ),
                      ],
                    ),
                    
                    // Description
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: task.isCompleted
                              ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                              : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 6),
                    
                    // Category and due date row
                    Row(
                      children: [
                        // Category badge
                        if (widget.config.showCategories && category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: category.color.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: category.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (task.dueDate != null) const SizedBox(width: 8),
                        ],
                        
                        // Due date
                        if (task.dueDate != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: _getDueDateColor(task.dueDate!, task.isCompleted),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDueDate(task.dueDate!, timeFormatProvider.isEuropean),
                              style: TextStyle(
                                color: _getDueDateColor(task.dueDate!, task.isCompleted),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          
          // Status indicator (overdue, today, etc.)
          if (task.dueDate != null && !task.isCompleted) ...[
            const SizedBox(height: 4),
            _buildStatusIndicator(task.dueDate!),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    String text;
    Color color;
    
    if (taskDate.isBefore(today)) {
      text = 'OVERDUE';
      color = Colors.red;
    } else if (taskDate.isAtSameMomentAs(today)) {
      if (dueDate.isBefore(now)) {
        text = 'OVERDUE';
        color = Colors.red;
      } else {
        text = 'TODAY';
        color = Colors.orange;
      }
    } else {
      final daysLeft = taskDate.difference(today).inDays;
      if (daysLeft <= 5) {
        text = '$daysLeft DAYS LEFT';
        color = daysLeft <= 2 ? Colors.orange : Colors.blue;
      } else {
        return const SizedBox.shrink(); // Don't show for far future dates
      }
    }
    
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withAlpha(128), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime dueDate, bool isEuropean) {
    final dateFormat = intl.DateFormat('MMM d');
    final timeFormat = isEuropean 
        ? intl.DateFormat('HH:mm')
        : intl.DateFormat('h:mm a');
    
    return '${dateFormat.format(dueDate)} · ${timeFormat.format(dueDate)}';
  }

  Color _getDueDateColor(DateTime dueDate, bool isCompleted) {
    if (isCompleted) {
      return Theme.of(context).colorScheme.onSurface.withAlpha(128);
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDate.isBefore(today) || (taskDate.isAtSameMomentAs(today) && dueDate.isBefore(now))) {
      return Colors.red; // Overdue
    } else if (taskDate.isAtSameMomentAs(today)) {
      return Colors.orange; // Today
    } else if (taskDate.isBefore(today.add(const Duration(days: 3)))) {
      return Colors.blue; // Within 3 days
    } else {
      return Theme.of(context).colorScheme.onSurface.withAlpha(179); // Future
    }
  }
}