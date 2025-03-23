import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/common/widgets/app_bar_with_time.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/features/settings/screens/log_viewer_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load app version
      final packageInfo = await PackageInfo.fromPlatform();
      
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
}