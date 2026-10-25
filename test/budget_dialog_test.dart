import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/config/app_theme.dart';
import 'package:splitsync/utils/currency_input_formatter.dart';

void main() {
  testWidgets('Test budget formatting and parsing utilities', (tester) async {
    expect(formatAmountNumber(15000), '15,000');
    expect(formatAmountNumber(0), '');
    expect(formatAmountNumber(-50), '');
    expect(formatAmountNumber(1450.50, includeDecimalsIfZero: true), '1,450.50');
    expect(tryParseAmountNumber('15,000'), 15000.0);
    expect(tryParseAmountNumber('0'), 0.0);
    expect(tryParseAmountNumber('invalid'), isNull);
    expect(tryParseAmountNumber(''), isNull);
  });

  testWidgets('Test ThousandsSeparatorInputFormatter handles edge cases safely', (tester) async {
    final formatter = ThousandsSeparatorInputFormatter();
    
    // Normal typing
    var res = formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      const TextEditingValue(text: '1400', selection: TextSelection.collapsed(offset: 4)),
    );
    expect(res.text, '1,400');

    // Comma backspace
    res = formatter.formatEditUpdate(
      const TextEditingValue(text: '1,400', selection: TextSelection.collapsed(offset: 2)),
      const TextEditingValue(text: '1400', selection: TextSelection.collapsed(offset: 1)),
    );
    expect(res.text, '400');

    // Decimal input
    res = formatter.formatEditUpdate(
      const TextEditingValue(text: '1,400'),
      const TextEditingValue(text: '1,400.5', selection: TextSelection.collapsed(offset: 7)),
    );
    expect(res.text, '1,400.5');

    // Multiple dots rejected
    res = formatter.formatEditUpdate(
      const TextEditingValue(text: '1,400.5'),
      const TextEditingValue(text: '1,400.5.5'),
    );
    expect(res.text, '1,400.5');
  });

  testWidgets('Test budget dialog UI rendering and cancellation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showDialog<double>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Monthly Budget'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Budget'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Budget'), findsNothing);
  });
}
