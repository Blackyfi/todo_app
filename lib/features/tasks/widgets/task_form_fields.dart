import 'package:flutter/material.dart';
import 'package:todo_app/common/widgets/category_chip.dart' as category_chip;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:intl/intl.dart' as intl;

class TaskFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final Function(DateTime?) onDateSelected;
  final Function(TimeOfDay?) onTimeSelected;
  final List<category_model.Category> categories;
  final int? selectedCategoryId;
  final Function(int?) onCategorySelected;
  final task_model.Priority priority;
  final Function(task_model.Priority) onPriorityChanged;

  const TaskFormFields({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    this.dueDate,
    this.dueTime,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    required this.priority,
    required this.onPriorityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        TextFormField(
          controller: titleController,
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
        
        // Description field
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Enter task description (optional)',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        
        const SizedBox(height: 16),
        
        // Due date & time
        Text(
          'Due Date & Time',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(context, theme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimePicker(context, theme),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Category selection
        Row(
          children: [
            Text(
              'Category (Optional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => onCategorySelected(null),
              child: const Text('Clear Selection'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCategoryChips(),
        
        const SizedBox(height: 16),
        
        // Priority selection
        Text(
          'Priority',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildPrioritySelector(),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => _selectDueDate(context),
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
                dueDate != null
                    ? intl.DateFormat('MMM d, yyyy').format(dueDate!)
                    : 'Select Date',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => _selectDueTime(context),
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
                dueTime != null
                    ? dueTime!.format(context)
                    : 'Select Time',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        return category_chip.CategoryChip(
          category: category,
          isSelected: selectedCategoryId == category.id,
          onTap: () => onCategorySelected(category.id),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return SegmentedButton<task_model.Priority>(
      segments: [
        ButtonSegment<task_model.Priority>(
          value: task_model.Priority.high,
          label: const Text('High'),
          icon: Icon(Icons.flag, color: Colors.red),
        ),
        ButtonSegment<task_model.Priority>(
          value: task_model.Priority.medium,
          label: const Text('Medium'),
          icon: Icon(Icons.flag, color: Colors.orange),
        ),
        ButtonSegment<task_model.Priority>(
          value: task_model.Priority.low,
          label: const Text('Low'),
          icon: Icon(Icons.flag, color: Colors.green),
        ),
      ],
      selected: {priority},
      onSelectionChanged: (Set<task_model.Priority> selection) {
        onPriorityChanged(selection.first);
      },
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (pickedDate != null && pickedDate != dueDate) {
      onDateSelected(pickedDate);
    }
  }

  Future<void> _selectDueTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: dueTime ?? TimeOfDay.now(),
    );
    
    if (pickedTime != null && pickedTime != dueTime) {
      onTimeSelected(pickedTime);
    }
  }
}