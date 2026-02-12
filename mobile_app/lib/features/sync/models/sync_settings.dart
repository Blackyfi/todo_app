/// Model representing the user's sync server configuration.
class SyncSettings {
  final int? id;
  final String serverUrl;
  final int serverPort;
  final String? username;
  final bool useSsl;
  final bool acceptSelfSignedCert;
  final bool autoSyncEnabled;
  final int syncInterval;
  final int? lastSyncTimestamp;
  final String? deviceId;
  final String? deviceName;

  SyncSettings({
    this.id,
    this.serverUrl = '',
    this.serverPort = 8443,
    this.username,
    this.useSsl = true,
    this.acceptSelfSignedCert = false,
    this.autoSyncEnabled = false,
    this.syncInterval = 30,
    this.lastSyncTimestamp,
    this.deviceId,
    this.deviceName,
  });

  /// Whether the server connection is configured.
  bool get isConfigured => serverUrl.isNotEmpty;

  /// Whether the user is authenticated (has a stored token).
  bool get isAuthenticated => username != null && username!.isNotEmpty;

  /// Build the full base URL for API calls.
  String get baseUrl {
    final protocol = useSsl ? 'https' : 'http';
    return '$protocol://$serverUrl:$serverPort';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serverUrl': serverUrl,
      'serverPort': serverPort,
      'username': username,
      'useSsl': useSsl ? 1 : 0,
      'acceptSelfSignedCert': acceptSelfSignedCert ? 1 : 0,
      'autoSyncEnabled': autoSyncEnabled ? 1 : 0,
      'syncInterval': syncInterval,
      'lastSyncTimestamp': lastSyncTimestamp,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory SyncSettings.fromMap(Map<String, dynamic> map) {
    return SyncSettings(
      id: map['id'] as int?,
      serverUrl: map['serverUrl'] as String? ?? '',
      serverPort: map['serverPort'] as int? ?? 8443,
      username: map['username'] as String?,
      useSsl: map['useSsl'] == 1,
      acceptSelfSignedCert: map['acceptSelfSignedCert'] == 1,
      autoSyncEnabled: map['autoSyncEnabled'] == 1,
      syncInterval: map['syncInterval'] as int? ?? 30,
      lastSyncTimestamp: map['lastSyncTimestamp'] as int?,
      deviceId: map['deviceId'] as String?,
      deviceName: map['deviceName'] as String?,
    );
  }

  SyncSettings copyWith({
    int? id,
    String? serverUrl,
    int? serverPort,
    String? username,
    bool? useSsl,
    bool? acceptSelfSignedCert,
    bool? autoSyncEnabled,
    int? syncInterval,
    int? lastSyncTimestamp,
    String? deviceId,
    String? deviceName,
  }) {
    return SyncSettings(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      serverPort: serverPort ?? this.serverPort,
      username: username ?? this.username,
      useSsl: useSsl ?? this.useSsl,
      acceptSelfSignedCert:
          acceptSelfSignedCert ?? this.acceptSelfSignedCert,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncInterval: syncInterval ?? this.syncInterval,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
