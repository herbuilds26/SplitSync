import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String upiId;
  final String defaultCurrency;
  final double monthlyBudget;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    this.upiId = '',
    this.defaultCurrency = 'INR',
    this.monthlyBudget = 15000.0,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      upiId: map['upiId'] ?? '',
      defaultCurrency: map['defaultCurrency'] ?? 'INR',
      monthlyBudget: (map['monthlyBudget'] ?? 15000.0).toDouble(),
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': name.trim().toLowerCase(),
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'upiId': upiId,
      'defaultCurrency': defaultCurrency,
      'monthlyBudget': monthlyBudget,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? upiId,
    String? defaultCurrency,
    double? monthlyBudget,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      upiId: upiId ?? this.upiId,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
