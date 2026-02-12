/// Model for a queued sync operation (offline-first support).
class SyncQueueItem {
  final int? id;
  final String operation;
  final String entityType;
  final int entityId;
  final String data;
  final int timestamp;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'timestamp': timestamp,
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      operation: map['operation'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as int,
      data: map['data'] as String,
      timestamp: map['timestamp'] as int,
      retryCount: map['retryCount'] as int? ?? 0,
      lastError: map['lastError'] as String?,
    );
  }

  SyncQueueItem copyWith({
    int? id,
    String? operation,
    String? entityType,
    int? entityId,
    String? data,
    int? timestamp,
    int? retryCount,
    String? lastError,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
