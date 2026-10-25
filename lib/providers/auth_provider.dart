import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '316360807560-13oont88fdgjcu30cbcjn7mn5921vkp7.apps.googleusercontent.com',
  );

  User? _firebaseUser;
  UserModel? _userModel;
  StreamSubscription<UserModel?>? _userSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  bool _isSigningUp = false;
  Timer? _sessionCheckTimer;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  AuthProvider() {
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      final initialName = (_firebaseUser!.displayName != null && _firebaseUser!.displayName!.trim().isNotEmpty)
          ? _firebaseUser!.displayName!.trim()
          : (_firebaseUser!.email != null && _firebaseUser!.email!.contains('@')
              ? _firebaseUser!.email!.split('@').first
              : 'SplitSync User');
      _userModel = UserModel(
        uid: _firebaseUser!.uid,
        name: initialName,
        email: _firebaseUser!.email ?? '',
        avatarUrl: _firebaseUser!.photoURL ?? '',
        phone: _firebaseUser!.phoneNumber ?? '',
        createdAt: DateTime.now(),
      );
      _loadCachedAvatarAndSync(_firebaseUser!.uid);
      _startSessionValidationTimer();
      Future.microtask(() => validateCurrentSession());
    }
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _startSessionValidationTimer() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_firebaseUser != null && !_isSigningUp) {
        validateCurrentSession();
      }
    });
  }

  void _stopSessionValidationTimer() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
  }

  Future<void> _handleAccountDeleted([String? message]) async {
    debugPrint('Account deleted in Firebase: $message');
    _stopSessionValidationTimer();
    _userSubscription?.cancel();
    _userSubscription = null;

    final uid = _firebaseUser?.uid ?? _userModel?.uid;
    if (uid != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('splitsync_avatar_$uid');
        await prefs.remove('splitsync_user_status');
        await prefs.remove('splitsync_last_avatar');
      } catch (_) {}
    }

    _userModel = null;
    _firebaseUser = null;
    _errorMessage = message ?? 'Your account is deleted or no longer available.';

    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    notifyListeners();
  }

  /// Verifies with authentication service and database whether the current user still exists
  Future<bool> validateCurrentSession() async {
    final user = _auth.currentUser ?? _firebaseUser;
    if (user == null) {
      if (_firebaseUser != null || _userModel != null) {
        await _handleAccountDeleted('Your account is no longer available.');
      }
      return false;
    }

    if (_isSigningUp) return true;

    try {
      // 1. Force reload user state from authentication server
      await user.reload().timeout(const Duration(seconds: 5));
      final reloadedUser = _auth.currentUser;
      if (reloadedUser == null) {
        debugPrint('User is null after reload. Account was deleted.');
        await _handleAccountDeleted('Your account is deleted or no longer available.');
        return false;
      }
      _firebaseUser = reloadedUser;

      // 2. Also check if the user profile document still exists in database
      final firestoreUser = await FirestoreService.getUser(user.uid)
          .timeout(const Duration(seconds: 5));
      if (firestoreUser == null) {
        debugPrint('Document not found for ${user.uid}. Account was deleted.');
        await _handleAccountDeleted('Your account is deleted or no longer available.');
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during validateCurrentSession: ${e.code}');
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-user-token' ||
          e.code == 'token-expired' ||
          e.code == 'user-token-expired') {
        debugPrint('Account deleted/disabled (${e.code}). Logging out...');
        await _handleAccountDeleted('Your account is deleted or no longer available.');
        return false;
      }
      return true;
    } on TimeoutException {
      return true;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('user-not-found') || errStr.contains('no user record')) {
        await _handleAccountDeleted('Your account is deleted or no longer available.');
        return false;
      }
      return true;
    }
  }

  Future<void> _loadCachedAvatarAndSync(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAvatar = prefs.getString('splitsync_avatar_$uid') ?? '';
      if (cachedAvatar.isNotEmpty && (_userModel == null || _userModel!.avatarUrl.isEmpty)) {
        if (_userModel != null) {
          _userModel = _userModel!.copyWith(avatarUrl: cachedAvatar);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_isSigningUp) return;

    _firebaseUser = user;

    if (user != null) {
      _startSessionValidationTimer();

      final prefs = await SharedPreferences.getInstance();
      final cachedAvatar = prefs.getString('splitsync_avatar_${user.uid}') ??
          user.photoURL ??
          '';

      if (_userModel == null || _userModel!.uid != user.uid) {
        final initialName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : (user.email != null && user.email!.contains('@')
                ? user.email!.split('@').first
                : 'SplitSync User');
        _userModel = UserModel(
          uid: user.uid,
          name: initialName,
          email: user.email ?? '',
          avatarUrl: cachedAvatar,
          phone: user.phoneNumber ?? '',
          createdAt: DateTime.now(),
        );
      } else if (_userModel!.avatarUrl.isEmpty && cachedAvatar.isNotEmpty) {
        _userModel = _userModel!.copyWith(avatarUrl: cachedAvatar);
      }
      notifyListeners();

      // Listen to real-time changes on user document so avatar/name changes sync immediately
      _userSubscription?.cancel();
      _userSubscription = FirestoreService.streamUser(user.uid).listen((fetched) async {
        if (_isSigningUp) return;

        if (fetched == null) {
          debugPrint('User document stream received null for ${user.uid}. Verifying deletion...');
          try {
            final check = await FirestoreService.getUser(user.uid).timeout(const Duration(seconds: 3));
            if (check == null) {
              await _handleAccountDeleted('Your account is deleted or no longer available.');
              return;
            }
          } catch (_) {}
        } else {
          final p = await SharedPreferences.getInstance();
          final localAvatar = p.getString('splitsync_avatar_${user.uid}') ?? '';
          if (fetched.avatarUrl.isNotEmpty) {
            _userModel = fetched;
            await p.setString('splitsync_avatar_${user.uid}', fetched.avatarUrl);
          } else if (localAvatar.isNotEmpty) {
            _userModel = fetched.copyWith(avatarUrl: localAvatar);
            unawaited(FirestoreService.saveUser(_userModel!));
          } else {
            _userModel = fetched;
          }
          notifyListeners();
        }
      });

      try {
        final fetched = await FirestoreService.getUser(user.uid)
            .timeout(const Duration(seconds: 4));
        if (fetched != null) {
          final localAvatar = prefs.getString('splitsync_avatar_${user.uid}') ?? '';
          if (fetched.avatarUrl.isNotEmpty) {
            _userModel = fetched;
            await prefs.setString('splitsync_avatar_${user.uid}', fetched.avatarUrl);
          } else if (localAvatar.isNotEmpty) {
            _userModel = fetched.copyWith(avatarUrl: localAvatar);
            unawaited(FirestoreService.saveUser(_userModel!));
          } else {
            _userModel = fetched;
          }
          notifyListeners();
        } else {
          if (!_isSigningUp) {
            debugPrint('User document does not exist in Firestore for ${user.uid}. Account deleted.');
            await _handleAccountDeleted('Your account is deleted or no longer available.');
            return;
          }
        }
      } catch (e) {
        debugPrint('Error fetching user model: $e');
      }

      // Update FCM Token safely without clobbering other fields
      try {
        final token = await NotificationService.getFcmToken()
            .timeout(const Duration(seconds: 4));
        if (token != null && _userModel != null) {
          await FirestoreService.updateFcmToken(user.uid, token);
          _userModel = _userModel!.copyWith(fcmToken: token);
        }
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
      notifyListeners();

      // Run server check
      validateCurrentSession();
    } else {
      _stopSessionValidationTimer();
      _userSubscription?.cancel();
      _userSubscription = null;
      _userModel = null;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    debugPrint('FIREBASE SIGN IN STARTED');
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _firebaseUser = credential.user;
      if (_firebaseUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final cachedAvatar = prefs.getString('splitsync_avatar_${_firebaseUser!.uid}') ??
            _firebaseUser!.photoURL ??
            '';
        final initialName = (_firebaseUser!.displayName != null && _firebaseUser!.displayName!.trim().isNotEmpty)
            ? _firebaseUser!.displayName!.trim()
            : email.split('@').first;
        _userModel = UserModel(
          uid: _firebaseUser!.uid,
          name: initialName,
          email: _firebaseUser!.email ?? email,
          avatarUrl: cachedAvatar,
          createdAt: DateTime.now(),
        );
        notifyListeners();
        try {
          final fetched = await FirestoreService.getUser(_firebaseUser!.uid)
              .timeout(const Duration(seconds: 4));
          if (fetched != null) {
            if (fetched.avatarUrl.isNotEmpty) {
              _userModel = fetched;
              await prefs.setString('splitsync_avatar_${_firebaseUser!.uid}', fetched.avatarUrl);
            } else if (cachedAvatar.isNotEmpty) {
              _userModel = fetched.copyWith(avatarUrl: cachedAvatar);
              await FirestoreService.saveUser(_userModel!);
            } else {
              _userModel = fetched;
            }
          }
        } catch (_) {}
      }
      debugPrint('FIREBASE SIGN IN SUCCESS');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: ${e.code} - ${e.message}');
      _errorMessage = _getFriendlyFirebaseAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: $e');
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String name, String email, String password) async {
    debugPrint('FIREBASE SIGN IN STARTED');
    _setLoading(true);
    _isSigningUp = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential.user != null) {
        // Clear any previous cached avatar so newly registered user starts fresh with name initial
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('splitsync_last_avatar');
          await prefs.remove('splitsync_avatar_${credential.user!.uid}');
        } catch (_) {}

        await credential.user!.updateDisplayName(name.trim());
        try {
          await credential.user!.sendEmailVerification();
        } catch (e) {
          debugPrint('Error sending initial verification email: $e');
        }
        try {
          await credential.user!.reload();
        } catch (_) {}
        _firebaseUser = _auth.currentUser ?? credential.user;
        final newUser = UserModel(
          uid: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
          avatarUrl: '',
          createdAt: DateTime.now(),
        );
        _userModel = newUser;
        try {
          await FirestoreService.saveUser(newUser)
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
        _startSessionValidationTimer();
      }
      debugPrint('FIREBASE SIGN IN SUCCESS');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: ${e.code} - ${e.message}');
      _errorMessage = _getFriendlyFirebaseAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: $e');
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      return false;
    } finally {
      _isSigningUp = false;
    }
  }

  Future<bool> sendEmailVerification() async {
    try {
      if (_firebaseUser != null) {
        await _firebaseUser!.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error resending email verification: $e');
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      if (_firebaseUser != null) {
        await _firebaseUser!.reload();
        _firebaseUser = _auth.currentUser;
        notifyListeners();
        return _firebaseUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error reloading user: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('FIREBASE SIGN IN STARTED');
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('FIREBASE SIGN IN ERROR: Google Sign In cancelled or aborted');
        _errorMessage = 'Google Sign In was cancelled.';
        _setLoading(false);
        return false;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      _firebaseUser = userCredential.user;
      debugPrint('FIREBASE SIGN IN SUCCESS');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: ${e.code} - ${e.message}');
      _errorMessage = e.message ?? 'Google Sign In failed';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('FIREBASE SIGN IN ERROR: $e');
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('ApiException: 10')) {
        _errorMessage =
            'Google Sign In error (Code 10: SHA-1 fingerprint missing in Firebase Console). Please register your SHA-1 fingerprint.';
      } else if (errStr.contains('12500')) {
        _errorMessage =
            'Google Sign In error (Code 12500). Please ensure Support Email is set in Firebase Console.';
      } else {
        _errorMessage = 'Google Sign In failed: $e';
      }
      _setLoading(false);
      return false;
    }
  }

  String _getFriendlyFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'This email address does not exist. Please check your email or create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please check your password.';
      case 'invalid-credential':
        return 'This email does not exist or the password is incorrect. Please check your email or create an account.';
      case 'invalid-email':
        return 'The email address is badly formatted or does not exist.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Please sign in instead.';
      case 'weak-password':
        return 'The password provided is too weak (minimum 6 characters).';
      default:
        return e.message ?? 'Authentication failed (${e.code})';
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? upiId,
    String? avatarUrl,
    String? defaultCurrency,
    double? monthlyBudget,
  }) async {
    if (_userModel == null) return;
    _userModel = _userModel!.copyWith(
      name: name,
      phone: phone,
      upiId: upiId,
      avatarUrl: avatarUrl,
      defaultCurrency: defaultCurrency,
      monthlyBudget: monthlyBudget,
    );

    // Save avatar to SharedPreferences for instant restoration across sessions
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('splitsync_avatar_${_userModel!.uid}', avatarUrl);
      } catch (_) {}
    }

    if (name != null && name.trim().isNotEmpty && _auth.currentUser != null) {
      try {
        await _auth.currentUser!.updateDisplayName(name.trim());
      } catch (_) {}
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty && _auth.currentUser != null) {
      try {
        await _auth.currentUser!.updatePhotoURL(avatarUrl);
      } catch (_) {}
    }

    // Update the UI immediately.
    notifyListeners();
    await FirestoreService.saveUser(_userModel!);
  }

  Future<void> signOut() async {
    _stopSessionValidationTimer();
    _userSubscription?.cancel();
    _userSubscription = null;
    _userModel = null;
    _firebaseUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('splitsync_last_avatar');
    } catch (_) {}
    notifyListeners();
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<bool> deleteAccount() async {
    final user = _auth.currentUser ?? _firebaseUser;
    if (user == null) return false;
    _setLoading(true);
    try {
      final uid = user.uid;
      // 1. Delete user document from Firestore
      await FirestoreService.deleteUser(uid);

      // 2. Clear local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('splitsync_avatar_$uid');
      await prefs.remove('splitsync_user_status');
      await prefs.remove('splitsync_last_avatar');

      // 3. Delete Firebase Auth account
      await user.delete();

      _stopSessionValidationTimer();
      _userSubscription?.cancel();
      _userSubscription = null;
      _userModel = null;
      _firebaseUser = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error deleting account: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        _errorMessage = 'For security, please sign in again before deleting your account.';
      } else {
        _errorMessage = e.message ?? 'Failed to delete account.';
      }
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _errorMessage = 'An error occurred: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _stopSessionValidationTimer();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}
