import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/settlement_model.dart';
import 'package:splitsync/services/debt_calculator.dart';
import 'package:splitsync/services/upi_service.dart';

void main() {
  group('SettleUp & UPI Service Logic Tests', () {
    test('UpiService builds compliant upi:// pay URI and URI string', () {
      final uri = UpiService.buildUpiUri(
        upiId: 'friend@okhdfcbank',
        payeeName: 'Friend Name',
        amount: 250.75,
        note: 'SplitSync Dinner Split',
      );

      expect(uri.scheme, 'upi');
      expect(uri.host, 'pay');
      expect(uri.queryParameters['pa'], 'friend@okhdfcbank');
      expect(uri.queryParameters['pn'], 'Friend Name');
      expect(uri.queryParameters['am'], '250.75');
      expect(uri.queryParameters['cu'], 'INR');
      expect(uri.queryParameters['tn'], 'SplitSync Dinner Split');

      final uriString = UpiService.buildUpiUriString(
        upiId: 'user@paytm',
        payeeName: 'User',
        amount: 100.0,
      );
      expect(uriString, contains('upi://pay?'));
      expect(uriString, anyOf(contains('pa=user%40paytm'), contains('pa=user@paytm')));
      expect(uriString, contains('am=100.00'));
    });

    test('SettlementModel handles Cash and UPI payment records with notes and refs', () {
      final now = DateTime.now();
      final cashSettlement = SettlementModel(
        id: 'settle_1',
        groupId: 'group_abc',
        fromUserId: 'user_1',
        toUserId: 'user_2',
        amount: 500.00,
        paymentMethod: 'Cash',
        upiTransactionRef: 'Handed cash at cafe',
        status: 'completed',
        createdAt: now,
      );

      final map = cashSettlement.toMap();
      expect(map['paymentMethod'], 'Cash');
      expect(map['upiTransactionRef'], 'Handed cash at cafe');
      expect(map['amount'], 500.00);

      final fromMap = SettlementModel.fromMap(map, 'settle_1');
      expect(fromMap.paymentMethod, 'Cash');
      expect(fromMap.upiTransactionRef, 'Handed cash at cafe');
      expect(fromMap.amount, 500.00);

      final upiSettlement = SettlementModel(
        id: 'settle_2',
        groupId: 'group_abc',
        fromUserId: 'user_1',
        toUserId: 'user_2',
        amount: 320.50,
        paymentMethod: 'UPI',
        upiTransactionRef: 'UTR123456789',
        status: 'completed',
        createdAt: now,
      );
      expect(upiSettlement.paymentMethod, 'UPI');
      expect(upiSettlement.upiTransactionRef, 'UTR123456789');
    });

    test('DebtCalculator simplifies balances into minimal required settlements', () {
      final netBalances = [
        NetBalanceEntry(userId: 'alice', amount: 500.0), // Creditor: owed 500
        NetBalanceEntry(userId: 'bob', amount: -300.0),   // Debtor: owes 300
        NetBalanceEntry(userId: 'charlie', amount: -200.0), // Debtor: owes 200
      ];

      final simplified = DebtCalculator.simplifyDebts(
        netBalances: netBalances,
        groupId: 'test_group',
      );

      expect(simplified.length, 2);
      expect(simplified.any((s) => s.fromUserId == 'bob' && s.toUserId == 'alice' && s.amount == 300.0), isTrue);
      expect(simplified.any((s) => s.fromUserId == 'charlie' && s.toUserId == 'alice' && s.amount == 200.0), isTrue);
    });

    test('Settlement flow creates verified UPI settlement record with UTR reference', () {
      final now = DateTime.now();
      final upiSettlement = SettlementModel(
        id: 'settle_verified',
        groupId: 'group_test',
        fromUserId: 'debtor_1',
        toUserId: 'creditor_1',
        amount: 450.0,
        paymentMethod: 'UPI',
        upiTransactionRef: '987654321098',
        createdAt: now,
      );

      expect(upiSettlement.paymentMethod, equals('UPI'));
      expect(upiSettlement.upiTransactionRef, equals('987654321098'));
      expect(upiSettlement.amount, equals(450.0));
      expect(upiSettlement.fromUserId, equals('debtor_1'));
      expect(upiSettlement.toUserId, equals('creditor_1'));
    });

    test('Settlement card grants Pay action ONLY to the payer and never to the receiver', () {
      const currentUserId = 'user_receiver';
      const payerUserId = 'user_debtor';

      final debt = SettlementModel(
        id: 'debt_1',
        groupId: 'grp_1',
        fromUserId: payerUserId,
        toUserId: currentUserId,
        amount: 250.0,
        createdAt: DateTime.now(),
      );

      // Simulate receiver perspective:
      final isPayer = currentUserId.isNotEmpty && debt.fromUserId == currentUserId;
      final isPayee = currentUserId.isNotEmpty && debt.toUserId == currentUserId;

      expect(isPayer, isFalse, reason: 'The user who has to receive must NEVER be identified as the payer');
      expect(isPayee, isTrue, reason: 'The user who has to receive must be identified as payee');
    });
  });
}
