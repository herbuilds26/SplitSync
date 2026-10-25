import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitsync/models/user_model.dart';
import 'package:splitsync/providers/auth_provider.dart';
import 'package:splitsync/screens/auth/email_verification_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _checked = false;
  bool _resubmitted = false;

  bool get wasChecked => _checked;
  bool get wasResubmitted => _resubmitted;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  User? get firebaseUser => null;

  @override
  UserModel? get userModel => UserModel(
        uid: 'test-user',
        name: 'Alex',
        email: 'alex@example.com',
        avatarUrl: '',
        createdAt: DateTime.now(),
      );

  @override
  bool get isAuthenticated => true;

  @override
  bool get isEmailVerified => false;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> checkEmailVerified() async {
    _checked = true;
    notifyListeners();
    return false;
  }

  @override
  Future<bool> sendEmailVerification() async {
    _resubmitted = true;
    return true;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('EmailVerificationScreen renders link-based verification UI cleanly', (tester) async {
    final mockAuth = MockAuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuth,
        child: const MaterialApp(
          home: EmailVerificationScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify Title and Subtitle
    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text("We've sent a verification link to:"), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Open Email App'), findsOneWidget);
    expect(find.text("I've Verified My Email"), findsOneWidget);
    expect(find.text('Resend Email'), findsOneWidget);
    expect(find.text('Entered wrong email? Sign out & change email'), findsOneWidget);

    // Verify NO OTP / PIN boxes or removed badges/banners
    expect(find.text('Enter Verification Code'), findsNothing);
    expect(find.text('Sender: SplitSync Official'), findsNothing);
    expect(find.textContaining('check your spam'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    // Tap "I've Verified My Email"
    await tester.tap(find.text("I've Verified My Email"));
    await tester.pump();
    expect(mockAuth.wasChecked, isTrue);
  });
}
