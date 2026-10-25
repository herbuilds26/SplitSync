import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../l10n/app_strings.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/debt_calculator.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/lively_animations.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/scan_bill_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../groups/create_group_screen.dart';
import '../groups/group_detail_screen.dart';
import '../groups/groups_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _motivationalQuotes = [
    'Share the bill and keep the peace so the laughter never cease 🌿',
    'Good meals, honest shares and friendships built on care 🍃',
    'Clear bills and warm smiles keep friendships going miles 🌸',
    'Eat together, split with ease, memories made under sunny breeze ☀️',
    'Good friends, great times and settled dimes 🌱',
  ];

  int _quoteIndex = 0;
  bool _isAllGroupsMode = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastIndex = prefs.getInt('splitsync_quote_index') ?? 0;
      final nextIndex = (lastIndex + 1) % _motivationalQuotes.length;
      await prefs.setInt('splitsync_quote_index', nextIndex);
      if (mounted) {
        setState(() {
          _quoteIndex = lastIndex;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quoteIndex = DateTime.now().day % _motivationalQuotes.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final rawName = (authProvider.userModel?.name != null && authProvider.userModel!.name.trim().isNotEmpty)
        ? authProvider.userModel!.name.trim()
        : ((authProvider.firebaseUser?.displayName != null && authProvider.firebaseUser!.displayName!.trim().isNotEmpty)
            ? authProvider.firebaseUser!.displayName!.trim()
            : (authProvider.firebaseUser?.email != null && authProvider.firebaseUser!.email!.contains('@')
                ? authProvider.firebaseUser!.email!.split('@').first
                : ''));
    final userName = rawName.isNotEmpty ? rawName : 'Friend';
    final activeGroup = groupProvider.activeGroup;
    final currentUserId = authProvider.userModel?.uid ?? '';

    // Listen to active group expenses and sync multi-group balances
    if (activeGroup != null && groupProvider.groups.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        expenseProvider.listenToGroupExpensesAndSettlements(
          activeGroup.id,
          activeGroup.memberIds,
          groupName: activeGroup.name,
          currency: activeGroup.currency,
          currentUserId: currentUserId,
        );
        if (currentUserId.isNotEmpty) {
          expenseProvider.fetchAllGroupBalances(
            groups: groupProvider.groups,
            currentUserId: currentUserId,
          );
        }
      });
    } else if (expenseProvider.isListeningToGroup) {
      // A group may have been left or deleted. Clear the previous group's
      // subscription so its expenses cannot remain in Recent Expenses.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        expenseProvider.stopListening();
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.berryRose,
          onRefresh: () async {
            final groupProv = context.read<GroupProvider>();
            final expProv = context.read<ExpenseProvider>();
            final authProv = context.read<AuthProvider>();
            final uid = authProv.userModel?.uid ?? '';
            await groupProv.refreshUserGroups(uid);
            if (groupProv.activeGroup != null) {
              await Future.wait([
                groupProv.refreshActiveGroupMembers(),
                expProv.refreshGroupExpenses(groupProv.activeGroup!.id),
                expProv.refreshSettlements(groupProv.activeGroup!.id),
              ]);
            }
            if (uid.isNotEmpty) {
              await expProv.fetchAllGroupBalances(
                groups: groupProv.groups,
                currentUserId: uid,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP BERRY HEADER =================
              _buildTopBerryHeader(context, userName),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ================= TOTAL BALANCE CARD WITH MINT LEAF =================
                    _buildTotalBalanceCard(
                      context,
                      expenseProvider,
                      groupProvider,
                      currentUserId,
                      activeGroup: activeGroup,
                    ),

                    const SizedBox(height: 24),

                    // ================= QUICK ACTIONS =================
                    _buildQuickActions(context),

                    const SizedBox(height: 28),

                    // ================= RECENT EXPENSES =================
                    _buildRecentExpensesSection(context, expenseProvider),

                    const SizedBox(height: 28),

                    // ================= YOUR GROUPS =================
                    _buildYourGroupsSection(context, groupProvider),

                    const SizedBox(height: 24),

                    // ================= MOTIVATIONAL PILL =================
                    _buildMotivationalQuote(context),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  // ================= TOP BERRY HEADER =================
  Widget _buildTopBerryHeader(BuildContext context, String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final String greetingTime;
    final IconData greetingIcon;
    final Color greetingIconColor;

    if (hour >= 5 && hour < 12) {
      greetingTime = 'Good morning';
      greetingIcon = Icons.wb_sunny_rounded;
      greetingIconColor = const Color(0xFFFFD54F);
    } else if (hour >= 12 && hour < 17) {
      greetingTime = 'Good afternoon';
      greetingIcon = Icons.wb_cloudy_rounded;
      greetingIconColor = const Color(0xFFFFB74D);
    } else if (hour >= 17 && hour < 21) {
      greetingTime = 'Good evening';
      greetingIcon = Icons.nights_stay_rounded;
      greetingIconColor = const Color(0xFFF48FB1);
    } else {
      greetingTime = 'Good night';
      greetingIcon = Icons.bedtime_rounded;
      greetingIconColor = const Color(0xFF81D4FA);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 54, 22, 30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.deepBerry,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Living animated bouquet with gentle sway in the breeze
          const Positioned(
            right: -6,
            bottom: -8,
            child: AnimatedBotanicalIllustration(
              style: BotanicalStyle.delicateBouquet,
              width: 145,
              height: 155,
              maxSwayAngle: 0.045,
              duration: Duration(milliseconds: 3400),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'SplitSync',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingItem(
                    distance: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(45), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(greetingIcon, size: 12, color: greetingIconColor),
                          const SizedBox(width: 4),
                          Text(
                            greetingTime,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Hi, $userName! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Good to see you back!',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TOTAL BALANCE CARD WITH MINT LEAF =================
  Widget _buildTotalBalanceCard(
    BuildContext context,
    ExpenseProvider expenseProvider,
    GroupProvider groupProvider,
    String currentUserId, {
    GroupModel? activeGroup,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppStrings.of(context);
    final double myBalance;
    if (_isAllGroupsMode) {
      myBalance = expenseProvider.overallNetBalance;
    } else {
      double bal = 0.0;
      for (final entry in expenseProvider.netBalances) {
        if (entry.userId == currentUserId) {
          bal = entry.amount;
          break;
        }
      }
      if (bal == 0.0 && activeGroup != null) {
        bal = expenseProvider.groupUserBalances[activeGroup.id] ?? 0.0;
      }
      myBalance = bal;
    }

    final hasBalanceToSend = myBalance < -0.01;
    final hasBalanceToReceive = myBalance > 0.01;
    final isSettled = !hasBalanceToSend && !hasBalanceToReceive;
    final absBalance = myBalance.abs();

    // Determine colors and borders based on state
    final Color cardBg;
    final Color borderColor;
    final Color accentColor;
    final Color iconBg;
    final IconData statusIcon;
    final String statusHeader;
    final String statusPillText;
    final IconData pillIcon;
    final String statusDescription;

    if (hasBalanceToSend) {
      accentColor = AppColors.berryRose;
      cardBg = isDark ? AppColors.darkCardSurface : AppColors.softBerryPink;
      borderColor = AppColors.berryRose.withAlpha(isDark ? 80 : 60);
      iconBg = AppColors.berryRose.withAlpha(isDark ? 50 : 35);
      statusIcon = Icons.arrow_upward_rounded;
      statusHeader = _isAllGroupsMode ? 'TOTAL TO SEND' : t.t('youHaveToSend').toUpperCase();
      statusPillText = _isAllGroupsMode
          ? 'You need to send ${DebtCalculator.formatCurrency(absBalance)} in total'
          : 'You need to send ${DebtCalculator.formatCurrency(absBalance)}';
      pillIcon = Icons.call_made_rounded;
      statusDescription = _isAllGroupsMode
          ? 'Combined amount you owe across all groups • Tap for breakdown'
          : (activeGroup != null
              ? 'Total amount you owe in ${activeGroup.name} • Tap for breakdown'
              : 'Total amount you owe • Tap for breakdown');
    } else if (hasBalanceToReceive) {
      accentColor = AppColors.sageGreen;
      cardBg = isDark ? AppColors.darkCardSurface : const Color(0xFFF0FDF4);
      borderColor = AppColors.sageGreen.withAlpha(isDark ? 80 : 70);
      iconBg = AppColors.mintGreen.withAlpha(isDark ? 50 : 60);
      statusIcon = Icons.arrow_downward_rounded;
      statusHeader = _isAllGroupsMode ? 'TOTAL TO RECEIVE' : t.t('youHaveToReceive').toUpperCase();
      statusPillText = _isAllGroupsMode
          ? 'You have to receive ${DebtCalculator.formatCurrency(absBalance)} in total'
          : 'You have to receive ${DebtCalculator.formatCurrency(absBalance)}';
      pillIcon = Icons.call_received_rounded;
      statusDescription = _isAllGroupsMode
          ? 'Combined amount owed to you across all groups • Tap for breakdown'
          : (activeGroup != null
              ? 'Total amount you are owed in ${activeGroup.name} • Tap for breakdown'
              : 'Total amount group members owe you • Tap for breakdown');
    } else {
      accentColor = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
      cardBg = isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(160);
      borderColor = isDark ? AppColors.darkBorder : AppColors.berryRose.withAlpha(30);
      iconBg = AppColors.mintGreen.withAlpha(isDark ? 50 : 60);
      statusIcon = Icons.check_circle_rounded;
      statusHeader = _isAllGroupsMode ? 'ALL GROUPS SETTLED' : t.t('totalBalance').toUpperCase();
      statusPillText = _isAllGroupsMode ? 'All groups settled up' : t.t('allSettledUp');
      pillIcon = Icons.eco_rounded;
      statusDescription = _isAllGroupsMode
          ? 'No outstanding balances across any groups • Tap for summary'
          : '${t.t('noBalanceToSendOrReceive')} • Tap for summary';
    }

    final glowColor = hasBalanceToSend
        ? AppColors.berryRose
        : (hasBalanceToReceive ? AppColors.mintGreen : AppColors.berryRose);

    return PulsingGlow(
      glowColor: glowColor,
      minBlur: 8,
      maxBlur: 20,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 165),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => _showTotalBalanceSummarySheet(
              context,
              expenseProvider,
              groupProvider,
              currentUserId,
            ),
            child: Stack(
              children: [
                // Living Botanical Heart Leaves with gentle breeze sway
                Positioned(
                  right: 4,
                  bottom: -4,
                  child: Opacity(
                    opacity: isDark ? 0.70 : 0.92,
                    child: const AnimatedBotanicalIllustration(
                      style: BotanicalStyle.heartLeaves,
                      width: 140,
                      height: 145,
                      maxSwayAngle: 0.035,
                      duration: Duration(milliseconds: 3600),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Header Row with Group Selection Option
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusIcon,
                              size: 15,
                              color: (hasBalanceToSend || hasBalanceToReceive)
                                  ? accentColor
                                  : AppColors.sageGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusHeader,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                              color: (hasBalanceToSend || hasBalanceToReceive)
                                  ? accentColor
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                          const Spacer(),
                          // Group Switcher Chip with Tactile Bounce
                          BouncingTap(
                            scaleLower: 0.90,
                            onTap: () => _showGroupSelectionSheet(
                              context,
                              expenseProvider,
                              groupProvider,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : AppColors.deepBerry).withAlpha(isDark ? 24 : 14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? Colors.white : AppColors.deepBerry).withAlpha(isDark ? 40 : 25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAllGroupsMode ? Icons.all_inclusive_rounded : Icons.groups_rounded,
                                    size: 13,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                                  ),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 100),
                                    child: Text(
                                      _isAllGroupsMode
                                          ? 'All Groups'
                                          : (activeGroup != null ? activeGroup.name : 'Select Group'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.deepBerry.withAlpha(180),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Animated Amount Display
                      AnimatedNumberCounter(
                        value: isSettled ? 0.0 : absBalance,
                        prefix: '₹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: (hasBalanceToSend || hasBalanceToReceive)
                              ? (isDark
                                  ? (hasBalanceToSend ? const Color(0xFFF48FB1) : const Color(0xFF6EE7B7))
                                  : accentColor)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.deepBerry),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: hasBalanceToSend
                              ? AppColors.berryRose.withAlpha(35)
                              : AppColors.mintGreen.withAlpha(isDark ? 55 : 65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasBalanceToSend
                                ? AppColors.berryRose.withAlpha(60)
                                : AppColors.sageGreen.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pillIcon,
                              size: 13,
                              color: hasBalanceToSend ? AppColors.berryRose : AppColors.sageGreen,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                statusPillText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hasBalanceToSend ? AppColors.berryRose : AppColors.sageGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Explanatory Subtitle
                      Text(
                        statusDescription,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= GROUP SELECTION SHEET =================
  void _showGroupSelectionSheet(
    BuildContext context,
    ExpenseProvider expenseProvider,
    GroupProvider groupProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = groupProvider.groups;
    final activeGroup = groupProvider.activeGroup;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Text(
                      'Select Balance Card View',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Option 1: All Groups (Combined Total)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _isAllGroupsMode
                                ? (isDark ? AppColors.berryRose : AppColors.deepBerry)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        tileColor: _isAllGroupsMode
                            ? (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(20)
                            : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(50)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.all_inclusive_rounded,
                            color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                          ),
                        ),
                        title: Text(
                          'All Groups (Combined Total)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Net balance: ${expenseProvider.overallNetBalance >= 0 ? '+' : '-'}${DebtCalculator.formatCurrency(expenseProvider.overallNetBalance.abs())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        trailing: _isAllGroupsMode
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                              )
                            : null,
                        onTap: () {
                          setState(() => _isAllGroupsMode = true);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Or Select a Group',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Options: Individual Groups
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No groups found',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...groups.map((group) {
                        final isSelected = !_isAllGroupsMode && activeGroup?.id == group.id;
                        final bal = expenseProvider.groupUserBalances[group.id] ?? 0.0;
                        final balText = bal > 0.01
                            ? '+${DebtCalculator.formatCurrency(bal)}'
                            : (bal < -0.01 ? '-${DebtCalculator.formatCurrency(bal.abs())}' : 'Settled');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? AppColors.berryRose : AppColors.deepBerry)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            tileColor: isSelected
                                ? (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(20)
                                : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(50)),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.sageGreen.withAlpha(isDark ? 40 : 25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              group.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Balance: $balText',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                                  )
                                : null,
                            onTap: () {
                              groupProvider.setActiveGroup(group);
                              setState(() => _isAllGroupsMode = false);
                              Navigator.pop(sheetContext);
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TOTAL BALANCE SUMMARY SHEET =================
  void _showTotalBalanceSummarySheet(
    BuildContext context,
    ExpenseProvider expenseProvider,
    GroupProvider groupProvider,
    String currentUserId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = groupProvider.groups;
    final activeGroup = groupProvider.activeGroup;

    // Refresh multi-group balances if needed
    if (groups.isNotEmpty && currentUserId.isNotEmpty) {
      expenseProvider.fetchAllGroupBalances(
        groups: groups,
        currentUserId: currentUserId,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final toReceive = expenseProvider.totalBalanceToReceive;
            final toSend = expenseProvider.totalBalanceToSend;
            final netTotal = expenseProvider.overallNetBalance;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.84,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 35),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Group Balances Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Amounts to be paid or received from every group',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Summary Metrics 3-Column Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(120),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.berryRose.withAlpha(25),
                            ),
                          ),
                          child: Row(
                            children: [
                              // To Receive
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_downward_rounded, size: 13, color: AppColors.sageGreen),
                                        const SizedBox(width: 4),
                                        Text(
                                          'To Receive',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.sageGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+${DebtCalculator.formatCurrency(toReceive)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF6EE7B7) : AppColors.sageGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: (isDark ? Colors.white : Colors.black).withAlpha(20),
                              ),
                              // To Send
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.berryRose),
                                          const SizedBox(width: 4),
                                          Text(
                                            'To Send',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.berryRose,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '-${DebtCalculator.formatCurrency(toSend)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFF48FB1) : AppColors.berryRose,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: (isDark ? Colors.white : Colors.black).withAlpha(20),
                              ),
                              // Net Total
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Net Total',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        netTotal.abs() < 0.01
                                            ? '₹0.00'
                                            : '${netTotal >= 0 ? '+' : '-'}${DebtCalculator.formatCurrency(netTotal.abs())}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: netTotal > 0.01
                                              ? (isDark ? const Color(0xFF6EE7B7) : AppColors.sageGreen)
                                              : (netTotal < -0.01
                                                  ? (isDark ? const Color(0xFFF48FB1) : AppColors.berryRose)
                                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Card Display Preference Selector (All Groups vs Single Group)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardSurface : AppColors.berryBlush,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.berryRose.withAlpha(30),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _isAllGroupsMode = true);
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _isAllGroupsMode
                                          ? (isDark ? AppColors.deepBerry : AppColors.deepBerry)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: _isAllGroupsMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(25),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Show All Groups (Total)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isAllGroupsMode
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _isAllGroupsMode = false);
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_isAllGroupsMode
                                          ? (isDark ? AppColors.deepBerry : AppColors.deepBerry)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !_isAllGroupsMode
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(25),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Show Selected Group',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: !_isAllGroupsMode
                                              ? Colors.white
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Title: Every Group Present
                        Row(
                          children: [
                            Text(
                              'Every Group (${groups.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (expenseProvider.isLoadingGroupBalances)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (groups.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            alignment: Alignment.center,
                            child: Text(
                              'No groups found. Create or join a group to see balances here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          )
                        else
                          ...groups.map((group) {
                            final bal = expenseProvider.groupUserBalances[group.id] ?? 0.0;
                            final hasReceive = bal > 0.01;
                            final hasSend = bal < -0.01;
                            final isGroupActive = activeGroup?.id == group.id;

                            final Color balColor = hasReceive
                                ? (isDark ? const Color(0xFF6EE7B7) : AppColors.sageGreen)
                                : (hasSend
                                    ? (isDark ? const Color(0xFFF48FB1) : AppColors.berryRose)
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));

                            final String balText = hasReceive
                                ? '+${DebtCalculator.formatCurrency(bal)}'
                                : (hasSend
                                    ? '-${DebtCalculator.formatCurrency(bal.abs())}'
                                    : '₹0.00');

                            final String badgeLabel = hasReceive
                                ? 'To receive'
                                : (hasSend ? 'To send' : 'Settled up');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSurface : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isGroupActive
                                      ? (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(120)
                                      : (isDark ? AppColors.darkBorder : AppColors.softBerryPink),
                                  width: isGroupActive ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (hasReceive
                                            ? AppColors.mintGreen
                                            : (hasSend ? AppColors.berryRose : AppColors.deepBerry))
                                        .withAlpha(isDark ? 40 : 25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      hasReceive
                                          ? Icons.arrow_downward_rounded
                                          : (hasSend ? Icons.arrow_upward_rounded : Icons.check_circle_rounded),
                                      color: balColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isGroupActive)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isDark ? AppColors.berryRose : AppColors.deepBerry).withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${group.memberIds.length} members • ${group.category}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      balText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: balColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (hasReceive
                                                ? AppColors.mintGreen
                                                : (hasSend ? AppColors.berryRose : AppColors.sageGreen))
                                            .withAlpha(isDark ? 35 : 25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badgeLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: balColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  groupProvider.setActiveGroup(group);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                                  );
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= QUICK ACTIONS =================
  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            context: context,
            icon: Icons.add_rounded,
            label: t.t('addExpense'),
            bgColor: AppColors.berryRose,
            iconColor: Colors.white,
            onTap: () {
              _selectGroupAndOpenExpense(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionButton(
            context: context,
            icon: Icons.group_add_rounded,
            label: t.t('createGroup'),
            bgColor: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
            iconColor: isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickActionButton(
            context: context,
            icon: Icons.receipt_long_rounded,
            label: t.t('scanBill'),
            bgColor: isDark ? AppColors.darkCardSurface : Colors.white,
            iconColor: isDark ? const Color(0xFF6EE7B7) : AppColors.berryRose,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanBillScreen()));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectGroupAndOpenExpense(BuildContext context) async {
    final groupProvider = context.read<GroupProvider>();
    final groups = groupProvider.groups;

    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a group before adding an expense.')),
      );
      return;
    }

    final selectedGroup = await showModalBottomSheet<GroupModel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add expense to which group?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the group that this expense belongs to.',
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 12),
              ...groups.map(
                (group) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softBerryPink,
                    child: Icon(Icons.groups_rounded, color: AppColors.berryRose),
                  ),
                  title: Text(group.name),
                  subtitle: Text('${group.memberIds.length} members'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, group),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedGroup == null || !context.mounted) return;
    await groupProvider.setActiveGroup(selectedGroup);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(group: selectedGroup)),
    );
  }

  Widget _quickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BouncingTap(
      scaleLower: 0.92,
      onTap: onTap,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: AppColors.darkBorder, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 9),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor == Colors.white
                    ? Colors.white.withAlpha(51)
                    : (isDark ? iconColor.withAlpha(38) : Colors.white.withAlpha(180)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : (iconColor == Colors.white ? Colors.white : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RECENT EXPENSES SECTION =================
  Widget _buildRecentExpensesSection(BuildContext context, ExpenseProvider expenseProvider) {
    final recent = expenseProvider.expenses.take(4).toList();
    final colors = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.t('recentExpenses'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(t.t('seeAll'), style: const TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
            ),
            child: LivelyEmptyState(
              illustrationStyle: BotanicalStyle.minimalBloom,
              illustrationSize: 85,
              title: t.t('noRecentExpenses'),
              subtitle: 'Add an expense to start tracking splits seamlessly',
              buttonLabel: t.t('addExpense'),
              buttonIcon: Icons.add_rounded,
              onButtonPressed: () => _selectGroupAndOpenExpense(context),
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final exp = recent[index];
              final catInfo = AppConstants.getCategory(exp.category);

              return StaggeredFadeSlide(
                index: index,
                child: BouncingTap(
                  scaleLower: 0.97,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: AppColors.darkBorder, width: 0.8) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (catInfo['color'] as Color).withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(catInfo['icon'] as IconData, color: catInfo['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.onSurface)),
                              const SizedBox(height: 2),
                              Text(exp.category, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${exp.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(t.t('today'), style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ================= YOUR GROUPS SECTION =================
  Widget _buildYourGroupsSection(BuildContext context, GroupProvider groupProvider) {
    final groups = groupProvider.groups;
    final colors = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.t('yourGroups'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen()));
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(t.t('seeAll'), style: const TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (groups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: isDark ? Border.all(color: AppColors.darkBorder) : null,
            ),
            child: LivelyEmptyState(
              illustrationStyle: BotanicalStyle.heartLeaves,
              illustrationSize: 85,
              title: t.t('noGroups'),
              subtitle: 'Create your first group to share expenses with friends & family',
              buttonLabel: t.t('createGroup'),
              buttonIcon: Icons.group_add_rounded,
              onButtonPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              },
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = groups[index];

              return StaggeredFadeSlide(
                index: index,
                child: BouncingTap(
                  scaleLower: 0.97,
                  onTap: () {
                    groupProvider.setActiveGroup(group);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark ? Border.all(color: AppColors.darkBorder, width: 0.8) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.softBerryPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: AppColors.berryRose, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.onSurface)),
                              const SizedBox(height: 2),
                              Text('${group.memberIds.length} members', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const GroupIllustration(size: 38),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ================= MOTIVATIONAL QUOTE =================
  Widget _buildMotivationalQuote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = _motivationalQuotes[_quoteIndex % _motivationalQuotes.length];

    return BouncingTap(
      scaleLower: 0.97,
      onTap: () {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _motivationalQuotes.length;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(160),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.berryRose.withAlpha(40),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.berryRose.withAlpha(isDark ? 15 : 10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            const FloatingItem(
              distance: 3,
              child: Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.berryRose),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                quote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                  letterSpacing: 0.2,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
