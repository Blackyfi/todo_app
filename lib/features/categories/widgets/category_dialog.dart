import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/categories/models/category.dart' as category_model;

/// Shows a dialog to add or edit a category
/// Returns a Map with 'name' and 'color' if user confirms, or null if cancelled
Future<Map<String, dynamic>?> showCategoryDialog({
  required mat.BuildContext context,
  category_model.Category? category,
}) async {
  final isEditing = category != null;
  final nameController = mat.TextEditingController(
    text: isEditing ? category.name : '',
  );
  mat.Color selectedColor = isEditing ? category.color : mat.Colors.blue;
  
  final result = await mat.showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => mat.StatefulBuilder(
      builder: (context, setState) {
        return mat.AlertDialog(
          title: mat.Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: mat.Column(
            mainAxisSize: mat.MainAxisSize.min,
            children: [
              mat.TextFormField(
                controller: nameController,
                decoration: const mat.InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'Enter category name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const mat.SizedBox(height: 16),
              mat.Text(
                'Color',
                style: mat.Theme.of(context).textTheme.titleMedium,
              ),
              const mat.SizedBox(height: 8),
              _buildColorPicker(
                context: context,
                selectedColor: selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    selectedColor = color;
                  });
                },
              ),
            ],
          ),
          actions: [
            mat.TextButton(
              onPressed: () => mat.Navigator.of(context).pop(),
              child: const mat.Text('CANCEL'),
            ),
            mat.FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  mat.Navigator.of(context).pop({
                    'name': name,
                    'color': selectedColor,
                  });
                }
              },
              child: mat.Text(isEditing ? 'UPDATE' : 'CREATE'),
            ),
          ],
        );
      },
    ),
  );
  
  nameController.dispose();
  return result;
}

mat.Widget _buildColorPicker({
  required mat.BuildContext context,
  required mat.Color selectedColor,
  required Function(mat.Color) onColorSelected,
}) {
  final colors = [
    mat.Colors.blue,
    mat.Colors.red,
    mat.Colors.green,
    mat.Colors.orange,
    mat.Colors.purple,
    mat.Colors.teal,
    mat.Colors.indigo,
    mat.Colors.pink,
  ];
  
  return mat.Wrap(
    spacing: 8,
    runSpacing: 8,
    children: colors.map((color) {
      return mat.InkWell(
        onTap: () => onColorSelected(color),
        child: mat.Container(
          width: 40,
          height: 40,
          decoration: mat.BoxDecoration(
            color: color,
            shape: mat.BoxShape.circle,
            border: mat.Border.all(
              color: selectedColor == color
                  ? mat.Colors.white
                  : mat.Colors.transparent,
              width: 2,
            ),
            boxShadow: selectedColor == color
                ? [
                    mat.BoxShadow(
                      color: color.withOpacity(0.7),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      );
    }).toList(),
  );
}