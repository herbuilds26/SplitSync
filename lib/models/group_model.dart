import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final String qrCodeData;
  final String currency;
  final String category;
  final List<String> memberIds;
  final List<String> adminIds;
  final String createdBy;
  final DateTime createdAt;
  final bool isPrivate;

  GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.qrCodeData,
    this.currency = 'INR',
    this.category = 'Trip',
    required this.memberIds,
    required this.adminIds,
    required this.createdBy,
    required this.createdAt,
    this.isPrivate = false,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      qrCodeData: map['qrCodeData'] ?? '',
      currency: map['currency'] ?? 'INR',
      category: map['category'] ?? 'Trip',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: map['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode.toUpperCase(),
      'qrCodeData': qrCodeData.isNotEmpty ? qrCodeData : 'splitsync://group/${inviteCode.toUpperCase()}',
      'currency': currency,
      'category': category,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? qrCodeData,
    String? currency,
    String? category,
    List<String>? memberIds,
    List<String>? adminIds,
    String? createdBy,
    DateTime? createdAt,
    bool? isPrivate,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
