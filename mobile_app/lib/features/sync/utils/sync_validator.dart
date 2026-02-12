/// Validation helpers for sync configuration inputs.
class SyncValidator {
  /// Validate a server URL.
  static String? validateServerUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server URL is required';
    }
    final trimmed = value.trim();
    // Allow hostnames and IPs, no protocol prefix expected
    if (trimmed.contains('://')) {
      return 'Enter the hostname only, without http:// or https://';
    }
    if (trimmed.contains(' ')) {
      return 'URL must not contain spaces';
    }
    return null;
  }

  /// Validate a port number.
  static String? validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Port is required';
    }
    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      return 'Enter a valid port (1-65535)';
    }
    return null;
  }

  /// Validate a username.
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  /// Validate a password.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain a number';
    }
    return null;
  }
}
