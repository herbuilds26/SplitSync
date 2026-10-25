import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/group_categories.dart';
import '../../l10n/app_strings.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/botanical_illustrations.dart';
import '../../widgets/lively_animations.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _copyInviteCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invite code $code copied to clipboard')),
    );
  }

  Future<void> _leaveGroup(BuildContext context, GroupModel group) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.userModel?.uid ?? auth.firebaseUser?.uid;
    if (uid == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Text(
          'Leave "${group.name}"?',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You will be removed from "${group.name}". Existing expenses will remain intact in the group.',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<GroupProvider>().leaveGroup(group.id, uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left "${group.name}" successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not leave group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;
    final t = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardSurface : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(t.t('yourGroups')),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.berryRose),
            tooltip: 'Join with QR / Code',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.berryRose,
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            final uid = auth.userModel?.uid ?? auth.firebaseUser?.uid;
            if (uid != null) {
              await groupProvider.refreshUserGroups(uid);
            }
          },
          child: groups.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  children: [
                    LivelyEmptyState(
                      illustrationStyle: BotanicalStyle.delicateBouquet,
                      illustrationSize: 110,
                      title: t.t('noGroups'),
                      subtitle: 'Create a group, then share the invite code or QR\nso friends can join from their phones.',
                      buttonLabel: t.t('createGroup'),
                      buttonIcon: Icons.add_rounded,
                      onButtonPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                      },
                      secondaryButtonLabel: 'Join with code or QR',
                      onSecondaryButtonPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
                      },
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final catInfo = GroupCategories.getCategory(group.category);

                    return StaggeredFadeSlide(
                      index: index,
                      child: BouncingTap(
                        scaleLower: 0.96,
                        onTap: () {
                          groupProvider.setActiveGroup(group);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 0 : 10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: catInfo.color.withAlpha(isDark ? 40 : 25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: catInfo.color.withAlpha(isDark ? 80 : 45),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(catInfo.icon, color: catInfo.color, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            group.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: catInfo.color.withAlpha(isDark ? 35 : 20),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            catInfo.name,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: catInfo.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${group.memberIds.length} members • ${group.currency} • Code: ${group.inviteCode}',
                                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: textSecondary),
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            tooltip: 'Manage Group',
                            onSelected: (value) {
                              if (value == 'open') {
                                groupProvider.setActiveGroup(group);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
                                );
                              } else if (value == 'copy') {
                                _copyInviteCode(context, group.inviteCode);
                              } else if (value == 'leave') {
                                _leaveGroup(context, group);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'open',
                                child: Row(
                                  children: [
                                    const Icon(Icons.visibility_rounded, size: 18, color: AppColors.berryRose),
                                    const SizedBox(width: 10),
                                    Text('View Details', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    const Icon(Icons.copy_rounded, size: 18, color: AppColors.sageGreen),
                                    const SizedBox(width: 10),
                                    Text('Copy Code (${group.inviteCode})', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'leave',
                                child: const Row(
                                  children: [
                                    Icon(Icons.exit_to_app_rounded, size: 18, color: Colors.redAccent),
                                    SizedBox(width: 10),
                                    Text('Leave Group', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
}
