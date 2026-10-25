import 'package:flutter/material.dart';

class PasswordValidationResult {
  final bool isValid;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;
  final String? errorMessage;

  const PasswordValidationResult({
    required this.isValid,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
    this.errorMessage,
  });

  int get fulfilledCount {
    int count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasDigit) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  double get strengthFraction => fulfilledCount / 5.0;

  String get strengthLabel {
    if (fulfilledCount <= 1) return 'Very Weak';
    if (fulfilledCount == 2) return 'Weak';
    if (fulfilledCount == 3) return 'Fair';
    if (fulfilledCount == 4) return 'Good';
    return 'Strong';
  }

  Color get strengthColor {
    if (fulfilledCount <= 2) return Colors.red.shade600;
    if (fulfilledCount == 3) return Colors.orange.shade700;
    if (fulfilledCount == 4) return Colors.amber.shade700;
    return const Color(0xFF2E7D32); // Deep Green
  }
}

class PasswordValidator {
  static PasswordValidationResult validate(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_+\-=\[\]\\/`~]').hasMatch(password);

    final isValid = hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;

    String? errorMessage;
    if (!isValid) {
      final missing = <String>[];
      if (!hasMinLength) missing.add('at least 8 characters');
      if (!hasUppercase) missing.add('an uppercase letter (A-Z)');
      if (!hasLowercase) missing.add('a lowercase letter (a-z)');
      if (!hasDigit) missing.add('a number (0-9)');
      if (!hasSpecialChar) missing.add('a special symbol (e.g. !@#\$)');

      errorMessage = 'Password must include ${missing.join(', ')}.';
    }

    return PasswordValidationResult(
      isValid: isValid,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigit: hasDigit,
      hasSpecialChar: hasSpecialChar,
      errorMessage: errorMessage,
    );
  }
}
