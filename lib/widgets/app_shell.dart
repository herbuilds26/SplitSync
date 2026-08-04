import 'package:flutter/material.dart';
import '../models/expense_models.dart';
import '../services/app_state.dart';
import '../services/expense_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _members = ['alex', 'maria', 'sam'];
  final _expenses = <ExpenseModel>[
    ExpenseModel(
      id: 'e1',
      groupId: 'g1',
      title: 'Groceries',
      amount: 180.0,
      category: 'Food',
      paidBy: 'alex',
      splits: const [
        ExpenseSplit(userId: 'alex', amount: 60, percentage: 33.3),
        ExpenseSplit(userId: 'maria', amount: 60, percentage: 33.3),
        ExpenseSplit(userId: 'sam', amount: 60, percentage: 33.3),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Weekend groceries',
      receiptPath: null,
      splitMethod: 'Equal',
      isSettled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final balances = ExpenseService.calculateBalances(_expenses, _members);
    final settlements = ExpenseService.simplifyDebts(balances, 'g1');

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SplitSync',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Premium group expenses, instantly',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              child: Icon(Icons.account_circle_rounded),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: IconButton.filledTonal(
                                onPressed: AppState.instance.toggleTheme,
                                icon: const Icon(Icons.dark_mode_rounded),
                                iconSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.wallet,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text('Net balance'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹ 120.00',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You are owed by 2 people',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI insights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You tend to overspend on dining out on weekends. A weekly budget reminder is recommended.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Live balances',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...balances.map(
                      (entry) => ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            entry.userId.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(entry.userId.toUpperCase()),
                        trailing: Text(
                          entry.amount >= 0
                              ? '+₹${entry.amount.toStringAsFixed(2)}'
                              : '-₹${(-entry.amount).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: entry.amount >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Suggested settlements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...settlements.map(
                      (s) => ListTile(
                        title: Text('${s.fromUserId} → ${s.toUserId}'),
                        subtitle: Text('₹${s.amount.toStringAsFixed(2)}'),
                        trailing: const Icon(Icons.swap_horiz_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('New expense'),
      ),
    );
  }
}
