import 'dart:math';
import '../models/password_strength.dart';

class PasswordStrengthAnalyzer {
  static const int _minPinLength = 4;
  static const int _maxPinLength = 6;
  static const int _minPasswordLength = 8;

  static bool isValidPin(String pin) {
    if (pin.length < _minPinLength || pin.length > _maxPinLength) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(pin);
  }

  static bool isValidPassword(String password) {
    return password.length >= _minPasswordLength;
  }

  static PasswordStrengthResult analyzePinStrength(String pin) {
    if (!isValidPin(pin)) {
      return PasswordStrengthResult(
        strength: PasswordStrength.veryWeak,
        crackTime: 'Invalid PIN',
        crackTimeDetailed: 'PIN must be 4-6 digits',
        score: 0.0,
        suggestions: [
          'Use $_minPinLength-$_maxPinLength digits only',
        ],
      );
    }

    final int length = pin.length;
    final int possibleCombinations = pow(10, length).toInt();

    final suggestions = <String>[];
    double score = 0.0;
    PasswordStrength strength;

    if (length == 4) {
      strength = PasswordStrength.veryWeak;
      score = 0.2;
      suggestions.add('Consider using a 6-digit PIN for better security');
      suggestions.add('Avoid common PINs like 1234, 0000, 1111');
    } else if (length == 5) {
      strength = PasswordStrength.weak;
      score = 0.4;
      suggestions.add('Consider using a 6-digit PIN for maximum PIN security');
    } else {
      strength = PasswordStrength.medium;
      score = 0.6;
      suggestions.add('Good! For even better security, consider using a password instead');
    }

    // Check for common weak patterns
    if (_isSequential(pin)) {
      suggestions.insert(0, 'Avoid sequential numbers (e.g., 1234, 4321)');
      score = max(0.1, score - 0.3);
      strength = PasswordStrength.veryWeak;
    }

    if (_isRepeating(pin)) {
      suggestions.insert(0, 'Avoid repeating digits (e.g., 1111, 2222)');
      score = max(0.1, score - 0.3);
      strength = PasswordStrength.veryWeak;
    }

    final crackTime = _calculatePinCrackTime(possibleCombinations);

    return PasswordStrengthResult(
      strength: strength,
      crackTime: crackTime.short,
      crackTimeDetailed: crackTime.detailed,
      score: score,
      suggestions: suggestions,
    );
  }

  static PasswordStrengthResult analyzePasswordStrength(String password) {
    if (password.length < _minPasswordLength) {
      return PasswordStrengthResult(
        strength: PasswordStrength.veryWeak,
        crackTime: 'Too Short',
        crackTimeDetailed: 'Password must be at least $_minPasswordLength characters',
        score: 0.0,
        suggestions: [
          'Use at least $_minPasswordLength characters',
        ],
      );
    }

    int score = 0;
    final suggestions = <String>[];

    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'\d'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final length = password.length;

    if (hasLowercase) score += 1;
    if (hasUppercase) score += 1;
    if (hasDigits) score += 1;
    if (hasSpecialChars) score += 2;

    if (length >= 8 && length < 10) {
      score += 1;
    } else if (length >= 10 && length < 12) {
      score += 2;
    } else if (length >= 12 && length < 16) {
      score += 3;
    } else if (length >= 16) {
      score += 4;
    }

    if (!hasLowercase) suggestions.add('Add lowercase letters (a-z)');
    if (!hasUppercase) suggestions.add('Add uppercase letters (A-Z)');
    if (!hasDigits) suggestions.add('Add numbers (0-9)');
    if (!hasSpecialChars) suggestions.add('Add special characters (!@#\$%^&*)');
    if (length < 12) suggestions.add('Use at least 12 characters for strong security');

    if (_hasCommonWords(password.toLowerCase())) {
      suggestions.insert(0, 'Avoid common words or dictionary terms');
      score = max(1, score - 2);
    }

    if (_hasRepeatingPatterns(password)) {
      suggestions.insert(0, 'Avoid repeating patterns');
      score = max(1, score - 1);
    }

    PasswordStrength strength;
    double normalizedScore;

    if (score <= 3) {
      strength = PasswordStrength.veryWeak;
      normalizedScore = 0.2;
    } else if (score <= 5) {
      strength = PasswordStrength.weak;
      normalizedScore = 0.4;
    } else if (score <= 7) {
      strength = PasswordStrength.medium;
      normalizedScore = 0.6;
    } else if (score <= 9) {
      strength = PasswordStrength.strong;
      normalizedScore = 0.8;
    } else {
      strength = PasswordStrength.veryStrong;
      normalizedScore = 1.0;
    }

    final entropy = _calculateEntropy(password);
    final crackTime = _calculatePasswordCrackTime(entropy);

    return PasswordStrengthResult(
      strength: strength,
      crackTime: crackTime.short,
      crackTimeDetailed: crackTime.detailed,
      score: normalizedScore,
      suggestions: suggestions,
    );
  }

