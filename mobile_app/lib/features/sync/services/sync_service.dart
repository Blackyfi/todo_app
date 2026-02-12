import 'dart:convert' as convert;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/models/sync_response.dart'
    as sync_response;
import 'package:todo_app/features/sync/services/sync_http_client.dart'
    as http_client;
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
  final db_helper.DatabaseHelper _dbHelper = db_helper.DatabaseHelper();

  /// Configure the HTTP client from stored settings.
  Future<void> _ensureConfigured() async {
    final settings = await _settingsRepo.getSettings();
    _http.configure(
      baseUrl: settings.baseUrl,
      acceptSelfSigned: settings.acceptSelfSignedCert,
    );
  }

  /// Test the connection to the server.
  Future<sync_response.SyncResponse> testConnection(
    settings_model.SyncSettings settings,
  ) async {
    _http.configure(
      baseUrl: settings.baseUrl,
      acceptSelfSigned: settings.acceptSelfSignedCert,
    );
    return _http.get('/health');
  }

  /// Register / login with the server.
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

  /// Log out: discard local token.
  Future<void> logout() async {
    await _http.clearToken();
    await _logger.logInfo('User logged out, token cleared');
  }

  /// Upload local changes to the server.
  Future<sync_response.UploadResult> upload(String deviceId) async {
    await _ensureConfigured();
    final settings = await _settingsRepo.getSettings();
    final since = settings.lastSyncTimestamp;

    final categories = await _getLocalCategories(since);
    final tasks = await _getLocalTasks(since);

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

  /// Download changes from server and merge locally.
  Future<resolver.MergeResult> download(String deviceId) async {
    await _ensureConfigured();
    final settings = await _settingsRepo.getSettings();
    final since = settings.lastSyncTimestamp;

    final params = <String, String>{'device_id': deviceId};
    if (since != null) {
      // Convert ms to seconds for server
      params['since'] = (since ~/ 1000).toString();
    }

    final response = await _http.get('/sync/download', queryParams: params);
    if (!response.success || response.data == null) {
      throw SyncException(response.message ?? 'Download failed');
    }

    final downloadData =
        sync_response.DownloadResult.fromData(response.data!);

    final catResult = await _mergeCategories(downloadData.categories);
    final taskResult = await _mergeTasks(downloadData.tasks);

    return resolver.MergeResult(
      inserted: catResult.inserted + taskResult.inserted,
      updated: catResult.updated + taskResult.updated,
      deleted: catResult.deleted + taskResult.deleted,
      skipped: catResult.skipped + taskResult.skipped,
    );
  }

  // --- Private helpers ---

  Future<List<Map<String, dynamic>>> _getLocalCategories(int? sinceMs) async {
    final db = await _dbHelper.database;
    final rows = sinceMs != null
        ? await db.query(
            'categories',
            where: 'updatedAt > ?',
            whereArgs: [sinceMs],
          )
        : await db.query('categories');

    return rows.map((r) {
      return {
        'client_id': r['id'],
        'name': r['name'],
        'color': r['color'],
        'updated_at': _msToSec(r['updatedAt'] as int?),
        'deleted': 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getLocalTasks(int? sinceMs) async {
    final db = await _dbHelper.database;
    final rows = sinceMs != null
        ? await db.query(
            'tasks',
            where: 'updatedAt > ?',
            whereArgs: [sinceMs],
          )
        : await db.query('tasks');

    return rows.map((r) {
      return {
        'client_id': r['id'],
        'title': r['title'],
        'description': r['description'] ?? '',
        'due_date': _msToSec(r['dueDate'] as int?),
        'is_completed': r['isCompleted'],
        'completed_at': _msToSec(r['completedAt'] as int?),
        'category_id': r['categoryId'],
        'priority': r['priority'],
        'updated_at': _msToSec(r['updatedAt'] as int?),
        'deleted': 0,
      };
    }).toList();
  }

  Future<resolver.MergeResult> _mergeCategories(
    List<Map<String, dynamic>> serverCats,
  ) async {
    final db = await _dbHelper.database;

    return resolver.SyncConflictResolver.mergeEntities(
      serverEntities: serverCats,
      entityType: 'category',
      findLocal: (clientId) async {
        final rows = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [clientId],
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      insertLocal: (entity) async {
        await db.insert('categories', {
          'name': entity['name'],
          'color': entity['color'],
          'updatedAt': _secToMs(entity['updated_at'] as int?),
        });
      },
      updateLocal: (entity) async {
        final clientId = entity['client_id'] as int;
        await db.update(
          'categories',
          {
            'name': entity['name'],
            'color': entity['color'],
            'updatedAt': _secToMs(entity['updated_at'] as int?),
          },
          where: 'id = ?',
          whereArgs: [clientId],
        );
      },
      deleteLocal: (clientId) async {
        await db.delete('categories', where: 'id = ?', whereArgs: [clientId]);
      },
    );
  }

  Future<resolver.MergeResult> _mergeTasks(
    List<Map<String, dynamic>> serverTasks,
  ) async {
    final db = await _dbHelper.database;

    return resolver.SyncConflictResolver.mergeEntities(
      serverEntities: serverTasks,
      entityType: 'task',
      findLocal: (clientId) async {
        final rows = await db.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [clientId],
        );
        return rows.isNotEmpty ? rows.first : null;
      },
      insertLocal: (entity) async {
        await db.insert('tasks', {
          'title': entity['title'],
          'description': entity['description'] ?? '',
          'dueDate': _secToMs(entity['due_date'] as int?),
          'isCompleted': entity['is_completed'] ?? 0,
          'completedAt': _secToMs(entity['completed_at'] as int?),
          'categoryId': entity['category_id'],
          'priority': entity['priority'] ?? 1,
          'updatedAt': _secToMs(entity['updated_at'] as int?),
        });
      },
      updateLocal: (entity) async {
        final clientId = entity['client_id'] as int;
        await db.update(
          'tasks',
          {
            'title': entity['title'],
            'description': entity['description'] ?? '',
            'dueDate': _secToMs(entity['due_date'] as int?),
            'isCompleted': entity['is_completed'] ?? 0,
            'completedAt': _secToMs(entity['completed_at'] as int?),
            'categoryId': entity['category_id'],
            'priority': entity['priority'] ?? 1,
            'updatedAt': _secToMs(entity['updated_at'] as int?),
          },
          where: 'id = ?',
          whereArgs: [clientId],
        );
      },
      deleteLocal: (clientId) async {
        await db.delete('tasks', where: 'id = ?', whereArgs: [clientId]);
      },
    );
  }

  int? _msToSec(int? ms) => ms != null ? ms ~/ 1000 : null;
  int? _secToMs(int? sec) => sec != null ? sec * 1000 : null;
}

/// Exception thrown when a sync operation fails.
class SyncException implements Exception {
  final String message;
  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
