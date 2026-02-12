import 'dart:io' as io;
import 'package:device_info_plus/device_info_plus.dart' as device_info;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:todo_app/common/constants/app_constants.dart'
    as app_constants;
import 'package:todo_app/core/logger/logger_service.dart';

/// Helper for generating and persisting a unique device identifier.
class DeviceInfoHelper {
  static final LoggerService _logger = LoggerService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Get or generate a persistent device ID.
  static Future<String> getDeviceId() async {
    // Check for existing stored ID first
    var storedId = await _storage.read(
      key: app_constants.AppConstants.syncDeviceIdKey,
    );
    if (storedId != null && storedId.isNotEmpty) return storedId;

    // Generate from platform info
    final id = await _generateDeviceId();
    await _storage.write(
      key: app_constants.AppConstants.syncDeviceIdKey,
      value: id,
    );
    await _logger.logInfo('Generated device ID: $id');
    return id;
  }

  /// Get a human-readable device name.
  static Future<String> getDeviceName() async {
    try {
      final info = device_info.DeviceInfoPlugin();
      if (kIsWeb) return 'Web Browser';
      if (io.Platform.isAndroid) {
        final android = await info.androidInfo;
        return '${android.brand} ${android.model}';
      }
      if (io.Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.name;
      }
      if (io.Platform.isWindows) {
        final win = await info.windowsInfo;
        return win.computerName;
      }
      if (io.Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return mac.computerName;
      }
      if (io.Platform.isLinux) {
        final linux = await info.linuxInfo;
        return linux.prettyName;
      }
    } catch (e) {
      await _logger.logWarning('Failed to get device name: $e');
    }
    return 'Unknown Device';
  }

  /// Get platform type string for the server.
  static String getDeviceType() {
    if (kIsWeb) return 'web';
    if (io.Platform.isAndroid) return 'android';
    if (io.Platform.isIOS) return 'ios';
    if (io.Platform.isWindows) return 'windows';
    if (io.Platform.isMacOS) return 'macos';
    if (io.Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static Future<String> _generateDeviceId() async {
    try {
      final info = device_info.DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return 'web-${web.userAgent.hashCode.abs()}';
      }
      if (io.Platform.isAndroid) {
        final android = await info.androidInfo;
        return 'android-${android.id}';
      }
      if (io.Platform.isIOS) {
        final ios = await info.iosInfo;
        return 'ios-${ios.identifierForVendor ?? ios.name.hashCode}';
      }
      if (io.Platform.isWindows) {
        final win = await info.windowsInfo;
        return 'win-${win.deviceId}';
      }
      if (io.Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return 'mac-${mac.systemGUID ?? mac.computerName.hashCode}';
      }
      if (io.Platform.isLinux) {
        final linux = await info.linuxInfo;
        return 'linux-${linux.machineId ?? linux.prettyName.hashCode}';
      }
    } catch (e) {
      await _logger.logWarning('Failed to get device info: $e');
    }
    // Fallback: timestamp-based ID
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
  }
}
