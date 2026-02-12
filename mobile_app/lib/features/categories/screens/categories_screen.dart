import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/widgets/empty_state.dart' as empty_state;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/features/categories/widgets/category_dialog.dart';
import 'package:todo_app/features/categories/widgets/category_list_item.dart';
import 'package:todo_app/l10n/app_localizations.dart';

class CategoriesScreen extends mat.StatefulWidget {
  const CategoriesScreen({super.key});

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
          const mat.SnackBar(
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
            const mat.SnackBar(
              content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteCategory(category_model.Category category) async {
    final l10n = AppLocalizations.of(context)!;
    final taskCount = _taskCountsByCategory[category.id] ?? 0;
    
    final confirmed = await mat.showDialog<bool>(
      context: context,
      builder: (context) => mat.AlertDialog(
        title: mat.Text('${l10n.delete} ${l10n.category}'),
        content: mat.Text(
          taskCount > 0
              ? 'Are you sure you want to delete "${category.name}"? This category contains $taskCount task(s) and deleting it will also delete all associated tasks.'
              : 'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(false),
            child: mat.Text(l10n.cancel),
          ),
          mat.TextButton(
            onPressed: () => mat.Navigator.of(context).pop(true),
            child: mat.Text(
              l10n.delete,
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
            mat.SnackBar(
              content: mat.Text(l10n.categoryDeleted),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          mat.ScaffoldMessenger.of(context).showSnackBar(
            const mat.SnackBar(
              content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
            ),
          );
        }
      }
    }
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: mat.Text(l10n.categories),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : _categories.isEmpty
              ? empty_state.EmptyState(
                  message: l10n.noCategoriesFound,
                  icon: mat.Icons.category,
                  actionLabel: l10n.addCategory,
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