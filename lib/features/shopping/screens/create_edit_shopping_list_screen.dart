import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/repository/shopping_repository.dart';
import '../../../core/logger/logger_service.dart';
import '../models/grocery_item.dart';
import '../models/shopping_list.dart';

class CreateEditShoppingListScreen extends StatefulWidget {
  final ShoppingList? shoppingList;

  const CreateEditShoppingListScreen({super.key, this.shoppingList});

  @override
  State<CreateEditShoppingListScreen> createState() =>
      _CreateEditShoppingListScreenState();
}

class _CreateEditShoppingListScreenState
    extends State<CreateEditShoppingListScreen> {
  final ShoppingRepository _repository = ShoppingRepository();
  final LoggerService _logger = LoggerService();
  final _formKey = GlobalKey<FormState>();
  final _listNameController = TextEditingController();
  final List<GroceryItemInput> _items = [];
  bool _isLoading = false;
  bool get _isEditing => widget.shoppingList != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _listNameController.text = widget.shoppingList!.name;
      _loadExistingItems();
    } else {
      _addEmptyItem();
    }
  }

  Future<void> _loadExistingItems() async {
    try {
      final items =
          await _repository.getGroceryItemsByList(widget.shoppingList!.id!);
      setState(() {
        _items.clear();
        for (var item in items) {
          _items.add(GroceryItemInput(
            name: item.name,
            quantity: item.quantity.toString(),
            unit: item.unit,
            existingId: item.id,
          ));
        }
        if (_items.isEmpty) {
          _addEmptyItem();
        }
      });
    } catch (e, stackTrace) {
      await _logger.logError('Error loading items', e, stackTrace);
    }
  }

  void _addEmptyItem() {
    setState(() {
      _items.add(GroceryItemInput());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _addEmptyItem();
      }
    });
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;

    // Filter out empty items
    final validItems = _items.where((item) => item.name.isNotEmpty).toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int listId;

      if (_isEditing) {
        // Update existing list
        listId = widget.shoppingList!.id!;
        final updatedList = widget.shoppingList!.copyWith(
          name: _listNameController.text.trim(),
        );
        await _repository.updateShoppingList(updatedList);

        // Delete all existing items and re-add them
        final existingItems = await _repository.getGroceryItemsByList(listId);
        for (var item in existingItems) {
          await _repository.deleteGroceryItem(item.id!);
        }
      } else {
        // Create new list
        final newList = ShoppingList(
          name: _listNameController.text.trim(),
        );
        listId = await _repository.insertShoppingList(newList);
      }

      // Add all items
      for (var i = 0; i < validItems.length; i++) {
        final input = validItems[i];
        final item = GroceryItem(
          shoppingListId: listId,
          name: input.name.trim(),
          quantity: double.tryParse(input.quantity) ?? 1.0,
          unit: input.unit,
          displayOrder: i,
        );
        await _repository.insertGroceryItem(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Shopping list updated'
                : 'Shopping list created'),
          ),
        );
      }
    } catch (e, stackTrace) {
      await _logger.logError('Error saving shopping list', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving shopping list')),
        );
      }
    }
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Shopping List' : 'Create Shopping List'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _listNameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  hintText: 'e.g., Weekly Groceries',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list_alt),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a list name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: _addEmptyItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _GroceryItemInputRow(
                    key: ValueKey(index),
                    input: _items[index],
                    onRemove: _items.length > 1 ? () => _removeItem(index) : null,
                    onChanged: () => setState(() {}),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _saveList,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEditing ? 'Update List' : 'Create List'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroceryItemInput {
  String name;
  String quantity;
  String unit;
  int? existingId;

  GroceryItemInput({
    this.name = '',
    this.quantity = '1',
    this.unit = 'pieces',
    this.existingId,
  });
}

class _GroceryItemInputRow extends StatefulWidget {
  final GroceryItemInput input;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _GroceryItemInputRow({
    super.key,
    required this.input,
    this.onRemove,
    required this.onChanged,
  });

  @override
  State<_GroceryItemInputRow> createState() => _GroceryItemInputRowState();
}

class _GroceryItemInputRowState extends State<_GroceryItemInputRow> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();

  static const List<String> _units = [
    'pieces',
    'kg',
    'g',
    'L',
    'mL',
    'lb',
    'oz',
    'dozen',
    'pack',
    'box',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.input.name;
    _quantityController.text = widget.input.quantity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g., Milk',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  widget.input.name = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  widget.input.quantity = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: widget.input.unit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      widget.input.unit = value;
                    });
                    widget.onChanged();
                  }
                },
              ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Remove',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
