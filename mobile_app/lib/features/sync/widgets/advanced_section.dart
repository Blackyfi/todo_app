import 'package:flutter/material.dart' as mat;
import 'package:todo_app/features/sync/services/sync_provider.dart'
    as sync_provider;

/// Advanced sync options: device info, queue clearing, sync reset.
class AdvancedSection extends mat.StatelessWidget {
  final sync_provider.SyncProvider provider;

  const AdvancedSection({super.key, required this.provider});

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
          subtitle: const mat.Text('Next sync will be a full sync'),
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
