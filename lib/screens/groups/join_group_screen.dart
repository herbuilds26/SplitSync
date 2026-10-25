import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/firestore_service.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      final code = FirestoreService.normalizeInviteCode(text);
      if (code.isNotEmpty) {
        _codeController.text = code;
        await _handleJoinGroup(code);
      } else {
        _codeController.text = text;
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty.')),
      );
    }
  }

  Future<void> _handleJoinGroup(String rawCode) async {
    final code = FirestoreService.normalizeInviteCode(rawCode);
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6-character group invite code.')),
      );
      return;
    }

    if (_isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final firebaseUser = authProvider.firebaseUser;
    final user = authProvider.userModel;
    final userId = user?.uid ?? firebaseUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before joining a group.')),
      );
      return;
    }

    final userName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (firebaseUser?.displayName ?? firebaseUser?.email?.split('@').first ?? 'You');

    setState(() => _isLoading = true);
    if (_isScanning) {
      try {
        await _scannerController.stop();
      } catch (_) {}
    }

    try {
      final group = await groupProvider.joinGroupByCode(
        code,
        userId,
        userName,
        userAvatarUrl: user?.avatarUrl ?? '',
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined "${group.name}" successfully!'),
          backgroundColor: AppColors.berryRose,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceFirst('Exception: ', '');
      final userMessage = rawError.contains('permission-denied')
          ? 'Permission denied while joining. Check your account connection.'
          : rawError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessage)),
      );

      // Resume scanner if scanning was active
      if (_isScanning) {
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Join Group'),
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
                'Enter Invite Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: _handleJoinGroup,
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. SPLIT6 or paste link',
                  hintStyle: TextStyle(color: textSecondary),
                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.berryRose),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, color: AppColors.berryRose),
                    tooltip: 'Paste from clipboard',
                    onPressed: _isLoading ? null : _pasteFromClipboard,
                  ),
                  filled: true,
                  fillColor: cardBg,
                  counterText: '',
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.berryRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : () => _handleJoinGroup(_codeController.text),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Join via Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR SCAN QR CODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 340,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : Colors.black12,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.berryRose, width: 2),
                ),
                child: _isScanning
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              if (_isLoading) return;
                              for (final barcode in capture.barcodes) {
                                final val = barcode.rawValue;
                                if (val != null && val.trim().isNotEmpty) {
                                  _handleJoinGroup(val);
                                  break;
                                }
                              }
                            },
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Close Camera',
                              onPressed: () {
                                _scannerController.stop();
                                setState(() => _isScanning = false);
                              },
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, size: 70, color: AppColors.berryRose),
                            const SizedBox(height: 16),
                            Text('Scan Group QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textPrimary,
                                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.camera_alt_rounded, color: AppColors.berryRose),
                              label: Text('Open Scanner Camera', style: TextStyle(color: textPrimary)),
                              onPressed: () {
                                setState(() => _isScanning = true);
                                _scannerController.start();
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
