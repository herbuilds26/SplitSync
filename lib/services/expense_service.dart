import 'dart:math' as math;
import '../models/expense_models.dart';

class ExpenseService {
  static List<BalanceEntry> calculateBalances(
    List<ExpenseModel> expenses,
    List<String> memberIds,
  ) {
    final balances = <String, double>{for (final id in memberIds) id: 0.0};

    for (final expense in expenses) {
      final total = expense.amount;
      for (final split in expense.splits) {
        balances[split.userId] = (balances[split.userId] ?? 0.0) - split.amount;
      }
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0.0) + total;
    }

    return balances.entries
        .map((entry) => BalanceEntry(userId: entry.key, amount: entry.value))
        .toList();
  }

  static List<SettlementModel> simplifyDebts(
    List<BalanceEntry> balances,
    String groupId,
  ) {
    final positive = balances.where((entry) => entry.amount > 0.001).toList();
    final negative = balances.where((entry) => entry.amount < -0.001).toList();

    final settlements = <SettlementModel>[];
    var i = 0;
    var j = 0;

    while (i < positive.length && j < negative.length) {
      final creditor = positive[i];
      final debtor = negative[j];
      final amount = math.min(creditor.amount, -debtor.amount).toDouble();
      if (amount > 0.001) {
        settlements.add(
          SettlementModel(
            id: 'settlement_${settlements.length + 1}',
            groupId: groupId,
            fromUserId: debtor.userId,
            toUserId: creditor.userId,
            amount: double.parse(amount.toStringAsFixed(2)),
            createdAt: DateTime.now(),
            isCompleted: false,
          ),
        );
        creditor.amount -= amount;
        debtor.amount += amount;
      }
      if (creditor.amount < 0.001) i++;
      if (debtor.amount > -0.001) j++;
    }

    return settlements;
  }

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = math.Random();
    return List.generate(
      6,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}
