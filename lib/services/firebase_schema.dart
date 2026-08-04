class FirestoreCollections {
  static const String users = 'users';
  static const String groups = 'groups';
  static const String members = 'members';
  static const String expenses = 'expenses';
  static const String splits = 'splits';
  static const String settlements = 'settlements';
  static const String notifications = 'notifications';
  static const String receipts = 'receipts';
  static const String activityLogs = 'activity_logs';
}

class FirestoreSchema {
  static const Map<String, dynamic> userDoc = {
    'id': 'string',
    'name': 'string',
    'email': 'string',
    'avatarUrl': 'string',
    'phone': 'string',
    'isPremium': 'bool',
    'preferences': 'map',
    'createdAt': 'timestamp',
  };

  static const Map<String, dynamic> groupDoc = {
    'id': 'string',
    'name': 'string',
    'inviteCode': 'string',
    'qrCode': 'string',
    'currency': 'string',
    'memberIds': 'array',
    'createdBy': 'string',
    'createdAt': 'timestamp',
    'isPrivate': 'bool',
  };

  static const Map<String, dynamic> expenseDoc = {
    'id': 'string',
    'groupId': 'string',
    'title': 'string',
    'amount': 'number',
    'category': 'string',
    'paidBy': 'string',
    'splitMethod': 'string',
    'note': 'string',
    'receiptPath': 'string',
    'createdAt': 'timestamp',
    'isSettled': 'bool',
  };
}
