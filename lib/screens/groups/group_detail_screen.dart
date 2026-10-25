import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../config/group_categories.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../models/settlement_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/export_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/lively_animations.dart';
import '../../widgets/profile_avatar.dart';
import '../expenses/add_expense_screen.dart';
import '../settlement/settle_up_screen.dart';

enum _GroupExportFormat { pdf, excel, csv }

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<GroupModel?>? _groupDocSubscription;
  final Map<String, String> _memberAvatarCache = {};
  final Set<String> _fetchingUserAvatars = {};

  void _fetchUserAvatar(String userId) {
    if (userId.isEmpty || _fetchingUserAvatars.contains(userId) || _memberAvatarCache.containsKey(userId)) return;
    _fetchingUserAvatars.add(userId);
    FirestoreService.getUser(userId).then((user) {
      if (user != null && mounted) {
        if (user.avatarUrl.isNotEmpty) {
          setState(() {
            _memberAvatarCache[userId] = user.avatarUrl;
          });
        }
      }
    }).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final groupProvider = context.read<GroupProvider>();
      final authProvider = context.read<AuthProvider>();
      final currentUid = authProvider.userModel?.uid ?? authProvider.firebaseUser?.uid ?? '';
      groupProvider.onExpenseActivityDetected = _onExpenseActivityDetected;
      groupProvider.setActiveGroup(widget.group);
      final group = groupProvider.activeGroup?.id == widget.group.id
          ? groupProvider.activeGroup!
          : widget.group;
      context.read<ExpenseProvider>().listenToGroupExpensesAndSettlements(
        group.id,
        group.memberIds,
        groupName: group.name,
        currency: group.currency,
        currentUserId: currentUid,
      );
    });

    // Real-time listener directly on this group's document
    _groupDocSubscription = FirestoreService.streamGroup(widget.group.id).listen((updated) {
      if (updated != null && mounted) {
        final groupProvider = context.read<GroupProvider>();
        final authProvider = context.read<AuthProvider>();
        final currentUid = authProvider.userModel?.uid ?? authProvider.firebaseUser?.uid ?? '';
        groupProvider.setActiveGroup(updated);
        context.read<ExpenseProvider>().listenToGroupExpensesAndSettlements(
          updated.id,
          updated.memberIds,
          groupName: updated.name,
          currency: updated.currency,
          currentUserId: currentUid,
        );
        setState(() {});
      }
    });
  }

  void _onExpenseActivityDetected() {
    if (!mounted) return;
    final live = _liveGroup(context.read<GroupProvider>());
    context.read<ExpenseProvider>().refreshGroupExpenses(live.id);
    context.read<ExpenseProvider>().refreshSettlements(live.id);
  }

  Future<void> _refreshAll() async {
    final groupProvider = context.read<GroupProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    final live = _liveGroup(groupProvider);
    await Future.wait([
      groupProvider.refreshActiveGroupMembers(),
      expenseProvider.refreshGroupExpenses(live.id),
      expenseProvider.refreshSettlements(live.id),
    ]);
  }

  @override
  void dispose() {
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.onExpenseActivityDetected == _onExpenseActivityDetected) {
      groupProvider.onExpenseActivityDetected = null;
    }
    _groupDocSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  GroupModel _liveGroup(GroupProvider groupProvider) {
    final active = groupProvider.activeGroup;
    if (active != null && active.id == widget.group.id) {
      final fromList = groupProvider.groups.where((g) => g.id == widget.group.id).firstOrNull;
      if (fromList != null && fromList.memberIds.length > active.memberIds.length) {
        return fromList;
      }
      return active;
    }
    final fromList = groupProvider.groups.where((g) => g.id == widget.group.id).firstOrNull;
    if (fromList != null) return fromList;
    return widget.group;
  }

  Future<void> _copyInvite(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code $code copied')),
    );
  }

  Future<void> _shareInvite(GroupModel group) async {
    final inviteMessage = 'Hey! Join my "${group.name}" group on SplitSync to split and track expenses together.\n\n'
        '👉 Group Code: ${group.inviteCode}\n\n'
        'How to join:\n'
        '1. Open SplitSync\n'
        '2. Tap "Your Groups" → Tap the QR / Join icon\n'
        '3. Enter code ${group.inviteCode} (or scan the QR code)\n\n'
        'Direct Link:\n'
        'https://splitsync.web.app/join?code=${group.inviteCode}\n\n'
        'App Link: splitsync://group/${group.inviteCode}';

    await Share.share(
      inviteMessage.trim(),
      subject: 'Join "${group.name}" on SplitSync',
    );
  }

  UserModel? _findPayer(String paidBy, GroupProvider groupProvider) {
    if (paidBy == 'everyone') return null;
    final auth = context.read<AuthProvider>();
    final currentModel = auth.userModel;
    if (paidBy == currentModel?.uid) return currentModel;
    for (final m in groupProvider.activeGroupMembers) {
      if (m.uid == paidBy) return m;
    }
    return null;
  }

  String _payerLabel(String paidBy, GroupProvider groupProvider) {
    if (paidBy == 'everyone') return 'Everyone';
    final auth = context.read<AuthProvider>();
    final currentUid = auth.userModel?.uid ?? auth.firebaseUser?.uid;
    if (paidBy == currentUid) {
      final name = auth.userModel?.name;
      return (name != null && name.isNotEmpty) ? '$name (You)' : 'You';
    }
    for (final m in groupProvider.activeGroupMembers) {
      if (m.uid == paidBy) {
        return m.name.isNotEmpty ? m.name : 'Member';
      }
    }
    return paidBy;
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" from this group? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final userName = (auth.userModel?.name != null && auth.userModel!.name.trim().isNotEmpty)
        ? auth.userModel!.name.trim()
        : (auth.firebaseUser?.displayName ?? 'Member');
    try {
      await context.read<ExpenseProvider>().deleteExpense(
        expense,
        userName,
        userAvatarUrl: auth.userModel?.avatarUrl ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete expense: $e')),
      );
    }
  }

  Future<void> _exportGroupExpenses(GroupModel group) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final format = await showModalBottomSheet<_GroupExportFormat>(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export ${group.name}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 6),
              Text('Export expenses, summary, balances, and settlements for this group.', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.berryRose.withAlpha(30), shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.berryRose),
                ),
                title: Text('PDF report', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('Printable report with summary and settlements', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _GroupExportFormat.pdf),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? AppColors.mintGreen.withAlpha(40) : AppColors.mintLight, shape: BoxShape.circle),
                  child: Icon(Icons.table_chart_rounded, color: isDark ? AppColors.mintGreen : AppColors.sageGreen),
                ),
                title: Text('Excel spreadsheet (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('Comprehensive workbook: Summary, Expenses, Balances, Settlements', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _GroupExportFormat.excel),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink, shape: BoxShape.circle),
                  child: Icon(Icons.grid_on_rounded, color: isDark ? AppColors.berryRose : AppColors.deepBerry),
                ),
                title: Text('CSV file', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('Raw tabular export for spreadsheets and data tools', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _GroupExportFormat.csv),
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing your group export…')));

      final expenseProvider = context.read<ExpenseProvider>();
      final groupProvider = context.read<GroupProvider>();

      var expenses = List<ExpenseModel>.from(expenseProvider.expenses);
      if (expenses.isEmpty) {
        expenses = await FirestoreService.getGroupExpenses(group.id);
        if (expenses.isEmpty) {
          expenses = await FirestoreService.streamGroupExpenses(group.id).first.timeout(
            const Duration(seconds: 4),
            onTimeout: () => <ExpenseModel>[],
          );
        }
      }

      var settlements = List<SettlementModel>.from(expenseProvider.settlements);
      if (settlements.isEmpty) {
        settlements = await FirestoreService.getGroupSettlements(group.id);
      }

      final memberMap = <String, String>{};
      for (final m in groupProvider.activeGroupMembers) {
        if (m.name.isNotEmpty) {
          memberMap[m.uid] = m.name;
        }
      }

      switch (format) {
        case _GroupExportFormat.pdf:
          await ExportService.exportToPdf(
            group: group,
            expenses: expenses,
            settlements: settlements,
            memberNames: memberMap,
          );
          break;
        case _GroupExportFormat.excel:
          await ExportService.exportToExcel(
            group: group,
            expenses: expenses,
            settlements: settlements,
            memberNames: memberMap,
          );
          break;
        case _GroupExportFormat.csv:
          await ExportService.exportToCsv(
            group: group,
            expenses: expenses,
            memberNames: memberMap,
          );
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the export. Please try again.')),
        );
      }
    }
  }

  Future<void> _leaveGroup(GroupModel group) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.userModel?.uid ?? auth.firebaseUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: Text('You will be removed from "${group.name}". Existing expenses stay in the group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<GroupProvider>().leaveGroup(group.id, uid);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not leave group: $e')),
      );
    }
  }

  void _showQrCodeModal(BuildContext context, GroupModel group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                group.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Invite Code: ${group.inviteCode}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.berryRose),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: group.qrCodeData.isNotEmpty ? group.qrCodeData : 'splitsync://group/${group.inviteCode}',
                  version: QrVersions.auto,
                  size: 180.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.deepBerry,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.deepBerry,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Friends scan this QR or enter the code to join. New expenses split across everyone in the group.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      onPressed: () => _copyInvite(group.inviteCode),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy code'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.berryRose,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _shareInvite(group),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
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

  void _showMembersModal(BuildContext context, GroupModel group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final groupProvider = context.read<GroupProvider>();
    final auth = context.read<AuthProvider>();
    final currentUid = auth.userModel?.uid ?? auth.firebaseUser?.uid ?? '';
    final members = groupProvider.activeGroupMembers;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Group Members (${group.memberIds.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showQrCodeModal(context, group);
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.berryRose),
                    label: const Text('Invite', style: TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Loading members...', style: TextStyle(color: textSecondary)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: members.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rawM = members[index];
                      final isCurrentUser = rawM.uid == currentUid;
                      final m = (isCurrentUser && auth.userModel != null) ? auth.userModel! : rawM;
                      final isCreator = m.uid == group.createdBy;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ProfileAvatar(
                          avatarId: m.avatarUrl,
                          name: m.name,
                          radius: 21,
                        ),
                        title: Row(
                          children: [
                            Text(
                              isCurrentUser ? '${m.name.isNotEmpty ? m.name : 'You'} (You)' : m.name,
                              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            if (isCreator) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.berryRose.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.berryRose),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: m.email.isNotEmpty ? Text(m.email, style: TextStyle(fontSize: 12, color: textSecondary)) : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = _liveGroup(groupProvider);

    final expenses = expenseProvider.expenses;
    final activityLogs = groupProvider.activityLogs;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.berryRose),
            tooltip: 'Refresh',
            onPressed: () async {
              await _refreshAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group and expenses refreshed'), duration: Duration(milliseconds: 900)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: AppColors.berryRose),
            tooltip: 'Invite',
            onPressed: () => _showQrCodeModal(context, group),
          ),
          PopupMenuButton<String>(
            iconColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
            color: isDark ? AppColors.darkSurface : Colors.white,
            onSelected: (value) {
              if (value == 'invite') _showQrCodeModal(context, group);
              if (value == 'export') _exportGroupExpenses(group);
              if (value == 'category') _showEditCategoryModal(context, group);
              if (value == 'leave') _leaveGroup(group);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.berryRose),
                    const SizedBox(width: 10),
                    Text('Invite members', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_download_outlined, size: 20, color: AppColors.berryRose),
                    const SizedBox(width: 10),
                    Text('Export group (Excel, PDF, CSV)', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(Icons.category_rounded, size: 20, color: textSecondary),
                    const SizedBox(width: 10),
                    Text('Edit category & features', style: TextStyle(color: textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'leave',
                child: const Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, size: 20, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Leave group', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: BouncingTap(
        scaleLower: 0.92,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group)));
        },
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.berryRose,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(group: group)));
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats Card matching Home Screen Botanical Style
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(minHeight: 130),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                borderRadius: BorderRadius.circular(26),
                border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.berryRose.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    // Living Botanical Minimal Bloom with gentle breeze sway
                    Positioned(
                      right: 6,
                      bottom: -10,
                      child: Opacity(
                        opacity: isDark ? 0.8 : 0.95,
                        child: const AnimatedBotanicalIllustration(
                          style: BotanicalStyle.minimalBloom,
                          width: 135,
                          height: 140,
                          maxSwayAngle: 0.04,
                          duration: Duration(milliseconds: 3200),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category Badge (Trip, Home, Couple, or Custom Other)
                                BouncingTap(
                                  scaleLower: 0.92,
                                  onTap: () => _showEditCategoryModal(context, group),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: GroupCategories.getCategory(group.category).color.withAlpha(isDark ? 50 : 25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: GroupCategories.getCategory(group.category).color.withAlpha(isDark ? 90 : 60),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          GroupCategories.getCategory(group.category).icon,
                                          size: 13,
                                          color: GroupCategories.getCategory(group.category).color,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          GroupCategories.getCategory(group.category).name,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.deepBerry,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 11,
                                          color: (isDark ? Colors.white : AppColors.deepBerry).withAlpha(140),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                InkWell(
                                  onTap: () => _showMembersModal(context, group),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.group_rounded,
                                          size: 16,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Group Members (${group.memberIds.length})',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Group Code with distinct mint/sage color badge & tap-to-copy
                                InkWell(
                                  onTap: () => _copyInvite(group.inviteCode),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.mintGreen.withAlpha(40)
                                          : AppColors.mintGreen.withAlpha(65),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.mintGreen.withAlpha(120)
                                            : AppColors.sageGreen.withAlpha(150),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.vpn_key_rounded,
                                          size: 14,
                                          color: isDark ? AppColors.mintGreen : AppColors.sageGreen,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Code: ${group.inviteCode}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: isDark ? AppColors.mintGreen : AppColors.sageGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          Icons.copy_rounded,
                                          size: 12,
                                          color: isDark
                                              ? AppColors.mintGreen.withAlpha(200)
                                              : AppColors.sageGreen.withAlpha(200),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          BouncingTap(
                            scaleLower: 0.93,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettleUpScreen()));
                            },
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.berryRose : AppColors.deepBerry,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: isDark ? 0 : 2,
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettleUpScreen()));
                              },
                              child: const Text(
                                'Settle Up',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Category Presets / Shortcuts Bar (Trip, Home, Couple, Other)
            Builder(
              builder: (context) {
                final catInfo = GroupCategories.getCategory(group.category);
                if (catInfo.quickTemplates.isEmpty) return const SizedBox.shrink();

                return Container(
                  height: 36,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: catInfo.quickTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final template = catInfo.quickTemplates[index];
                      return BouncingTap(
                        scaleLower: 0.92,
                        child: ActionChip(
                          avatar: Icon(template.icon, size: 14, color: catInfo.color),
                          label: Text(template.title),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                          ),
                          backgroundColor: isDark ? AppColors.darkCardSurface : Colors.white,
                          side: BorderSide(
                            color: catInfo.color.withAlpha(isDark ? 80 : 40),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(
                                  group: group,
                                  initialTitle: template.title,
                                  initialCategory: template.category,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.berryRose,
              unselectedLabelColor: textSecondary,
              indicatorColor: AppColors.berryRose,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Activity Log'),
              ],
            ),

            // Tab Bar Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Expenses List
                  RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: AppColors.berryRose,
                    child: expenses.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Text('No expenses recorded in this group yet.', style: TextStyle(color: textSecondary)),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: expenses.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final exp = expenses[index];
                              final catInfo = AppConstants.getCategory(exp.category);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
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
                                          Text(exp.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                                          const SizedBox(height: 2),
                                          Builder(builder: (context) {
                                            final payer = _findPayer(exp.paidBy, groupProvider);
                                            return Row(
                                              children: [
                                                Text('Paid by ', style: TextStyle(fontSize: 12, color: textSecondary)),
                                                if (payer != null) ...[
                                                  ProfileAvatar(avatarId: payer.avatarUrl, name: payer.name, radius: 8),
                                                  const SizedBox(width: 4),
                                                ],
                                                Flexible(
                                                  child: Text(
                                                    _payerLabel(exp.paidBy, groupProvider),
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
                                      '${group.currency} ${exp.amount.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                      tooltip: 'Delete expense',
                                      onPressed: () => _deleteExpense(exp),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Activity Log List
                  RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: AppColors.berryRose,
                    child: activityLogs.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Text('No recent activity', style: TextStyle(color: textSecondary)),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: activityLogs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final log = activityLogs[index];
                              final members = groupProvider.activeGroupMembers;
                              final auth = context.read<AuthProvider>();
                              final currentUid = auth.userModel?.uid ?? auth.firebaseUser?.uid;
                              final isCurrentUser = log.userId.isNotEmpty && log.userId == currentUid;

                              UserModel? actor;
                              if (isCurrentUser && auth.userModel != null) {
                                actor = auth.userModel;
                              } else {
                                for (final m in members) {
                                  if (m.uid == log.userId) {
                                    actor = m;
                                    break;
                                  }
                                }
                              }
                              if (actor == null && isCurrentUser) {
                                actor = auth.userModel;
                              }

                              String effectiveAvatarId = '';
                              if (isCurrentUser && auth.userModel != null && auth.userModel!.avatarUrl.isNotEmpty) {
                                effectiveAvatarId = auth.userModel!.avatarUrl;
                              }
                              if (effectiveAvatarId.isEmpty && actor != null && actor.avatarUrl.isNotEmpty) {
                                effectiveAvatarId = actor.avatarUrl;
                              }
                              if (effectiveAvatarId.isEmpty && log.userAvatarUrl.isNotEmpty) {
                                effectiveAvatarId = log.userAvatarUrl;
                              }
                              if (effectiveAvatarId.isEmpty && _memberAvatarCache.containsKey(log.userId)) {
                                effectiveAvatarId = _memberAvatarCache[log.userId]!;
                              }
                              if (effectiveAvatarId.isEmpty && log.userId.isNotEmpty) {
                                _fetchUserAvatar(log.userId);
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                                ),
                                child: ListTile(
                                  leading: ProfileAvatar(
                                    avatarId: effectiveAvatarId,
                                    name: log.userName.isNotEmpty ? log.userName : (actor?.name ?? 'User'),
                                    radius: 20,
                                  ),
                                  title: Text(log.details, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                                  subtitle: Text('${log.userName} • ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(color: textSecondary)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryModal(BuildContext context, GroupModel group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final initialCat = group.category;
    String selectedCat = (initialCat == 'Trip' || initialCat == 'Home' || initialCat == 'Couple')
        ? initialCat
        : 'Other';
    final customController = TextEditingController(
      text: (selectedCat == 'Other' && initialCat != 'Other') ? initialCat : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final catInfo = GroupCategories.getCategory(selectedCat);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Category & Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a category to customize group features and expense presets',
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // 4 category choices
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: GroupCategories.all.map((c) {
                      final isSelected = selectedCat == c.id;
                      return InkWell(
                        onTap: () => setModalState(() => selectedCat = c.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? c.color.withAlpha(isDark ? 50 : 30) : cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? c.color : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark ? Colors.white : AppColors.deepBerry)
                                        : textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: c.color, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (selectedCat == 'Other') ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: customController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Custom Category Name',
                        hintText: 'e.g. Festival, Project, Badminton Club',
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.berryRose),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: GroupCategories.customCategorySuggestions.map((s) {
                        return ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setModalState(() {
                              customController.text = s;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Features Included: ${catInfo.featureHighlights.join(' • ')}',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.berryRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final custom = customController.text.trim();
                        final effective = (selectedCat == 'Other' && custom.isNotEmpty)
                            ? custom
                            : selectedCat;

                        Navigator.pop(sheetContext);
                        final groupProvider = context.read<GroupProvider>();
                        await groupProvider.updateGroupCategory(group, effective);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Category updated to "$effective"')),
                          );
                        }
                      },
                      child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
