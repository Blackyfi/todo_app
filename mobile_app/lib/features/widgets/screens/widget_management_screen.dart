import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/providers/widget_providers.dart';
import 'package:todo_app/common/widgets/empty_state.dart';
import 'package:todo_app/features/widgets/screens/widget_creation_screen.dart';

class WidgetManagementScreen extends ConsumerWidget {
  const WidgetManagementScreen({super.key});

  Future<void> _createWidget(BuildContext context, WidgetRef ref) async {
    final isSupported = await ref.read(widgetSupportedProvider.future);

    if (!isSupported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Widgets are not supported on this device')),
        );
      }
      return;
    }

    // Check if security is enabled
    final isSecurityEnabled = await ref.read(widgetSecurityEnabledProvider.future);

    if (isSecurityEnabled) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.lock, size: 48, color: Colors.orange),
            title: const Text('Widgets Disabled'),
            content: const Text(
              'Home screen widgets are automatically disabled when password protection is enabled to keep your data secure.\n\n'
              'To use widgets, please disable password protection in Settings > Security & Privacy.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const WidgetCreationScreen(),
        ),
      );

      if (result == true) {
        ref.read(widgetConfigProvider.notifier).loadWidgets();
      }
    }
  }

  Future<void> _editWidget(BuildContext context, WidgetRef ref, WidgetConfig config) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WidgetCreationScreen(existingConfig: config),
      ),
    );

    if (result == true) {
      ref.read(widgetConfigProvider.notifier).loadWidgets();
    }
  }

  Future<void> _deleteWidget(BuildContext context, WidgetRef ref, WidgetConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Widget'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && config.id != null) {
      try {
        await ref.read(widgetConfigProvider.notifier).deleteWidget(config.id!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Widget deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting widget')),
          );
        }
      }
    }
  }

  Future<void> _updateAllWidgets(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(widgetConfigProvider.notifier).updateAllWidgets();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All widgets updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating widgets')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetsAsync = ref.watch(widgetConfigProvider);
    final isSupported = ref.watch(widgetSupportedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen Widgets'),
        actions: [
          widgetsAsync.whenOrNull(
            data: (widgets) => widgets.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _updateAllWidgets(context, ref),
                  tooltip: 'Update all widgets',
                )
              : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: isSupported.when(
        data: (supported) {
          if (!supported) {
            return _buildUnsupportedView(context);
          }

          return widgetsAsync.when(
            data: (widgets) {
              if (widgets.isEmpty) {
                return EmptyState(
                  message: 'No home screen widgets created yet',
                  icon: Icons.widgets,
                  actionLabel: 'Create Widget',
                  onActionPressed: () => _createWidget(context, ref),
                );
              }
              return _buildWidgetList(context, ref, widgets);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading widgets: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(widgetConfigProvider.notifier).loadWidgets(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildUnsupportedView(context),
      ),
      ),
      floatingActionButton: isSupported.whenOrNull(
        data: (supported) => supported
          ? FloatingActionButton(
              onPressed: () => _createWidget(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      ),
    );
  }

  Widget _buildUnsupportedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Widgets Not Supported',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Home screen widgets are not supported on this device or platform.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetList(BuildContext context, WidgetRef ref, List<WidgetConfig> widgets) {
    return ListView.builder(
      itemCount: widgets.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final widget = widgets[index];
        return _buildWidgetItem(context, ref, widget);
      },
    );
  }

  Widget _buildWidgetItem(BuildContext context, WidgetRef ref, WidgetConfig config) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.widgets,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          config.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${config.size.label}'),
            Text('Max tasks: ${config.maxTasks}'),
            if (config.categoryFilter != null)
              Text('Category: ${config.categoryFilter}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await _editWidget(context, ref, config);
                break;
              case 'delete':
                await _deleteWidget(context, ref, config);
                break;
              case 'update':
                if (config.id != null) {
                  await ref.read(widgetConfigProvider.notifier).updateWidget(config.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Widget updated')),
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'update',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Update'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
