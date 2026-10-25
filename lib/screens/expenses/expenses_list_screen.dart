import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/lively_animations.dart';
import '../../widgets/profile_avatar.dart';

class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  UserModel? _findPayer(String paidBy, GroupProvider groupProvider, AuthProvider authProvider) {
    if (paidBy == 'everyone') return null;
    final currentModel = authProvider.userModel;
    if (paidBy == currentModel?.uid) return currentModel;
    for (final m in groupProvider.activeGroupMembers) {
      if (m.uid == paidBy) return m;
    }
    return null;
  }

  String _payerLabel(String paidBy, GroupProvider groupProvider, AuthProvider authProvider) {
    if (paidBy == 'everyone') return 'Everyone';
    final currentUid = authProvider.userModel?.uid ?? authProvider.firebaseUser?.uid;
    if (paidBy == currentUid) {
      final name = authProvider.userModel?.name;
      return (name != null && name.isNotEmpty) ? name : 'You';
    }
    for (final m in groupProvider.activeGroupMembers) {
      if (m.uid == paidBy) {
        return m.name.isNotEmpty ? m.name : 'Member';
      }
    }
    return paidBy;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final t = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final filtered = expenseProvider.filteredExpenses;
    final isFiltering = expenseProvider.searchQuery.trim().isNotEmpty ||
        expenseProvider.selectedCategoryFilter != 'All';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(t.t('expenses')),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (val) => expenseProvider.setSearchQuery(val),
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search expenses by title or category...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.berryRose, size: 22),
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.berryRose, width: 2),
                  ),
                  suffixIcon: expenseProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: textSecondary, size: 20),
                          onPressed: () => expenseProvider.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),

            // Streamlined Category Filter Chips without awkward height or spacing
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _categoryChip(context, 'All', expenseProvider),
                    ...AppConstants.categories.map((c) => _categoryChip(context, c['name'], expenseProvider)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Expenses List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final activeGroup = groupProvider.activeGroup;
                  if (activeGroup != null) {
                    await Future.wait([
                      expenseProvider.refreshGroupExpenses(activeGroup.id),
                      expenseProvider.refreshSettlements(activeGroup.id),
                    ]);
                  }
                },
                color: AppColors.berryRose,
                child: filtered.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isFiltering) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.berryRose.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 40,
                                  color: AppColors.berryRose,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching expenses found',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                expenseProvider.searchQuery.trim().isNotEmpty
                                    ? 'No results for "${expenseProvider.searchQuery.trim()}". Try checking your spelling or search term.'
                                    : 'No expenses found under "${expenseProvider.selectedCategoryFilter}".',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () {
                                  expenseProvider.setSearchQuery('');
                                  expenseProvider.setCategoryFilter('All');
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Clear Search & Filter'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.berryRose,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              const LivelyEmptyState(
                                illustrationStyle: BotanicalStyle.minimalBloom,
                                illustrationSize: 100,
                                title: 'No expenses yet',
                                subtitle: 'Expenses added to this group will show up here.\nTap + to add your first expense!',
                              ),
                            ],
                          ],
                        ),
                      )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final exp = filtered[index];
                        final catInfo = AppConstants.getCategory(exp.category);

                        return StaggeredFadeSlide(
                          index: index,
                          child: BouncingTap(
                            scaleLower: 0.97,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: isDark ? Border.all(color: borderColor) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 0 : 8),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (catInfo['color'] as Color).withAlpha(isDark ? 55 : 38),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(catInfo['icon'] as IconData, color: catInfo['color'] as Color, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exp.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Builder(builder: (context) {
                                          final payer = _findPayer(exp.paidBy, groupProvider, authProvider);
                                          return Row(
                                            children: [
                                              Text(
                                                exp.category,
                                                style: TextStyle(fontSize: 12, color: textSecondary),
                                              ),
                                              Text(' • Paid by ', style: TextStyle(fontSize: 12, color: textSecondary)),
                                              if (payer != null) ...[
                                                ProfileAvatar(
                                                  avatarId: payer.avatarUrl,
                                                  name: payer.name,
                                                  radius: 8,
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  _payerLabel(exp.paidBy, groupProvider, authProvider),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${exp.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String label, ExpenseProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = provider.selectedCategoryFilter == label;
    final catInfo = label == 'All' ? null : AppConstants.getCategory(label);

    return BouncingTap(
      scaleLower: 0.92,
      onTap: () => provider.setCategoryFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.berryRose
              : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(120)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.berryRose
                : (isDark ? AppColors.darkBorder : AppColors.softBerryPink),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (catInfo != null) ...[
              Icon(
                catInfo['icon'] as IconData,
                size: 13,
                color: isSelected ? Colors.white : (isDark ? AppColors.mintGreen : AppColors.berryRose),
              ),
              const SizedBox(width: 5),
            ] else ...[
              Icon(
                Icons.grid_view_rounded,
                size: 13,
                color: isSelected ? Colors.white : (isDark ? AppColors.mintGreen : AppColors.berryRose),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
