import 'package:flutter/material.dart';
import '../../../common/constants/app_constants.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../core/database/repository/shopping_repository.dart';
import '../../../core/logger/logger_service.dart';
import '../models/shopping_list.dart';
import '../widgets/shopping_list_card.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final ShoppingRepository _repository = ShoppingRepository();
  final LoggerService _logger = LoggerService();
  List<ShoppingList> _shoppingLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
  }

  Future<void> _loadShoppingLists() async {
    try {
      setState(() => _isLoading = true);
      final lists = await _repository.getAllShoppingLists();
      setState(() {
        _shoppingLists = lists;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      await _logger.logError('Error loading shopping lists', e, stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading shopping lists')),
        );
      }
    }
  }

  Future<void> _deleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && list.id != null) {
      try {
        await _repository.deleteShoppingList(list.id!);
        await _loadShoppingLists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${list.name}" deleted')),
          );
        }
      } catch (e, stackTrace) {
        await _logger.logError('Error deleting shopping list', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting shopping list')),
          );
        }
      }
    }
  }

  void _createNewList() {
    Navigator.pushNamed(
      context,
      AppConstants.createShoppingListRoute,
    ).then((_) => _loadShoppingLists());
  }

  void _openList(ShoppingList list) {
    Navigator.pushNamed(
      context,
      AppConstants.editShoppingListRoute,
      arguments: list,
    ).then((_) => _loadShoppingLists());
  }

  void _openShoppingMode(ShoppingList list) {
    Navigator.pushNamed(
      context,
      AppConstants.shoppingModeRoute,
      arguments: list,
    ).then((_) => _loadShoppingLists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingLists.isEmpty
              ? EmptyState(
                  message: 'No shopping lists yet',
                  icon: Icons.shopping_basket_outlined,
                  actionLabel: 'Create Your First List',
                  onActionPressed: _createNewList,
                )
              : RefreshIndicator(
                  onRefresh: _loadShoppingLists,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shoppingLists.length,
                    itemBuilder: (context, index) {
                      final list = _shoppingLists[index];
                      return ShoppingListCard(
                        shoppingList: list,
                        onTap: () => _openList(list),
                        onShop: () => _openShoppingMode(list),
                        onDelete: () => _deleteList(list),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewList,
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }
}
