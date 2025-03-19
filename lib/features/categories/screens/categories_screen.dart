import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/empty_state.dart' as empty_state;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;

class CategoriesScreen extends mat.StatefulWidget {
  const CategoriesScreen({mat.Key? key}) : super(key: key);

  @override
  mat.State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends mat.State<CategoriesScreen> {
  final _categoryRepository = category_repository.CategoryRepository();
  final _taskRepository = task_repository.TaskRepository();
  
  List<category_model.Category> _categories = [];
  Map<int, int> _taskCountsByCategory = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await _categoryRepository.getAllCategories();
      final taskCountsByCategory = <int, int>{};
      
      for (final category in categories) {
        if (category.id != null) {
          final tasks = await _taskRepository.getTasksByCategory(category.id!);
          taskCountsByCategory[category.id!] = tasks.length;
        }
      }
      
      setState(() {
        _categories = categories;
        _taskCountsByCategory = taskCountsByCategory;
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
  
  Future<void> _showAddEditCategoryDialog([category_model.Category? category]) async {
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
                mat.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    mat.Colors.blue,
                    mat.Colors.red,
                    mat.Colors.green,
                    mat.Colors.orange,
                    mat.Colors.purple,
                    mat.Colors.teal,
                    mat.Colors.indigo,
                    mat.Colors.pink,
                  ].map((color) {
                    return mat.InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
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
    
    if (result != null) {
      try {
        if (isEditing) {
          final updatedCategory = category.copyWith(
            name: result['name'],
            color: result['color'],
          );
          await _categoryRepository.updateCategory(updatedCategory);
        } else {
          final newCategory = category_model.Category(
            name: result['name'],
            color: result['color'],
          );
          await _categoryRepository.insertCategory(newCategory);
        }
        
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
    
    nameController.dispose();
  }
  
  Future<void> _deleteCategory(category_model.Category category) async {
    final taskCount = _taskCountsByCategory[category.id] ?? 0;
    
    final confirmed = await mat.showDialog<bool>(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: const mat.Text('Delete Category'),
        content: mat.Text(
          taskCount > 0
              ? 'This category contains $taskCount task(s). Deleting it will also delete all associated tasks. Are you sure?'
              : 'Are you sure you want to delete this category?',
        ),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(false),
            child: const mat.Text('CANCEL'),
          ),
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(true),
            child: mat.Text(
              'DELETE',
              style: mat.TextStyle(color: mat.Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true && category.id != null) {
      try {
        await _categoryRepository.deleteCategory(category.id!);
        await _loadData();
        
        if (mounted) {
          mat.ScaffoldMessenger.of(context).showSnackBar(
            const mat.SnackBar(
              content: mat.Text('Category deleted'),
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
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: const mat.Text('Categories'),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : _categories.isEmpty
              ? empty_state.EmptyState(
                  message: 'No categories found',
                  icon: mat.Icons.category,
                  actionLabel: 'Add Category',
                  onActionPressed: () => _showAddEditCategoryDialog(),
                )
              : mat.ListView.builder(
                  itemCount: _categories.length,
                  padding: const mat.EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final taskCount = _taskCountsByCategory[category.id] ?? 0;
                    
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
                        await _deleteCategory(category);
                        return false; // We're handling the deletion in _deleteCategory
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
                                onPressed: () => _showAddEditCategoryDialog(category),
                              ),
                              mat.IconButton(
                                icon: const mat.Icon(mat.Icons.delete),
                                onPressed: () => _deleteCategory(category),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: mat.FloatingActionButton(
        onPressed: () => _showAddEditCategoryDialog(),
        child: const mat.Icon(mat.Icons.add),
      ),
    );
  }
}
