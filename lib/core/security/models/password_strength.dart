enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  String get color {
    switch (this) {
      case PasswordStrength.veryWeak:
        return '#D32F2F'; // Red 700
      case PasswordStrength.weak:
        return '#F57C00'; // Orange 700
      case PasswordStrength.medium:
        return '#FBC02D'; // Yellow 700
      case PasswordStrength.strong:
        return '#7CB342'; // Light Green 600
      case PasswordStrength.veryStrong:
        return '#388E3C'; // Green 700
    }
  }

  double get progress {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}

class PasswordStrengthResult {
  final PasswordStrength strength;
  final String crackTime;
  final String crackTimeDetailed;
  final double score;
  final List<String> suggestions;

  const PasswordStrengthResult({
    required this.strength,
    required this.crackTime,
    required this.crackTimeDetailed,
    required this.score,
    required this.suggestions,
  });
}
