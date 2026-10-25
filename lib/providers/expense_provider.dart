import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/settlement_model.dart';
import '../services/debt_calculator.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  List<SettlementModel> _settlements = [];
  List<NetBalanceEntry> _netBalances = [];
  List<SettlementModel> _simplifiedDebts = [];
  Map<String, double> _groupUserBalances = {};
  bool _isLoadingGroupBalances = false;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  StreamSubscription? _expensesSubscription;
  StreamSubscription? _settlementsSubscription;
  String? _listeningGroupId;
  String? _listeningUserId;
  List<String> _memberIds = [];
  bool _hasInitializedExpenses = false;
  bool _hasInitializedSettlements = false;
  String _listeningGroupName = 'Group';
  String _listeningCurrency = '₹';

  List<ExpenseModel> get expenses => _expenses;
  List<SettlementModel> get settlements => _settlements;
  List<NetBalanceEntry> get netBalances => _netBalances;
  List<SettlementModel> get simplifiedDebts => _simplifiedDebts;
  Map<String, double> get groupUserBalances => _groupUserBalances;
  bool get isLoadingGroupBalances => _isLoadingGroupBalances;
  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  bool get isListeningToGroup => _listeningGroupId != null;

  double get totalBalanceToReceive {
    double sum = 0.0;
    for (final bal in _groupUserBalances.values) {
      if (bal > 0.01) sum += bal;
    }
    return sum;
  }

  double get totalBalanceToSend {
    double sum = 0.0;
    for (final bal in _groupUserBalances.values) {
      if (bal < -0.01) sum += bal.abs();
    }
    return sum;
  }

  double get overallNetBalance {
    double sum = 0.0;
    for (final bal in _groupUserBalances.values) {
      sum += bal;
    }
    return sum;
  }

  List<ExpenseModel> get filteredExpenses {
    return _expenses.where((e) {
      final matchesSearch = e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          e.category.toLowerCase() == _selectedCategoryFilter.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void listenToGroupExpensesAndSettlements(
    String groupId,
    List<String> memberIds, {
    String groupName = 'Group',
    String currency = '₹',
    String currentUserId = '',
  }) {
    _memberIds = List<String>.from(memberIds);
    _listeningGroupName = groupName;
    _listeningCurrency = currency;
    if (currentUserId.isNotEmpty) {
      _listeningUserId = currentUserId;
    }

    if (_listeningGroupId == groupId && _expensesSubscription != null) {
      _recalculateBalances(groupId, _memberIds, currentUserId: _listeningUserId ?? '');
      notifyListeners();
      unawaited(refreshGroupExpenses(groupId));
      return;
    }

    _listeningGroupId = groupId;
    _hasInitializedExpenses = false;
    _hasInitializedSettlements = false;
    _expensesSubscription?.cancel();
    _settlementsSubscription?.cancel();

    _expensesSubscription = FirestoreService.streamGroupExpenses(groupId).listen(
      (expensesList) {
        final previousExpenses = _expenses;
        _expenses = expensesList;
        _recalculateBalances(groupId, _memberIds, currentUserId: _listeningUserId ?? '');
        notifyListeners();

        // Safely trigger push notification in isolated try-catch so it NEVER blocks UI updates
        if (_hasInitializedExpenses && previousExpenses.isNotEmpty) {
          for (final e in expensesList) {
            final isNew = !previousExpenses.any((existing) => existing.id == e.id);
            if (isNew) {
              try {
                NotificationService.showExpenseAddedNotification(
                  groupName: _listeningGroupName,
                  expenseTitle: e.title,
                  amount: e.amount,
                  payerName: 'A group member',
                  currency: _listeningCurrency,
                );
              } catch (e) {
                debugPrint('Notification failed: $e');
              }
            }
          }
        }
        _hasInitializedExpenses = true;
      },
      onError: (error) {
        debugPrint('Error in streamGroupExpenses subscription for $groupId: $error');
      },
    );

    _settlementsSubscription = FirestoreService.streamGroupSettlements(groupId).listen(
      (settlementList) {
        final previousSettlements = _settlements;
        _settlements = settlementList;
        _recalculateBalances(groupId, _memberIds, currentUserId: _listeningUserId ?? '');
        notifyListeners();

        if (_hasInitializedSettlements && previousSettlements.isNotEmpty) {
          for (final s in settlementList) {
            final isNew = !previousSettlements.any((existing) => existing.id == s.id);
            if (isNew) {
              try {
                NotificationService.showSettlementNotification(
                  groupName: _listeningGroupName,
                  payerName: 'A member',
                  payeeName: 'member',
                  amount: s.amount,
                  currency: _listeningCurrency,
                );
              } catch (e) {
                debugPrint('Settlement notification failed: $e');
              }
            }
          }
        }
        _hasInitializedSettlements = true;
      },
      onError: (error) {
        debugPrint('Error in streamGroupSettlements subscription for $groupId: $error');
      },
    );

    // Also fetch immediately via one-time query to ensure instant sync
    unawaited(refreshGroupExpenses(groupId));
  }

  /// Explicitly refreshes expenses from Firestore for a group and updates UI immediately
  Future<void> refreshGroupExpenses(String groupId) async {
    try {
      final fresh = await FirestoreService.getGroupExpenses(groupId);
      if (fresh.isNotEmpty || _expenses.isEmpty) {
        _expenses = fresh;
        _recalculateBalances(groupId, _memberIds, currentUserId: _listeningUserId ?? '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh group expenses for $groupId: $e');
    }
  }

  /// Explicitly refreshes settlements from Firestore for a group and updates UI immediately
  Future<void> refreshSettlements(String groupId) async {
    try {
      final fresh = await FirestoreService.getGroupSettlements(groupId);
      if (fresh.isNotEmpty || _settlements.isEmpty) {
        _settlements = fresh;
        _recalculateBalances(groupId, _memberIds, currentUserId: _listeningUserId ?? '');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh settlements for $groupId: $e');
    }
  }

  void _recalculateBalances(String groupId, List<String> memberIds, {String currentUserId = ''}) {
    _netBalances = DebtCalculator.calculateNetBalances(
      expenses: _expenses,
      settlements: _settlements,
      memberIds: memberIds,
    );

    _simplifiedDebts = DebtCalculator.simplifyDebts(
      netBalances: _netBalances,
      groupId: groupId,
    );

    final uid = currentUserId.isNotEmpty ? currentUserId : (_listeningUserId ?? '');
    if (uid.isNotEmpty) {
      double bal = 0.0;
      for (final entry in _netBalances) {
        if (entry.userId == uid) {
          bal = entry.amount;
          break;
        }
      }
      _groupUserBalances[groupId] = bal;
    }
  }

  DateTime? _lastBalancesFetchTime;
  String? _lastBalancesFetchKey;

  Future<void> fetchAllGroupBalances({
    required List<GroupModel> groups,
    required String currentUserId,
    bool forceRefresh = false,
  }) async {
    if (groups.isEmpty || currentUserId.isEmpty) {
      if (_groupUserBalances.isNotEmpty) {
        _groupUserBalances = {};
        notifyListeners();
      }
      return;
    }

    final groupsKey = '$currentUserId:${groups.map((g) => g.id).join(',')}';
    if (!forceRefresh) {
      if (_isLoadingGroupBalances) return;
      if (_lastBalancesFetchKey == groupsKey &&
          _lastBalancesFetchTime != null &&
          DateTime.now().difference(_lastBalancesFetchTime!) < const Duration(seconds: 15)) {
        return;
      }
    }

    _lastBalancesFetchKey = groupsKey;
    _lastBalancesFetchTime = DateTime.now();
    _listeningUserId = currentUserId;
    _isLoadingGroupBalances = true;
    notifyListeners();

    try {
      final Map<String, double> results = Map<String, double>.from(_groupUserBalances);
      final futures = groups.map((g) async {
        if (g.id == _listeningGroupId && _netBalances.isNotEmpty) {
          double activeBal = 0.0;
          for (final b in _netBalances) {
            if (b.userId == currentUserId) {
              activeBal = b.amount;
              break;
            }
          }
          results[g.id] = activeBal;
          return;
        }

        try {
          final expenses = await FirestoreService.getGroupExpenses(g.id);
          final settlements = await FirestoreService.getGroupSettlements(g.id);
          final net = DebtCalculator.calculateNetBalances(
            expenses: expenses,
            settlements: settlements,
            memberIds: g.memberIds,
          );
          double bal = 0.0;
          for (final b in net) {
            if (b.userId == currentUserId) {
              bal = b.amount;
              break;
            }
          }
          results[g.id] = bal;
        } catch (_) {
          results[g.id] = _groupUserBalances[g.id] ?? 0.0;
        }
      });

      await Future.wait(futures);
      _groupUserBalances = results;
    } finally {
      _isLoadingGroupBalances = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addExpense({
    required ExpenseModel expense,
    required String userName,
    String userAvatarUrl = '',
  }) async {
    await FirestoreService.addExpense(expense);
    _lastBalancesFetchTime = null; // Invalidate cache so home screen balance updates immediately
    await refreshGroupExpenses(expense.groupId);
    await FirestoreService.logActivity(
      ActivityLogModel(
        id: '',
        groupId: expense.groupId,
        userId: expense.createdBy,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        action: 'added_expense',
        details: 'Added "${expense.title}" for ₹${expense.amount.toStringAsFixed(2)}',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> deleteExpense(
    ExpenseModel expense,
    String userName, {
    String userAvatarUrl = '',
  }) async {
    await FirestoreService.deleteExpense(expense.id);
    _lastBalancesFetchTime = null;
    await refreshGroupExpenses(expense.groupId);
    await FirestoreService.logActivity(
      ActivityLogModel(
        id: '',
        groupId: expense.groupId,
        userId: expense.createdBy,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        action: 'deleted_expense',
        details: 'Deleted expense "${expense.title}"',
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> recordSettlement(
    SettlementModel settlement,
    String userName, {
    String userAvatarUrl = '',
  }) async {
    await FirestoreService.addSettlement(settlement);
    _lastBalancesFetchTime = null;
    await refreshSettlements(settlement.groupId);
    await FirestoreService.logActivity(
      ActivityLogModel(
        id: '',
        groupId: settlement.groupId,
        userId: settlement.fromUserId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        action: 'settled_up',
        details: 'Settled ₹${settlement.amount.toStringAsFixed(2)} via ${settlement.paymentMethod}',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    _settlementsSubscription?.cancel();
    super.dispose();
  }

  void stopListening() {
    _expensesSubscription?.cancel();
    _settlementsSubscription?.cancel();
    _expensesSubscription = null;
    _settlementsSubscription = null;
    _listeningGroupId = null;
    _hasInitializedExpenses = false;
    _hasInitializedSettlements = false;
    _memberIds = [];
    _expenses = [];
    _settlements = [];
    _netBalances = [];
    _simplifiedDebts = [];
    notifyListeners();
  }
}
