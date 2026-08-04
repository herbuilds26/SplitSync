import 'package:flutter/foundation.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  final ValueNotifier<String> selectedScreen = ValueNotifier<String>('home');

  void signIn() {
    isAuthenticated.value = true;
  }

  void signOut() {
    isAuthenticated.value = false;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }
}
