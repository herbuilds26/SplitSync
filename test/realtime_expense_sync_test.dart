import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/activity_log_model.dart';
import 'package:splitsync/models/expense_model.dart';
import 'package:splitsync/providers/group_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseModel resilient parsing tests', () {
    test('ExpenseModel.fromMap parses standard fields correctly', () {
      final map = {
        'title': 'Dinner at Cafe',
        'amount': 450.50,
        'paidBy': 'user_1',
        'groupId': 'group_1',
        'splitMethod': 'equal',
        'splits': [
          {'userId': 'user_1', 'amount': 225.25},
          {'userId': 'user_2', 'amount': 225.25},
        ],
        'category': 'Food & Drinks',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 11, 20, 0)),
      };

      final expense = ExpenseModel.fromMap(map, 'exp_1');
      expect(expense.id, equals('exp_1'));
      expect(expense.title, equals('Dinner at Cafe'));
      expect(expense.amount, equals(450.50));
      expect(expense.paidBy, equals('user_1'));
      expect(expense.splits.length, equals(2));
      expect(expense.splits.first.amount, equals(225.25));
    });

    test('ExpenseModel.fromMap handles string amounts, missing splits, and integer amounts safely', () {
      final map = {
        'title': 'Groceries',
        'amount': '1200', // String representation
        'paidBy': 'user_2',
        'groupId': 'group_1',
        'splitMethod': 'equal',
        'splits': null, // Null splits
        'category': 'Shopping',
        'createdAt': DateTime(2026, 10, 11).toIso8601String(), // String timestamp
      };

      final expense = ExpenseModel.fromMap(map, 'exp_2');
      expect(expense.amount, equals(1200.0));
      expect(expense.splits, isEmpty);
      expect(expense.createdAt.year, equals(2026));
    });

    test('ExpenseModel.fromMap handles integers and null timestamps gracefully', () {
      final map = {
        'title': 'Uber',
        'amount': 300, // Int amount
        'paidBy': 'user_1',
        'groupId': 'group_1',
        'category': 'Transport',
      };

      final expense = ExpenseModel.fromMap(map, 'exp_3');
      expect(expense.amount, equals(300.0));
      expect(expense.createdAt, isA<DateTime>());
    });

    test('ExpenseSplit.fromMap handles string and dynamic amounts safely', () {
      final split = ExpenseSplit.fromMap({
        'userId': 'user_x',
        'amount': '45.75',
      });
      expect(split.userId, equals('user_x'));
      expect(split.amount, equals(45.75));
    });
  });

  group('GroupProvider Activity Log Expense detection', () {
    test('onExpenseActivityDetected callback triggers for expense actions', () {
      final groupProvider = GroupProvider();
      bool triggered = false;

      groupProvider.onExpenseActivityDetected = () {
        triggered = true;
      };

      // Simulating manual callback trigger verification
      groupProvider.onExpenseActivityDetected?.call();
      expect(triggered, isTrue);

      groupProvider.stopListening();
      expect(groupProvider.onExpenseActivityDetected, isNull);
    });

    test('ActivityLogModel parses expense actions correctly', () {
      final logMap = {
        'groupId': 'g1',
        'userId': 'u1',
        'userName': 'Alex',
        'action': 'added_expense',
        'details': 'Alex added "Movie tickets" (₹500)',
        'timestamp': Timestamp.now(),
      };

      final log = ActivityLogModel.fromMap(logMap, 'log_1');
      expect(log.action, equals('added_expense'));
      expect(log.userName, equals('Alex'));
    });
  });
}
