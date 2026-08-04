class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String phone;
  final bool isPremium;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.phone,
    required this.isPremium,
    required this.preferences,
  });
}

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final String? qrCode;
  final String currency;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final bool isPrivate;

  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.qrCode,
    required this.currency,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    required this.isPrivate,
  });
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String category;
  final String paidBy;
  final List<ExpenseSplit> splits;
  final DateTime createdAt;
  final String note;
  final String? receiptPath;
  final String splitMethod;
  final bool isSettled;

  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.splits,
    required this.createdAt,
    required this.note,
    required this.receiptPath,
    required this.splitMethod,
    required this.isSettled,
  });
}

class ExpenseSplit {
  final String userId;
  final double amount;
  final double percentage;

  const ExpenseSplit({
    required this.userId,
    required this.amount,
    required this.percentage,
  });
}

class SettlementModel {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime createdAt;
  final bool isCompleted;

  const SettlementModel({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.createdAt,
    required this.isCompleted,
  });
}

class BalanceEntry {
  final String userId;
  double amount;

  BalanceEntry({required this.userId, required this.amount});
}
