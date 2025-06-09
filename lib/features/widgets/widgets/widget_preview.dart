import 'package:flutter/material.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/common/widgets/priority_badge.dart';

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

      // Sort and limit
      filteredTasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        if (a.priority != b.priority) {
          return a.priority.index.compareTo(b.priority.index);
        }
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
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
    // In a real widget, this would open the add task screen
    // For now, we'll just show a message since this is a preview
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add task button pressed - would open add task screen'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onRefreshPressed() {
    // Refresh the widget data
    _loadPreviewData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onSettingsPressed() {
    // In a real widget, this would open widget settings
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
                  : _buildWidgetContent(),
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

  Widget _buildWidgetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskCounter(),
        const SizedBox(height: 8),
        Expanded(
          child: _tasks.isEmpty
              ? _buildEmptyState()
              : _buildTaskList(),
        ),
      ],
    );
  }

  Widget _buildTaskCounter() {
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

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskItem(task);
      },
    );
  }

  Widget _buildTaskItem(task_model.Task task) {
    final category = task.categoryId != null
        ? _categories.firstWhere(
            (cat) => cat.id == task.categoryId,
            orElse: () => category_model.Category(id: 0, name: 'Unknown', color: Colors.grey),
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                        : null,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.config.showCategories && category != null)
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: category.color,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.config.showPriority)
            PriorityBadge(
              priority: task.priority,
              size: 8,
            ),
        ],
      ),
    );
  }
}