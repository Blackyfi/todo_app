enum AuthType {
  none,
  pin,
  password;

  String get displayName {
    switch (this) {
      case AuthType.none:
        return 'No Protection';
      case AuthType.pin:
        return 'PIN Code';
      case AuthType.password:
        return 'Password';
    }
  }

  String get description {
    switch (this) {
      case AuthType.none:
        return 'Your data is not password protected';
      case AuthType.pin:
        return 'Quick 4-6 digit PIN - Faster access, less secure';
      case AuthType.password:
        return 'Strong password - Better security, takes longer to enter';
    }
  }

  String get securityLevel {
    switch (this) {
      case AuthType.none:
        return 'None';
      case AuthType.pin:
        return 'Basic';
      case AuthType.password:
        return 'Military-Grade';
    }
  }
}
