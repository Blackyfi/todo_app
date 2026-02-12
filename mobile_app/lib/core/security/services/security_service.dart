import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/auth_type.dart';
import '../models/security_info.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  late final FlutterSecureStorage _secureStorage;
  late final LocalAuthentication _localAuth;

  static const String _keyAuthType = 'auth_type';
  static const String _keyPasswordHash = 'password_hash';
  static const String _keySalt = 'password_salt';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyDatabasePassword = 'database_password';
  static const int _pbkdf2Iterations = 100000;

  bool _isInitialized = false;
  bool _isAuthenticated = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );

    _localAuth = LocalAuthentication();
    _isInitialized = true;
  }

  Future<AuthType> getAuthType() async {
    final authTypeStr = await _secureStorage.read(key: _keyAuthType);
    if (authTypeStr == null) return AuthType.none;

    switch (authTypeStr) {
      case 'pin':
        return AuthType.pin;
      case 'password':
        return AuthType.password;
      default:
        return AuthType.none;
    }
  }

  Future<bool> isSecurityEnabled() async {
    final authType = await getAuthType();
    return authType != AuthType.none;
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _keyBiometricEnabled);
    return enabled == 'true';
  }

  Future<bool> canUseBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> setupSecurity({
    required AuthType authType,
    required String credential,
    bool enableBiometric = false,
  }) async {
    if (authType == AuthType.none) {
      return await disableSecurity();
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(credential, salt);
    final databasePassword = _generateDatabasePassword(credential, salt);

    await _secureStorage.write(
      key: _keyAuthType,
      value: authType == AuthType.pin ? 'pin' : 'password',
    );
    await _secureStorage.write(key: _keyPasswordHash, value: passwordHash);
    await _secureStorage.write(key: _keySalt, value: salt);
    await _secureStorage.write(key: _keyDatabasePassword, value: databasePassword);
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enableBiometric.toString(),
    );

    _isAuthenticated = true;
    return true;
  }

  Future<bool> disableSecurity() async {
    await _secureStorage.delete(key: _keyAuthType);
    await _secureStorage.delete(key: _keyPasswordHash);
    await _secureStorage.delete(key: _keySalt);
    await _secureStorage.delete(key: _keyDatabasePassword);
    await _secureStorage.delete(key: _keyBiometricEnabled);

    _isAuthenticated = false;
    return true;
  }

  Future<bool> verifyCredential(String credential) async {
    final storedHash = await _secureStorage.read(key: _keyPasswordHash);
    final salt = await _secureStorage.read(key: _keySalt);

    if (storedHash == null || salt == null) {
      return false;
    }

    final inputHash = _hashPassword(credential, salt);
    final isValid = inputHash == storedHash;

    if (isValid) {
      _isAuthenticated = true;
    }

    return isValid;
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your tasks',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        _isAuthenticated = true;
      }

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeCredential({
    required String oldCredential,
    required String newCredential,
  }) async {
    final isValid = await verifyCredential(oldCredential);
    if (!isValid) return false;

    final authType = await getAuthType();
    final biometricEnabled = await isBiometricEnabled();

    return await setupSecurity(
      authType: authType,
      credential: newCredential,
      enableBiometric: biometricEnabled,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<String?> getDatabasePassword() async {
    return await _secureStorage.read(key: _keyDatabasePassword);
  }

  bool get isAuthenticated => _isAuthenticated;

  void logout() {
    _isAuthenticated = false;
  }

  SecurityInfo getSecurityInfo() {
    return SecurityInfo.aes256;
  }

  String _generateSalt() {
    final random = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Encode(random);
  }

  String _hashPassword(String password, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);

    List<int> hash = passwordBytes;
    for (int i = 0; i < _pbkdf2Iterations; i++) {
      final combined = [...hash, ...saltBytes];
      hash = sha256.convert(combined).bytes;
    }

    return base64Encode(hash);
  }

  String _generateDatabasePassword(String credential, String salt) {
    final combined = credential + salt;
    final hash = sha256.convert(utf8.encode(combined));
    return base64Encode(hash.bytes);
  }
}