  static bool _isSequential(String pin) {
    for (int i = 0; i < pin.length - 1; i++) {
      final current = int.parse(pin[i]);
      final next = int.parse(pin[i + 1]);
      if ((next - current).abs() != 1) {
        return false;
      }
    }
    return true;
  }

  static bool _isRepeating(String pin) {
    return pin.split('').toSet().length == 1;
  }

  static bool _hasRepeatingPatterns(String password) {
    final patterns = [
      RegExp(r'(.)\1{2,}'), // Same character 3+ times
      RegExp(r'(..)\1{1,}'), // Same 2 characters repeated
      RegExp(r'abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz', caseSensitive: false),
      RegExp(r'123|234|345|456|567|678|789|890'),
    ];

    return patterns.any((pattern) => password.contains(pattern));
  }

  static bool _hasCommonWords(String password) {
    final commonWords = [
      'password', 'admin', 'user', 'login', 'welcome', 'letmein',
      'monkey', 'dragon', 'master', 'sunshine', 'princess', 'starwars',
      'football', 'baseball', 'whatever', 'hello', 'freedom', 'shadow',
    ];

    return commonWords.any((word) => password.contains(word));
  }

  static double _calculateEntropy(String password) {
    int charsetSize = 0;

    if (password.contains(RegExp(r'[a-z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'\d'))) charsetSize += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) charsetSize += 32;

    return password.length * (log(charsetSize) / log(2));
  }

  static ({String short, String detailed}) _calculatePinCrackTime(int combinations) {
    const int attemptsPerSecond = 1000000;
    final double secondsToCrack = combinations / (2 * attemptsPerSecond);

    return _formatCrackTime(secondsToCrack, isPin: true);
  }

  static ({String short, String detailed}) _calculatePasswordCrackTime(double entropy) {
    const double attemptsPerSecond = 100000000000;
    final double combinations = pow(2, entropy).toDouble();
    final double secondsToCrack = combinations / (2 * attemptsPerSecond);

    return _formatCrackTime(secondsToCrack, isPin: false);
  }

  static ({String short, String detailed}) _formatCrackTime(double seconds, {required bool isPin}) {
    if (seconds < 1) {
      return (
        short: 'Instantly',
        detailed: 'This ${isPin ? "PIN" : "password"} could be cracked instantly (less than 1 second) using modern computing power.',
      );
    } else if (seconds < 60) {
      return (
        short: '${seconds.round()} seconds',
        detailed: 'This ${isPin ? "PIN" : "password"} could be cracked in approximately ${seconds.round()} seconds using a modern computer.',
      );
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).round();
      return (
        short: '$minutes minutes',
        detailed: 'This ${isPin ? "PIN" : "password"} could be cracked in approximately $minutes minutes using specialized cracking hardware.',
      );
    } else if (seconds < 86400) {
      final hours = (seconds / 3600).round();
      return (
        short: '$hours hours',
        detailed: 'This ${isPin ? "PIN" : "password"} could be cracked in approximately $hours hours using specialized cracking hardware.',
      );
    } else if (seconds < 2592000) {
      final days = (seconds / 86400).round();
      return (
        short: '$days days',
        detailed: 'This ${isPin ? "PIN" : "password"} could be cracked in approximately $days days using specialized cracking hardware.',
      );
    } else if (seconds < 31536000) {
      final months = (seconds / 2592000).round();
      return (
        short: '$months months',
        detailed: 'This ${isPin ? "PIN" : "password"} would require approximately $months months to crack using specialized cracking hardware.',
      );
    } else if (seconds < 3153600000) {
      final years = (seconds / 31536000).round();
      return (
        short: '$years years',
        detailed: 'This ${isPin ? "PIN" : "password"} would require approximately $years years to crack using current technology.',
      );
    } else if (seconds < 31536000000) {
      final centuries = (seconds / 3153600000).round();
      return (
        short: '$centuries centuries',
        detailed: 'This ${isPin ? "PIN" : "password"} would require approximately $centuries centuries to crack - considered extremely secure.',
      );
    } else {
      return (
        short: 'Millions of years',
        detailed: 'This ${isPin ? "PIN" : "password"} would require millions of years to crack with current technology - considered virtually unbreakable.',
      );
    }
  }
}
