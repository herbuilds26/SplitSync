import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/main.dart';

void main() {
  testWidgets('SplitSync launches with auth screen', (tester) async {
    await tester.pumpWidget(const SplitSyncApp());

    expect(find.text('SplitSync'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}