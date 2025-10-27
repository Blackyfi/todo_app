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
                  title: 'Notifications', // Add this section
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
    return RadioGroup<ThemeMode>(
      groupValue: _themeMode,
      onChanged: (value) => _setThemeMode(value!),
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('System Theme'),
            value: ThemeMode.system,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeFormatSelector(TimeFormatProvider provider) {
    return RadioGroup<TimeFormat>(
      groupValue: provider.timeFormat,
      onChanged: (value) => provider.setTimeFormat(value!),
      child: Column(
        children: [
          RadioListTile<TimeFormat>(
            title: const Text('European Time (24-hour)'),
            subtitle: const Text('Example: 14:30'),
            value: TimeFormat.european,
          ),
          RadioListTile<TimeFormat>(
            title: const Text('American Time (12-hour)'),
            subtitle: const Text('Example: 2:30 PM'),
            value: TimeFormat.american,
          ),
        ],
      ),
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