import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/group_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirestoreService.enableOfflineSupport();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const SplitSyncApp(),
    ),
  );

  // Initialize background push notifications asynchronously so splash dismisses immediately
  unawaited(NotificationService.initialize());
}

class SplitSyncApp extends StatelessWidget {
  const SplitSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'SplitSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('kn')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _boundUserId;
  bool? _boundEmailVerified;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final uid = authProvider.firebaseUser?.uid;
    final isVerified = authProvider.isEmailVerified;

    if (uid != _boundUserId || isVerified != _boundEmailVerified) {
      _boundUserId = uid;
      _boundEmailVerified = isVerified;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final groups = context.read<GroupProvider>();
        final expenses = context.read<ExpenseProvider>();
        if (uid == null || !isVerified) {
          groups.stopListening();
          expenses.stopListening();
        } else {
          groups.listenToUserGroups(uid);
        }
      });
    }

    if (authProvider.isAuthenticated) {
      if (authProvider.isEmailVerified) {
        return const AppShell();
      } else {
        return const EmailVerificationScreen();
      }
    }

    return const AuthScreen();
  }
}
