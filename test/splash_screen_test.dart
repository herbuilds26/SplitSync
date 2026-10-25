import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/screens/splash/splash_screen.dart';

void main() {
  group('SplashScreen Animation & Navigation Tests', () {
    testWidgets('SplashScreen renders animated logo, title, and tagline cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            autoNavigate: false,
          ),
        ),
      );

      // Verify title and tagline are present
      expect(find.text('SplitSync'), findsOneWidget);
      expect(find.text('Your expenses, beautifully in sync'), findsOneWidget);

      // Pump animation frames to ensure no exceptions during animation lifecycle
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('SplitSync'), findsOneWidget);
    });

    testWidgets('SplashScreen navigates to destination widget upon animation completion', (tester) async {
      const destinationKey = Key('destination-page');

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(milliseconds: 500),
            autoNavigate: true,
            destination: Scaffold(
              key: destinationKey,
              body: Text('Destination Loaded'),
            ),
          ),
        ),
      );

      expect(find.text('SplitSync'), findsOneWidget);
      expect(find.byKey(destinationKey), findsNothing);

      // Advance clock past splash duration and transition
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Destination Loaded'), findsOneWidget);
    });

    testWidgets('Tapping the screen navigates immediately when entrance is completed', (tester) async {
      const destinationKey = Key('fast-forward-dest');

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(seconds: 10), // Long delay
            autoNavigate: true,
            destination: Scaffold(
              key: destinationKey,
              body: Text('Fast Forwarded'),
            ),
          ),
        ),
      );

      // Advance past entrance animation
      await tester.pump(const Duration(milliseconds: 1500));

      // Tap anywhere on the splash screen
      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      expect(find.byKey(destinationKey), findsOneWidget);
      expect(find.text('Fast Forwarded'), findsOneWidget);
    });
  });
}
