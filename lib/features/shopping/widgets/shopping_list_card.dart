import 'package:flutter/material.dart';
import '../models/shopping_list.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback onTap;
  final VoidCallback onShop;
  final VoidCallback onDelete;

  const ShoppingListCard({
    super.key,
    required this.shoppingList,
    required this.onTap,
    required this.onShop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = shoppingList.progress;
    final isCompleted = shoppingList.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shoppingList.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shoppingList.purchasedItems} of ${shoppingList.totalItems} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onShop,
                    icon: const Icon(Icons.shopping_cart, size: 18),
                    label: const Text('Shop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
