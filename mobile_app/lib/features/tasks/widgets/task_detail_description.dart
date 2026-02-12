import 'package:flutter/material.dart' as mat;

class TaskDetailDescription extends mat.StatelessWidget {
  final String description;

  const TaskDetailDescription({
    super.key,
    required this.description,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Column(
      crossAxisAlignment: mat.CrossAxisAlignment.start,
      children: [
        mat.Text(
          'Description',
          style: theme.textTheme.titleLarge,
        ),
        const mat.SizedBox(height: 8),
        mat.Container(
          width: double.infinity,
          padding: const mat.EdgeInsets.all(16),
          decoration: mat.BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(77), // 0.3 * 255 ≈ 77
            borderRadius: mat.BorderRadius.circular(16),
          ),
          child: mat.Text(
            description.isEmpty
                ? 'No description provided'
                : description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: description.isEmpty
                  ? theme.colorScheme.onSurface.withAlpha(153) // 0.6 * 255 ≈ 153
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}