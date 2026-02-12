import 'package:flutter/material.dart' as mat;
import 'package:provider/provider.dart' as provider_pkg;
import 'package:todo_app/features/sync/services/sync_provider.dart'
    as sync_provider;
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/widgets/server_config_form.dart'
    as config_form;
import 'package:todo_app/features/sync/widgets/auth_form.dart' as auth_form;
import 'package:todo_app/features/sync/widgets/sync_status_card.dart'
    as status_card;

/// Full-screen settings page for configuring server synchronisation.
class SyncSettingsScreen extends mat.StatelessWidget {
  const SyncSettingsScreen({super.key});

  @override
  mat.Widget build(mat.BuildContext context) {
    final sp = provider_pkg.Provider.of<sync_provider.SyncProvider>(context);

    return mat.Scaffold(
      appBar: mat.AppBar(title: const mat.Text('Sync Settings')),
      body: mat.ListView(
        padding: const mat.EdgeInsets.only(bottom: 32),
        children: [
          // Sync status
          mat.Padding(
            padding: const mat.EdgeInsets.all(16),
            child: status_card.SyncStatusCard(
              status: sp.status,
              isSyncing: sp.isSyncing,
              onSyncNow: sp.isAuthenticated ? () => sp.syncNow() : null,
            ),
          ),

          _SectionHeader('Server Connection'),
          mat.Padding(
            padding: const mat.EdgeInsets.symmetric(horizontal: 16),
            child: config_form.ServerConfigForm(
              settings: sp.settings,
              onSave: (s) async {
                await sp.updateSettings(s);
                if (context.mounted) {
                  mat.ScaffoldMessenger.of(context).showSnackBar(
                    const mat.SnackBar(
                      content: mat.Text('Server settings saved'),
                    ),
                  );
                }
              },
              onTest: (s) async {
                final result = await sp.testConnection(s);
                if (!result.success && context.mounted) {
                  mat.ScaffoldMessenger.of(context).showSnackBar(
                    mat.SnackBar(
                      content: mat.Text(
                        result.message ?? 'Connection failed',
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          const mat.Divider(height: 32),
          _SectionHeader('Authentication'),
          auth_form.AuthForm(
            currentUsername: sp.settings.username,
            onLogin: (user, pass) => _handleLogin(context, sp, user, pass),
            onRegister: (user, pass) =>
                _handleRegister(context, sp, user, pass),
            onLogout: () => sp.logout(),
          ),

          if (sp.isAuthenticated) ...[
            const mat.Divider(height: 32),
            _SectionHeader('Auto Sync'),
            _AutoSyncSection(settings: sp.settings, provider: sp),

            const mat.Divider(height: 32),
            _SectionHeader('Advanced'),
            _AdvancedSection(provider: sp),
          ],
        ],
      ),
    );
  }

  Future<String?> _handleLogin(
    mat.BuildContext ctx,
    sync_provider.SyncProvider sp,
    String user,
    String pass,
  ) async {
    final res = await sp.login(username: user, password: pass);
    if (res.success) {
      if (ctx.mounted) {
        mat.ScaffoldMessenger.of(ctx).showSnackBar(
          const mat.SnackBar(content: mat.Text('Logged in successfully')),
        );
      }
      return null;
    }
    return res.message ?? 'Login failed';
  }

  Future<String?> _handleRegister(
    mat.BuildContext ctx,
    sync_provider.SyncProvider sp,
    String user,
    String pass,
  ) async {
    final res = await sp.register(
      username: user,
      password: pass,
    );
    if (res.success) return null;
    return res.message ?? 'Registration failed';
  }
}

class _SectionHeader extends mat.StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Padding(
      padding: const mat.EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: mat.Text(
        title,
        style: mat.TextStyle(
          color: mat.Theme.of(context).colorScheme.primary,
          fontWeight: mat.FontWeight.bold,
        ),
      ),
    );
  }
}

class _AutoSyncSection extends mat.StatelessWidget {
  final settings_model.SyncSettings settings;
  final sync_provider.SyncProvider provider;

  const _AutoSyncSection({required this.settings, required this.provider});

  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Column(
      children: [
        mat.SwitchListTile(
          title: const mat.Text('Enable auto sync'),
          subtitle: const mat.Text(
            'Sync automatically at a set interval',
          ),
          value: settings.autoSyncEnabled,
          onChanged: (v) => provider.updateSettings(
            settings.copyWith(autoSyncEnabled: v),
          ),
        ),
        if (settings.autoSyncEnabled)
          mat.ListTile(
            title: const mat.Text('Sync interval'),
            trailing: mat.DropdownButton<int>(
              value: settings.syncInterval,
              onChanged: (v) {
                if (v != null) {
                  provider.updateSettings(
                    settings.copyWith(syncInterval: v),
                  );
                }
              },
              items: const [
                mat.DropdownMenuItem(value: 15, child: mat.Text('15 min')),
                mat.DropdownMenuItem(value: 30, child: mat.Text('30 min')),
                mat.DropdownMenuItem(value: 60, child: mat.Text('1 hour')),
                mat.DropdownMenuItem(value: 120, child: mat.Text('2 hours')),
                mat.DropdownMenuItem(value: 240, child: mat.Text('4 hours')),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdvancedSection extends mat.StatelessWidget {
  final sync_provider.SyncProvider provider;
  const _AdvancedSection({required this.provider});

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);

    return mat.Column(
      children: [
        if (provider.settings.deviceId != null)
          mat.ListTile(
            leading: const mat.Icon(mat.Icons.phone_android),
            title: const mat.Text('Device ID'),
            subtitle: mat.Text(
              provider.settings.deviceId!,
              style: theme.textTheme.bodySmall,
            ),
          ),
        mat.ListTile(
          leading: const mat.Icon(mat.Icons.delete_sweep),
          title: const mat.Text('Clear sync queue'),
          subtitle: mat.Text(
            '${provider.status.queuedItemsCount} item(s) queued',
          ),
          onTap: () => _confirmAction(
            context,
            'Clear Queue',
            'Remove all queued sync operations?',
            () => provider.clearQueue(),
          ),
        ),
        mat.ListTile(
          leading: mat.Icon(
            mat.Icons.restart_alt,
            color: theme.colorScheme.error,
          ),
          title: const mat.Text('Reset sync data'),
          subtitle: const mat.Text(
            'Next sync will be a full sync',
          ),
          onTap: () => _confirmAction(
            context,
            'Reset Sync',
            'This will clear the last sync timestamp. '
                'The next sync will download all data from the server.',
            () => provider.resetSyncData(),
          ),
        ),
      ],
    );
  }

  void _confirmAction(
    mat.BuildContext context,
    String title,
    String message,
    VoidCallback action,
  ) {
    mat.showDialog(
      context: context,
      builder: (ctx) => mat.AlertDialog(
        title: mat.Text(title),
        content: mat.Text(message),
        actions: [
          mat.TextButton(
            onPressed: () => mat.Navigator.pop(ctx),
            child: const mat.Text('Cancel'),
          ),
          mat.FilledButton(
            onPressed: () {
              mat.Navigator.pop(ctx);
              action();
            },
            child: const mat.Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
