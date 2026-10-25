import 'package:flutter/material.dart';

import '../../../models/expense_models.dart';
import '../../../services/expense_repository.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final ExpenseRepository repo;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.repo,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  double get totalSpent {
    return widget.repo.expenses
        .where((expense) => expense.groupId == widget.group.id)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<ExpenseModel> get groupExpenses {
    final expenses = widget.repo.expenses
        .where((expense) => expense.groupId == widget.group.id)
        .toList();

    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    const berry = Color(0xFF4A2545);
    const mint = Color(0xFF8FD3C1);
    const cream = Color(0xFFFFF8E7);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.group.name,
          style: const TextStyle(
            color: berry,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: berry),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: berry,
        foregroundColor: Colors.white,
        onPressed: () {
          _showAddMemberDialog();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Member'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // GROUP SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: berry,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  widget.group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${widget.group.memberIds.length} members',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Total Spending',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '₹ ${totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: mint,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // MEMBERS
          const Text(
            'Members',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: berry,
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.group.memberIds.map((member) {
              return Chip(
                avatar: const Icon(
                  Icons.person,
                  size: 18,
                  color: berry,
                ),
                label: Text(member),
                backgroundColor: const Color(0xFFE4F3EE),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          // EXPENSES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Group Expenses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: berry,
                ),
              ),

              Text(
                '${groupExpenses.length} expenses',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (groupExpenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3EE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 45,
                    color: berry,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No expenses yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Add an expense to start tracking spending.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...groupExpenses.map(
              (expense) => Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE6EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: berry,
                    ),
                  ),
                  title: Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${expense.category} • Paid by ${expense.paidBy}',
                  ),
                  trailing: Text(
                    '₹ ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: berry,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter member name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                widget.repo.addMember(controller.text);

                setState(() {});

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}