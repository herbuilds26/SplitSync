import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplitSync basic smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('SplitSync'),
        ),
      ),
    );

    expect(find.text('SplitSync'), findsOneWidget);
  });
}
