import 'dart:async' show Timer;
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/features/sync/models/sync_settings.dart'
    as settings_model;
import 'package:todo_app/features/sync/models/sync_status.dart'
    as status_model;
import 'package:todo_app/features/sync/models/sync_response.dart'
    as sync_response;
import 'package:todo_app/features/sync/services/sync_service.dart'
    as sync_service;
import 'package:todo_app/features/sync/repositories/sync_settings_repository.dart'
    as settings_repo;
import 'package:todo_app/features/sync/repositories/sync_queue_repository.dart'
    as queue_repo;
import 'package:todo_app/features/sync/utils/device_info_helper.dart'
    as device_helper;

/// ChangeNotifier providing reactive sync state to the UI.
class SyncProvider extends ChangeNotifier {
  final LoggerService _logger = LoggerService();
  final sync_service.SyncService _syncService = sync_service.SyncService();
  final settings_repo.SyncSettingsRepository _settingsRepo =
      settings_repo.SyncSettingsRepository();
  final queue_repo.SyncQueueRepository _queueRepo =
      queue_repo.SyncQueueRepository();

  settings_model.SyncSettings _settings = settings_model.SyncSettings();
  status_model.SyncStatus _status = const status_model.SyncStatus();
  Timer? _autoSyncTimer;
  bool _initialized = false;

  settings_model.SyncSettings get settings => _settings;
  status_model.SyncStatus get status => _status;
  bool get isConfigured => _settings.isConfigured;
  bool get isAuthenticated => _settings.isAuthenticated;
  bool get isSyncing => _status.state == status_model.SyncState.syncing;

  /// Load settings and start auto-sync timer.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _settings = await _settingsRepo.getSettings();
      final queueCount = await _queueRepo.getPendingCount();
      _status = _status.copyWith(
        queuedItemsCount: queueCount,
        lastSyncTime: _settings.lastSyncTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(_settings.lastSyncTimestamp!)
            : null,
        state: _settings.lastSyncTimestamp != null
            ? status_model.SyncState.synced
            : status_model.SyncState.idle,
      );
      _startAutoSync();
      notifyListeners();
    } catch (e) {
      await _logger.logError('SyncProvider init failed', e);
    }
  }

  Future<void> updateSettings(settings_model.SyncSettings s) async {
    await _settingsRepo.saveSettings(s);
    _settings = await _settingsRepo.getSettings();
    _startAutoSync();
    notifyListeners();
  }

  Future<sync_response.SyncResponse> testConnection(
    settings_model.SyncSettings s,
  ) => _syncService.testConnection(s);

  Future<sync_response.SyncResponse> login({
    required String username,
    required String password,
  }) async {
    final deviceId = await device_helper.DeviceInfoHelper.getDeviceId();
    final deviceName = await device_helper.DeviceInfoHelper.getDeviceName();
    final response = await _syncService.login(
      username: username,
      password: password,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: device_helper.DeviceInfoHelper.getDeviceType(),
    );
    if (response.success) {
      _settings = _settings.copyWith(
        username: username, deviceId: deviceId, deviceName: deviceName,
      );
      await _settingsRepo.saveSettings(_settings);
      notifyListeners();
    }
    return response;
  }

  Future<sync_response.SyncResponse> register({
    required String username,
    required String password,
    String? email,
  }) => _syncService.register(
        username: username, password: password, email: email,
      );

  Future<void> logout() async {
    await _syncService.logout();
    _settings = _settings.copyWith(username: '');
    await _settingsRepo.saveSettings(_settings);
    _status = const status_model.SyncStatus();
    _stopAutoSync();
    notifyListeners();
  }

  /// Perform a full sync (upload then download).
  Future<void> syncNow() async {
    if (isSyncing || !_settings.isConfigured || !_settings.isAuthenticated) {
      return;
    }
    final deviceId = _settings.deviceId;
    if (deviceId == null) return;

    _status = _status.copyWith(state: status_model.SyncState.syncing);
    notifyListeners();

    try {
      final conn = await connectivity.Connectivity().checkConnectivity();
      if (conn.contains(connectivity.ConnectivityResult.none)) {
        throw sync_service.SyncException('No internet connection');
      }
      await _syncService.upload(deviceId);
      await _syncService.download(deviceId);

      final now = DateTime.now();
      _settings = _settings.copyWith(
        lastSyncTimestamp: now.millisecondsSinceEpoch,
      );
      await _settingsRepo.updateLastSyncTimestamp(now.millisecondsSinceEpoch);
      _status = status_model.SyncStatus(
        state: status_model.SyncState.synced,
        lastSyncTime: now,
        queuedItemsCount: await _queueRepo.getPendingCount(),
      );
      await _logger.logInfo('Sync completed successfully');
    } catch (e) {
      await _logger.logError('Sync failed', e);
      _status = _status.copyWith(
        state: status_model.SyncState.error,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> clearQueue() async {
    await _queueRepo.clearAll();
    _status = _status.copyWith(queuedItemsCount: 0);
    notifyListeners();
  }

  Future<void> resetSyncData() async {
    _settings = _settings.copyWith(lastSyncTimestamp: 0);
    await _settingsRepo.saveSettings(_settings);
    _status = _status.copyWith(
      state: status_model.SyncState.idle, lastSyncTime: null,
    );
    notifyListeners();
  }

  void _startAutoSync() {
    _stopAutoSync();
    if (_settings.autoSyncEnabled && _settings.syncInterval > 0) {
      _autoSyncTimer = Timer.periodic(
        Duration(minutes: _settings.syncInterval), (_) => syncNow(),
      );
    }
  }

  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}
