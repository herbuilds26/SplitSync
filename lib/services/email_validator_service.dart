import 'dart:io';

class EmailValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestion;

  const EmailValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestion,
  });

  static const valid = EmailValidationResult(isValid: true);
}

/// Service to validate email syntax, detect disposable/fake email domains,
/// suggest corrections for common domain typos, and verify domain DNS existence.
class EmailValidatorService {
  // Regex conforming to standard email format
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
  );

  /// Known temporary, fake, and disposable email providers
  static const Set<String> _disposableDomains = {
    'mailinator.com',
    'tempmail.com',
    'temp-mail.org',
    '10minutemail.com',
    'guerrillamail.com',
    'guerrillamail.net',
    'guerrillamail.biz',
    'guerrillamail.org',
    'sharklasers.com',
    'yopmail.com',
    'yopmail.net',
    'yopmail.fr',
    'trashmail.com',
    'throwawaymail.com',
    'dispostable.com',
    'fake.com',
    'fakemail.com',
    'fakeemail.com',
    'test.com',
    'testing.com',
    'test.org',
    'test.net',
    'dummy.com',
    'dummy.org',
    'dummy.net',
    'example.com',
    'sample.com',
    'sample.org',
    'sample.net',
    'invalid.com',
    'notreal.com',
    'nomail.com',
    'noemail.com',
    'xyz.com',
    'abc.com',
    'asdf.com',
    'qwerty.com',
    'temp.com',
    'trash.com',
    'generator.email',
    'mytemp.email',
    'inboxkitten.com',
    'crazymailing.com',
    'maildrop.cc',
    'tempail.com',
    'dropmail.me',
    'burnermail.io',
    'getairmail.com',
    'getnada.com',
    'nada.ltd',
    'mohmal.com',
    'mytempemail.com',
    'fakemailgenerator.com',
    'emailondeck.com',
    'discard.email',
    'discardmail.com',
    'spamgourmet.com',
    'harakirimail.com',
    'guerrillamailblock.com',
    'pokemail.net',
    'spam4.me',
    'grr.la',
    'nowmymail.com',
  };

  /// Obvious fake, placeholder, and test usernames (e.g. fake@..., test123@..., dummy@...)
  static final RegExp _fakeLocalPartPattern = RegExp(
    r'^(fake|fakemail|fakeemail|fakeuser|fakeaccount|test|tester|testing|testuser|testemail|dummy|dummyuser|dummyemail|asdf|asdfgh|qwerty|qwertyuiop|123456|12345678|noemail|nomail|notreal|sample|sampleuser)[0-9._-]*$',
    caseSensitive: false,
  );

  /// Common domain typos and their correct suggestions
  static const Map<String, String> _domainTypoMap = {
    'gmial.com': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gnail.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'gmaik.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'hotmial.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotamail.com': 'hotmail.com',
    'yaho.com': 'yahoo.com',
    'yahooo.com': 'yahoo.com',
    'yaho.co': 'yahoo.com',
    'outlok.com': 'outlook.com',
    'outloo.com': 'outlook.com',
    'putlook.com': 'outlook.com',
    'icoud.com': 'icloud.com',
    'iclud.com': 'icloud.com',
    'rediffmial.com': 'rediffmail.com',
    'redifmail.com': 'rediffmail.com',
  };

  /// Synchronous quick check for syntax, disposable domains, and typos
  static EmailValidationResult validateFormat(String email) {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Email address cannot be empty.',
      );
    }

    if (!trimmed.contains('@')) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Email must contain "@" (e.g. name@gmail.com).',
      );
    }

    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Email must have exactly one "@".',
      );
    }

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.isEmpty) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Please enter the username part before "@".',
      );
    }

    if (domain.isEmpty) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Please enter the email domain after "@".',
      );
    }

    if (!domain.contains('.')) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Email domain must contain a valid extension (e.g. .com).',
      );
    }

    final tld = domain.split('.').last;
    if (tld.length < 2) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Domain extension is too short (e.g. .com, .net).',
      );
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'Please enter a valid email format (e.g. name@gmail.com).',
      );
    }

    // Check obvious fake / placeholder usernames
    if (_fakeLocalPartPattern.hasMatch(localPart)) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'This looks like a fake or test email address. Please use your real email.',
      );
    }

    // Check disposable / burner domains
    if (_disposableDomains.contains(domain)) {
      return const EmailValidationResult(
        isValid: false,
        errorMessage: 'This email domain is fake or temporary. Please use a real email address.',
      );
    }

    // Check known domain typos
    if (_domainTypoMap.containsKey(domain)) {
      final suggestedDomain = _domainTypoMap[domain]!;
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'Did you mean @$suggestedDomain? This email domain does not exist.',
        suggestion: '$localPart@$suggestedDomain',
      );
    }

    return EmailValidationResult.valid;
  }

  /// Full validation including DNS domain existence check
  static Future<EmailValidationResult> validateEmail(String email, {bool checkDns = true}) async {
    final formatResult = validateFormat(email);
    if (!formatResult.isValid) {
      return formatResult;
    }

    if (!checkDns) {
      return EmailValidationResult.valid;
    }

    final trimmed = email.trim().toLowerCase();
    final domain = trimmed.split('@')[1];

    // Check if domain actually exists in DNS
    final domainExists = await verifyDomainExists(domain);
    if (!domainExists) {
      return EmailValidationResult(
        isValid: false,
        errorMessage: 'This email domain "$domain" does not exist. Please check your email.',
      );
    }

    return EmailValidationResult.valid;
  }

  /// Verifies if a domain resolves via DNS.
  /// Falls back gracefully if the device itself is offline.
  static Future<bool> verifyDomainExists(String domain) async {
    try {
      final addresses = await InternetAddress.lookup(domain).timeout(
        const Duration(seconds: 4),
      );
      return addresses.isNotEmpty;
    } on SocketException catch (_) {
      // Check if internet connection is alive by looking up a known root host
      try {
        final onlineCheck = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 2),
        );
        if (onlineCheck.isNotEmpty) {
          // Device IS online, so the queried domain definitely does NOT exist
          return false;
        }
      } catch (_) {
        // Device itself might be offline - do not falsely block in offline scenario
        return true;
      }
      return false;
    } catch (_) {
      return true; // Fallback gracefully on unknown exceptions
    }
  }
}
