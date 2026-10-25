import 'package:flutter/foundation.dart';

import '../models/expense_models.dart';
import 'expense_service.dart';

class ExpenseRepository extends ChangeNotifier {
  final groups = <GroupModel>[];
  final expenses = <ExpenseModel>[];

  String activeGroupId = '';

  GroupModel? get activeGroup {
    final matches = groups.where((g) => g.id == activeGroupId);
    return matches.isEmpty ? null : matches.first;
  }

  List<String> get members => activeGroup?.memberIds ?? const [];

  List<ExpenseModel> get activeExpenses {
    final list = expenses.where((e) => e.groupId == activeGroupId).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list;
  }

  void createGroup(String name, String owner) {
    if (name.trim().isEmpty) return;

    final group = GroupModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      inviteCode: ExpenseService.generateInviteCode(),
      qrCode: null,
      currency: 'INR',
      memberIds: [owner],
      createdBy: owner,
      createdAt: DateTime.now(),
      isPrivate: false,
    );

    groups.add(group);
    activeGroupId = group.id;

    notifyListeners();
  }

  void selectGroup(String groupId) {
    activeGroupId = groupId;
    notifyListeners();
  }

  void addMember(String name) {
    final index = groups.indexWhere((g) => g.id == activeGroupId);

    if (index < 0 || name.trim().isEmpty) return;

    final group = groups[index];
    final member = name.trim();

    if (!group.memberIds.contains(member)) {
      groups[index] = GroupModel(
        id: group.id,
        name: group.name,
        inviteCode: group.inviteCode,
        qrCode: group.qrCode,
        currency: group.currency,
        memberIds: [...group.memberIds, member],
        createdBy: group.createdBy,
        createdAt: group.createdAt,
        isPrivate: group.isPrivate,
      );

      notifyListeners();
    }
  }

  void saveExpense(ExpenseModel expense) {
    final index = expenses.indexWhere((e) => e.id == expense.id);

    if (index == -1) {
      expenses.add(expense);
    } else {
      expenses[index] = expense;
    }

    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
