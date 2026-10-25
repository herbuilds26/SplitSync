import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_colors.dart';
import '../../l10n/app_strings.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/export_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/profile_avatar.dart';
import '../settlement/settle_up_screen.dart';

enum _ExportFormat { pdf, excel, csv }

class _UserStatusOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _UserStatusOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<_UserStatusOption> _statusOptions = [
  _UserStatusOption(
    id: 'Active',
    label: 'Active',
    subtitle: 'Online & ready to split expenses',
    icon: Icons.spa_rounded,
    color: AppColors.mintGreen,
  ),
  _UserStatusOption(
    id: 'Busy',
    label: 'Busy',
    subtitle: 'In a meeting or occupied',
    icon: Icons.do_not_disturb_on_rounded,
    color: AppColors.berryRose,
  ),
  _UserStatusOption(
    id: 'Away',
    label: 'Away',
    subtitle: 'Stepped away from phone',
    icon: Icons.access_time_filled_rounded,
    color: Color(0xFFFFA000),
  ),
  _UserStatusOption(
    id: 'On Trip',
    label: 'On Trip',
    subtitle: 'Traveling & splitting holiday bills',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF00ACC1),
  ),
  _UserStatusOption(
    id: 'Not Available',
    label: 'Not Available',
    subtitle: 'Currently unavailable or offline',
    icon: Icons.nightlight_round,
    color: Color(0xFF9E9E9E),
  ),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _upiController = TextEditingController();
  bool _notificationsEnabled = true;
  String _userStatus = 'Active';

  _UserStatusOption get _currentStatusInfo =>
      _statusOptions.firstWhere(
        (o) => o.id == _userStatus || (o.id == 'Not Available' && _userStatus == 'Offline'),
        orElse: () => _UserStatusOption(
          id: _userStatus,
          label: _userStatus,
          subtitle: 'Custom status',
          icon: Icons.edit_note_rounded,
          color: AppColors.berryRose,
        ),
      );

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _upiController.text = auth.userModel?.upiId ?? '';
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();
    final savedStatus = prefs.getString('splitsync_user_status') ?? 'Active';
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _userStatus = savedStatus;
      });
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (groupProvider.groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create or join a group before exporting expenses.')),
      );
      return;
    }

    final group = await showModalBottomSheet<GroupModel>(
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
              Text('Choose a group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
              const SizedBox(height: 6),
              Text('Export the expenses belonging to this group.', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 12),
              ...groupProvider.groups.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.softBerryPink,
                      child: Icon(Icons.groups_rounded, color: AppColors.berryRose),
                    ),
                    title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    subtitle: Text('${item.memberIds.length} members', style: TextStyle(color: textSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.berryRose),
                    onTap: () => Navigator.pop(sheetContext, item),
                  )),
            ],
          ),
        ),
      ),
    );
    if (group == null || !context.mounted) return;

    final format = await showModalBottomSheet<_ExportFormat>(
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
              Text('Choose a file format.', style: TextStyle(color: textSecondary)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.berryRose.withAlpha(30), shape: BoxShape.circle),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.berryRose),
                ),
                title: Text('PDF report', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('A printable expense report', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _ExportFormat.pdf),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? AppColors.mintGreen.withAlpha(40) : AppColors.mintLight, shape: BoxShape.circle),
                  child: Icon(Icons.table_chart_rounded, color: isDark ? AppColors.mintGreen : AppColors.sageGreen),
                ),
                title: Text('Excel spreadsheet (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('For editing totals and analysis', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _ExportFormat.excel),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink, shape: BoxShape.circle),
                  child: Icon(Icons.grid_on_rounded, color: isDark ? AppColors.berryRose : AppColors.deepBerry),
                ),
                title: Text('CSV file', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                subtitle: Text('For spreadsheets and data import', style: TextStyle(color: textSecondary)),
                onTap: () => Navigator.pop(sheetContext, _ExportFormat.csv),
              ),
            ],
          ),
        ),
      ),
    );
    if (format == null || !context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing your export…')));
      var expenses = await FirestoreService.getGroupExpenses(group.id);
      if (expenses.isEmpty) {
        expenses = await FirestoreService.streamGroupExpenses(group.id).first.timeout(
          const Duration(seconds: 4),
          onTimeout: () => <ExpenseModel>[],
        );
      }
      final settlements = await FirestoreService.getGroupSettlements(group.id);

      final memberMap = <String, String>{};
      for (final m in groupProvider.activeGroupMembers) {
        if (m.name.isNotEmpty) {
          memberMap[m.uid] = m.name;
        }
      }

      switch (format) {
        case _ExportFormat.pdf:
          await ExportService.exportToPdf(
            group: group,
            expenses: expenses,
            settlements: settlements,
            memberNames: memberMap,
          );
          break;
        case _ExportFormat.excel:
          await ExportService.exportToExcel(
            group: group,
            expenses: expenses,
            settlements: settlements,
            memberNames: memberMap,
          );
          break;
        case _ExportFormat.csv:
          await ExportService.exportToCsv(
            group: group,
            expenses: expenses,
            memberNames: memberMap,
          );
          break;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not create the export. Please try again.')));
      }
    }
  }

  Future<void> _confirmDeleteAccount(AuthProvider authProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
            SizedBox(width: 10),
            Text(
              'Delete Account?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your SplitSync account? This will permanently remove all your profile data and sign you out. This action cannot be undone.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting your account...'),
          duration: Duration(seconds: 2),
        ),
      );
      final success = await authProvider.deleteAccount();
      if (!success && mounted) {
        final err = authProvider.errorMessage ?? 'Could not delete account. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  Future<void> _showStatusPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isPredefined = _statusOptions.any((opt) => opt.id == _userStatus);
    final initialCustomText = isPredefined ? '' : _userStatus;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final customController = TextEditingController(text: initialCustomText);

        return SafeArea(
          child: AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.berryRose.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sentiment_satisfied_alt_rounded, color: AppColors.berryRose, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Your Status',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.deepBerry,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Let group members know your availability',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ..._statusOptions.map((opt) {
                    final isCurrent = _userStatus == opt.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(120))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? AppColors.berryRose : (isDark ? AppColors.darkBorder.withAlpha(50) : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: opt.color.withAlpha(35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(opt.icon, color: opt.color, size: 20),
                        ),
                        title: Text(
                          opt.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          opt.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.berryRose, size: 22)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, opt.id),
                      ),
                    );
                  }),
                  // Editable "Other (Custom)" Status Option
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !isPredefined
                          ? (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(120))
                          : (isDark ? AppColors.darkBackground.withAlpha(80) : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isPredefined ? AppColors.berryRose : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.berryRose.withAlpha(35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: AppColors.berryRose, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Other (Custom Status)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Type your own custom status or activity',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (!isPredefined)
                              const Icon(Icons.check_circle_rounded, color: AppColors.berryRose, size: 22),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customController,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Working from home, In gym...',
                                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  filled: true,
                                  fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.berryRose, width: 1.5),
                                  ),
                                ),
                                onSubmitted: (val) {
                                  final trimmed = val.trim();
                                  if (trimmed.isNotEmpty) {
                                    Navigator.pop(sheetContext, trimmed);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.berryRose,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: () {
                                final text = customController.text.trim();
                                if (text.isNotEmpty) {
                                  Navigator.pop(sheetContext, text);
                                }
                              },
                              child: const Text('Set', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _userStatus = selected);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitsync_user_status', selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $selected'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveUpiId(AuthProvider authProvider) async {
    final upiId = _upiController.text.trim();
    if (upiId.isNotEmpty && !upiId.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID (must contain @)')),
      );
      return;
    }
    await authProvider.updateProfile(upiId: upiId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID saved. Group members can now pay you through Settle Up.')),
      );
    }
  }

  Future<void> _chooseAvatar(AuthProvider authProvider) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.softBerryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.palette_rounded, color: AppColors.berryRose, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Avatar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.deepBerry,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SplitSync Berry & Mint collection',
                          style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profileAvatarOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final option = profileAvatarOptions[index];
                    final selected = resolveAvatarId(authProvider.userModel?.avatarUrl ?? '') == option.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(sheetContext, option.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.softBerryPink.withAlpha(isDark ? 60 : 160)
                              : (isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.berryRose : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ProfileAvatar(
                                  avatarId: option.id,
                                  name: authProvider.userModel?.name ?? '',
                                  radius: 24,
                                ),
                                if (selected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.berryRose,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                                color: selected
                                    ? AppColors.berryRose
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (avatarId != null && mounted) {
      await authProvider.updateProfile(avatarUrl: avatarId);
      if (mounted) {
        if (authProvider.userModel != null) {
          context.read<GroupProvider>().syncCurrentUser(authProvider.userModel!);
        }
        unawaited(context.read<GroupProvider>().refreshActiveGroupMembers());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully!')),
        );
      }
    }
  }

  Future<void> _editNameDialog(AuthProvider authProvider, String currentName) async {
    final controller = TextEditingController(text: currentName == 'SplitSync User' ? '' : currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.berryRose),
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.pop(dialogContext, trimmed);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      await authProvider.updateProfile(name: newName);
      if (mounted) {
        context.read<GroupProvider>().refreshActiveGroupMembers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      }
    }
  }

  // ================= TOP BERRY PROFILE HEADER =================
  Widget _buildTopProfileHeader(
    BuildContext context,
    AuthProvider authProvider,
    dynamic user,
    dynamic t,
    bool isDark,
  ) {
    final userName = (user?.name?.isNotEmpty == true) ? user.name : 'SplitSync User';
    final userEmail = (user?.email?.isNotEmpty == true) ? user.email : 'user@splitsync.app';

    return Container(
      width: double.infinity,
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
          // Botanical Moonlit Florals (Option 5 matching reference)
          const Positioned(
            right: -6,
            bottom: -8,
            child: MoonlitFloralsIllustration(width: 145, height: 150),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 28),
            child: Column(
              children: [
                // Top Title & Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t.t('profileSettings'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showStatusPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_currentStatusInfo.icon, color: _currentStatusInfo.color, size: 15),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                _currentStatusInfo.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Interactive Avatar with colorful Berry ring
                GestureDetector(
                  onTap: () => _chooseAvatar(authProvider),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(35),
                          border: Border.all(color: Colors.white.withAlpha(70), width: 2.5),
                        ),
                        child: ProfileAvatar(
                          avatarId: user?.avatarUrl ?? '',
                          name: userName,
                          radius: 46,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.berryRose,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name & Email
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _editNameDialog(authProvider, userName),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final topHeaderColor = isDark ? AppColors.darkSurface : AppColors.deepBerry;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final t = AppStrings.of(context);

    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Seamless top backdrop matching header so no blank screen can ever appear when pulling
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(color: topHeaderColor),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ================= TOP BERRY PROFILE HEADER =================
                  _buildTopProfileHeader(context, authProvider, user, t, isDark),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ================= GROUPS OVERVIEW CARD =================
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                        borderRadius: BorderRadius.circular(24),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.berryRose.withAlpha(15),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded, color: AppColors.berryRose, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${groupProvider.groups.length} ${groupProvider.groups.length == 1 ? "Active Group" : "Active Groups"}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Synced with your profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (groupProvider.activeGroup != null)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.berryRose : AppColors.deepBerry,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettleUpScreen()));
                              },
                              child: const Text('Settle Up', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= PAYMENT & UPI CARD =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : Border.all(color: AppColors.lightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 0 : 8),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'Payment & Settle Up',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.berryRose,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // UPI ID Field
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.account_balance_wallet_rounded, color: isDark ? AppColors.berryRose : AppColors.deepBerry, size: 22),
                            ),
                            title: Text(t.t('upiId'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            subtitle: TextField(
                              controller: _upiController,
                              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: 'Enter UPI ID / VPA',
                                hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                isDense: true,
                                border: const UnderlineInputBorder(),
                              ),
                              onSubmitted: (_) => _saveUpiId(authProvider),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.berryRose,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _saveUpiId(authProvider),
                              child: const Text('Save', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const Divider(height: 20),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.mintGreen.withAlpha(40) : AppColors.mintLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.payments_rounded, color: isDark ? AppColors.mintGreen : AppColors.sageGreen, size: 22),
                            ),
                            title: Text(t.t('settlePayments'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            subtitle: Text('Pay group members via UPI directly', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.berryRose),
                            onTap: () {
                              if (groupProvider.activeGroup == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Select a group before settling payments.')),
                                );
                                return;
                              }
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettleUpScreen()));
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= PREFERENCES CARD =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: isDark ? Border.all(color: AppColors.darkBorder) : Border.all(color: AppColors.lightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 0 : 8),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'App Preferences',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.berryRose,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Dark Mode Toggle
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.dark_mode_rounded, color: AppColors.berryRose, size: 22),
                            ),
                            title: Text(t.t('darkMode'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            value: themeProvider.isDarkMode,
                            activeThumbColor: AppColors.berryRose,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                          ),

                          const Divider(height: 20),

                          // Language Selector
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.language_rounded, color: AppColors.berryRose, size: 22),
                            ),
                            title: Text(t.t('language'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: DropdownButton<String>(
                                value: ['en', 'hi', 'kn'].contains(localeProvider.locale.languageCode)
                                    ? localeProvider.locale.languageCode
                                    : 'en',
                                underline: const SizedBox(),
                                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                                items: [
                                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))),
                                  DropdownMenuItem(value: 'hi', child: Text('हिंदी', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))),
                                  DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))),
                                ],
                                onChanged: (code) {
                                  if (code != null) localeProvider.setLocale(Locale(code));
                                },
                              ),
                            ),
                          ),

                          const Divider(height: 20),

                          // Export Expenses Data
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.mintGreen.withAlpha(40) : AppColors.mintLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.file_download_rounded, color: isDark ? AppColors.mintGreen : AppColors.sageGreen, size: 22),
                            ),
                            title: Text(t.t('exportExpenses'), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            subtitle: Text('Export to PDF, Excel, or CSV', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.berryRose),
                            onTap: () => _showExportDialog(context),
                          ),

                          const Divider(height: 20),

                          // Push Notifications Toggle
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.berryRose.withAlpha(40) : AppColors.softBerryPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: AppColors.berryRose, size: 22),
                            ),
                            title: Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            subtitle: Text('Group activity & budget reminders', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                            value: _notificationsEnabled,
                            activeThumbColor: AppColors.berryRose,
                            onChanged: (val) async {
                              await NotificationService.setNotificationsEnabled(val);
                              setState(() => _notificationsEnabled = val);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(val ? 'Push notifications enabled 🔔' : 'Push notifications paused 🔕'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= SIGN OUT BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC4334C),
                          side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: Text(
                          t.t('signOut'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () async {
                          await authProvider.signOut();
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ================= DELETE ACCOUNT BUTTON =================
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onPressed: () => _confirmDeleteAccount(authProvider),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}
