import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/models/sync_response.dart'
    as sync_response;
import 'package:todo_app/features/sync/services/sync_http_client.dart'
    as http_client;
import 'package:todo_app/features/sync/services/sync_merge_helper.dart'
    as merge_helper;
import 'package:todo_app/features/sync/services/sync_upload_builder.dart'
    as upload_builder;
import 'package:todo_app/features/sync/repositories/sync_settings_repository.dart'
    as settings_repo;
import 'package:todo_app/features/sync/utils/sync_conflict_resolver.dart'
    as resolver;

/// Core synchronisation service handling upload and download.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LoggerService _logger = LoggerService();
  final http_client.SyncHttpClient _http = http_client.SyncHttpClient();
  final settings_repo.SyncSettingsRepository _settingsRepo =
      settings_repo.SyncSettingsRepository();
  final merge_helper.SyncMergeHelper _merger = merge_helper.SyncMergeHelper();
  final upload_builder.SyncUploadBuilder _uploader =
      upload_builder.SyncUploadBuilder();

  Future<void> _ensureConfigured() async {
    final settings = await _settingsRepo.getSettings();
    _http.configure(
      baseUrl: settings.baseUrl,
      acceptSelfSigned: settings.acceptSelfSignedCert,
    );
  }

  /// Test the connection to the server's health endpoint.
  Future<sync_response.SyncResponse> testConnection(
    settings_model.SyncSettings settings,
  ) async {
    _http.configure(
      baseUrl: settings.baseUrl,
      acceptSelfSigned: settings.acceptSelfSignedCert,
    );
    return _http.get('/health');
  }

  /// Authenticate with the server and store the JWT token.
  Future<sync_response.SyncResponse> login({
    required String username,
    required String password,
    required String deviceId,
    required String deviceName,
    String? deviceType,
  }) async {
    await _ensureConfigured();
    final response = await _http.post(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
        'device_type': deviceType ?? 'unknown',
      },
      auth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data!['token'] as String?;
      if (token != null) {
        await _http.saveToken(token);
        await _logger.logInfo('Login successful for $username');
      }
    }
    return response;
  }

  /// Register a new account on the server.
  Future<sync_response.SyncResponse> register({
    required String username,
    required String password,
    String? email,
  }) async {
    await _ensureConfigured();
    return _http.post(
      '/auth/register',
      body: {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
      },
      auth: false,
    );
  }

  /// Discard the local token.
  Future<void> logout() async {
    await _http.clearToken();
    await _logger.logInfo('User logged out, token cleared');
  }

  /// Upload local changes to the server.
  Future<sync_response.UploadResult> upload(String deviceId) async {
    await _ensureConfigured();
    final settings = await _settingsRepo.getSettings();
    final categories = await _uploader.getCategories(settings.lastSyncTimestamp);
    final tasks = await _uploader.getTasks(settings.lastSyncTimestamp);

    if (categories.isEmpty && tasks.isEmpty) {
      await _logger.logInfo('Upload: nothing to send');
      return sync_response.UploadResult(
        uploaded: {},
        conflicts: {},
        syncTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    final response = await _http.post(
      '/sync/upload',
      body: {
        'device_id': deviceId,
        'data': {
          if (categories.isNotEmpty) 'categories': categories,
          if (tasks.isNotEmpty) 'tasks': tasks,
        },
      },
      timeoutSeconds: 60,
    );

    if (!response.success) {
      throw SyncException(response.message ?? 'Upload failed');
    }
    return sync_response.UploadResult.fromData(response.data!);
  }

  /// Download server changes and merge into local database.
  Future<resolver.MergeResult> download(String deviceId) async {
    await _ensureConfigured();
    final settings = await _settingsRepo.getSettings();
    final since = settings.lastSyncTimestamp;

    final params = <String, String>{'device_id': deviceId};
    if (since != null) params['since'] = (since ~/ 1000).toString();

    final response = await _http.get('/sync/download', queryParams: params);
    if (!response.success || response.data == null) {
      throw SyncException(response.message ?? 'Download failed');
    }

    final data = sync_response.DownloadResult.fromData(response.data!);
    final catResult = await _merger.mergeCategories(data.categories);
    final taskResult = await _merger.mergeTasks(data.tasks);

    return resolver.MergeResult(
      inserted: catResult.inserted + taskResult.inserted,
      updated: catResult.updated + taskResult.updated,
      deleted: catResult.deleted + taskResult.deleted,
      skipped: catResult.skipped + taskResult.skipped,
    );
  }
}

/// Exception thrown when a sync operation fails.
class SyncException implements Exception {
  final String message;
  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
