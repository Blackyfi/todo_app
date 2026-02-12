import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/services/sync_provider.dart'
    as sync_provider;

/// Toggle and interval selector for automatic synchronisation.
class AutoSyncSection extends mat.StatelessWidget {
  final settings_model.SyncSettings settings;
  final sync_provider.SyncProvider provider;

  const AutoSyncSection({
    super.key,
    required this.settings,
    required this.provider,
  });

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
