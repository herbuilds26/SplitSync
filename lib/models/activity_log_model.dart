import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String action;
  final String details;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl = '',
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLogModel(
      id: id,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      userAvatarUrl: map['userAvatarUrl'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'action': action,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
