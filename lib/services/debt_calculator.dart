import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';

class DebtCalculator {
  /// Calculates net balance vector for all group members based on expenses and settlements.
  static List<NetBalanceEntry> calculateNetBalances({
    required List<ExpenseModel> expenses,
    required List<SettlementModel> settlements,
    required List<String> memberIds,
  }) {
    final allMemberIds = <String>{...memberIds};
    for (final exp in expenses) {
      if (exp.paidBy.isNotEmpty && exp.paidBy != 'everyone') {
        allMemberIds.add(exp.paidBy);
      }
      for (final split in exp.splits) {
        if (split.userId.isNotEmpty) {
          allMemberIds.add(split.userId);
        }
      }
    }
    for (final st in settlements) {
      if (st.fromUserId.isNotEmpty) allMemberIds.add(st.fromUserId);
      if (st.toUserId.isNotEmpty) allMemberIds.add(st.toUserId);
    }

    final balances = <String, double>{for (final id in allMemberIds) id: 0.0};

    // 1. Process Expenses
    for (final expense in expenses) {
      if (expense.isSettled) continue;

      final payer = expense.paidBy;
      final total = expense.amount;

      if (payer == 'everyone') {
        // Everyone contributed equally, so credit each member an equal share.
        final perMember = allMemberIds.isEmpty ? 0.0 : total / allMemberIds.length;
        for (final id in allMemberIds) {
          balances[id] = (balances[id] ?? 0.0) + perMember;
        }
      } else {
        // Payer gets credited total amount paid
        balances[payer] = (balances[payer] ?? 0.0) + total;
      }

      // Each participant gets debited their split share
      for (final split in expense.splits) {
        balances[split.userId] = (balances[split.userId] ?? 0.0) - split.amount;
      }
    }

    // 2. Process Settlements
    for (final settlement in settlements) {
      if (settlement.status != 'completed') continue;

      // FromUser paid ToUser, so FromUser's debt decreases (balance gets +), ToUser's credit decreases (balance gets -)
      balances[settlement.fromUserId] = (balances[settlement.fromUserId] ?? 0.0) + settlement.amount;
      balances[settlement.toUserId] = (balances[settlement.toUserId] ?? 0.0) - settlement.amount;
    }

    return balances.entries
        .map((entry) => NetBalanceEntry(userId: entry.key, amount: double.parse(entry.value.toStringAsFixed(2))))
        .toList();
  }

  /// Debt Simplification Algorithm (Greedy Max Creditor / Max Debtor Matching).
  /// Reduces total transactions required to settle group debts to a minimum.
  static List<SettlementModel> simplifyDebts({
    required List<NetBalanceEntry> netBalances,
    required String groupId,
  }) {
    // Separate positive (creditors) and negative (debtors) balances
    final creditors = netBalances
        .where((b) => b.amount > 0.01)
        .map((b) => NetBalanceEntry(userId: b.userId, amount: b.amount))
        .toList();

    final debtors = netBalances
        .where((b) => b.amount < -0.01)
        .map((b) => NetBalanceEntry(userId: b.userId, amount: b.amount))
        .toList();

    final simplifiedSettlements = <SettlementModel>[];
    int i = 0;
    int j = 0;

    while (i < creditors.length && j < debtors.length) {
      final creditor = creditors[i];
      final debtor = debtors[j];

      final amount = math.min(creditor.amount, -debtor.amount);
      final roundedAmount = double.parse(amount.toStringAsFixed(2));

      if (roundedAmount > 0.01) {
        simplifiedSettlements.add(
          SettlementModel(
            id: 'simplified_${simplifiedSettlements.length + 1}',
            groupId: groupId,
            fromUserId: debtor.userId,
            toUserId: creditor.userId,
            amount: roundedAmount,
            paymentMethod: 'UPI',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );

        creditor.amount -= roundedAmount;
        debtor.amount += roundedAmount;
      }

      if (creditor.amount < 0.01) i++;
      if (debtor.amount > -0.01) j++;
    }

    return simplifiedSettlements;
  }

  /// Generate a random 6-character uppercase Invite Code.
  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = math.Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Helper to format currency values cleanly.
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }
}
