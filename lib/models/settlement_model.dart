import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementModel {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String paymentMethod; // UPI, Cash, BankTransfer
  final String? upiTransactionRef;
  final String status; // completed, pending
  final DateTime createdAt;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.paymentMethod = 'UPI',
    this.upiTransactionRef,
    this.status = 'completed',
    required this.createdAt,
  });

  factory SettlementModel.fromMap(Map<String, dynamic> map, String id) {
    return SettlementModel(
      id: id,
      groupId: map['groupId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      upiTransactionRef: map['upiTransactionRef'],
      status: map['status'] ?? 'completed',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'upiTransactionRef': upiTransactionRef,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NetBalanceEntry {
  final String userId;
  double amount; // Positive: Owed to user (creditor), Negative: User owes (debtor)

  NetBalanceEntry({required this.userId, required this.amount});
}
