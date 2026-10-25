import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/expense_model.dart';

void main() {
  group('Expense Split Methods Calculation & Validation Tests', () {
    test('Equal Split: divides amount equally among included members', () {
      const totalAmount = 300.0;
      final memberIds = ['user1', 'user2', 'user3'];

      final perPerson = totalAmount / memberIds.length;
      final perPersonPct = 100.0 / memberIds.length;

      final splits = memberIds.map((id) => ExpenseSplit(
        userId: id,
        amount: double.parse(perPerson.toStringAsFixed(2)),
        percentage: double.parse(perPersonPct.toStringAsFixed(2)),
        shares: 1.0,
      )).toList();

      expect(splits.length, 3);
      for (final split in splits) {
        expect(split.amount, 100.0);
        expect(split.percentage, 33.33);
        expect(split.shares, 1.0);
      }
    });

    test('Equal Split with 2 of 3 members selected', () {
      const totalAmount = 500.0;
      final selectedMembers = ['user1', 'user3'];

      final perPerson = totalAmount / selectedMembers.length;
      final splits = selectedMembers.map((id) => ExpenseSplit(
        userId: id,
        amount: perPerson,
        percentage: 100.0 / selectedMembers.length,
      )).toList();

      expect(splits.length, 2);
      expect(splits[0].amount, 250.0);
      expect(splits[1].amount, 250.0);
    });

    test('Exact Split: preserves exact custom amounts and computes percentages', () {
      const totalAmount = 1000.0;
      final exactInputs = {'user1': 450.0, 'user2': 350.0, 'user3': 200.0};

      final totalExact = exactInputs.values.fold(0.0, (sum, val) => sum + val);
      expect((totalExact - totalAmount).abs() <= 0.05, isTrue);

      final splits = exactInputs.entries.map((entry) {
        final val = entry.value;
        final pct = (val / totalAmount) * 100.0;
        return ExpenseSplit(
          userId: entry.key,
          amount: val,
          percentage: pct,
        );
      }).toList();

      expect(splits.length, 3);
      expect(splits[0].amount, 450.0);
      expect(splits[0].percentage, 45.0);
      expect(splits[1].amount, 350.0);
      expect(splits[1].percentage, 35.0);
      expect(splits[2].amount, 200.0);
      expect(splits[2].percentage, 20.0);
    });

    test('Percentage Split: calculates exact amounts from percentages', () {
      const totalAmount = 800.0;
      final pctInputs = {'user1': 50.0, 'user2': 30.0, 'user3': 20.0};

      final totalPct = pctInputs.values.fold(0.0, (sum, val) => sum + val);
      expect((totalPct - 100.0).abs() <= 0.5, isTrue);

      final splits = pctInputs.entries.map((entry) {
        final pct = entry.value;
        final amount = totalAmount * (pct / 100.0);
        return ExpenseSplit(
          userId: entry.key,
          amount: amount,
          percentage: pct,
        );
      }).toList();

      expect(splits.length, 3);
      expect(splits[0].amount, 400.0);
      expect(splits[1].amount, 240.0);
      expect(splits[2].amount, 160.0);
    });

    test('Custom Shares: correctly calculates weighted split by shares/ratios', () {
      const totalAmount = 600.0;
      // user1 has 3 shares, user2 has 2 shares, user3 has 1 share -> total 6 shares
      final shares = {'user1': 3.0, 'user2': 2.0, 'user3': 1.0};

      final totalShares = shares.values.fold(0.0, (sum, s) => sum + s);
      expect(totalShares, 6.0);

      final splits = shares.entries.map((entry) {
        final share = entry.value;
        final amount = totalAmount * (share / totalShares);
        final pct = (share / totalShares) * 100.0;
        return ExpenseSplit(
          userId: entry.key,
          amount: amount,
          percentage: pct,
          shares: share,
        );
      }).toList();

      expect(splits[0].amount, 300.0); // 3/6 = 50%
      expect(splits[0].percentage, 50.0);
      expect(splits[0].shares, 3.0);

      expect(splits[1].amount, 200.0); // 2/6 = 33.33%
      expect(splits[1].percentage, closeTo(33.33, 0.01));
      expect(splits[1].shares, 2.0);

      expect(splits[2].amount, 100.0); // 1/6 = 16.67%
      expect(splits[2].percentage, closeTo(16.67, 0.01));
      expect(splits[2].shares, 1.0);
    });

    test('Custom Shares with decimal weights', () {
      const totalAmount = 250.0;
      // user1: 1.5 shares, user2: 1.0 share -> total 2.5 shares
      final shares = {'user1': 1.5, 'user2': 1.0};
      final totalShares = shares.values.fold(0.0, (sum, s) => sum + s);
      expect(totalShares, 2.5);

      final splits = shares.entries.map((entry) {
        final share = entry.value;
        final amount = totalAmount * (share / totalShares);
        return ExpenseSplit(userId: entry.key, amount: amount, shares: share);
      }).toList();

      expect(splits[0].amount, 150.0); // 1.5 / 2.5 * 250 = 150
      expect(splits[1].amount, 100.0); // 1.0 / 2.5 * 250 = 100
    });

    test('Split Evenly (Exact): cent/paise balancing distributes without penny loss', () {
      const totalAmount = 100.0;
      final activeIds = ['u1', 'u2', 'u3'];
      final count = activeIds.length;
      final totalCents = (totalAmount * 100).round();
      final baseCents = totalCents ~/ count;
      final remainderCents = totalCents % count;

      final amounts = <double>[];
      for (int i = 0; i < count; i++) {
        final cents = baseCents + (i < remainderCents ? 1 : 0);
        amounts.add(cents / 100.0);
      }

      expect(amounts, [33.34, 33.33, 33.33]);
      final sum = amounts.fold(0.0, (a, b) => a + b);
      expect((sum - totalAmount).abs() < 0.0001, isTrue);
    });

    test('Split Evenly (Percentage): distributes exactly 100.0% across 3 members', () {
      final activeIds = ['u1', 'u2', 'u3'];
      final count = activeIds.length;
      final basePct = double.parse((100.0 / count).toStringAsFixed(1));
      final currentSum = basePct * count;
      final diff = double.parse((100.0 - currentSum).toStringAsFixed(1));

      final pcts = <double>[];
      for (int i = 0; i < count; i++) {
        pcts.add(i == 0 ? (basePct + diff) : basePct);
      }

      expect(pcts, [33.4, 33.3, 33.3]);
      final sumPct = pcts.fold(0.0, (a, b) => a + b);
      expect(sumPct, closeTo(100.0, 0.0001));
    });

    test('Fill Remaining (Exact): allocates remaining balance to empty fields', () {
      const totalAmount = 1000.0;
      final enteredAmounts = {'u1': 600.0, 'u2': 0.0};
      final remaining = totalAmount - enteredAmounts['u1']!;
      expect(remaining, 400.0);

      enteredAmounts['u2'] = remaining;
      final sum = enteredAmounts.values.fold(0.0, (a, b) => a + b);
      expect(sum, totalAmount);
    });
  });
}

