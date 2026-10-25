import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/activity_log_model.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/settlement_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static void enableOfflineSupport() {
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ================= USERS =================

  static Future<void> saveUser(UserModel user) async {
    final map = user.toMap();
    map['nameLower'] = user.name.trim().toLowerCase();
    if (user.avatarUrl.isEmpty) {
      // Guard against erasing an existing avatar in Firestore with an empty string
      map.remove('avatarUrl');
    }
    await _db.collection('users').doc(user.uid).set(map, SetOptions(merge: true));
  }

  /// Checks if a user display name or username is already taken in Firestore
  static Future<bool> isNameTaken(String name, {String? excludeUid}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();

    try {
      // 1. Query by nameLower (case-insensitive)
      final lowerSnapshot = await _db
          .collection('users')
          .where('nameLower', isEqualTo: lower)
          .limit(3)
          .get()
          .timeout(const Duration(seconds: 4));

      for (final doc in lowerSnapshot.docs) {
        if (excludeUid != null && doc.id == excludeUid) continue;
        return true;
      }

      // 2. Query by exact name (for backward compatibility with older user docs)
      final exactSnapshot = await _db
          .collection('users')
          .where('name', isEqualTo: trimmed)
          .limit(3)
          .get()
          .timeout(const Duration(seconds: 4));

      for (final doc in exactSnapshot.docs) {
        if (excludeUid != null && doc.id == excludeUid) continue;
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error getting user $uid: $e');
    }
    return null;
  }

  static Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  static Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
    } catch (_) {}
  }

  // ================= GROUPS =================

  static String normalizeInviteCode(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';

    // If text contains a deep link or web link
    final uri = Uri.tryParse(value);
    if (uri != null && uri.queryParameters.containsKey('code')) {
      final qCode = uri.queryParameters['code']!;
      final cleanQ = qCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (cleanQ.isNotEmpty) return cleanQ;
    }

    const prefix = 'splitsync://group/';
    if (value.toLowerCase().startsWith(prefix)) {
      value = value.substring(prefix.length);
    } else if (value.contains('splitsync.web.app/join?code=')) {
      final idx = value.indexOf('code=');
      value = value.substring(idx + 5);
    } else if (value.contains('/')) {
      value = value.split('/').last;
    }

    value = value.split('?').first.split('#').first;
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.length == 6) {
      return cleaned;
    }

    // If it's a long text (e.g. copied invite message like "Join my SplitSync group ... invite code ABC123")
    final match = RegExp(r'\b[A-Z0-9]{6}\b', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }

    return cleaned;
  }

  static Future<String> createGroup(GroupModel group) async {
    final docRef = _db.collection('groups').doc();
    final payload = group.toMap();
    payload['inviteCode'] = group.inviteCode.toUpperCase();
    payload['qrCodeData'] = 'splitsync://group/${payload['inviteCode']}';
    try {
      await docRef.set(payload).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline fallback: Local cache already holds the document and background sync handles server push.
    }
    return docRef.id;
  }

  static Future<GroupModel?> getGroup(String groupId) async {
    final doc = await _db.collection('groups').doc(groupId).get(const GetOptions(source: Source.serverAndCache));
    if (doc.exists && doc.data() != null) {
      return GroupModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  static Stream<GroupModel?> streamGroup(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return GroupModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  static Future<void> updateGroup(GroupModel group) async {
    try {
      await _db.collection('groups').doc(group.id).update(group.toMap()).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline fallback
    }
  }

  static Stream<List<GroupModel>> streamUserGroups(String userId) {
    return _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  static Future<List<GroupModel>> getUserGroups(String userId) async {
    final snapshot = await _db
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(const Duration(seconds: 10));
    return snapshot.docs.map((doc) => GroupModel.fromMap(doc.data(), doc.id)).toList();
  }

  static Future<GroupModel?> findGroupByInviteCode(String code) async {
    final normalized = normalizeInviteCode(code);
    if (normalized.isEmpty) return null;

    final snapshot = await _db
        .collection('groups')
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache))
        .timeout(const Duration(seconds: 10));

    if (snapshot.docs.isNotEmpty) {
      return GroupModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    return null;
  }

  static Future<void> joinGroup(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  static Future<void> leaveOrRemoveMember(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  // ================= EXPENSES =================

  static Future<String> addExpense(ExpenseModel expense) async {
    final docRef = _db.collection('expenses').doc();
    final payload = expense.toMap();
    try {
      await docRef.set(payload).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Background sync continues
    }
    return docRef.id;
  }

  static Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _db.collection('expenses').doc(expense.id).update(expense.toMap()).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Background sync
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    try {
      await _db.collection('expenses').doc(expenseId).delete().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Background sync
    }
  }

  static Stream<List<ExpenseModel>> streamGroupExpenses(String groupId) {
    return _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final list = <ExpenseModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(ExpenseModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Error mapping expense doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<List<ExpenseModel>> getGroupExpenses(String groupId) async {
    try {
      final snapshot = await _db
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));
      final list = <ExpenseModel>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(ExpenseModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Error mapping expense doc ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('Failed to get group expenses for $groupId: $e');
      return [];
    }
  }

  // ================= SETTLEMENTS =================

  static Future<void> addSettlement(SettlementModel settlement) async {
    final docRef = _db.collection('settlements').doc();
    try {
      await docRef.set(settlement.toMap()).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Background sync
    }
  }

  static Stream<List<SettlementModel>> streamGroupSettlements(String groupId) {
    return _db
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SettlementModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  static Future<List<SettlementModel>> getGroupSettlements(String groupId) async {
    try {
      final snapshot = await _db
          .collection('settlements')
          .where('groupId', isEqualTo: groupId)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) => SettlementModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return [];
    }
  }

  // ================= ACTIVITY LOGS =================

  static Future<void> logActivity(ActivityLogModel log) async {
    final docRef = _db.collection('activityLogs').doc();
    try {
      await docRef.set(log.toMap()).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Background sync
    }
  }

  static Stream<List<ActivityLogModel>> streamGroupActivityLogs(String groupId) {
    return _db
        .collection('activityLogs')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
