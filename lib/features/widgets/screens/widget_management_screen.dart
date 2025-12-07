import 'package:flutter/material.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/common/widgets/empty_state.dart';
import 'package:todo_app/features/widgets/screens/widget_creation_screen.dart';
import 'package:todo_app/core/logger/logger_service.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({super.key});

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  final _widgetService = WidgetService();
  final _logger = LoggerService();
  
  List<WidgetConfig> _widgets = [];
  bool _isLoading = true;
  bool _isSupported = false;

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
      await _logger.logInfo('Loading widget management data');
      
      final isSupported = await _widgetService.isWidgetSupported();
      final widgets = isSupported ? await _widgetService.getAllWidgetConfigs() : <WidgetConfig>[];

      setState(() {
        _isSupported = isSupported;
        _widgets = widgets;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
     await _logger.logError('Error loading widget management data', e, stackTrace);
     
     setState(() {
       _isLoading = false;
     });
     
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error loading widgets')),
       );
     }
   }
 }

 Future<void> _createWidget() async {
   if (!_isSupported) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Widgets are not supported on this device')),
     );
     return;
   }

   // Check if security is enabled
   if (await _widgetService.isSecurityEnabled()) {
     if (mounted) {
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

   final result = await Navigator.of(context).push<bool>(
     MaterialPageRoute(
       builder: (_) => const WidgetCreationScreen(),
     ),
   );

   if (result == true) {
     await _loadData();
   }
 }

 Future<void> _editWidget(WidgetConfig config) async {
   final result = await Navigator.of(context).push<bool>(
     MaterialPageRoute(
       builder: (_) => WidgetCreationScreen(existingConfig: config),
     ),
   );

   if (result == true) {
     await _loadData();
   }
 }

 Future<void> _deleteWidget(WidgetConfig config) async {
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
       await _widgetService.deleteWidget(config.id!);
       await _loadData();
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Widget deleted successfully')),
         );
       }
     } catch (e, stackTrace) {
       await _logger.logError('Error deleting widget', e, stackTrace);
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Error deleting widget')),
         );
       }
     }
   }
 }

 Future<void> _updateAllWidgets() async {
   try {
     await _widgetService.updateAllWidgets();
     
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('All widgets updated')),
       );
     }
   } catch (e, stackTrace) {
     await _logger.logError('Error updating all widgets', e, stackTrace);
     
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Error updating widgets')),
       );
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Home Screen Widgets'),
       actions: [
         if (_widgets.isNotEmpty)
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _updateAllWidgets,
             tooltip: 'Update all widgets',
           ),
       ],
     ),
     body: _isLoading
         ? const Center(child: CircularProgressIndicator())
         : !_isSupported
             ? _buildUnsupportedView()
             : _widgets.isEmpty
                 ? EmptyState(
                     message: 'No home screen widgets created yet',
                     icon: Icons.widgets,
                     actionLabel: 'Create Widget',
                     onActionPressed: _createWidget,
                   )
                 : _buildWidgetList(),
     floatingActionButton: _isSupported && !_isLoading
         ? FloatingActionButton(
             onPressed: _createWidget,
             child: const Icon(Icons.add),
           )
         : null,
   );
 }

 Widget _buildUnsupportedView() {
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

 Widget _buildWidgetList() {
   return ListView.builder(
     itemCount: _widgets.length,
     padding: const EdgeInsets.symmetric(vertical: 8),
     itemBuilder: (context, index) {
       final widget = _widgets[index];
       return _buildWidgetItem(widget);
     },
   );
 }

 Widget _buildWidgetItem(WidgetConfig config) {
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
         onSelected: (value) {
           switch (value) {
             case 'edit':
               _editWidget(config);
               break;
             case 'delete':
               _deleteWidget(config);
               break;
             case 'update':
               if (config.id != null) {
                 _widgetService.updateWidget(config.id!);
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