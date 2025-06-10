import 'package:flutter/material.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/features/widgets/widgets/widget_preview.dart';

class WidgetCreationScreen extends StatefulWidget {
  final WidgetConfig? existingConfig;

  const WidgetCreationScreen({
    super.key,
    this.existingConfig,
  });

  @override
  State<WidgetCreationScreen> createState() => _WidgetCreationScreenState();
}

class _WidgetCreationScreenState extends State<WidgetCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widgetService = WidgetService();
  final _categoryRepository = category_repository.CategoryRepository();
  final _logger = LoggerService();

  WidgetSize _selectedSize = WidgetSize.medium;
  bool _showCompleted = false;
  bool _showCategories = true;
  bool _showPriority = true;
  String? _categoryFilter;
  int _maxTasks = 5;
  
  List<category_model.Category> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _logger.logInfo('Loading categories for widget creation');
      final categories = await _categoryRepository.getAllCategories();

      setState(() {
        _categories = categories;
        
        if (_isEditing) {
          final config = widget.existingConfig!;
          _nameController.text = config.name;
          _selectedSize = config.size;
          _showCompleted = config.showCompleted;
          _showCategories = config.showCategories;
          _showPriority = config.showPriority;
          _categoryFilter = config.categoryFilter;
          _maxTasks = config.maxTasks;
        }
        
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      await _logger.logError('Error loading data for widget creation', e, stackTrace);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading categories')),
        );
      }
    }
  }

  Future<void> _saveWidget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final config = WidgetConfig(
        id: _isEditing ? widget.existingConfig!.id : null,
        name: _nameController.text.trim(),
        size: _selectedSize,
        showCompleted: _showCompleted,
        showCategories: _showCategories,
        showPriority: _showPriority,
        categoryFilter: _categoryFilter,
        maxTasks: _maxTasks,
      );

      if (_isEditing) {
        // UPDATE THE CONFIG FIRST
        await _logger.logInfo('Updating existing widget config: ID=${config.id}');
        final configRepository = WidgetConfigRepository();
        await configRepository.updateWidgetConfig(config);
        
        // THEN UPDATE THE WIDGET DISPLAY
        await _logger.logInfo('Updating widget display after config change');
        await _widgetService.updateWidget(config.id!);
        
        await _logger.logInfo('Widget updated: ID=${config.id}, Name=${config.name}');
      } else {
        await _widgetService.createWidget(config);
        await _logger.logInfo('Widget created: Name=${config.name}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Widget updated successfully' : 'Widget created successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error saving widget', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving widget')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Widget' : 'Create Home Widget'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveWidget,
              child: Text(_isEditing ? 'Update' : 'Create'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicSettings(),
                    const SizedBox(height: 24),
                    _buildDisplaySettings(),
                    const SizedBox(height: 24),
                    _buildFilterSettings(),
                    const SizedBox(height: 24),
                    _buildPreview(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveWidget,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Update Widget' : 'Create Widget',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Widget Name',
            hintText: 'Enter widget name',
            prefixIcon: Icon(Icons.label),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a widget name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Widget Size',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<WidgetSize>(
          segments: WidgetSize.values.map((size) {
            return ButtonSegment<WidgetSize>(
              value: size,
              label: Text(size.label),
            );
          }).toList(),
          selected: {_selectedSize},
          onSelectionChanged: (Set<WidgetSize> selection) {
            setState(() {
              _selectedSize = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Options',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Show completed tasks'),
          subtitle: const Text('Include completed tasks in the widget'),
          value: _showCompleted,
          onChanged: (value) {
            setState(() {
              _showCompleted = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show categories'),
          subtitle: const Text('Display category information'),
          value: _showCategories,
          onChanged: (value) {
            setState(() {
              _showCategories = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show priority'),
          subtitle: const Text('Display priority indicators'),
          value: _showPriority,
          onChanged: (value) {
            setState(() {
              _showPriority = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Maximum tasks to show',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _maxTasks.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final newValue = int.tryParse(value);
                  if (newValue != null && newValue > 0 && newValue <= 20) {
                    setState(() {
                      _maxTasks = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Category Filter',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _categoryFilter,
          decoration: const InputDecoration(
            hintText: 'All categories',
            prefixIcon: Icon(Icons.category),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All categories'),
            ),
            ..._categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category.name,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _categoryFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final config = WidgetConfig(
      name: _nameController.text.trim().isEmpty ? 'Preview' : _nameController.text.trim(),
      size: _selectedSize,
      showCompleted: _showCompleted,
      showCategories: _showCategories,
      showPriority: _showPriority,
      categoryFilter: _categoryFilter,
      maxTasks: _maxTasks,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: WidgetPreview(config: config),
        ),
      ],
    );
  }
}