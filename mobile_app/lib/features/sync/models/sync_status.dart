/// Represents the current state of the sync engine.
enum SyncState {
  /// Never synced or not configured.
  idle,

  /// Sync is currently in progress.
  syncing,

  /// Last sync completed successfully.
  synced,

  /// Last sync encountered an error.
  error,
}

/// Holds the observable sync status for the UI layer.
class SyncStatus {
  final SyncState state;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int queuedItemsCount;

  const SyncStatus({
    this.state = SyncState.idle,
    this.lastSyncTime,
    this.errorMessage,
    this.queuedItemsCount = 0,
  });

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncTime,
    String? errorMessage,
    int? queuedItemsCount,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      queuedItemsCount: queuedItemsCount ?? this.queuedItemsCount,
    );
  }
}
