import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/group_model.dart';
import 'package:splitsync/services/debt_calculator.dart';
import 'package:splitsync/services/firestore_service.dart';

void main() {
  group('Group Join & Invite Code Tests', () {
    test('normalizeInviteCode handles raw 6-character uppercase and lowercase codes', () {
      expect(FirestoreService.normalizeInviteCode('SPLIT6'), equals('SPLIT6'));
      expect(FirestoreService.normalizeInviteCode('split6'), equals('SPLIT6'));
      expect(FirestoreService.normalizeInviteCode('  k9m2p4  '), equals('K9M2P4'));
    });

    test('normalizeInviteCode extracts code from custom deep links', () {
      expect(FirestoreService.normalizeInviteCode('splitsync://group/ABC123'), equals('ABC123'));
      expect(FirestoreService.normalizeInviteCode('splitsync://group/xyz789'), equals('XYZ789'));
    });

    test('normalizeInviteCode extracts code from web join links', () {
      expect(FirestoreService.normalizeInviteCode('https://splitsync.web.app/join?code=XYZ789'), equals('XYZ789'));
      expect(FirestoreService.normalizeInviteCode('https://splitsync.app/group/DEF456'), equals('DEF456'));
    });

    test('normalizeInviteCode extracts 6-char code from formatted WhatsApp share messages', () {
      const shareMessage = '''
Hey! Join my "Goa Trip" group on SplitSync to split and track expenses together.

👉 Group Code: GOA456

How to join:
1. Open SplitSync
2. Tap "Your Groups" → Tap the QR / Join icon
3. Enter code GOA456
''';
      expect(FirestoreService.normalizeInviteCode(shareMessage), equals('GOA456'));
    });

    test('normalizeInviteCode returns empty for empty input', () {
      expect(FirestoreService.normalizeInviteCode(''), equals(''));
      expect(FirestoreService.normalizeInviteCode('   '), equals(''));
    });

    test('DebtCalculator.generateInviteCode produces valid 6-char codes', () {
      for (int i = 0; i < 20; i++) {
        final code = DebtCalculator.generateInviteCode();
        expect(code.length, equals(6));
        expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);
      }
    });

    test('GroupModel copyWith updates memberIds immutably', () {
      final now = DateTime.now();
      final original = GroupModel(
        id: 'group_1',
        name: 'Apartment',
        inviteCode: 'APT123',
        qrCodeData: 'splitsync://group/APT123',
        memberIds: ['user_a'],
        adminIds: ['user_a'],
        createdBy: 'user_a',
        createdAt: now,
      );

      final updated = original.copyWith(memberIds: ['user_a', 'user_b']);
      expect(updated.id, equals('group_1'));
      expect(updated.name, equals('Apartment'));
      expect(updated.memberIds, equals(['user_a', 'user_b']));
      expect(original.memberIds, equals(['user_a'])); // Immutability preserved
    });

    test('Payer display resolution distinguishes between current user and other joined members', () {
      const userAId = 'user_a';
      const userBId = 'user_b';

      // Simulation of Phone A perspective
      String getPayerLabelForUser(String memberId, String viewerId, Map<String, String> names) {
        if (memberId == 'everyone') return 'Everyone';
        if (memberId == viewerId) return 'You';
        return names[memberId] ?? 'Member';
      }

      final names = {userAId: 'Alex', userBId: 'Bob'};

      // From User A (Creator) perspective:
      expect(getPayerLabelForUser(userAId, userAId, names), equals('You'));
      expect(getPayerLabelForUser(userBId, userAId, names), equals('Bob'));
      expect(getPayerLabelForUser('everyone', userAId, names), equals('Everyone'));

      // From User B (Joined member) perspective:
      expect(getPayerLabelForUser(userBId, userBId, names), equals('You'));
      expect(getPayerLabelForUser(userAId, userBId, names), equals('Alex'));
      expect(getPayerLabelForUser('everyone', userBId, names), equals('Everyone'));
    });
  });
}
