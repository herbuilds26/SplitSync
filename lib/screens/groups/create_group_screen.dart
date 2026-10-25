import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../config/group_categories.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  String _selectedCategory = 'Trip';
  String _selectedCurrency = 'INR';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final firebaseUser = authProvider.firebaseUser;
    final user = authProvider.userModel;

    final userId = user?.uid ?? firebaseUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before creating a group.')),
      );
      return;
    }

    final userName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (firebaseUser?.displayName ?? firebaseUser?.email?.split('@').first ?? 'You');

    setState(() => _isLoading = true);

    final customCat = _customCategoryController.text.trim();
    final effectiveCategory = (_selectedCategory == 'Other' && customCat.isNotEmpty)
        ? customCat
        : _selectedCategory;

    try {
      final created = await groupProvider.createGroup(
        name: name,
        category: effectiveCategory,
        currency: _selectedCurrency,
        userId: userId,
        userName: userName,
        userAvatarUrl: user?.avatarUrl ?? '',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: created)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Create New Group'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleCreateGroup(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: const Icon(Icons.group_work_rounded, color: AppColors.berryRose),
                  filled: true,
                  fillColor: cardBg,
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
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Group Category & Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a category to unlock smart splitting presets and tailored expense features',
                style: TextStyle(fontSize: 12.5, color: textSecondary),
              ),
              const SizedBox(height: 12),
              // Category Selection Grid (Trip, Home, Couple, Other)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: GroupCategories.all.map((catInfo) {
                  final isSelected = _selectedCategory == catInfo.id;
                  final displayName = (catInfo.id == 'Other' && _customCategoryController.text.trim().isNotEmpty)
                      ? _customCategoryController.text.trim()
                      : catInfo.name;

                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = catInfo.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catInfo.color.withAlpha(isDark ? 50 : 30)
                            : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? catInfo.color
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: catInfo.color.withAlpha(isDark ? 40 : 25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: catInfo.color.withAlpha(isSelected ? 60 : (isDark ? 35 : 20)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              catInfo.icon,
                              color: catInfo.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark ? Colors.white : AppColors.deepBerry)
                                        : textPrimary,
                                  ),
                                ),
                                Text(
                                  catInfo.id == 'Trip'
                                      ? 'Vacations'
                                      : (catInfo.id == 'Home'
                                          ? 'Flatmates'
                                          : (catInfo.id == 'Couple' ? 'Partners' : 'Custom')),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? catInfo.color : textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: catInfo.color,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Category Details & Feature Highlights Panel
              _buildCategoryFeaturesPanel(isDark, textPrimary, textSecondary, cardBg, borderColor),
              const SizedBox(height: 24),
              Text(
                'Default Currency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_exchange_rounded, color: AppColors.berryRose),
                  filled: true,
                  fillColor: cardBg,
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
                ),
                items: AppConstants.currencies.map((c) {
                  return DropdownMenuItem(
                    value: c['code'],
                    child: Text(
                      '${c['name']} (${c['symbol']})',
                      style: TextStyle(color: textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.berryRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: isDark ? 0 : 2,
                  ),
                  onPressed: _isLoading ? null : _handleCreateGroup,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Create Group',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFeaturesPanel(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final catInfo = GroupCategories.getCategory(_selectedCategory);
    final isOther = _selectedCategory == 'Other';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink.withAlpha(90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: catInfo.color.withAlpha(isDark ? 80 : 60),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: catInfo.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(catInfo.icon, size: 16, color: catInfo.color),
              ),
              const SizedBox(width: 8),
              Text(
                catInfo.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.deepBerry,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catInfo.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${catInfo.name} Features',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: catInfo.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            catInfo.subtitle,
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),

          // Custom Category Title & Suggestions if 'Other'
          if (isOther) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _customCategoryController,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Custom Category Name',
                hintText: 'e.g. Festival, Project, Badminton Club',
                hintStyle: TextStyle(color: textSecondary),
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
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.berryRose, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Quick Suggestions:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: GroupCategories.customCategorySuggestions.map((suggestion) {
                final isCurrent = _customCategoryController.text.trim().toLowerCase() == suggestion.toLowerCase();
                return ActionChip(
                  label: Text(suggestion),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.deepBerry),
                  ),
                  backgroundColor: isCurrent
                      ? AppColors.berryRose
                      : (isDark ? AppColors.darkSurface : Colors.white),
                  side: BorderSide(
                    color: isCurrent ? AppColors.berryRose : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  onPressed: () {
                    setState(() {
                      _customCategoryController.text = suggestion;
                    });
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Included Features & Split Presets:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepBerry,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: catInfo.featureHighlights.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: catInfo.color.withAlpha(isDark ? 60 : 40),
                  ),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
