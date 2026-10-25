import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../utils/currency_input_formatter.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/lively_animations.dart';
import '../expenses/add_expense_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _chartColors = [
    AppColors.berryRose,
    AppColors.deepBerry,
    AppColors.sageGreen,
    Color(0xFFB85C7D),
    Color(0xFF8D5570),
    Color(0xFFA97B8B),
  ];

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final activeGroup = groupProvider.activeGroup;
    final groups = groupProvider.groups;
    final expenseProvider = context.watch<ExpenseProvider>();

    if (activeGroup != null && !expenseProvider.isListeningToGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        expenseProvider.listenToGroupExpensesAndSettlements(
          activeGroup.id,
          activeGroup.memberIds,
          groupName: activeGroup.name,
          currency: activeGroup.currency,
        );
      });
    }

    final expenses = expenseProvider.expenses;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppStrings.of(context);
    final budget = context.watch<AuthProvider>().userModel?.monthlyBudget ?? 15000.0;
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month).toList();
    final totalSpent = thisMonth.fold<double>(0, (sum, expense) => sum + expense.amount);
    final budgetProgress = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0).toDouble() : 0.0;
    final categoryTotals = <String, double>{};
    for (final expense in thisMonth) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    final categories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final prediction = _predictNextMonth(expenses, now, totalSpent);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('insights')),
        centerTitle: false,
        actions: [
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ActionChip(
                backgroundColor: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.berryRose.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                avatar: const Icon(Icons.groups_rounded, size: 16, color: AppColors.berryRose),
                label: Text(
                  activeGroup?.name ?? 'Select Group',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.berryRose),
                ),
                onPressed: () => _selectGroup(context, groupProvider, expenseProvider),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StaggeredFadeSlide(
              index: 0,
              child: PulsingGlow(
                glowColor: isDark ? AppColors.berryRose.withAlpha(25) : AppColors.softBerryPink,
                minBlur: 8,
                maxBlur: 18,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.berryRose.withAlpha(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -15,
                        child: Opacity(
                          opacity: 0.12,
                          child: AnimatedBotanicalIllustration(
                            style: BotanicalStyle.minimalBloom,
                            width: 85,
                            height: 85,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.t('monthlyBudget'),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.onSurface),
                                ),
                              ),
                              BouncingTap(
                                scaleLower: 0.9,
                                onTap: () => _editBudget(context, budget),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : AppColors.deepBerry).withAlpha(15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: AppColors.berryRose, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              AnimatedNumberCounter(
                                value: totalSpent,
                                prefix: '₹',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.berryRose,
                                ),
                              ),
                              Text(
                                ' of ₹${budget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: budgetProgress,
                              minHeight: 12,
                              color: budgetProgress > 0.85 ? Colors.red : AppColors.berryRose,
                              backgroundColor: colors.surface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            budgetProgress > 0.85
                                ? 'You have used ${(budgetProgress * 100).toStringAsFixed(0)}% of this month’s budget.'
                                : 'You are on track with your spending this month.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: budgetProgress > 0.85 ? Colors.red : AppColors.sageGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.t('categoryBreakdown'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22)),
                    child: categories.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBotanicalIllustration(
                                  style: BotanicalStyle.heartLeaves,
                                  width: 64,
                                  height: 64,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No spending recorded this month',
                                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : PieChart(PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 42,
                            sections: categories.asMap().entries.map((entry) {
                              final category = entry.value;
                              return PieChartSectionData(
                                color: _chartColors[entry.key % _chartColors.length],
                                value: category.value,
                                title: category.key,
                                radius: 52,
                                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StaggeredFadeSlide(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.t('insights'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
                  const SizedBox(height: 12),
                  _insightCard(
                    context: context,
                    icon: Icons.trending_up_rounded,
                    title: t.t('predictedExpense'),
                    description: expenses.isEmpty
                        ? 'Tap to view spending prediction formula & forecast.'
                        : 'Based on your spending velocity, projected next month: ₹${formatAmountNumber(prediction)}.',
                    onTap: () => _showPredictionDetails(
                      context,
                      expenses,
                      thisMonth,
                      now,
                      totalSpent,
                      budget,
                      prediction,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _insightCard(
                    context: context,
                    icon: Icons.category_rounded,
                    title: t.t('topCategory'),
                    description: categories.isEmpty
                        ? 'Tap to explore category breakdown & transaction insights.'
                        : '${categories.first.key} is your #1 spending category at ₹${formatAmountNumber(categories.first.value)}.',
                    onTap: () => _showCategoryBreakdownDetails(
                      context,
                      expenses,
                      thisMonth,
                      totalSpent,
                      categories,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _selectGroup(
    BuildContext context,
    GroupProvider groupProvider,
    ExpenseProvider expenseProvider,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<GroupModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Select Group for Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const Divider(),
              ...groupProvider.groups.map((group) {
                final isSelected = group.id == groupProvider.activeGroup?.id;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.berryRose
                          : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: isSelected ? Colors.white : AppColors.berryRose,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${group.memberIds.length} members • ${group.currency}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.berryRose)
                      : null,
                  onTap: () => Navigator.pop(ctx, group),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await groupProvider.setActiveGroup(selected);
      expenseProvider.listenToGroupExpensesAndSettlements(
        selected.id,
        selected.memberIds,
        groupName: selected.name,
        currency: selected.currency,
      );
    }
  }

  void _showPredictionDetails(
    BuildContext context,
    List<ExpenseModel> allExpenses,
    List<ExpenseModel> thisMonthExpenses,
    DateTime now,
    double totalSpent,
    double budget,
    double prediction,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysElapsed = max(1, now.day);
    final daysRemaining = max(0, totalDaysInMonth - now.day);
    final dailyPace = totalSpent / daysElapsed;
    final remainingBudget = max(0.0, budget - totalSpent);
    final recommendedDailyAllowance =
        daysRemaining > 0 ? remainingBudget / daysRemaining : 0.0;
    final isOverBudget = budget > 0 && totalSpent > budget;
    final isProjectedOverBudget = budget > 0 && prediction > budget;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.berryRose, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Prediction & Forecast',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          'Predictive projection based on velocity',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (allExpenses.isEmpty && thisMonthExpenses.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.berryRose),
                      const SizedBox(height: 12),
                      Text(
                        'No expenses recorded yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Once you record expenses in your groups, SplitSync will calculate your daily velocity and forecast your next month’s expenses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.berryRose,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Metric cards grid
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        context: context,
                        label: 'Projected Next Month',
                        value: '₹${formatAmountNumber(prediction)}',
                        accentColor: AppColors.berryRose,
                        subtitle: 'Paced for $totalDaysInMonth days',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricTile(
                        context: context,
                        label: 'Spent This Month',
                        value: '₹${formatAmountNumber(totalSpent)}',
                        accentColor: AppColors.deepBerry,
                        subtitle: '$daysElapsed days elapsed',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        context: context,
                        label: 'Daily Burn Rate',
                        value: '₹${formatAmountNumber(dailyPace)}/day',
                        accentColor: AppColors.sageGreen,
                        subtitle: 'Average spending/day',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricTile(
                        context: context,
                        label: 'Days Remaining',
                        value: '$daysRemaining days',
                        accentColor: const Color(0xFFB85C7D),
                        subtitle: 'Remaining in month',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Budget comparison analysis
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSurface : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isProjectedOverBudget
                          ? Colors.red.withValues(alpha: 0.5)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isOverBudget
                                ? Icons.warning_amber_rounded
                                : (isProjectedOverBudget ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded),
                            color: (isOverBudget || isProjectedOverBudget) ? Colors.red : AppColors.sageGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOverBudget
                                ? 'Exceeded Monthly Budget'
                                : (isProjectedOverBudget ? 'Paced to Exceed Budget' : 'On Track with Budget'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: (isOverBudget || isProjectedOverBudget) ? Colors.red : AppColors.sageGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        budget <= 0
                            ? 'Set a monthly budget to see budget health alerts.'
                            : isOverBudget
                                ? 'You have spent ₹${formatAmountNumber(totalSpent)}, exceeding your ₹${formatAmountNumber(budget)} budget.'
                                : isProjectedOverBudget
                                    ? 'At your current burn rate of ₹${formatAmountNumber(dailyPace)}/day, you are projected to reach ₹${formatAmountNumber(prediction)}, exceeding your budget of ₹${formatAmountNumber(budget)}.'
                                    : 'At your current burn rate, you are expected to stay comfortably within your monthly budget of ₹${formatAmountNumber(budget)}.',
                        style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant, height: 1.4),
                      ),
                      if (budget > 0 && !isOverBudget && daysRemaining > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.sageGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.savings_outlined, size: 16, color: AppColors.sageGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Safe limit for next $daysRemaining days: ₹${formatAmountNumber(recommendedDailyAllowance)}/day',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sageGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editBudget(context, budget);
                        },
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Adjust Budget'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.berryRose,
                          side: const BorderSide(color: AppColors.berryRose),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.berryRose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryBreakdownDetails(
    BuildContext context,
    List<ExpenseModel> allExpenses,
    List<ExpenseModel> thisMonthExpenses,
    double totalSpent,
    List<MapEntry<String, double>> categories,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.category_rounded, color: AppColors.berryRose, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Spending Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        totalSpent > 0
                            ? 'Total ₹${formatAmountNumber(totalSpent)} across ${categories.length} categories'
                            : 'No expenses recorded this month',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 28),

            if (categories.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pie_chart_outline_rounded, size: 54, color: AppColors.berryRose),
                      const SizedBox(height: 12),
                      Text(
                        'No category spending recorded yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add expenses to see a categorized breakdown of where your money is spent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.berryRose,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catInfo = AppConstants.getCategory(cat.key);
                    final icon = catInfo['icon'] as IconData? ?? Icons.category_rounded;
                    final catColor = (catInfo['color'] as Color?) ?? AppColors.berryRose;
                    final percentage = totalSpent > 0 ? (cat.value / totalSpent) * 100 : 0.0;
                    final matchingExpenses =
                        thisMonthExpenses.where((e) => e.category == cat.key).toList();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardSurface : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: index == 0
                              ? AppColors.berryRose.withValues(alpha: 0.4)
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index == 0 ? AppColors.berryRose : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: index == 0 ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: catColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${matchingExpenses.length} ${matchingExpenses.length == 1 ? 'transaction' : 'transactions'}',
                                      style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${formatAmountNumber(cat.value)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: catColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (percentage / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              color: catColor,
                              backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required BuildContext context,
    required String label,
    required String value,
    required Color accentColor,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.5, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  double _predictNextMonth(List<ExpenseModel> expenses, DateTime now, double currentMonthSpent) {
    final nextMonthDays = DateTime(now.year, now.month + 2, 0).day;
    if (currentMonthSpent > 0) return currentMonthSpent / now.day * nextMonthDays;
    final monthlyTotals = <String, double>{};
    for (final expense in expenses) {
      final month = '${expense.createdAt.year}-${expense.createdAt.month}';
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + expense.amount;
    }
    if (monthlyTotals.isEmpty) return 0;
    return monthlyTotals.values.reduce((sum, amount) => sum + amount) / monthlyTotals.length;
  }

  Future<void> _editBudget(BuildContext context, double currentBudget) async {
    final newBudget = await showDialog<double>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _EditBudgetDialog(currentBudget: currentBudget),
    );

    if (newBudget != null && context.mounted) {
      await context.read<AuthProvider>().updateProfile(monthlyBudget: newBudget);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Monthly budget updated to ₹${formatAmountNumber(newBudget)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _insightCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BouncingTap(
      scaleLower: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.berryRose, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.berryRose,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBudgetDialog extends StatefulWidget {
  final double currentBudget;

  const _EditBudgetDialog({required this.currentBudget});

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initialText = widget.currentBudget > 0
        ? formatAmountNumber(widget.currentBudget)
        : '';
    _controller = TextEditingController(text: initialText);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: initialText.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSave() {
    final value = tryParseAmountNumber(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _errorText = 'Please enter an amount greater than 0';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.berryRose,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Set your monthly spending limit to stay on track.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.berryRose,
                  ),
                  hintText: 'e.g. 15,000',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                        .withValues(alpha: 0.6),
                  ),
                  errorText: _errorText,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkCardSurface
                      : AppColors.softBerryPink.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.berryRose, width: 2),
                  ),
                ),
                onSubmitted: (_) => _onSave(),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.berryRose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

