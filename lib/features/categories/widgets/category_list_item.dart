import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:flutter/foundation.dart';

class CategoryListItem extends mat.StatelessWidget {
  final category_model.Category category;
  final int taskCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.taskCount,
    required this.onEdit,
    required this.onDelete,
  });

  Future<bool> _confirmDeletion(mat.BuildContext context) async {
    return await mat.showDialog<bool>(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: const mat.Text('Delete Category'),
        content: mat.Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(false),
            child: const mat.Text('Cancel'),
          ),
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(true),
            child: const mat.Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Dismissible(
      key: mat.Key('category-${category.id}'),
      direction: mat.DismissDirection.endToStart,
      background: mat.Container(
        alignment: mat.Alignment.centerRight,
        padding: const mat.EdgeInsets.only(right: 20.0),
        color: mat.Theme.of(context).colorScheme.error,
        child: mat.Icon(
          mat.Icons.delete,
          color: mat.Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await _confirmDeletion(context);
        if (confirmed) {
          onDelete();
        }
        return false;
      },
      child: mat.Card(
        margin: const mat.EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: mat.ListTile(
          leading: mat.Container(
            width: 24,
            height: 24,
            decoration: mat.BoxDecoration(
              color: category.color,
              shape: mat.BoxShape.circle,
            ),
          ),
          title: mat.Text(
            category.name,
            style: mat.Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: mat.Text('$taskCount task(s)'),
          trailing: mat.Row(
            mainAxisSize: mat.MainAxisSize.min,
            children: [
              mat.IconButton(
                icon: const mat.Icon(mat.Icons.edit),
                onPressed: onEdit,
              ),
              mat.IconButton(
                icon: const mat.Icon(mat.Icons.delete),
                onPressed: () async {
                  if (await _confirmDeletion(context)) {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}