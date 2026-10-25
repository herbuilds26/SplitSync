import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/debt_calculator.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class GroupProvider extends ChangeNotifier {
  List<GroupModel> _groups = [];
  GroupModel? _activeGroup;
  List<UserModel> _activeGroupMembers = [];
  List<ActivityLogModel> _activityLogs = [];
  StreamSubscription? _groupsSubscription;
  StreamSubscription? _activitySubscription;
  StreamSubscription? _activeGroupDocSubscription;
  final Map<String, StreamSubscription<UserModel?>> _memberSubscriptions = {};
  String? _listeningUserId;
  String? _activityGroupId;
  String? _errorMessage;
  bool _hasInitializedGroups = false;

  List<GroupModel> get groups => _groups;
  GroupModel? get activeGroup => _activeGroup;
  List<UserModel> get activeGroupMembers => _activeGroupMembers;
  List<ActivityLogModel> get activityLogs => _activityLogs;
  String? get errorMessage => _errorMessage;

  VoidCallback? onExpenseActivityDetected;

  void listenToUserGroups(String userId) {
    if (userId.isEmpty || _listeningUserId == userId) return;
    _listeningUserId = userId;
    _groupsSubscription?.cancel();
    _groupsSubscription = FirestoreService.streamUserGroups(userId).listen(
      (groupList) async {
        groupList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Notify user when a new group is added by someone else
        if (_hasInitializedGroups && _groups.isNotEmpty) {
          for (final g in groupList) {
            final isNew = !_groups.any((existing) => existing.id == g.id);
            if (isNew) {
              try {
                NotificationService.showGroupAddedNotification(groupName: g.name);
              } catch (_) {}
            }
          }
        }
        _hasInitializedGroups = true;

        _groups = groupList;
        if (_groups.isNotEmpty) {
          if (_activeGroup == null || !_groups.any((g) => g.id == _activeGroup!.id)) {
            await setActiveGroup(_groups.first);
          } else {
            await setActiveGroup(_groups.firstWhere((g) => g.id == _activeGroup!.id));
          }
        } else {
          _activeGroup = null;
          _activeGroupMembers = [];
          _activityLogs = [];
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Failed to stream groups: $error');
        _errorMessage = 'Could not load groups. Check your connection.';
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _groupsSubscription?.cancel();
    _activitySubscription?.cancel();
    _activeGroupDocSubscription?.cancel();
    _cancelMemberSubscriptions();
    _groupsSubscription = null;
    _activitySubscription = null;
    _activeGroupDocSubscription = null;
    _listeningUserId = null;
    _activityGroupId = null;
    _hasInitializedGroups = false;
    _groups = [];
    _activeGroup = null;
    _activeGroupMembers = [];
    _activityLogs = [];
    _errorMessage = null;
    onExpenseActivityDetected = null;
    notifyListeners();
  }

  Future<void> setActiveGroup(GroupModel group) async {
    final membersChanged = _activeGroup?.id != group.id ||
        _activeGroup?.memberIds.length != group.memberIds.length ||
        !_sameMembers(_activeGroup?.memberIds ?? const [], group.memberIds);

    _activeGroup = group;
    notifyListeners();

    if (membersChanged || _activeGroupMembers.length != group.memberIds.length) {
      await _loadMembersForActiveGroup();
    }
    _listenToActiveGroupDoc(group.id);
    _listenToActivityLogs(group.id);
  }

  void _listenToActiveGroupDoc(String groupId) {
    if (_activeGroupDocSubscription != null && _activeGroup?.id == groupId) {
      return;
    }
    _activeGroupDocSubscription?.cancel();
    _activeGroupDocSubscription = FirestoreService.streamGroup(groupId).listen(
      (updatedGroup) async {
        if (updatedGroup == null) return;
        final membersChanged = _activeGroup == null ||
            _activeGroup!.memberIds.length != updatedGroup.memberIds.length ||
            !_sameMembers(_activeGroup!.memberIds, updatedGroup.memberIds);

        _activeGroup = updatedGroup;
        _groups = _groups.map((g) => g.id == updatedGroup.id ? updatedGroup : g).toList();
        if (!_groups.any((g) => g.id == updatedGroup.id)) {
          _groups.insert(0, updatedGroup);
        }
        notifyListeners();

        if (membersChanged || _activeGroupMembers.length != updatedGroup.memberIds.length) {
          await _loadMembersForActiveGroup();
        }
      },
      onError: (error) {
        debugPrint('Error streaming active group doc: $error');
      },
    );
  }

  bool _sameMembers(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final setA = a.toSet();
    return b.every(setA.contains);
  }

  Future<void> _loadMembersForActiveGroup() async {
    final group = _activeGroup;
    if (group == null) return;
    final memberIds = List<String>.from(group.memberIds);
    if (memberIds.isEmpty) {
      _activeGroupMembers = [];
      _cancelMemberSubscriptions();
      notifyListeners();
      return;
    }

    try {
      final memberFutures = memberIds.map((uid) async {
        final user = await FirestoreService.getUser(uid);
        if (user != null) return user;
        return UserModel(
          uid: uid,
          name: 'Member',
          email: '',
          createdAt: DateTime.now(),
        );
      });
      final members = await Future.wait(memberFutures);
      _activeGroupMembers = members;
      notifyListeners();

      // Listen to real-time changes on each member document so avatar/name updates reflect instantly
      _listenToMemberProfiles(memberIds);
    } catch (e) {
      debugPrint('Error loading members for active group: $e');
    }
  }

  void _listenToMemberProfiles(List<String> memberIds) {
    // 1. Cancel subscriptions for members no longer in the group
    _memberSubscriptions.removeWhere((uid, sub) {
      if (!memberIds.contains(uid)) {
        sub.cancel();
        return true;
      }
      return false;
    });

    // 2. Start streaming each member document
    for (final uid in memberIds) {
      if (_memberSubscriptions.containsKey(uid)) continue;
      _memberSubscriptions[uid] = FirestoreService.streamUser(uid).listen(
        (updatedUser) {
          if (updatedUser == null) return;
          final index = _activeGroupMembers.indexWhere((m) => m.uid == uid);
          if (index != -1) {
            final old = _activeGroupMembers[index];
            if (old.name != updatedUser.name ||
                old.avatarUrl != updatedUser.avatarUrl ||
                old.upiId != updatedUser.upiId) {
              _activeGroupMembers[index] = updatedUser;
              notifyListeners();
            }
          } else {
            _activeGroupMembers.add(updatedUser);
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Error streaming member user $uid: $err');
        },
      );
    }
  }

  void _cancelMemberSubscriptions() {
    for (final sub in _memberSubscriptions.values) {
      sub.cancel();
    }
    _memberSubscriptions.clear();
  }

  /// Immediately synchronizes the current user's profile model in active members
  void syncCurrentUser(UserModel user) {
    final index = _activeGroupMembers.indexWhere((m) => m.uid == user.uid);
    if (index != -1) {
      _activeGroupMembers[index] = user;
      notifyListeners();
    }
  }

  Future<void> refreshActiveGroupMembers() async {
    if (_activeGroup != null) {
      try {
        final latest = await FirestoreService.getGroup(_activeGroup!.id);
        if (latest != null) {
          _activeGroup = latest;
          _groups = _groups.map((g) => g.id == latest.id ? latest : g).toList();
        }
      } catch (_) {}
      await _loadMembersForActiveGroup();
    }
  }

  Future<void> refreshUserGroups([String? userId]) async {
    final uid = userId ?? _listeningUserId;
    if (uid == null || uid.isEmpty) return;
    try {
      final groupList = await FirestoreService.getUserGroups(uid);
      groupList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _groups = groupList;
      if (_activeGroup != null) {
        final match = _groups.cast<GroupModel?>().firstWhere(
              (g) => g?.id == _activeGroup!.id,
              orElse: () => null,
            );
        if (match != null) {
          _activeGroup = match;
        }
      }
      notifyListeners();
      if (_activeGroup != null) {
        await _loadMembersForActiveGroup();
      }
    } catch (e) {
      debugPrint('Error refreshing user groups: $e');
    }
  }

  void _listenToActivityLogs(String groupId) {
    if (_activityGroupId == groupId && _activitySubscription != null) return;
    _activityGroupId = groupId;
    _activitySubscription?.cancel();
    _activitySubscription = FirestoreService.streamGroupActivityLogs(groupId).listen(
      (logs) {
        final previousLogs = _activityLogs;
        _activityLogs = logs;
        notifyListeners();

        // If a new activity log arrived with an expense/settlement action, notify listener to sync expenses immediately
        if (logs.isNotEmpty) {
          final newestId = logs.first.id;
          final hadOld = previousLogs.any((l) => l.id == newestId);
          if (!hadOld && previousLogs.isNotEmpty) {
            final action = logs.first.action;
            if (action == 'added_expense' ||
                action == 'updated_expense' ||
                action == 'deleted_expense' ||
                action == 'settled_up') {
              onExpenseActivityDetected?.call();
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Failed to stream activity: $error');
      },
    );
  }

  Future<GroupModel> createGroup({
    required String name,
    required String category,
    required String currency,
    required String userId,
    required String userName,
    String userAvatarUrl = '',
  }) async {
    final inviteCode = DebtCalculator.generateInviteCode();
    final createdAt = DateTime.now();
    final trimmedName = name.trim();
    final draft = GroupModel(
      id: '',
      name: trimmedName,
      inviteCode: inviteCode,
      qrCodeData: 'splitsync://group/$inviteCode',
      currency: currency,
      category: category,
      memberIds: [userId],
      adminIds: [userId],
      createdBy: userId,
      createdAt: createdAt,
    );

    final groupId = await FirestoreService.createGroup(draft);

    final created = GroupModel(
      id: groupId,
      name: trimmedName,
      inviteCode: inviteCode,
      qrCodeData: 'splitsync://group/$inviteCode',
      currency: currency,
      category: category,
      memberIds: [userId],
      adminIds: [userId],
      createdBy: userId,
      createdAt: createdAt,
    );

    if (!_groups.any((g) => g.id == created.id)) {
      _groups = [created, ..._groups];
    }
    _activeGroup = created;
    _activeGroupMembers = [
      UserModel(
        uid: userId,
        name: userName,
        avatarUrl: userAvatarUrl,
        email: '',
        createdAt: createdAt,
      ),
    ];
    notifyListeners();
    listenToUserGroups(userId);
    unawaited(setActiveGroup(created));
    unawaited(
      FirestoreService.logActivity(
        ActivityLogModel(
          id: '',
          groupId: groupId,
          userId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          action: 'created_group',
          details: 'Created group "$trimmedName"',
          timestamp: createdAt,
        ),
      ),
    );

    return created;
  }

  Future<void> updateGroupCategory(GroupModel group, String newCategory) async {
    final updated = group.copyWith(category: newCategory.trim());
    await FirestoreService.updateGroup(updated);
    _activeGroup = updated;
    _groups = _groups.map((g) => g.id == updated.id ? updated : g).toList();
    notifyListeners();
  }

  Future<GroupModel> joinGroupByCode(
    String code,
    String userId,
    String userName, {
    String userAvatarUrl = '',
  }) async {
    final group = await FirestoreService.findGroupByInviteCode(code);
    if (group == null) {
      throw Exception('No group found for that invite code.');
    }

    if (!group.memberIds.contains(userId)) {
      await FirestoreService.joinGroup(group.id, userId);
      try {
        await FirestoreService.logActivity(
          ActivityLogModel(
            id: '',
            groupId: group.id,
            userId: userId,
            userName: userName,
            userAvatarUrl: userAvatarUrl,
            action: 'joined_group',
            details: '$userName joined group',
            timestamp: DateTime.now(),
          ),
        );
      } catch (e) {
        debugPrint('Joined group but activity log failed: $e');
      }
    }

    final updatedMemberIds = group.memberIds.contains(userId)
        ? group.memberIds
        : [...group.memberIds, userId];
    final updated = group.copyWith(memberIds: updatedMemberIds);

    if (!_groups.any((g) => g.id == updated.id)) {
      _groups = [updated, ..._groups];
    } else {
      _groups = _groups.map((g) => g.id == updated.id ? updated : g).toList();
    }
    notifyListeners();

    // Ensure real-time stream listener is active for this user
    listenToUserGroups(userId);

    await setActiveGroup(updated);
    return updated;
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await FirestoreService.leaveOrRemoveMember(groupId, userId);
    if (_activeGroup?.id == groupId) {
      _activeGroup = null;
      _activeGroupMembers = [];
      _cancelMemberSubscriptions();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _activitySubscription?.cancel();
    _activeGroupDocSubscription?.cancel();
    _cancelMemberSubscriptions();
    super.dispose();
  }
}
