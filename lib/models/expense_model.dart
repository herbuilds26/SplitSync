import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseSplit {
  final String userId;
  final double amount;
  final double percentage;
  final double shares;

  ExpenseSplit({
    required this.userId,
    required this.amount,
    this.percentage = 0.0,
    this.shares = 1.0,
  });

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      userId: map['userId']?.toString() ?? '',
      amount: ExpenseModel.parseAmount(map['amount']),
      percentage: ExpenseModel.parseAmount(map['percentage']),
      shares: ExpenseModel.parseAmount(map['shares'], 1.0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'percentage': percentage,
      'shares': shares,
    };
  }
}

class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String category;
  final String paidBy;
  final String splitMethod; // equal, exact, percentage, custom
  final List<ExpenseSplit> splits;
  final String note;
  final String? receiptUrl;
  final String createdBy;
  final DateTime createdAt;
  final bool isSettled;

  static double parseAmount(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  static DateTime parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.splitMethod,
    required this.splits,
    this.note = '',
    this.receiptUrl,
    required this.createdBy,
    required this.createdAt,
    this.isSettled = false,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    final rawSplits = map['splits'];
    final parsedSplits = <ExpenseSplit>[];
    if (rawSplits is List) {
      for (final item in rawSplits) {
        if (item is Map) {
          try {
            parsedSplits.add(ExpenseSplit.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    return ExpenseModel(
      id: id,
      groupId: map['groupId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: parseAmount(map['amount']),
      category: map['category']?.toString() ?? 'Other',
      paidBy: map['paidBy']?.toString() ?? '',
      splitMethod: map['splitMethod']?.toString() ?? 'equal',
      splits: parsedSplits,
      note: map['note']?.toString() ?? '',
      receiptUrl: map['receiptUrl']?.toString(),
      createdBy: map['createdBy']?.toString() ?? '',
      createdAt: parseDate(map['createdAt']),
      isSettled: map['isSettled'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'splitMethod': splitMethod,
      'splits': splits.map((x) => x.toMap()).toList(),
      'note': note,
      'receiptUrl': receiptUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSettled': isSettled,
    };
  }
}
