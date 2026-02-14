import 'package:flutter/material.dart' as mat;
import 'package:provider/provider.dart' as provider_pkg;
import 'package:todo_app/features/sync/services/sync_provider.dart'
    as sync_provider;
import 'package:todo_app/features/sync/widgets/server_config_form.dart'
    as config_form;
import 'package:todo_app/features/sync/widgets/auth_form.dart' as auth_form;
import 'package:todo_app/features/sync/widgets/sync_status_card.dart'
    as status_card;
import 'package:todo_app/features/sync/widgets/auto_sync_section.dart'
    as auto_sync;
import 'package:todo_app/features/sync/widgets/advanced_section.dart'
    as advanced;

/// Full-screen settings page for configuring server synchronisation.
class SyncSettingsScreen extends mat.StatelessWidget {
  const SyncSettingsScreen({super.key});

  @override
  mat.Widget build(mat.BuildContext context) {
    final sp = provider_pkg.Provider.of<sync_provider.SyncProvider>(context);

    return mat.Scaffold(
      appBar: mat.AppBar(title: const mat.Text('Sync Settings')),
      body: mat.SafeArea(
        top: false,
        child: mat.ListView(
          padding: const mat.EdgeInsets.only(bottom: 32),
          children: [
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
            onLogin: (u, p) => _handleLogin(context, sp, u, p),
            onRegister: (u, p) => _handleRegister(sp, u, p),
            onLogout: () => sp.logout(),
          ),
          if (sp.isAuthenticated) ...[
            const mat.Divider(height: 32),
            _SectionHeader('Auto Sync'),
            auto_sync.AutoSyncSection(
              settings: sp.settings,
              provider: sp,
            ),
            const mat.Divider(height: 32),
            _SectionHeader('Advanced'),
            advanced.AdvancedSection(provider: sp),
          ],
        ],
        ),
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
    sync_provider.SyncProvider sp,
    String user,
    String pass,
  ) async {
    final res = await sp.register(username: user, password: pass);
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
