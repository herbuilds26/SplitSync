import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitsync/services/email_otp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EmailOtpService Unit Tests', () {
    test('generateAndSendOtp generates a valid 6-digit numeric code', () async {
      const uid = 'test-uid-123';
      const email = 'alex@example.com';

      final code = await EmailOtpService.generateAndSendOtp(
        uid: uid,
        email: email,
        userName: 'Alex',
      );

      expect(code.length, equals(6));
      expect(int.tryParse(code), isNotNull);
      expect(int.parse(code), inInclusiveRange(100000, 999999));
    });

    test('verifyOtp returns true for correct 6-digit code', () async {
      const uid = 'test-uid-456';
      const email = 'sarah@example.com';

      final code = await EmailOtpService.generateAndSendOtp(
        uid: uid,
        email: email,
        userName: 'Sarah',
      );

      final verified = await EmailOtpService.verifyOtp(
        uid: uid,
        enteredCode: code,
      );

      expect(verified, isTrue);

      // Check user is marked as verified locally
      final isVerified = await EmailOtpService.isEmailVerifiedLocally(uid);
      expect(isVerified, isTrue);
    });

    test('verifyOtp returns false for incorrect code', () async {
      const uid = 'test-uid-789';
      const email = 'john@example.com';

      await EmailOtpService.generateAndSendOtp(
        uid: uid,
        email: email,
        userName: 'John',
      );

      final verified = await EmailOtpService.verifyOtp(
        uid: uid,
        enteredCode: '000000',
      );

      expect(verified, isFalse);

      final isVerified = await EmailOtpService.isEmailVerifiedLocally(uid);
      expect(isVerified, isFalse);
    });

    test('verifyOtp handles spaces and whitespace in entered code', () async {
      const uid = 'test-uid-spaces';
      const email = 'spaces@example.com';

      final code = await EmailOtpService.generateAndSendOtp(
        uid: uid,
        email: email,
        userName: 'User',
      );

      // E.g. " 123 456 "
      final formattedWithSpaces = '${code.substring(0, 3)} ${code.substring(3)}';
      final verified = await EmailOtpService.verifyOtp(
        uid: uid,
        enteredCode: formattedWithSpaces,
      );

      expect(verified, isTrue);
    });

    test('verifyOtp rejects invalid lengths', () async {
      const uid = 'test-uid-length';
      const email = 'length@example.com';

      await EmailOtpService.generateAndSendOtp(
        uid: uid,
        email: email,
      );

      expect(await EmailOtpService.verifyOtp(uid: uid, enteredCode: '123'), isFalse);
      expect(await EmailOtpService.verifyOtp(uid: uid, enteredCode: '1234567'), isFalse);
      expect(await EmailOtpService.verifyOtp(uid: uid, enteredCode: ''), isFalse);
    });

    test('HTML template includes the generated 6-digit code and branding', () {
      const testCode = '742918';
      final html = EmailOtpService.getHtmlTemplate(testCode, 'Priya');

      expect(html, contains('7 &nbsp; 4 &nbsp; 2 &nbsp; 9 &nbsp; 1 &nbsp; 8'));
      expect(html, contains('SplitSync'));
      expect(html, contains('Priya'));
      expect(html, contains('10 minutes'));
      // Verifies no raw link is present in the email body
      expect(html, isNot(contains('http://')));
      expect(html, isNot(contains('https://splitsync')));
    });
  });
}
