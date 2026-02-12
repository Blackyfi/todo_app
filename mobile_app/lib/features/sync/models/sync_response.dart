/// Wrapper for server API responses.
class SyncResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final int statusCode;

  SyncResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode = 200,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json, int code) {
    return SyncResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      statusCode: code,
    );
  }

  factory SyncResponse.error(String message, int code) {
    return SyncResponse(
      success: false,
      message: message,
      statusCode: code,
    );
  }
}

/// Parsed result of a sync upload operation.
class UploadResult {
  final Map<String, int> uploaded;
  final Map<String, int> conflicts;
  final int syncTimestamp;

  UploadResult({
    required this.uploaded,
    required this.conflicts,
    required this.syncTimestamp,
  });

  factory UploadResult.fromData(Map<String, dynamic> data) {
    final uploadedRaw = data['uploaded'] as Map<String, dynamic>? ?? {};
    final conflictsRaw = data['conflicts'] as Map<String, dynamic>? ?? {};

    return UploadResult(
      uploaded: uploadedRaw.map((k, v) => MapEntry(k, v as int? ?? 0)),
      conflicts: conflictsRaw.map((k, v) => MapEntry(k, v as int? ?? 0)),
      syncTimestamp: data['sync_timestamp'] as int? ?? 0,
    );
  }

  int get totalUploaded => uploaded.values.fold(0, (a, b) => a + b);
  int get totalConflicts => conflicts.values.fold(0, (a, b) => a + b);
}

/// Parsed result of a sync download operation.
class DownloadResult {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> tasks;
  final int syncTimestamp;

  DownloadResult({
    required this.categories,
    required this.tasks,
    required this.syncTimestamp,
  });

  factory DownloadResult.fromData(Map<String, dynamic> data) {
    return DownloadResult(
      categories: _toListOfMaps(data['categories']),
      tasks: _toListOfMaps(data['tasks']),
      syncTimestamp: data['sync_timestamp'] as int? ?? 0,
    );
  }

  static List<Map<String, dynamic>> _toListOfMaps(dynamic list) {
    if (list is! List) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
