import 'package:flutter/material.dart';
import '../../../core/database/repository/shopping_repository.dart';
import '../../../core/logger/logger_service.dart';
import '../models/grocery_item.dart';
import '../models/shopping_list.dart';

class ShoppingModeScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ShoppingModeScreen({super.key, required this.shoppingList});

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {
  final ShoppingRepository _repository = ShoppingRepository();
  final LoggerService _logger = LoggerService();
  List<GroceryItem> _unpurchasedItems = [];
  List<GroceryItem> _purchasedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      final unpurchased =
          await _repository.getUnpurchasedItems(widget.shoppingList.id!);
      final purchased =
          await _repository.getPurchasedItems(widget.shoppingList.id!);
      setState(() {
        _unpurchasedItems = unpurchased;
        _purchasedItems = purchased;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      await _logger.logError('Error loading items', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading items')),
        );
      }
    }
  }

  Future<void> _toggleItem(GroceryItem item) async {
    try {
      final newState = !item.isPurchased;
      await _repository.toggleItemPurchased(item.id!, newState);
      await _loadItems();
    } catch (e, stackTrace) {
      await _logger.logError('Error toggling item', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating item')),
        );
      }
    }
  }

  Future<void> _resetAllItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Items'),
        content: const Text(
          'This will mark all items as unpurchased. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.resetAllItems(widget.shoppingList.id!);
        await _loadItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All items reset')),
          );
        }
      } catch (e, stackTrace) {
        await _logger.logError('Error resetting items', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error resetting items')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = _unpurchasedItems.length + _purchasedItems.length;
    final purchasedCount = _purchasedItems.length;
    final progress = totalItems > 0 ? purchasedCount / totalItems : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.shoppingList.name),
            Text(
              '$purchasedCount of $totalItems items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withAlpha(204),
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          if (_purchasedItems.isNotEmpty)
            IconButton(
              onPressed: _resetAllItems,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset all items',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress indicator
                Container(
                  color: theme.colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shopping Progress',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: theme.colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Items list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadItems,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Unpurchased items section
                        if (_unpurchasedItems.isNotEmpty) ...[
                          Text(
                            'TO BUY',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._unpurchasedItems.map((item) => _ShoppingItemCard(
                                item: item,
                                onToggle: () => _toggleItem(item),
                                isPurchased: false,
                              )),
                        ],
                        // Purchased items section
                        if (_purchasedItems.isNotEmpty) ...[
                          if (_unpurchasedItems.isNotEmpty)
                            const SizedBox(height: 24),
                          Text(
                            'PURCHASED',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.outline,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._purchasedItems.map((item) => _ShoppingItemCard(
                                item: item,
                                onToggle: () => _toggleItem(item),
                                isPurchased: true,
                              )),
                        ],
                        // Empty state
                        if (_unpurchasedItems.isEmpty &&
                            _purchasedItems.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items in this list',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final bool isPurchased;

  const _ShoppingItemCard({
    required this.item,
    required this.onToggle,
    required this.isPurchased,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPurchased ? 0.5 : 2,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPurchased
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: isPurchased
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                child: isPurchased
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: isPurchased
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isPurchased
                            ? theme.colorScheme.onSurface.withAlpha(128)
                            : theme.colorScheme.onSurface,
                        fontWeight: isPurchased ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.quantityDisplay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isPurchased
                            ? theme.colorScheme.onSurface.withAlpha(102)
                            : theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
