import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/common/widgets/app_bar_with_time.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/features/settings/screens/log_viewer_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:flutter/services.dart';
import 'package:todo_app/core/notifications/notification_service.dart'; // Add this import
import 'package:todo_app/features/widgets/screens/widget_management_screen.dart';
import 'package:todo_app/core/security/providers/security_provider.dart';
import 'package:todo_app/features/security/screens/setup_security_screen.dart';
import 'package:todo_app/features/security/screens/security_info_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:todo_app/core/sharing/widgets/import_dialog.dart';
import 'package:todo_app/core/sharing/models/share_data.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/database/repository/shopping_repository.dart';
import 'package:todo_app/features/sync/services/sync_provider.dart' as sync_provider;
import 'package:todo_app/features/sync/screens/sync_settings_screen.dart' as sync_screen;
import 'package:todo_app/features/sync/models/sync_status.dart' as sync_status;
import 'package:todo_app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  String _appVersion = '';
  bool _isLoading = true;
  AutoDeleteSettings _autoDeleteSettings = AutoDeleteSettings();
  bool _isLoadingAutoDeleteSettings = true;
  final _autoDeleteSettingsRepository = AutoDeleteSettingsRepository();
  final _autoDeleteDaysController = TextEditingController();
  final _notificationService = NotificationService(); // Add this

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _isLoadingAutoDeleteSettings = true;
    });

    try {
      // Load app version
      final packageInfo = await PackageInfo.fromPlatform();
      final autoDeleteSettings = await _autoDeleteSettingsRepository.getSettings();
      _autoDeleteDaysController.text = autoDeleteSettings.deleteAfterDays.toString();

      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _autoDeleteSettings = autoDeleteSettings;
        _isLoading = false;
        _isLoadingAutoDeleteSettings = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingAutoDeleteSettings = false;
      });
    }
  }

  Future<void> _saveAutoDeleteSettings() async {
    setState(() {
      _isLoadingAutoDeleteSettings = true;
    });

    try {
      int days = 1;
      try {
        days = int.parse(_autoDeleteDaysController.text);
        if (days < 1) days = 1;
      } catch (e) {
        days = 1;
        _autoDeleteDaysController.text = '1';
      }

      final updatedSettings = _autoDeleteSettings.copyWith(
        deleteAfterDays: days,
      );

      await _autoDeleteSettingsRepository.updateSettings(updatedSettings);

      setState(() {
        _autoDeleteSettings = updatedSettings;
        _isLoadingAutoDeleteSettings = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-delete settings saved')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingAutoDeleteSettings = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving auto-delete settings')),
        );
      }
    }
  }

  @override
  void dispose() {
    _autoDeleteDaysController.dispose();
    super.dispose();
  }

  void _setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    // Here you would save the theme preference to SharedPreferences
    // and notify the app to change theme
  }

  Future<void> _openWidgetManagement() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WidgetManagementScreen(),
      ),
    );
  }

  Future<void> _importSharedData() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'encrypted'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final filePath = result.files.single.path!;

      // Show import dialog
      if (!mounted) return;

      final shareData = await showDialog<ShareData>(
        context: context,
        builder: (context) => ImportDialog(filePath: filePath),
      );

      if (shareData == null) return; // User cancelled import

      // Import the data
      await _handleImportedData(shareData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImportedData(ShareData shareData) async {
    try {
      int importedCount = 0;

      switch (shareData.type) {
        case ShareDataType.task:
          final task = shareData.extractTask();
          if (task != null) {
            await TaskRepository().insertTask(task);
            importedCount = 1;
          }
          break;

        case ShareDataType.taskList:
        case ShareDataType.allTasks:
          final tasks = shareData.extractTaskList();
          for (final task in tasks) {
            await TaskRepository().insertTask(task);
          }
          importedCount = tasks.length;
          break;

        case ShareDataType.shoppingList:
          final list = shareData.extractShoppingList();
          if (list != null) {
            await ShoppingRepository().insertShoppingList(list);
            importedCount = 1;
          }
          break;

        case ShareDataType.shoppingListWithItems:
          final list = shareData.extractShoppingList();
          final items = shareData.extractGroceryItems();
          if (list != null) {
            final listId = await ShoppingRepository().insertShoppingList(list);
            for (final item in items) {
              await ShoppingRepository().insertGroceryItem(
                item.copyWith(shoppingListId: listId),
              );
            }
            importedCount = 1;
          }
          break;

        case ShareDataType.allShoppingLists:
          final listsWithItems = shareData.extractAllShoppingLists();
          for (final entry in listsWithItems.entries) {
            final listId = await ShoppingRepository().insertShoppingList(entry.key);
            for (final item in entry.value) {
              await ShoppingRepository().insertGroceryItem(
                item.copyWith(shoppingListId: listId),
              );
            }
          }
          importedCount = listsWithItems.length;
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              importedCount == 1
                  ? '${shareData.description} imported successfully'
                  : '$importedCount items imported successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);
    
    return Scaffold(
      appBar: AppBarWithTime(
        title: l10n.settings,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(
                  title: l10n.security,
                  children: [
                    _buildSecuritySettings(),
                  ],
                ),
                _buildSection(
                  title: 'Sync',
                  children: [
                    _buildSyncSettings(),
                  ],
                ),
                _buildSection(
                  title: l10n.theme,
                  children: [
                    _buildThemeSelector(),
                  ],
                ),
                _buildSection(
                  title: l10n.general,
                  children: [
                    _buildTimeFormatSelector(timeFormatProvider),
                  ],
                ),
                _buildSection(
                  title: l10n.notifications, // Add this section
                  children: [
                    _buildNotificationSettings(),
                  ],
                ),
                _buildSection(
                  title: 'Home Screen Integration',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.widgets),
                      title: const Text('Create Home Integrated Task Screen'),
                      subtitle: const Text('Create widgets to display tasks on your home screen'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openWidgetManagement,
                    ),
                  ],
                ),
                _buildSection(
                  title: 'Import & Export',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('Import Shared Data'),
                      subtitle: const Text('Import tasks or shopping lists from files'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _importSharedData,
                    ),
                  ],
                ),
                _buildSection(
                  title: 'Debugging',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: Text(l10n.viewLogs),
                      subtitle: const Text('View application error logs'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LogViewerScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _buildSection(
                  title: l10n.about,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: Text(l10n.version),
                      subtitle: Text(_appVersion),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(l10n.license),
                      subtitle: const Text('MIT License'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Show license dialog
                      },
                    ),
                  ],
                ),
                _buildSection(
                  title: 'Auto-Delete Tasks',
                  children: [
                    _buildAutoDeleteSection(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildThemeSelector() {
    final l10n = AppLocalizations.of(context)!;
    
    return RadioGroup<ThemeMode>(
      groupValue: _themeMode,
      onChanged: (value) => _setThemeMode(value!),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: Text(l10n.systemTheme),
            value: ThemeMode.system,
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.lightTheme),
            value: ThemeMode.light,
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.darkTheme),
            value: ThemeMode.dark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeFormatSelector(TimeFormatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return RadioGroup<TimeFormat>(
      groupValue: provider.timeFormat,
      onChanged: (value) => provider.setTimeFormat(value!),
      child: Column(
        children: [
          RadioListTile<TimeFormat>(
            title: Text(l10n.twentyFourHour),
            subtitle: const Text('Example: 14:30'),
            value: TimeFormat.european,
          ),
          RadioListTile<TimeFormat>(
            title: Text(l10n.twelveHour),
            subtitle: const Text('Example: 2:30 PM'),
            value: TimeFormat.american,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    final securityProvider = context.watch<SecurityProvider>();

    return Column(
      children: [
        ListTile(
          leading: Icon(
            securityProvider.isSecurityEnabled ? Icons.lock : Icons.lock_open,
            color: securityProvider.isSecurityEnabled ? Colors.green : null,
          ),
          title: Text(securityProvider.isSecurityEnabled
              ? 'Password Protection Enabled'
              : 'No Password Protection'),
          subtitle: Text(securityProvider.isSecurityEnabled
              ? '${securityProvider.authType.displayName} - Tap to manage'
              : 'Protect your data with PIN or Password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SetupSecurityScreen(),
              ),
            );
            setState(() {});
          },
        ),
        if (securityProvider.isSecurityEnabled) ...[
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Security Details'),
            subtitle: const Text('View encryption information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SecurityInfoScreen(),
                ),
              );
            },
          ),
          if (securityProvider.canUseBiometric)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Authentication'),
              subtitle: Text(securityProvider.biometricEnabled
                  ? 'Enabled - Use fingerprint or face to unlock'
                  : 'Disabled - Use password only'),
              value: securityProvider.biometricEnabled,
              onChanged: (value) async {
                await securityProvider.setBiometricEnabled(value);
                setState(() {});
              },
            ),
        ],
      ],
    );
  }

  // Add this new method
  Widget _buildNotificationSettings() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notification Settings'),
          subtitle: const Text('Manage app notification permissions'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await _notificationService.openAppSettings();
          },
        ),
        FutureBuilder<bool>(
          future: _notificationService.areNotificationPermissionsGranted(),
          builder: (context, snapshot) {
            final isEnabled = snapshot.data ?? false;
            return ListTile(
              leading: Icon(
                isEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: isEnabled ? Colors.green : Colors.red,
              ),
              title: Text('Notifications ${isEnabled ? 'Enabled' : 'Disabled'}'),
              subtitle: Text(
                isEnabled 
                  ? 'You will receive task reminders'
                  : 'Enable notifications to receive task reminders',
              ),
              trailing: !isEnabled 
                ? TextButton(
                    onPressed: () async {
                      await _notificationService.showNotificationPermissionDialog(context);
                      setState(() {}); // Refresh the UI
                    },
                    child: const Text('Enable'),
                  )
                : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSyncSettings() {
    final sp = context.watch<sync_provider.SyncProvider>();
    final state = sp.status.state;
    final isError = state == sync_status.SyncState.error;
    final isSynced = state == sync_status.SyncState.synced;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isSynced
                ? Icons.cloud_done
                : isError
                    ? Icons.cloud_off
                    : Icons.cloud_queue,
            color: isSynced
                ? Colors.green
                : isError
                    ? Colors.red
                    : null,
          ),
          title: Text(sp.isAuthenticated
              ? 'Sync enabled (${sp.settings.username})'
              : 'Server Synchronization'),
          subtitle: Text(
            sp.isAuthenticated
                ? isSynced
                    ? 'Last synced: ${_formatSyncTime(sp.status.lastSyncTime)}'
                    : isError
                        ? 'Sync error - tap to configure'
                        : 'Tap to configure'
                : 'Sync your data across devices',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const sync_screen.SyncSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatSyncTime(DateTime? time) {
    if (time == null) return 'Never';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildAutoDeleteSection() {
    return _isLoadingAutoDeleteSettings
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              SwitchListTile(
                title: const Text('Delete completed tasks immediately'),
                subtitle: const Text('When enabled, tasks will be deleted as soon as they are marked as completed'),
                value: _autoDeleteSettings.deleteImmediately,
                onChanged: (value) async {
                  setState(() {
                    _autoDeleteSettings = _autoDeleteSettings.copyWith(
                      deleteImmediately: value,
                    );
                  });
                  await _autoDeleteSettingsRepository.updateSettings(_autoDeleteSettings);
                },
              ),
              if (!_autoDeleteSettings.deleteImmediately)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Delete completed tasks after:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: _autoDeleteDaysController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'days',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _saveAutoDeleteSettings,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
            ],
          );
  }
}