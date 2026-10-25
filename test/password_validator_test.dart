import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/services/password_validator.dart';

void main() {
  group('PasswordValidator Tests', () {
    test('Valid strong passwords pass', () {
      final strongPasswords = [
        'SplitSync@2026',
        'StrongP@ssw0rd!',
        'User#99Secure',
        'C0mpl3x!String',
      ];

      for (final pwd in strongPasswords) {
        final result = PasswordValidator.validate(pwd);
        expect(result.isValid, isTrue, reason: 'Failed for: $pwd');
        expect(result.hasMinLength, isTrue);
        expect(result.hasUppercase, isTrue);
        expect(result.hasLowercase, isTrue);
        expect(result.hasDigit, isTrue);
        expect(result.hasSpecialChar, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.strengthLabel, equals('Strong'));
      }
    });

    test('Passwords lacking length fail', () {
      final result = PasswordValidator.validate('A1@bc');
      expect(result.isValid, isFalse);
      expect(result.hasMinLength, isFalse);
      expect(result.errorMessage, contains('at least 8 characters'));
    });

    test('Passwords lacking uppercase fail', () {
      final result = PasswordValidator.validate('splitsync@2026');
      expect(result.isValid, isFalse);
      expect(result.hasUppercase, isFalse);
      expect(result.errorMessage, contains('uppercase letter'));
    });

    test('Passwords lacking lowercase fail', () {
      final result = PasswordValidator.validate('SPLITSYNC@2026');
      expect(result.isValid, isFalse);
      expect(result.hasLowercase, isFalse);
      expect(result.errorMessage, contains('lowercase letter'));
    });

    test('Passwords lacking numbers fail', () {
      final result = PasswordValidator.validate('SplitSync@Secret');
      expect(result.isValid, isFalse);
      expect(result.hasDigit, isFalse);
      expect(result.errorMessage, contains('number'));
    });

    test('Passwords lacking special symbols fail', () {
      final result = PasswordValidator.validate('SplitSync2026');
      expect(result.isValid, isFalse);
      expect(result.hasSpecialChar, isFalse);
      expect(result.errorMessage, contains('special symbol'));
    });
  });
}
