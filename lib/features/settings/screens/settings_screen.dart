import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/common/widgets/app_bar_with_time.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/features/settings/screens/log_viewer_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:flutter/services.dart'; // This includes FilteringTextInputFormatter
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutter_notifications;

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

  Future<void> _testNotification() async {
    try {
      final notificationService = notification_service.NotificationService();
      
      // Show a simple test notification immediately
      await notificationService.flutterLocalNotificationsPlugin.show(
        9999,
        'Test Notification',
        'This is a test notification from the settings screen!',
        const flutter_notifications.NotificationDetails(
          android: flutter_notifications.AndroidNotificationDetails(
            'todo_app_channel',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: flutter_notifications.Importance.high,
            priority: flutter_notifications.Priority.high,
          ),
          iOS: flutter_notifications.DarwinNotificationDetails(),
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending test notification: $e')),
        );
      }
    }
  }

  Future<void> _checkPendingNotifications() async {
    try {
      final notificationService = notification_service.NotificationService();
      
      // Get pending notifications
      final pending = await notificationService.flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Pending Notifications (${pending.length})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: pending.isEmpty
                  ? const Center(child: Text('No pending notifications'))
                  : ListView.builder(
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final notification = pending[index];
                        return ListTile(
                          title: Text(notification.title ?? 'No title'),
                          subtitle: Text('ID: ${notification.id}'),
                          trailing: Text(notification.body ?? 'No body'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking pending notifications: $e')),
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

  @override
  Widget build(BuildContext context) {
    final timeFormatProvider = Provider.of<TimeFormatProvider>(context);
    
    return Scaffold(
      appBar: const AppBarWithTime(
        title: 'Settings',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(
                  title: 'Appearance',
                  children: [
                    _buildThemeSelector(),
                  ],
                ),
                _buildSection(
                  title: 'Preferences',
                  children: [
                    _buildTimeFormatSelector(timeFormatProvider),
                  ],
                ),
                _buildSection(
                  title: 'Debugging',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bug_report),
                      title: const Text('View Logs'),
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
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Test Notification'),
                      subtitle: const Text('Send a test notification immediately'),
                      trailing: const Icon(Icons.send),
                      onTap: _testNotification,
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Check Pending Notifications'),
                      subtitle: const Text('View scheduled notifications'),
                      trailing: const Icon(Icons.list),
                      onTap: _checkPendingNotifications,
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Request Notification Permissions'),
                      subtitle: const Text('Manually request notification and exact alarm permissions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          final notificationService = notification_service.NotificationService();
                          await notificationService.requestAllPermissions();
                          
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Permission request completed. Check your notification settings.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Error requesting permissions'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                _buildSection(
                  title: 'About',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: Text(_appVersion),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('License'),
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
    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('System Theme'),
          value: ThemeMode.system,
          groupValue: _themeMode,
          onChanged: (value) => _setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light Theme'),
          value: ThemeMode.light,
          groupValue: _themeMode,
          onChanged: (value) => _setThemeMode(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark Theme'),
          value: ThemeMode.dark,
          groupValue: _themeMode,
          onChanged: (value) => _setThemeMode(value!),
        ),
      ],
    );
  }
  
  Widget _buildTimeFormatSelector(TimeFormatProvider provider) {
    return Column(
      children: [
        RadioListTile<TimeFormat>(
          title: const Text('European Time (24-hour)'),
          subtitle: const Text('Example: 14:30'),
          value: TimeFormat.european,
          groupValue: provider.timeFormat,
          onChanged: (value) => provider.setTimeFormat(value!),
        ),
        RadioListTile<TimeFormat>(
          title: const Text('American Time (12-hour)'),
          subtitle: const Text('Example: 2:30 PM'),
          value: TimeFormat.american,
          groupValue: provider.timeFormat,
          onChanged: (value) => provider.setTimeFormat(value!),
        ),
      ],
    );
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