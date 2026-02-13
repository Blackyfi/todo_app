import 'package:flutter/material.dart' as mat;
import 'package:intl/intl.dart' as intl;
import 'package:todo_app/features/sync/models/sync_status.dart'
    as status_model;

/// A card widget displaying the current sync status.
class SyncStatusCard extends mat.StatelessWidget {
  final status_model.SyncStatus status;
  final bool isSyncing;
  final mat.VoidCallback? onSyncNow;

  const SyncStatusCard({
    super.key,
    required this.status,
    this.isSyncing = false,
    this.onSyncNow,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);

    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Row(
              children: [
                _buildStatusIcon(theme),
                const mat.SizedBox(width: 12),
                mat.Expanded(
                  child: mat.Column(
                    crossAxisAlignment: mat.CrossAxisAlignment.start,
                    children: [
                      mat.Text(
                        _statusLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (status.lastSyncTime != null)
                        mat.Text(
                          'Last sync: ${_formatTime(status.lastSyncTime!)}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                mat.FilledButton.tonalIcon(
                  onPressed: isSyncing ? null : onSyncNow,
                  icon: isSyncing
                      ? const mat.SizedBox(
                          width: 16,
                          height: 16,
                          child: mat.CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const mat.Icon(mat.Icons.sync),
                  label: const mat.Text('Sync'),
                ),
              ],
            ),
            if (status.errorMessage != null &&
                status.state == status_model.SyncState.error) ...[
              const mat.SizedBox(height: 8),
              mat.Text(
                status.errorMessage!,
                style: mat.TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (status.queuedItemsCount > 0) ...[
              const mat.SizedBox(height: 4),
              mat.Text(
                '${status.queuedItemsCount} item(s) queued for sync',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  mat.Widget _buildStatusIcon(mat.ThemeData theme) {
    switch (status.state) {
      case status_model.SyncState.idle:
        return mat.Icon(
          mat.Icons.cloud_off,
          color: theme.colorScheme.outline,
        );
      case status_model.SyncState.syncing:
        return const mat.SizedBox(
          width: 24,
          height: 24,
          child: mat.CircularProgressIndicator(strokeWidth: 2),
        );
      case status_model.SyncState.synced:
        return const mat.Icon(
          mat.Icons.cloud_done,
          color: mat.Colors.green,
        );
      case status_model.SyncState.error:
        return mat.Icon(
          mat.Icons.cloud_off,
          color: theme.colorScheme.error,
        );
    }
  }

  String get _statusLabel {
    switch (status.state) {
      case status_model.SyncState.idle:
        return 'Not synced';
      case status_model.SyncState.syncing:
        return 'Syncing...';
      case status_model.SyncState.synced:
        return 'Synced';
      case status_model.SyncState.error:
        return 'Sync error';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return intl.DateFormat('MMM d, HH:mm').format(time);
  }
}
