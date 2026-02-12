import 'package:flutter/foundation.dart';
import '../models/auth_type.dart';
import '../services/security_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityService _securityService = SecurityService();

  AuthType _authType = AuthType.none;
  bool _isAuthenticated = false;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;

  AuthType get authType => _authType;
  bool get isAuthenticated => _isAuthenticated;
  bool get biometricEnabled => _biometricEnabled;
  bool get canUseBiometric => _canUseBiometric;
  bool get isSecurityEnabled => _authType != AuthType.none;

  Future<void> initialize() async {
    await _securityService.initialize();
    await loadSecuritySettings();
  }

  Future<void> loadSecuritySettings() async {
    _authType = await _securityService.getAuthType();
    _biometricEnabled = await _securityService.isBiometricEnabled();
    _canUseBiometric = await _securityService.canUseBiometric();
    _isAuthenticated = _securityService.isAuthenticated;
    notifyListeners();
  }

  Future<bool> setupSecurity({
    required AuthType authType,
    required String credential,
    bool enableBiometric = false,
  }) async {
    final success = await _securityService.setupSecurity(
      authType: authType,
      credential: credential,
      enableBiometric: enableBiometric,
    );

    if (success) {
      await loadSecuritySettings();
    }

    return success;
  }

  Future<bool> disableSecurity() async {
    final success = await _securityService.disableSecurity();

    if (success) {
      await loadSecuritySettings();
    }

    return success;
  }

  Future<bool> verifyCredential(String credential) async {
    final isValid = await _securityService.verifyCredential(credential);

    if (isValid) {
      _isAuthenticated = true;
      notifyListeners();
    }

    return isValid;
  }

  Future<bool> authenticateWithBiometric() async {
    final success = await _securityService.authenticateWithBiometric();

    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }

    return success;
  }

  Future<bool> changeCredential({
    required String oldCredential,
    required String newCredential,
  }) async {
    return await _securityService.changeCredential(
      oldCredential: oldCredential,
      newCredential: newCredential,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _securityService.setBiometricEnabled(enabled);
    await loadSecuritySettings();
  }

  void logout() {
    _securityService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<String?> getDatabasePassword() async {
    return await _securityService.getDatabasePassword();
  }
}
