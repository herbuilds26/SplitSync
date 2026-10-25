import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/email_validator_service.dart';
import '../../services/firestore_service.dart';
import '../../services/password_validator.dart';
import '../../widgets/botanical_illustrations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isValidatingEmail = false;
  bool _isValidatingName = false;
  String? _nameWarningMessage;
  String? _emailWarningMessage;
  String? _emailSuggestion;
  PasswordValidationResult? _passwordStrength;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty) {
        _showMessage(auth.errorMessage!, isWarning: true);
        auth.clearErrorMessage();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    FocusScope.of(context).unfocus();
    debugPrint('AUTH SUBMIT PRESSED: isLogin=$_isLogin');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password', isWarning: true);
      return;
    }

    // Sign up mode: name validation & unique database name check
    if (!_isLogin) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _showMessage('Please enter your name', isWarning: true);
        return;
      }
      if (name.length < 3) {
        setState(() {
          _nameWarningMessage = 'Name must be at least 3 characters long.';
        });
        _showMessage('Name must be at least 3 characters long.', isWarning: true);
        return;
      }

      // Check if username already exists in Firestore database
      setState(() => _isValidatingName = true);
      final isTaken = await FirestoreService.isNameTaken(name);
      if (!mounted) return;
      setState(() => _isValidatingName = false);

      if (isTaken) {
        setState(() {
          _nameWarningMessage = 'The name "$name" is already taken. Please choose a unique name.';
        });
        _showMessage('This name is already registered. Please enter a unique name.', isWarning: true);
        return;
      } else {
        setState(() => _nameWarningMessage = null);
      }

      // Sign up mode: Strong password validation
      final pwdResult = PasswordValidator.validate(password);
      if (!pwdResult.isValid) {
        _showMessage(
          pwdResult.errorMessage ?? 'Please choose a stronger password meeting all requirements.',
          isWarning: true,
        );
        return;
      }
    }

    // Fast synchronous validation: syntax, disposable domains, and typos
    final formatCheck = EmailValidatorService.validateFormat(email);
    if (!formatCheck.isValid) {
      setState(() {
        _emailWarningMessage = formatCheck.errorMessage;
        _emailSuggestion = formatCheck.suggestion;
      });
      _showMessage(formatCheck.errorMessage ?? 'Please enter a valid email address.', isWarning: true);
      return;
    }

    // Async DNS Domain Existence Check (verifies whether the domain exists)
    setState(() => _isValidatingEmail = true);
    final validation = await EmailValidatorService.validateEmail(email);
    if (!mounted) return;
    setState(() => _isValidatingEmail = false);

    if (!validation.isValid) {
      setState(() {
        _emailWarningMessage = validation.errorMessage;
        _emailSuggestion = validation.suggestion;
      });
      _showMessage(validation.errorMessage ?? 'This email domain does not exist.', isWarning: true);
      return;
    }

    setState(() {
      _emailWarningMessage = null;
      _emailSuggestion = null;
    });

    bool success = false;
    if (_isLogin) {
      success = await authProvider.signInWithEmail(email, password);
    } else {
      final name = _nameController.text.trim();
      success = await authProvider.signUpWithEmail(name, email, password);
    }

    if (!success && mounted) {
      final err = authProvider.errorMessage ?? 'Authentication failed';
      debugPrint('SIGN IN FAILED, SHOWING SNACKBAR: $err');
      _showMessage(err, isWarning: true);
    }
  }

  void _showMessage(String msg, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? const Color(0xFFC2185B) : AppColors.berryRose,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    const textPrimary = AppColors.lightTextPrimary;
    const textSecondary = AppColors.lightTextSecondary;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Deep Berry Card with Botanical Illustrations
                Container(
                  height: 270,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.deepBerry,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Botanical Cascading Hanging Vines (Option 3 matching reference)
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: HangingVinesIllustration(width: 155, height: 165),
                      ),
                      Positioned(
                        top: 50,
                        left: 28,
                        child: Row(
                          children: const [
                            Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'SplitSync',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        left: 28,
                        bottom: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your expenses,',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'beautifully in sync.',
                              style: TextStyle(color: AppColors.softBerryPink, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLogin ? 'Welcome back 😸' : 'Create account 😺',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      if (_isLogin) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in and manage expenses together.',
                          style: TextStyle(color: textSecondary),
                        ),
                      ],
                      const SizedBox(height: 28),

                      if (!_isLogin) ...[
                        const Text('Your name (must be unique)', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppColors.lightTextPrimary, fontSize: 15),
                          onChanged: (val) {
                            if (_nameWarningMessage != null) {
                              setState(() => _nameWarningMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter your unique username',
                            hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.berryRose),
                            suffixIcon: _isValidatingName
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.berryRose,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (_nameWarningMessage != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _nameWarningMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      const Text('Email address', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.lightTextPrimary, fontSize: 15),
                        onChanged: (val) {
                          if (_emailWarningMessage != null || _emailSuggestion != null) {
                            setState(() {
                              _emailWarningMessage = null;
                              _emailSuggestion = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.berryRose),
                          suffixIcon: _isValidatingEmail
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.berryRose,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),

                      if (_emailWarningMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _emailWarningMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_emailSuggestion != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _emailController.text = _emailSuggestion!;
                              _emailWarningMessage = null;
                              _emailSuggestion = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.softBerryPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.berryRose.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_fix_high_rounded, color: AppColors.berryRose, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Did you mean $_emailSuggestion? Tap to fix',
                                    style: const TextStyle(
                                      color: AppColors.deepBerry,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.lightTextPrimary, fontSize: 15),
                        onChanged: (val) {
                          if (!_isLogin) {
                            setState(() {
                              _passwordStrength = val.isEmpty ? null : PasswordValidator.validate(val);
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.berryRose),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.berryRose),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      if (!_isLogin && _passwordStrength != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength!.strengthFraction,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrength!.strengthColor),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _passwordStrength!.strengthLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _passwordStrength!.strengthColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _buildRuleItem('8+ chars', _passwordStrength!.hasMinLength),
                            _buildRuleItem('Uppercase (A-Z)', _passwordStrength!.hasUppercase),
                            _buildRuleItem('Lowercase (a-z)', _passwordStrength!.hasLowercase),
                            _buildRuleItem('Number (0-9)', _passwordStrength!.hasDigit),
                            _buildRuleItem('Symbol (!@#\$)', _passwordStrength!.hasSpecialChar),
                          ],
                        ),
                      ],

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (authProvider.isLoading || _isValidatingEmail || _isValidatingName) ? null : _submit,
                          child: (authProvider.isLoading || _isValidatingEmail || _isValidatingName)
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isLogin = !_isLogin;
                            _nameWarningMessage = null;
                            _emailWarningMessage = null;
                            _emailSuggestion = null;
                            _passwordStrength = null;
                          }),
                          child: Text(
                            _isLogin ? 'New to SplitSync? Create account' : 'Already have an account? Sign in',
                            style: const TextStyle(color: AppColors.berryRose, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildRuleItem(String label, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? const Color(0xFF2E7D32) : Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            color: isMet ? const Color(0xFF2E7D32) : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
