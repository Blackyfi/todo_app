import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/empty_state.dart' as empty_state;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/features/categories/widgets/category_dialog.dart';
import 'package:todo_app/features/categories/widgets/category_list_item.dart';

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
    
    final result = await showCategoryDialog(
      context: context,
      category: category,
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
                    
                    return CategoryListItem(
                      category: category,
                      taskCount: taskCount,
                      onEdit: () => _showAddEditCategoryDialog(category),
                      onDelete: () => _deleteCategory(category),
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