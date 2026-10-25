import 'dart:async';
import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _verificationPollTimer;
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 0;
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to automatically proceed when the user clicks the verification link in their email
    _verificationPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _verificationPollTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerificationStatus({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) {
      setState(() => _isChecking = true);
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final verified = await auth.checkEmailVerified();

    if (!mounted) return;
    if (!silent) {
      setState(() => _isChecking = false);
    }

    if (verified) {
      _verificationPollTimer?.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Email verified successfully! Welcome to SplitSync.',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Email not verified yet. Please tap the link in your email and try again.',
            style: TextStyle(fontSize: 13),
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldownSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sent = await auth.sendEmailVerification();

    if (!mounted) return;
    setState(() => _isResending = false);

    if (sent) {
      setState(() => _resendCooldownSeconds = 30);
      _resendCooldownTimer?.cancel();
      _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_resendCooldownSeconds <= 1) {
          timer.cancel();
          setState(() => _resendCooldownSeconds = 0);
        } else {
          setState(() => _resendCooldownSeconds--);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verification email sent! Please check your inbox.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not send verification email. Please try again in a moment.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _openEmailApp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = (auth.firebaseUser?.email ?? auth.userModel?.email ?? '').toLowerCase();

    // 1. Android: Open email app inbox via native Intent (NOT compose mailto:)
    if (Platform.isAndroid) {
      // First attempt: Standard Android Email category
      try {
        const intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          category: 'android.intent.category.APP_EMAIL',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
        return;
      } catch (_) {}

      // Second attempt: Specific client based on email domain or popular clients
      final candidatePackages = <String>[];
      if (email.contains('@gmail.com') || email.contains('@googlemail.com')) {
        candidatePackages.add('com.google.android.gm');
      } else if (email.contains('@outlook.com') ||
          email.contains('@hotmail.com') ||
          email.contains('@live.com')) {
        candidatePackages.add('com.microsoft.office.outlook');
      } else if (email.contains('@yahoo.com')) {
        candidatePackages.add('com.yahoo.mobile.client.android.mail');
      }
      candidatePackages.addAll([
        'com.google.android.gm',
        'com.microsoft.office.outlook',
        'com.samsung.android.email.provider',
      ]);

      for (final pkg in candidatePackages.toSet()) {
        try {
          final pkgIntent = AndroidIntent(
            action: 'android.intent.action.MAIN',
            package: pkg,
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await pkgIntent.launch();
          return;
        } catch (_) {}
      }
    }

    // 2. iOS: Open email app inbox via URL schemes
    if (Platform.isIOS) {
      final schemes = <String>[];
      if (email.contains('@gmail.com') || email.contains('@googlemail.com')) {
        schemes.add('googlegmail://');
      } else if (email.contains('@outlook.com') ||
          email.contains('@hotmail.com') ||
          email.contains('@live.com')) {
        schemes.add('ms-outlook://');
      } else if (email.contains('@yahoo.com')) {
        schemes.add('ymail://');
      }
      schemes.addAll(['message://', 'googlegmail://', 'ms-outlook://']);

      for (final scheme in schemes.toSet()) {
        try {
          final uri = Uri.parse(scheme);
          if (await canLaunchUrl(uri)) {
            final launched = await launchUrl(uri);
            if (launched) return;
          }
        } catch (_) {}
      }
    }

    // 3. Fallback: Open webmail inbox in browser (NOT mailto: which creates a blank compose draft)
    try {
      Uri webMailUri;
      if (email.contains('@gmail.com') || email.contains('@googlemail.com')) {
        webMailUri = Uri.parse('https://mail.google.com/mail/u/0/#inbox');
      } else if (email.contains('@outlook.com') ||
          email.contains('@hotmail.com') ||
          email.contains('@live.com')) {
        webMailUri = Uri.parse('https://outlook.live.com/mail/0/inbox');
      } else if (email.contains('@yahoo.com')) {
        webMailUri = Uri.parse('https://mail.yahoo.com/d/folders/1');
      } else {
        webMailUri = Uri.parse('https://mail.google.com');
      }

      final webLaunched = await launchUrl(
        webMailUri,
        mode: LaunchMode.externalApplication,
      );
      if (webLaunched) return;
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please open your email application to click the verification link.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final email = auth.firebaseUser?.email ?? auth.userModel?.email ?? 'your email';

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SplitSync Logo (Big, Centered)
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepBerry.withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.berryRose.withValues(alpha: 0.35),
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/wallet_icon.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 56,
                              color: AppColors.deepBerry,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "We've sent a verification link to:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // User Email Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.berryRose.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBerry,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Please click the link in your email to verify your account.\nSplitSync will automatically detect when you verify.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.lightTextSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button 1: Open Email App
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openEmailApp,
                      icon: const Icon(Icons.mark_email_read_rounded, size: 20),
                      label: const Text(
                        'Open Email App',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepBerry,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: I've Already Verified (Manual check)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : () => _checkVerificationStatus(silent: false),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.deepBerry,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 19),
                      label: Text(
                        _isChecking ? 'Checking...' : "I've Verified My Email",
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.deepBerry,
                        side: BorderSide(
                          color: AppColors.deepBerry.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend Email with timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive the email? ",
                        style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                      ),
                      GestureDetector(
                        onTap: (_resendCooldownSeconds > 0 || _isResending) ? null : _resendEmail,
                        child: Text(
                          _resendCooldownSeconds > 0
                              ? 'Resend in ${_resendCooldownSeconds}s'
                              : (_isResending ? 'Sending...' : 'Resend Email'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _resendCooldownSeconds > 0 ? Colors.grey : AppColors.berryRose,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Change email / Sign out
                  GestureDetector(
                    onTap: () async {
                      await auth.signOut();
                    },
                    child: const Text(
                      'Entered wrong email? Sign out & change email',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.berryRose,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
