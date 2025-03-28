import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/categories/models/category.dart' as category_model;

class TaskDetailCategory extends mat.StatelessWidget {
  final category_model.Category category;

  const TaskDetailCategory({
    super.key,
    required this.category,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Row(
          children: [
            mat.Icon(
              mat.Icons.category,
              color: category.color,
              size: 20,
            ),
            const mat.SizedBox(width: 8),
            mat.Text(
              'Category: ${category.name}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: category.color,
              ),
            ),
          ],
        ),
        const mat.SizedBox(height: 16),
      ],
    );
  }
}