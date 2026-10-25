import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/services/email_validator_service.dart';

void main() {
  group('EmailValidatorService Format & Disposable & Typo Tests', () {
    test('Valid email addresses pass syntax check', () {
      final validEmails = [
        'john.doe@gmail.com',
        'alex_123@yahoo.com',
        'user@splitsync.app',
        'contact@sub.domain.org',
        'test.name+tag@outlook.com',
      ];

      for (final email in validEmails) {
        final res = EmailValidatorService.validateFormat(email);
        expect(res.isValid, isTrue, reason: 'Failed for $email: ${res.errorMessage}');
      }
    });

    test('Empty or malformed emails fail syntax check', () {
      final invalidEmails = [
        '',
        '   ',
        'notanemail',
        'missingat.com',
        '@missinguser.com',
        'user@',
        'user@domain',
        'user@domain.',
        'user@@doubleat.com',
      ];

      for (final email in invalidEmails) {
        final res = EmailValidatorService.validateFormat(email);
        expect(res.isValid, isFalse, reason: 'Should have failed for: $email');
        expect(res.errorMessage, isNotNull);
      }
    });

    test('Obvious fake or placeholder email usernames are rejected', () {
      final fakeUserEmails = [
        'fake@gmail.com',
        'fake123@yahoo.com',
        'fakeuser@outlook.com',
        'fakemail@gmail.com',
        'test@gmail.com',
        'test1234@yahoo.com',
        'tester@outlook.com',
        'testing@gmail.com',
        'dummy@gmail.com',
        'asdf@gmail.com',
        'qwerty@gmail.com',
        '123456@gmail.com',
      ];

      for (final email in fakeUserEmails) {
        final res = EmailValidatorService.validateFormat(email);
        expect(res.isValid, isFalse, reason: 'Fake username should be rejected for: $email');
        expect(res.errorMessage, contains('fake or test email address'));
      }
    });

    test('Temporary / Fake / Disposable email domains are rejected', () {
      final disposableEmails = [
        'john.doe@tempmail.com',
        'alex.smith@mailinator.com',
        'robert.w@guerrillamail.com',
        'david.m@10minutemail.com',
        'sarah.c@yopmail.com',
        'emma.d@throwawaymail.com',
        'michael@sharklasers.com',
        'clara@fake.com',
        'clara@test.com',
        'clara@xyz.com',
      ];

      for (final email in disposableEmails) {
        final res = EmailValidatorService.validateFormat(email);
        expect(res.isValid, isFalse, reason: 'Disposable domain should be rejected for: $email');
        expect(res.errorMessage, contains('fake or temporary'));
      }
    });

    test('Common domain typos suggest correct alternatives', () {
      final typoEmails = {
        'john@gmial.com': 'john@gmail.com',
        'sarah@gmai.com': 'sarah@gmail.com',
        'mike@hotmial.com': 'mike@hotmail.com',
        'lisa@outlok.com': 'lisa@outlook.com',
        'david@yaho.com': 'david@yahoo.com',
      };

      for (final entry in typoEmails.entries) {
        final res = EmailValidatorService.validateFormat(entry.key);
        expect(res.isValid, isFalse, reason: 'Typo should be flagged for: ${entry.key}');
        expect(res.suggestion, equals(entry.value));
        expect(res.errorMessage, contains('Did you mean'));
      }
    });

    test('Async validateEmail flags non-existent domain via DNS', () async {
      final res = await EmailValidatorService.validateEmail(
        'realuser@thisdomaindoesnotexist999888777xyz.com',
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('does not exist'));
    });

    test('Async validateEmail passes for genuine domain', () async {
      final res = await EmailValidatorService.validateEmail('support@google.com');
      expect(res.isValid, isTrue);
    });
  });
}
