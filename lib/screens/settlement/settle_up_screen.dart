import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/group_model.dart';
import '../../models/settlement_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/debt_calculator.dart';
import '../../services/upi_service.dart';
import '../../widgets/profile_avatar.dart';

class SettleUpScreen extends StatefulWidget {
  const SettleUpScreen({super.key});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final groupProvider = context.read<GroupProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      final activeGroup = groupProvider.activeGroup;
      if (activeGroup != null) {
        expenseProvider.refreshGroupExpenses(activeGroup.id);
        expenseProvider.refreshSettlements(activeGroup.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  UserModel _resolveMember(
    String uid,
    List<UserModel> members,
    UserModel? currentUser,
  ) {
    final currentUid = currentUser?.uid ?? '';
    return members.firstWhere(
      (m) => m.uid == uid,
      orElse: () => uid == currentUid && currentUser != null
          ? currentUser
          : UserModel(
              uid: uid,
              name: 'Member',
              email: '',
              createdAt: DateTime.now(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final debts = expenseProvider.simplifiedDebts;
    final settlements = expenseProvider.settlements;
    final activeGroup = groupProvider.activeGroup;
    final currentUser = authProvider.userModel;
    final currentUid = currentUser?.uid ?? authProvider.firebaseUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settle Up & Balances'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.berryRose,
          labelColor: AppColors.berryRose,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pending Debts'),
                  if (debts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.berryRose.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${debts.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.berryRose,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('History'),
                  if (settlements.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${settlements.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sageGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // ================= TAB 1: PENDING DEBTS =================
            _buildPendingDebtsTab(
              context: context,
              debts: debts,
              activeGroup: activeGroup,
              currentUser: currentUser,
              currentUid: currentUid,
              groupMembers: groupProvider.activeGroupMembers,
              expenseProvider: expenseProvider,
            ),

            // ================= TAB 2: SETTLEMENT HISTORY =================
            _buildSettlementHistoryTab(
              context: context,
              settlements: settlements,
              groupMembers: groupProvider.activeGroupMembers,
              currentUser: currentUser,
            ),
          ],
        ),
      ),
    );
  }

  // ================= PENDING DEBTS TAB =================
  Widget _buildPendingDebtsTab({
    required BuildContext context,
    required List<SettlementModel> debts,
    required GroupModel? activeGroup,
    required UserModel? currentUser,
    required String currentUid,
    required List<UserModel> groupMembers,
    required ExpenseProvider expenseProvider,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settlementsCount = expenseProvider.settlements.length;

    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.sageGreen),
              ),
              const SizedBox(height: 18),
              Text(
                'All Settled Up!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No outstanding debts in this group. You are all square 🌿',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
              ),
              if (settlementsCount > 0) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.history_rounded, color: AppColors.berryRose),
                  label: Text(
                    'View Settlement History ($settlementsCount)',
                    style: const TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: AppColors.berryRose),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: debts.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.berryRose.withAlpha(30)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.berryRose, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SplitSync debt minimization algorithm combines group balances into the fewest transactions.',
                    style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          );
        }

        final debt = debts[index - 1];
        final fromMember = _resolveMember(debt.fromUserId, groupMembers, currentUser);
        final toMember = _resolveMember(debt.toUserId, groupMembers, currentUser);

        final fromName = fromMember.name.isNotEmpty ? fromMember.name : 'Member';
        final toName = toMember.name.isNotEmpty ? toMember.name : 'Member';
        final isPayer = currentUid.isNotEmpty && fromMember.uid == currentUid;
        final isPayee = currentUid.isNotEmpty && toMember.uid == currentUid;

        Widget actionWidget;
        if (isPayer) {
          actionWidget = SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.berryRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
              label: Text(
                'Pay ${DebtCalculator.formatCurrency(debt.amount)} via UPI',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                if (currentUser != null && activeGroup != null) {
                  _handleUpiPayment(
                    context: context,
                    debt: debt,
                    fromMember: fromMember,
                    toMember: toMember,
                    currentUser: currentUser,
                    activeGroup: activeGroup,
                    expenseProvider: expenseProvider,
                  );
                }
              },
            ),
          );
        } else if (isPayee) {
          actionWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.berryRose.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: AppColors.berryRose, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Awaiting payment from $fromName',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.berryRose,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text('Show QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    _showReceiveQrModal(
                      context: context,
                      debt: debt,
                      fromMember: fromMember,
                      currentUser: currentUser ?? toMember,
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          actionWidget = Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardSurface : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.withAlpha(60)),
            ),
            child: Center(
              child: Text(
                'Pending payment from $fromName to $toName',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: isDark ? Border.all(color: AppColors.darkBorder) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    avatarId: fromMember.avatarUrl,
                    name: fromMember.name,
                    radius: 20,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.berryRose),
                  const SizedBox(width: 8),
                  ProfileAvatar(
                    avatarId: toMember.avatarUrl,
                    name: toMember.name,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$fromName owes $toName',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DebtCalculator.formatCurrency(debt.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              actionWidget,
            ],
          ),
        );
      },
    );
  }

  // ================= SETTLEMENT HISTORY TAB =================
  Widget _buildSettlementHistoryTab({
    required BuildContext context,
    required List<SettlementModel> settlements,
    required List<UserModel> groupMembers,
    required UserModel? currentUser,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (settlements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.softBerryPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.berryRose),
              ),
              const SizedBox(height: 18),
              Text(
                'No Settlements Recorded Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'When UPI payments are verified and completed, the permanent proof will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightTextSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = List<SettlementModel>.from(settlements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final settlement = sorted[index];
        final fromMember = _resolveMember(settlement.fromUserId, groupMembers, currentUser);
        final toMember = _resolveMember(settlement.toUserId, groupMembers, currentUser);
        final isCash = settlement.paymentMethod.toLowerCase() == 'cash';
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(settlement.createdAt);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: AppColors.darkBorder) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 8),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Payment Method Tag & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCash
                          ? AppColors.mintGreen.withAlpha(45)
                          : AppColors.berryRose.withAlpha(35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded,
                          size: 13,
                          color: isCash ? AppColors.sageGreen : AppColors.berryRose,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isCash ? 'Cash Payment' : 'UPI Payment',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isCash ? AppColors.sageGreen : AppColors.berryRose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Row: Avatars, Names, and Amount
              Row(
                children: [
                  ProfileAvatar(avatarId: fromMember.avatarUrl, name: fromMember.name, radius: 18),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.berryRose),
                  const SizedBox(width: 8),
                  ProfileAvatar(avatarId: toMember.avatarUrl, name: toMember.name, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fromMember.name} paid ${toMember.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (settlement.upiTransactionRef != null &&
                            settlement.upiTransactionRef!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ref: ${settlement.upiTransactionRef}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.lightTextSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    DebtCalculator.formatCurrency(settlement.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isDark ? const Color(0xFF6EE7B7) : AppColors.sageGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom status pill
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.sageGreen),
                  const SizedBox(width: 4),
                  const Text(
                    'Recorded & Balanced',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sageGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SHOW RECEIVE QR MODAL (FOR PAYEE) =================
  Future<void> _showReceiveQrModal({
    required BuildContext context,
    required SettlementModel debt,
    required UserModel fromMember,
    required UserModel currentUser,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upiId = currentUser.upiId.trim();

    if (upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your UPI ID in your Profile settings first so others can pay you directly.'),
        ),
      );
      return;
    }

    final uriString = UpiService.buildUpiUriString(
      upiId: upiId,
      payeeName: currentUser.name,
      amount: debt.amount,
      note: 'SplitSync settlement from ${fromMember.name}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Receive ${DebtCalculator.formatCurrency(debt.amount)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Payment from ${fromMember.name}',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: uriString,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.berryRose),
                    const SizedBox(width: 8),
                    Text(
                      'UPI: $upiId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: upiId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied to clipboard!')),
                        );
                      },
                      child: const Icon(Icons.copy_rounded, size: 15, color: AppColors.berryRose),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ask them to scan with Google Pay, PhonePe, Paytm, or BHIM',
                style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ================= HANDLE UPI PAYMENT =================
  Future<void> _handleUpiPayment({
    required BuildContext context,
    required SettlementModel debt,
    required UserModel fromMember,
    required UserModel toMember,
    required UserModel currentUser,
    required GroupModel activeGroup,
    required ExpenseProvider expenseProvider,
  }) async {
    String upiId = toMember.upiId.trim();

    // If payee has not added a UPI ID yet, prompt the payer to enter it
    if (upiId.isEmpty) {
      final enteredUpi = await _promptForUpiId(context, toMember);
      if (enteredUpi == null || enteredUpi.trim().isEmpty) return;
      upiId = enteredUpi.trim();
    }

    if (!context.mounted) return;

    await _showUpiPaymentSheet(
      context: context,
      debt: debt,
      fromMember: fromMember,
      toMember: toMember,
      upiId: upiId,
      currentUser: currentUser,
      activeGroup: activeGroup,
      expenseProvider: expenseProvider,
    );
  }

  // ================= PROMPT FOR UPI ID IF MISSING =================
  Future<String?> _promptForUpiId(BuildContext context, UserModel toMember) async {
    final upiController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: AppColors.berryRose),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter UPI ID for ${toMember.name}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${toMember.name} has not set a UPI ID yet. Enter their UPI ID to proceed with payment:',
              style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: upiController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'UPI ID / VPA',
                hintText: 'Enter UPI ID / VPA',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = upiController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(dialogCtx, val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.berryRose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue to Pay'),
          ),
        ],
      ),
    );
  }

  // ================= UPI PAYMENT MODAL (APP LAUNCH + QR CODE + CONFIRMATION) =================
  Future<void> _showUpiPaymentSheet({
    required BuildContext context,
    required SettlementModel debt,
    required UserModel fromMember,
    required UserModel toMember,
    required String upiId,
    required UserModel currentUser,
    required GroupModel activeGroup,
    required ExpenseProvider expenseProvider,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uriString = UpiService.buildUpiUriString(
      upiId: upiId,
      payeeName: toMember.name,
      amount: debt.amount,
      note: 'SplitSync to ${toMember.name}',
    );

    final utrController = TextEditingController();
    bool hasInitiatedPayment = false;
    bool isRecording = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.berryRose.withAlpha(35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.berryRose, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay ${toMember.name}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Amount: ${DebtCalculator.formatCurrency(debt.amount)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.berryRose,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // UPI ID Pill with Copy button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.berryRose.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.berryRose),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'UPI ID: $upiId',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.berryRose),
                            tooltip: 'Copy UPI ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: upiId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('UPI ID copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (!hasInitiatedPayment) ...[
                      // STEP 1: BEFORE PAYING - ONLY PAYMENT OPTIONS ARE AVAILABLE
                      // Live UPI QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: uriString,
                          version: QrVersions.auto,
                          size: 155,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Scan with Google Pay, PhonePe, Paytm, or BHIM',
                        style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Primary Action: Open UPI App to Pay
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                          label: Text(
                            'Pay ${DebtCalculator.formatCurrency(debt.amount)} in UPI App',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.berryRose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final launched = await UpiService.launchUpiPayment(
                              upiId: upiId,
                              payeeName: toMember.name,
                              amount: debt.amount,
                              note: 'SplitSync to ${toMember.name}',
                            );

                            setModalState(() {
                              hasInitiatedPayment = true;
                            });

                            if (!launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open UPI app directly. Please scan the QR code above or pay to $upiId in your banking app.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.berryRose),
                        label: const Text(
                          'Paid by scanning QR on another device?',
                          style: TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            hasInitiatedPayment = true;
                          });
                        },
                      ),
                    ] else ...[
                      // STEP 2: ONLY DISPLAYED AFTER USER HAS OPENED UPI APP OR SCANNED QR
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.mintGreen.withAlpha(30) : AppColors.mintGreen.withAlpha(50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.sageGreen.withAlpha(120), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.sageGreen, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Initiated',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.sageGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SplitSync launched your UPI payment for ${DebtCalculator.formatCurrency(debt.amount)}. Enter your 12-digit UPI Ref / UTR number from your payment receipt to complete settlement.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      TextField(
                        controller: utrController,
                        autofocus: true,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: 'UPI Reference / UTR Number',
                          hintText: 'e.g. 12-digit UTR from GPay / PhonePe / Paytm',
                          prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.sageGreen),
                          filled: true,
                          fillColor: isDark ? AppColors.darkCardSurface : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: isRecording
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: Text(
                            isRecording ? 'Verifying & Recording...' : 'Verify Transaction & Settle Up',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sageGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: isRecording
                              ? null
                              : () async {
                                  final utr = utrController.text.trim();
                                  if (utr.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter the UPI Reference / UTR number from your payment receipt to verify settlement.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setModalState(() => isRecording = true);

                                  await expenseProvider.recordSettlement(
                                    SettlementModel(
                                      id: '',
                                      groupId: activeGroup.id,
                                      fromUserId: debt.fromUserId,
                                      toUserId: debt.toUserId,
                                      amount: debt.amount,
                                      paymentMethod: 'UPI',
                                      upiTransactionRef: utr,
                                      createdAt: DateTime.now(),
                                    ),
                                    currentUser.name,
                                    userAvatarUrl: currentUser.avatarUrl,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(modalContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.deepBerry,
                                        content: Text(
                                          'UPI payment of ${DebtCalculator.formatCurrency(debt.amount)} verified & settled! View in Settlement History.',
                                        ),
                                      ),
                                    );
                                    _tabController.animateTo(1);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            hasInitiatedPayment = false;
                          });
                        },
                        child: const Text(
                          'Payment Cancelled or Failed • Go Back',
                          style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
