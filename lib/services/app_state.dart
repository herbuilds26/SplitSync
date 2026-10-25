import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  void checkUser() {
    final user = _auth.currentUser;

    isAuthenticated.value = user != null;

    if (user != null) {
      userName.value = user.displayName ?? 'Member';
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    userName.value = name;
    isAuthenticated.value = true;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    userName.value =
        credential.user?.displayName ?? 'Member';

    isAuthenticated.value = true;
  }

  Future<void> signOut() async {
    await _auth.signOut();

    userName.value = '';
    isAuthenticated.value = false;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }
}
