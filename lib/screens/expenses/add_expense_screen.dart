import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../config/group_categories.dart';
import '../../models/expense_model.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/ai_receipt_scanner.dart';
import '../../services/voice_input_service.dart';
import '../../utils/currency_input_formatter.dart';
import '../../widgets/lively_animations.dart';
import '../../widgets/profile_avatar.dart';

class AddExpenseScreen extends StatefulWidget {
  final GroupModel? group;
  final bool autoOpenOcr;
  final double? initialAmount;
  final String? initialTitle;
  final String? initialCategory;

  const AddExpenseScreen({
    super.key,
    this.group,
    this.autoOpenOcr = false,
    this.initialAmount,
    this.initialTitle,
    this.initialCategory,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  final FocusNode _customCategoryFocusNode = FocusNode();

  String _selectedCategory = 'Food';
  String _splitMethod = 'equal'; // equal, exact, percentage, custom
  String _paidBy = ''; // uid of payer, or 'everyone' when the whole group paid
  File? _receiptImage;

  final VoiceInputService _voiceService = VoiceInputService();
  bool _isListeningVoice = false;
  bool _isProcessingOcr = false;
  String _voiceTranscript = '';
  bool _voiceReviewShown = false;
  Set<String> _splitMemberIds = {};

  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, TextEditingController> _percentageControllers = {};
  final Map<String, TextEditingController> _customShareControllers = {};
  final Map<String, double> _customShares = {};

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = formatAmountNumber(widget.initialAmount!);
    }
    if (widget.initialTitle?.isNotEmpty == true) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialCategory?.isNotEmpty == true) {
      final exists = AppConstants.categories.any(
        (c) => (c['name'] as String).toLowerCase() == widget.initialCategory!.toLowerCase(),
      );
      if (exists) {
        _selectedCategory = widget.initialCategory!;
      } else {
        _selectedCategory = 'Other';
        _customCategoryController.text = widget.initialCategory!;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final groupProvider = context.read<GroupProvider>();
      if (widget.group != null && groupProvider.activeGroup?.id != widget.group!.id) {
        groupProvider.setActiveGroup(widget.group!);
      } else {
        groupProvider.refreshActiveGroupMembers();
      }
      if (widget.autoOpenOcr) {
        _pickAndScanReceipt();
      }
    });
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _customCategoryController.dispose();
    _customCategoryFocusNode.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    for (final c in _customShareControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndScanReceipt() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Bill / Receipt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Capture or select any printed or handwritten bill',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.berryRose.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.berryRose, size: 22),
                ),
                title: Text('Take photo with camera', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sageGreen.withAlpha(isDark ? 50 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.sageGreen, size: 22),
                ),
                title: Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
        _isProcessingOcr = true;
      });

      final result = await AiReceiptScanner.scanReceipt(_receiptImage!);

      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
          if (result.amount > 0) {
            _amountController.text = formatAmountNumber(result.amount);
          }
          if (result.title.isNotEmpty) {
            _titleController.text = result.title;
          }
          if (result.category.isNotEmpty) {
            final exists = AppConstants.categories.any(
              (c) => (c['name'] as String).toLowerCase() == result.category.toLowerCase(),
            );
            if (exists) {
              _selectedCategory = result.category;
            } else {
              _selectedCategory = 'Other';
              _customCategoryController.text = result.category;
            }
          }
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (result.amount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scanned bill! Total: ₹${result.amount.toStringAsFixed(2)}'),
              backgroundColor: AppColors.deepBerry,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not auto-detect total. Please verify or enter manually.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleVoiceListening() async {
    if (_isListeningVoice) {
      await _voiceService.stop();
      setState(() => _isListeningVoice = false);
    } else {
      setState(() {
        _isListeningVoice = true;
        _voiceTranscript = '';
        _voiceReviewShown = false;
      });
      await _voiceService.listen(
        onResult: (text) {
          if (!mounted) return;
          setState(() => _voiceTranscript = text);
        },
        onListeningComplete: () {
          if (mounted) {
            setState(() => _isListeningVoice = false);
            if (_voiceTranscript.trim().isNotEmpty && !_voiceReviewShown) {
              _voiceReviewShown = true;
              _showVoiceExpenseReview(_voiceTranscript);
            }
          }
        },
        onError: (message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
      );
    }
  }

  Future<void> _showVoiceExpenseReview(String transcript) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userModel;
    final rawMembers = groupProvider.activeGroupMembers;
    final members = rawMembers.map((m) {
      if (currentUser != null && m.uid == currentUser.uid) {
        return currentUser;
      }
      return m;
    }).toList();
    if (currentUser != null && !members.any((m) => m.uid == currentUser.uid)) {
      members.insert(0, currentUser);
    }
    final parsed = VoiceInputService.parseSpokenText(
      transcript,
      knownMemberNames: members.map((member) => member.name),
    );
    final amountController = TextEditingController(
      text: parsed.amount > 0 ? formatAmountNumber(parsed.amount) : '',
    );
    final descriptionController = TextEditingController(text: parsed.title);
    String selectedPayer = _memberIdForName(parsed.payerName, members) ?? currentUser?.uid ?? '';
    String selectedSplitMethod = parsed.splitMethod;
    final isCategoryPredefined = AppConstants.categories.any(
      (c) => (c['name'] as String).toLowerCase() == parsed.category.toLowerCase(),
    );
    String selectedCategory = isCategoryPredefined ? parsed.category : 'Other';
    final customCategoryController = TextEditingController(
      text: isCategoryPredefined ? '' : parsed.category,
    );
    final parsedMemberIds = members
        .where((member) => parsed.memberNames.any((name) => name.toLowerCase() == member.name.toLowerCase()))
        .map((member) => member.uid)
        .toSet();
    Set<String> selectedMembers = parsedMemberIds.isEmpty
        ? members.map((member) => member.uid).toSet()
        : parsedMemberIds;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Review Voice Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Heard: $transcript', style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedPayer.isEmpty ? null : selectedPayer,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: [
                    const DropdownMenuItem(
                      value: 'everyone',
                      child: Row(
                        children: [
                          Icon(Icons.groups_rounded, size: 18, color: AppColors.berryRose),
                          SizedBox(width: 8),
                          Text('Everyone'),
                        ],
                      ),
                    ),
                    ...members.map((member) => DropdownMenuItem(
                          value: member.uid,
                          child: Row(
                            children: [
                              ProfileAvatar(avatarId: member.avatarUrl, name: member.name, radius: 11),
                              const SizedBox(width: 8),
                              Text(member.uid == currentUser?.uid
                                  ? (member.name.isNotEmpty ? member.name : 'You')
                                  : (member.name.isNotEmpty ? member.name : 'Member')),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (value) => setDialogState(() => selectedPayer = value ?? ''),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category['name'] as String,
                          child: Text(category['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value ?? 'Other'),
                ),
                if (selectedCategory == 'Other') ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Category Title',
                      hintText: 'e.g. Books, Gifts...',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedSplitMethod,
                  decoration: const InputDecoration(labelText: 'Split method'),
                  items: const [
                    DropdownMenuItem(value: 'equal', child: Text('Equal')),
                    DropdownMenuItem(value: 'exact', child: Text('Exact')),
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedSplitMethod = value ?? 'equal'),
                ),
                const SizedBox(height: 18),
                const Text('Split among'),
                ...members.map((member) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: ProfileAvatar(avatarId: member.avatarUrl, name: member.name, radius: 14),
                      title: Text(member.uid == currentUser?.uid
                          ? (member.name.isNotEmpty ? member.name : 'You')
                          : (member.name.isNotEmpty ? member.name : 'Member')),
                      value: selectedMembers.contains(member.uid),
                      onChanged: (selected) => setDialogState(() {
                        if (selected == true) {
                          selectedMembers.add(member.uid);
                        } else if (selectedMembers.length > 1) {
                          selectedMembers.remove(member.uid);
                        }
                      }),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _amountController.text = amountController.text.trim();
                  _titleController.text = descriptionController.text.trim();
                  _paidBy = selectedPayer;
                  _splitMethod = selectedSplitMethod;
                  _splitMemberIds = selectedMembers;
                  _selectedCategory = selectedCategory;
                  if (selectedCategory == 'Other' && customCategoryController.text.trim().isNotEmpty) {
                    _customCategoryController.text = customCategoryController.text.trim();
                  }
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Continue editing'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    descriptionController.dispose();
    customCategoryController.dispose();
  }

  String? _memberIdForName(String name, List<UserModel> members) {
    final normalizedName = name.trim().toLowerCase();
    if (normalizedName.isEmpty) return null;
    for (final member in members) {
      final memberName = member.name.trim().toLowerCase();
      if (memberName == normalizedName || normalizedName.contains(memberName)) {
        return member.uid;
      }
    }
    return null;
  }

  void _onSplitMethodChanged(String method, List<UserModel> members, double totalAmount) {
    _splitMethod = method;
    final activeMemberIds = _splitMemberIds.isEmpty
        ? members.map((m) => m.uid).toList()
        : members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList();

    if (method == 'exact') {
      final allEmpty = activeMemberIds.every((id) {
        final text = _exactControllers[id]?.text.trim() ?? '';
        return text.isEmpty || text == '0' || text == '0.00';
      });
      if (allEmpty && totalAmount > 0) {
        _autoBalanceExact(totalAmount, activeMemberIds, showFeedback: false);
      }
    } else if (method == 'percentage') {
      final allEmpty = activeMemberIds.every((id) {
        final text = _percentageControllers[id]?.text.trim() ?? '';
        return text.isEmpty || text == '0';
      });
      if (allEmpty) {
        _autoBalancePercentage(activeMemberIds, showFeedback: false);
      }
    } else if (method == 'custom') {
      for (final id in activeMemberIds) {
        _customShares.putIfAbsent(id, () => 1.0);
        final share = _customShares[id] ?? 1.0;
        _customShareControllers[id]?.text =
            share.truncateToDouble() == share ? share.toStringAsFixed(0) : share.toStringAsFixed(1);
      }
    }
  }

  void _autoBalanceExact(double totalAmount, List<String> activeIds, {bool showFeedback = true}) {
    if (activeIds.isEmpty) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one member to split with')),
        );
      }
      return;
    }
    if (totalAmount <= 0) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the total expense amount first')),
        );
      }
      return;
    }

    final count = activeIds.length;
    // Divide cents/paise with remainder to ensure exact sum matches totalAmount
    final totalCents = (totalAmount * 100).round();
    final baseCents = totalCents ~/ count;
    final remainderCents = totalCents % count;

    for (int i = 0; i < count; i++) {
      final id = activeIds[i];
      final cents = baseCents + (i < remainderCents ? 1 : 0);
      final memberAmount = cents / 100.0;
      _exactControllers[id]?.text = formatAmountNumber(memberAmount, includeDecimalsIfZero: true);
    }

    if (showFeedback) {
      HapticFeedback.lightImpact();
      final perPerson = totalAmount / count;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Split ₹${totalAmount.toStringAsFixed(2)} evenly ($count members • ₹${perPerson.toStringAsFixed(2)} each)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {});
  }

  void _splitRemainingExact(double totalAmount, List<String> activeIds) {
    if (activeIds.isEmpty) return;
    if (totalAmount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the total expense amount first')),
        );
      }
      return;
    }

    double currentSum = 0.0;
    final emptyIds = <String>[];
    for (final id in activeIds) {
      final val = parseAmountNumber(_exactControllers[id]?.text);
      if (val <= 0) {
        emptyIds.add(id);
      } else {
        currentSum += val;
      }
    }

    final remaining = totalAmount - currentSum;
    if (remaining <= 0.05) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No remaining amount to split')),
        );
      }
      return;
    }

    final targetIds = emptyIds.isNotEmpty ? emptyIds : activeIds;
    final count = targetIds.length;
    final totalCents = (remaining * 100).round();
    final baseCents = totalCents ~/ count;
    final remainderCents = totalCents % count;

    for (int i = 0; i < count; i++) {
      final id = targetIds[i];
      final currentVal = emptyIds.isNotEmpty ? 0.0 : parseAmountNumber(_exactControllers[id]?.text);
      final cents = baseCents + (i < remainderCents ? 1 : 0);
      final added = cents / 100.0;
      final newVal = currentVal + added;
      _exactControllers[id]?.text = formatAmountNumber(newVal, includeDecimalsIfZero: true);
    }

    HapticFeedback.lightImpact();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Distributed remaining ₹${remaining.toStringAsFixed(2)} evenly'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _autoBalancePercentage(List<String> activeIds, {bool showFeedback = true}) {
    if (activeIds.isEmpty) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one member to split with')),
        );
      }
      return;
    }

    final count = activeIds.length;
    final basePct = double.parse((100.0 / count).toStringAsFixed(1));
    final currentSum = basePct * count;
    final diff = double.parse((100.0 - currentSum).toStringAsFixed(1));

    for (int i = 0; i < count; i++) {
      final id = activeIds[i];
      final pct = i == 0 ? (basePct + diff) : basePct;
      _percentageControllers[id]?.text = pct.toStringAsFixed(1);
    }

    if (showFeedback) {
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Split percentages evenly (100% total across $count members)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {});
  }

  void _fillRemainingPercentage(List<String> activeIds) {
    if (activeIds.isEmpty) return;
    double currentSum = 0.0;
    final emptyIds = <String>[];
    for (final id in activeIds) {
      final val = double.tryParse(_percentageControllers[id]?.text.trim() ?? '0') ?? 0.0;
      if (val <= 0) {
        emptyIds.add(id);
      } else {
        currentSum += val;
      }
    }

    final remaining = 100.0 - currentSum;
    if (remaining <= 0.05) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No remaining percentage to fill')),
        );
      }
      return;
    }

    final targetIds = emptyIds.isNotEmpty ? emptyIds : activeIds;
    final count = targetIds.length;
    final perTarget = double.parse((remaining / count).toStringAsFixed(1));
    final currentDistributed = perTarget * count;
    final diff = double.parse((remaining - currentDistributed).toStringAsFixed(1));

    for (int i = 0; i < count; i++) {
      final id = targetIds[i];
      final currentVal = emptyIds.isNotEmpty ? 0.0 : (double.tryParse(_percentageControllers[id]?.text.trim() ?? '0') ?? 0.0);
      final added = i == 0 ? (perTarget + diff) : perTarget;
      _percentageControllers[id]?.text = (currentVal + added).toStringAsFixed(1);
    }

    HapticFeedback.lightImpact();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filled remaining ${remaining.toStringAsFixed(1)}% (100% total)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetCustomShares(List<String> activeIds) {
    if (activeIds.isEmpty) return;
    for (final id in activeIds) {
      _customShares[id] = 1.0;
      _customShareControllers[id]?.text = '1';
    }
    HapticFeedback.lightImpact();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset all custom shares to 1'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveExpense() async {
    final amountText = _amountController.text.trim();
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense title or description')),
      );
      return;
    }

    final parsedAmount = tryParseAmountNumber(amountText);
    if (amountText.isEmpty || parsedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }
    final totalAmount = parsedAmount;
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense amount must be greater than zero')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final currentUser = authProvider.userModel;
    final activeGroup = groupProvider.activeGroup;

    if (currentUser == null || activeGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active group selected')));
      return;
    }

    final activeMemberIds = _splitMemberIds.isEmpty ? activeGroup.memberIds : _splitMemberIds.toList();
    if (activeMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one member to split with')));
      return;
    }

    final splits = <ExpenseSplit>[];

    if (_splitMethod == 'equal') {
      final perPerson = totalAmount / activeMemberIds.length;
      final perPersonPct = 100.0 / activeMemberIds.length;
      for (final id in activeMemberIds) {
        splits.add(ExpenseSplit(
          userId: id,
          amount: double.parse(perPerson.toStringAsFixed(2)),
          percentage: double.parse(perPersonPct.toStringAsFixed(2)),
          shares: 1.0,
        ));
      }
    } else if (_splitMethod == 'exact') {
      double totalExact = 0.0;
      for (final id in activeMemberIds) {
        final val = parseAmountNumber(_exactControllers[id]?.text);
        if (val < 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exact amounts cannot be negative')));
          return;
        }
        totalExact += val;
      }

      final diff = (totalExact - totalAmount).abs();
      if (diff > 0.05) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total of exact amounts (₹${totalExact.toStringAsFixed(2)}) does not match the expense amount (₹${totalAmount.toStringAsFixed(2)})',
            ),
          ),
        );
        return;
      }

      for (final id in activeMemberIds) {
        final val = parseAmountNumber(_exactControllers[id]?.text);
        final pct = totalAmount > 0 ? (val / totalAmount) * 100 : 0.0;
        splits.add(ExpenseSplit(
          userId: id,
          amount: double.parse(val.toStringAsFixed(2)),
          percentage: double.parse(pct.toStringAsFixed(2)),
          shares: 1.0,
        ));
      }
    } else if (_splitMethod == 'percentage') {
      double totalPct = 0.0;
      for (final id in activeMemberIds) {
        final pct = double.tryParse(_percentageControllers[id]?.text.trim() ?? '0') ?? 0.0;
        if (pct < 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Percentages cannot be negative')));
          return;
        }
        totalPct += pct;
      }

      final diff = (totalPct - 100.0).abs();
      if (diff > 0.5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total percentages (${totalPct.toStringAsFixed(1)}%) must add up to 100%',
            ),
          ),
        );
        return;
      }

      for (final id in activeMemberIds) {
        final pct = double.tryParse(_percentageControllers[id]?.text.trim() ?? '0') ?? 0.0;
        final val = totalAmount * (pct / 100.0);
        splits.add(ExpenseSplit(
          userId: id,
          amount: double.parse(val.toStringAsFixed(2)),
          percentage: double.parse(pct.toStringAsFixed(2)),
          shares: 1.0,
        ));
      }
    } else if (_splitMethod == 'custom') {
      double totalShares = 0.0;
      for (final id in activeMemberIds) {
        final share = _customShares[id] ?? 1.0;
        if (share < 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom shares cannot be negative')));
          return;
        }
        totalShares += share;
      }

      if (totalShares <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total shares must be greater than zero')));
        return;
      }

      for (final id in activeMemberIds) {
        final share = _customShares[id] ?? 1.0;
        final val = totalAmount * (share / totalShares);
        final pct = (share / totalShares) * 100.0;
        splits.add(ExpenseSplit(
          userId: id,
          amount: double.parse(val.toStringAsFixed(2)),
          percentage: double.parse(pct.toStringAsFixed(2)),
          shares: share,
        ));
      }
    }

    final customCategoryTitle = _customCategoryController.text.trim();
    final effectiveCategory = (_selectedCategory == 'Other' && customCategoryTitle.isNotEmpty)
        ? customCategoryTitle
        : _selectedCategory;

    final expense = ExpenseModel(
      id: '',
      groupId: activeGroup.id,
      title: title.isNotEmpty ? title : effectiveCategory,
      amount: totalAmount,
      category: effectiveCategory,
      paidBy: _paidBy.isEmpty ? currentUser.uid : _paidBy,
      splitMethod: _splitMethod,
      splits: splits,
      note: _noteController.text.trim(),
      createdBy: currentUser.uid,
      createdAt: DateTime.now(),
    );

    await expenseProvider.addExpense(
      expense: expense,
      userName: currentUser.name,
      userAvatarUrl: currentUser.avatarUrl,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userModel;
    final currentUid = currentUser?.uid ?? authProvider.firebaseUser?.uid ?? '';
    final rawMembers = groupProvider.activeGroupMembers;
    final members = rawMembers.map((m) {
      if (currentUser != null && m.uid == currentUser.uid) {
        return currentUser;
      }
      return m;
    }).toList();
    if (currentUser != null &&
        !members.any((m) => m.uid == currentUser.uid) &&
        (widget.group?.memberIds.contains(currentUser.uid) == true ||
            groupProvider.activeGroup?.memberIds.contains(currentUser.uid) == true)) {
      members.insert(0, currentUser);
    }

    // Default the payer to the current user.
    if (_paidBy.isEmpty && currentUid.isNotEmpty) {
      _paidBy = currentUid;
    }

    // Initialize split members default if empty
    if (_splitMemberIds.isEmpty && members.isNotEmpty) {
      _splitMemberIds = members.map((m) => m.uid).toSet();
    }

    final totalAmount = parseAmountNumber(_amountController.text);

    // Initialize controllers for splits
    for (final m in members) {
      _exactControllers.putIfAbsent(m.uid, () => TextEditingController());
      _percentageControllers.putIfAbsent(m.uid, () => TextEditingController());
      _customShares.putIfAbsent(m.uid, () => 1.0);
      _customShareControllers.putIfAbsent(
        m.uid,
        () => TextEditingController(
          text: (_customShares[m.uid] ?? 1.0)
              .toStringAsFixed((_customShares[m.uid] ?? 1.0).truncateToDouble() == (_customShares[m.uid] ?? 1.0) ? 0 : 1),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListeningVoice ? Colors.red : AppColors.berryRose,
            ),
            onPressed: _toggleVoiceListening,
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded, color: AppColors.berryRose),
            onPressed: _pickAndScanReceipt,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isProcessingOcr)
                const LinearProgressIndicator(color: AppColors.berryRose),

              // Amount Card
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.deepBerry,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.mintGreen : AppColors.berryRose,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: textSecondary.withAlpha(140),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.description_rounded, color: AppColors.berryRose),
                  hintText: 'What is this expense for?',
                  hintStyle: TextStyle(color: textSecondary.withAlpha(150)),
                ),
              ),

              // Category Quick Presets
              Builder(
                builder: (context) {
                  final activeGroup = widget.group ?? groupProvider.activeGroup;
                  final categoryInfo = GroupCategories.getCategory(activeGroup?.category ?? 'Trip');
                  if (categoryInfo.quickTemplates.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            categoryInfo.icon,
                            size: 14,
                            color: categoryInfo.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Quick ${categoryInfo.name} Ideas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: categoryInfo.quickTemplates.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final template = categoryInfo.quickTemplates[index];
                            final isPicked = _titleController.text.trim().toLowerCase() == template.title.toLowerCase();

                            return BouncingTap(
                              scaleLower: 0.93,
                              onTap: () {
                                setState(() {
                                  _titleController.text = template.title;
                                  _selectedCategory = template.category;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isPicked
                                      ? categoryInfo.color
                                      : (isDark ? AppColors.darkCardSurface : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPicked
                                        ? categoryInfo.color
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: isPicked ? 1.5 : 1,
                                  ),
                                  boxShadow: isPicked
                                      ? [
                                          BoxShadow(
                                            color: categoryInfo.color.withAlpha(90),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      template.icon,
                                      size: 14,
                                      color: isPicked ? Colors.white : categoryInfo.color,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      template.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isPicked ? FontWeight.bold : FontWeight.w600,
                                        color: isPicked ? Colors.white : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Paid By
              Text(
                'Paid by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _paidByChip(
                    label: 'Everyone',
                    value: 'everyone',
                    icon: Icons.groups_rounded,
                    isDark: isDark,
                    textPrimary: textPrimary,
                  ),
                  for (final m in members)
                    _paidByChip(
                      label: m.uid == currentUid
                          ? (m.name.isNotEmpty ? m.name : 'You')
                          : (m.name.isNotEmpty ? m.name : 'Member'),
                      value: m.uid,
                      leadingWidget: ProfileAvatar(
                        avatarId: m.avatarUrl,
                        name: m.name,
                        radius: 11,
                      ),
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Category Grid
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final cat = AppConstants.categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  final isOther = cat['name'] == 'Other';
                  final customText = _customCategoryController.text.trim();

                  return BouncingTap(
                    scaleLower: 0.93,
                    onTap: () {
                      setState(() => _selectedCategory = cat['name']);
                      if (isOther) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _customCategoryFocusNode.requestFocus();
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.berryRose.withAlpha(50) : AppColors.softBerryPink)
                            : (isDark ? AppColors.darkCardSurface : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.berryRose
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            isOther && isSelected && customText.isNotEmpty
                                ? customText
                                : (isOther ? 'Other / Custom' : cat['name']),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? const Color(0xFFF48FB1) : AppColors.deepBerry)
                                  : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_selectedCategory == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customCategoryController,
                  focusNode: _customCategoryFocusNode,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Custom Category Title',
                    labelStyle: TextStyle(
                      color: isDark ? AppColors.berryRose : AppColors.deepBerry,
                      fontSize: 13,
                    ),
                    hintText: 'e.g., Books, Gifts, Fitness, Pet care...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.berryRose),
                    suffixIcon: _customCategoryController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _customCategoryController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCardSurface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.berryRose, width: 2),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    'Books',
                    'Gifts',
                    'Fitness',
                    'Pet care',
                    'Donation',
                    'Repair',
                    'Party',
                    'Subscriptions',
                    'Medical',
                  ].map((suggestion) {
                    final isPicked = _customCategoryController.text.trim().toLowerCase() == suggestion.toLowerCase();
                    return BouncingTap(
                      scaleLower: 0.93,
                      onTap: () {
                        setState(() {
                          _customCategoryController.text = suggestion;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPicked
                              ? AppColors.berryRose.withAlpha(35)
                              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPicked
                                ? AppColors.berryRose
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isPicked ? FontWeight.bold : FontWeight.w500,
                            color: isPicked
                                ? (isDark ? AppColors.berryRose : AppColors.deepBerry)
                                : textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Split Methods Selector
              Text(
                'Split Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _splitMethodChip(
                    label: 'Equal',
                    value: 'equal',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    members: members,
                    totalAmount: totalAmount,
                  ),
                  _splitMethodChip(
                    label: 'Exact',
                    value: 'exact',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    members: members,
                    totalAmount: totalAmount,
                  ),
                  _splitMethodChip(
                    label: 'Percentage',
                    value: 'percentage',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    members: members,
                    totalAmount: totalAmount,
                  ),
                  _splitMethodChip(
                    label: 'Custom',
                    value: 'custom',
                    isDark: isDark,
                    textPrimary: textPrimary,
                    members: members,
                    totalAmount: totalAmount,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Split Details & Breakdown Section
              _buildSplitBreakdownSection(
                members: members,
                currentUid: currentUid,
                totalAmount: totalAmount,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 32),

              // Submit Button
              BouncingTap(
                scaleLower: 0.96,
                onTap: _saveExpense,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: IgnorePointer(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Save Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paidByChip({
    required String label,
    required String value,
    IconData? icon,
    Widget? leadingWidget,
    required bool isDark,
    required Color textPrimary,
  }) {
    final isSelected = _paidBy == value;
    return GestureDetector(
      onTap: () => setState(() => _paidBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.berryRose
              : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(128)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.berryRose
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder.withAlpha(120)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.mintGreen : AppColors.berryRose),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _splitMethodChip({
    required String label,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required List<UserModel> members,
    required double totalAmount,
  }) {
    final isSelected = _splitMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _onSplitMethodChanged(value, members, totalAmount);
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.berryRose
                : (isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(128)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.berryRose
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder.withAlpha(120)),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitBreakdownSection({
    required List<UserModel> members,
    required String currentUid,
    required double totalAmount,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          'No group members found to split with.',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
      );
    }

    final activeMemberCount = members.where((m) => _splitMemberIds.contains(m.uid)).length;

    IconData headerIcon;
    String headerTitle;
    String headerSubtitle;
    Widget? headerAction;

    if (_splitMethod == 'equal') {
      headerIcon = Icons.balance_rounded;
      headerTitle = 'Equal Split';
      final perPerson = activeMemberCount > 0 ? (totalAmount / activeMemberCount) : 0.0;
      headerSubtitle = totalAmount > 0
          ? '₹${totalAmount.toStringAsFixed(2)} split equally among $activeMemberCount member${activeMemberCount == 1 ? '' : 's'} (₹${perPerson.toStringAsFixed(2)} each)'
          : 'Split equally among selected members';
      headerAction = TextButton(
        onPressed: () {
          setState(() {
            if (_splitMemberIds.length == members.length) {
              _splitMemberIds = {currentUid.isNotEmpty ? currentUid : members.first.uid};
            } else {
              _splitMemberIds = members.map((m) => m.uid).toSet();
            }
          });
        },
        child: Text(
          _splitMemberIds.length == members.length ? 'Deselect others' : 'Select all',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.berryRose),
        ),
      );
    } else if (_splitMethod == 'exact') {
      headerIcon = Icons.pin_rounded;
      headerTitle = 'Exact Amounts';
      headerSubtitle = 'Enter custom amount for each member, or tap Split Evenly to divide total';
      headerAction = TextButton.icon(
        icon: const Icon(Icons.auto_fix_high_rounded, size: 14, color: AppColors.berryRose),
        label: const Text('Split Evenly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.berryRose)),
        onPressed: () => _autoBalanceExact(
          totalAmount,
          members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList(),
          showFeedback: true,
        ),
      );
    } else if (_splitMethod == 'percentage') {
      headerIcon = Icons.percent_rounded;
      headerTitle = 'Percentage Split';
      headerSubtitle = 'Specify percentage for each member (must total 100%)';
      headerAction = TextButton.icon(
        icon: const Icon(Icons.auto_fix_high_rounded, size: 14, color: AppColors.berryRose),
        label: const Text('Split Evenly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.berryRose)),
        onPressed: () => _autoBalancePercentage(
          members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList(),
          showFeedback: true,
        ),
      );
    } else {
      headerIcon = Icons.pie_chart_rounded;
      headerTitle = 'Custom Shares / Ratios';
      headerSubtitle = 'Assign shares or weights to members (e.g. 1, 2, 3)';
      headerAction = TextButton.icon(
        icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.berryRose),
        label: const Text('Reset Shares', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.berryRose)),
        onPressed: () => _resetCustomShares(
          members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList(),
        ),
      );
    }

    Widget? validationBanner;
    if (_splitMethod == 'exact') {
      final sumExact = members.fold(0.0, (sum, m) {
        if (!_splitMemberIds.contains(m.uid)) return sum;
        return sum + parseAmountNumber(_exactControllers[m.uid]?.text);
      });
      final diff = totalAmount - sumExact;
      final isMatch = diff.abs() <= 0.05 && totalAmount > 0;
      final isOver = diff < -0.05;

      validationBanner = Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMatch
              ? Colors.green.withAlpha(isDark ? 40 : 25)
              : (isOver ? Colors.red.withAlpha(isDark ? 40 : 25) : Colors.amber.withAlpha(isDark ? 40 : 25)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMatch
                ? Colors.green.withAlpha(120)
                : (isOver ? Colors.red.withAlpha(120) : Colors.amber.withAlpha(120)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isMatch ? Icons.check_circle_rounded : (isOver ? Icons.error_outline_rounded : Icons.info_outline_rounded),
              size: 18,
              color: isMatch ? Colors.green : (isOver ? Colors.red : Colors.orange[800]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMatch
                    ? 'Total matched: ₹${sumExact.toStringAsFixed(2)} of ₹${totalAmount.toStringAsFixed(2)}'
                    : (isOver
                        ? '₹${(-diff).toStringAsFixed(2)} over total (₹${sumExact.toStringAsFixed(2)} / ₹${totalAmount.toStringAsFixed(2)})'
                        : '₹${diff.toStringAsFixed(2)} remaining (₹${sumExact.toStringAsFixed(2)} / ₹${totalAmount.toStringAsFixed(2)})'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMatch ? Colors.green : (isOver ? Colors.red : Colors.orange[800]),
                ),
              ),
            ),
            if (!isMatch && !isOver && totalAmount > 0) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _splitRemainingExact(
                  totalAmount,
                  members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.berryRose.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.berryRose.withAlpha(140)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_normal_rounded, size: 12, color: AppColors.berryRose),
                      SizedBox(width: 4),
                      Text(
                        'Fill remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.berryRose,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else if (_splitMethod == 'percentage') {
      final sumPct = members.fold(0.0, (sum, m) {
        if (!_splitMemberIds.contains(m.uid)) return sum;
        return sum + (double.tryParse(_percentageControllers[m.uid]?.text.trim() ?? '0') ?? 0.0);
      });
      final diffPct = 100.0 - sumPct;
      final isMatch = diffPct.abs() <= 0.5;
      final isOver = diffPct < -0.5;

      validationBanner = Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMatch
              ? Colors.green.withAlpha(isDark ? 40 : 25)
              : (isOver ? Colors.red.withAlpha(isDark ? 40 : 25) : Colors.amber.withAlpha(isDark ? 40 : 25)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMatch
                ? Colors.green.withAlpha(120)
                : (isOver ? Colors.red.withAlpha(120) : Colors.amber.withAlpha(120)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isMatch ? Icons.check_circle_rounded : (isOver ? Icons.error_outline_rounded : Icons.info_outline_rounded),
              size: 18,
              color: isMatch ? Colors.green : (isOver ? Colors.red : Colors.orange[800]),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMatch
                    ? '100% fully allocated!'
                    : (isOver
                        ? '${(-diffPct).toStringAsFixed(1)}% over 100% (${sumPct.toStringAsFixed(1)}% entered)'
                        : '${diffPct.toStringAsFixed(1)}% remaining (${sumPct.toStringAsFixed(1)}% entered)'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isMatch ? Colors.green : (isOver ? Colors.red : Colors.orange[800]),
                ),
              ),
            ),
            if (!isMatch && !isOver) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _fillRemainingPercentage(
                  members.where((m) => _splitMemberIds.contains(m.uid)).map((m) => m.uid).toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.berryRose.withAlpha(isDark ? 50 : 30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.berryRose.withAlpha(140)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_normal_rounded, size: 12, color: AppColors.berryRose),
                      SizedBox(width: 4),
                      Text(
                        'Fill remaining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.berryRose,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    } else if (_splitMethod == 'custom') {
      final totalShares = members.fold(0.0, (sum, m) {
        if (!_splitMemberIds.contains(m.uid)) return sum;
        return sum + (_customShares[m.uid] ?? 1.0);
      });
      final perShare = totalShares > 0 ? (totalAmount / totalShares) : 0.0;

      validationBanner = Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.softBerryPink.withAlpha(80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_rounded, size: 16, color: AppColors.berryRose),
                const SizedBox(width: 6),
                Text(
                  'Total: ${totalShares.toStringAsFixed(totalShares.truncateToDouble() == totalShares ? 0 : 1)} shares',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
            Text(
              '₹${perShare.toStringAsFixed(2)} / share',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.mintGreen : AppColors.berryRose),
            ),
          ],
        ),
      );
    }

    final totalCustomShares = members.fold(0.0, (sum, m) {
      if (!_splitMemberIds.contains(m.uid)) return sum;
      return sum + (_customShares[m.uid] ?? 1.0);
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
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
              Icon(headerIcon, size: 18, color: AppColors.berryRose),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerTitle,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              headerAction,
            ],
          ),
          const SizedBox(height: 2),
          Text(
            headerSubtitle,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 14),
          ?validationBanner,
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...members.map((m) {
            final isIncluded = _splitMemberIds.contains(m.uid);
            final displayName = m.uid == currentUid
                ? (m.name.isNotEmpty ? m.name : 'You')
                : (m.name.isNotEmpty ? m.name : 'Member');

            Widget trailingControl;

            if (_splitMethod == 'equal') {
              final perPerson = activeMemberCount > 0 ? (totalAmount / activeMemberCount) : 0.0;
              trailingControl = isIncluded
                  ? Text(
                      '₹ ${perPerson.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.mintGreen : AppColors.deepBerry,
                      ),
                    )
                  : Text(
                      'Excluded',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary.withAlpha(150)),
                    );
            } else if (_splitMethod == 'exact') {
              trailingControl = isIncluded
                  ? Container(
                      width: 110,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.softBerryPink.withAlpha(80),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: TextField(
                        controller: _exactControllers[m.uid],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixText: ' ₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.mintGreen : AppColors.berryRose,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    )
                  : Text(
                      'Excluded',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary.withAlpha(150)),
                    );
            } else if (_splitMethod == 'percentage') {
              final pct = double.tryParse(_percentageControllers[m.uid]?.text.trim() ?? '0') ?? 0.0;
              final memberAmount = totalAmount * (pct / 100.0);
              trailingControl = isIncluded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 85,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.softBerryPink.withAlpha(80),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: TextField(
                            controller: _percentageControllers[m.uid],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              suffixText: ' % ',
                              suffixStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.mintGreen : AppColors.berryRose,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹ ${memberAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.mintGreen : AppColors.berryRose,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Excluded',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary.withAlpha(150)),
                    );
            } else {
              // Custom Shares
              final share = _customShares[m.uid] ?? 1.0;
              final memberAmount = totalCustomShares > 0 ? (totalAmount * (share / totalCustomShares)) : 0.0;
              final memberPct = totalCustomShares > 0 ? ((share / totalCustomShares) * 100.0) : 0.0;

              trailingControl = isIncluded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final current = _customShares[m.uid] ?? 1.0;
                                if (current > 1.0) {
                                  setState(() {
                                    final next = current - 1.0;
                                    _customShares[m.uid] = next;
                                    _customShareControllers[m.uid]?.text =
                                        next.truncateToDouble() == next ? next.toStringAsFixed(0) : next.toStringAsFixed(1);
                                  });
                                } else if (current > 0.1) {
                                  setState(() {
                                    _customShares[m.uid] = 0.0;
                                    _customShareControllers[m.uid]?.text = '0';
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.softBerryPink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.berryRose),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 44,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.softBerryPink.withAlpha(80),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: TextField(
                                controller: _customShareControllers[m.uid],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                onChanged: (val) {
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed != null && parsed >= 0) {
                                    setState(() {
                                      _customShares[m.uid] = parsed;
                                    });
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                final current = _customShares[m.uid] ?? 1.0;
                                setState(() {
                                  final next = current + 1.0;
                                  _customShares[m.uid] = next;
                                  _customShareControllers[m.uid]?.text =
                                      next.truncateToDouble() == next ? next.toStringAsFixed(0) : next.toStringAsFixed(1);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.softBerryPink,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, size: 16, color: AppColors.berryRose),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '₹ ${memberAmount.toStringAsFixed(2)} (${memberPct.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.mintGreen : AppColors.berryRose,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Excluded',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary.withAlpha(150)),
                    );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: isIncluded,
                    activeColor: AppColors.berryRose,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _splitMemberIds.add(m.uid);
                        } else if (_splitMemberIds.length > 1) {
                          _splitMemberIds.remove(m.uid);
                        }
                      });
                    },
                  ),
                  ProfileAvatar(avatarId: m.avatarUrl, name: m.name, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isIncluded ? textPrimary : textSecondary.withAlpha(120),
                          ),
                        ),
                        if (_splitMethod == 'custom' && isIncluded)
                          Text(
                            '${(_customShares[m.uid] ?? 1.0).toStringAsFixed((_customShares[m.uid] ?? 1.0).truncateToDouble() == (_customShares[m.uid] ?? 1.0) ? 0 : 1)} share${(_customShares[m.uid] ?? 1.0) == 1.0 ? '' : 's'}',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  trailingControl,
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
