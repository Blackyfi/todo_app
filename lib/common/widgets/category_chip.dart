import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/categories/models/category.dart' as category_model;

class CategoryChip extends mat.StatelessWidget {
  final category_model.Category category;
  final bool isSelected;
  final mat.VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.GestureDetector(
      onTap: onTap,
      child: mat.Container(
        padding: const mat.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: mat.BoxDecoration(
          color: isSelected
              ? category.color.withAlpha((0.2 * 255).round())
              : mat.Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
          borderRadius: mat.BorderRadius.circular(20),
          border: mat.Border.all(
            color: isSelected ? category.color : mat.Colors.transparent,
            width: 1.5,
          ),
        ),
        child: mat.Row(
          mainAxisSize: mat.MainAxisSize.min,
          children: [
            mat.Container(
              width: 10,
              height: 10,
              decoration: mat.BoxDecoration(
                color: category.color,
                shape: mat.BoxShape.circle,
              ),
            ),
            const mat.SizedBox(width: 8),
            mat.Text(
              category.name,
              style: mat.TextStyle(
                color: isSelected
                    ? category.color
                    : mat.Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? mat.FontWeight.bold : mat.FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
