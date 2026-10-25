import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/utils/currency_input_formatter.dart';

void main() {
  group('ThousandsSeparatorInputFormatter Tests', () {
    final formatter = ThousandsSeparatorInputFormatter();

    test('Formats 1400 into 1,400 automatically', () {
      const oldValue = TextEditingValue(text: '140', selection: TextSelection.collapsed(offset: 3));
      const newValue = TextEditingValue(text: '1400', selection: TextSelection.collapsed(offset: 4));
      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('1,400'));
      expect(result.selection.end, equals(5)); // Cursor at the end after the comma
    });

    test('Formats smaller numbers without commas', () {
      const oldValue = TextEditingValue(text: '14', selection: TextSelection.collapsed(offset: 2));
      const newValue = TextEditingValue(text: '140', selection: TextSelection.collapsed(offset: 3));
      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('140'));
      expect(result.selection.end, equals(3));
    });

    test('Formats 14000 into 14,000 and 140000 into 1,40,000', () {
      const v1 = TextEditingValue(text: '14000', selection: TextSelection.collapsed(offset: 5));
      expect(formatter.formatEditUpdate(TextEditingValue.empty, v1).text, equals('14,000'));

      const v2 = TextEditingValue(text: '140000', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(TextEditingValue.empty, v2).text, equals('1,40,000'));
    });

    test('Preserves decimal point and digits e.g. 1,400.50', () {
      const v = TextEditingValue(text: '1400.5', selection: TextSelection.collapsed(offset: 6));
      final result = formatter.formatEditUpdate(TextEditingValue.empty, v);
      expect(result.text, equals('1,400.5'));

      const v2 = TextEditingValue(text: '1400.50', selection: TextSelection.collapsed(offset: 7));
      final result2 = formatter.formatEditUpdate(TextEditingValue.empty, v2);
      expect(result2.text, equals('1,400.50'));
    });

    test('Rejects typing more than 2 decimal digits', () {
      const oldValue = TextEditingValue(text: '1,400.50', selection: TextSelection.collapsed(offset: 8));
      const newValue = TextEditingValue(text: '1,400.509', selection: TextSelection.collapsed(offset: 9));
      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('1,400.50')); // Rejects 3rd decimal
    });

    test('Handles typing a leading decimal point', () {
      const newValue = TextEditingValue(text: '.5', selection: TextSelection.collapsed(offset: 2));
      final result = formatter.formatEditUpdate(TextEditingValue.empty, newValue);

      expect(result.text, equals('0.5'));
    });

    test('Deletes digit before comma when backspacing comma', () {
      // User has 1,400 with cursor right after comma (offset 2) and hits backspace
      const oldValue = TextEditingValue(text: '1,400', selection: TextSelection.collapsed(offset: 2));
      const newValue = TextEditingValue(text: '1400', selection: TextSelection.collapsed(offset: 1));
      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('400'));
    });
  });

  group('formatAmountNumber and parseAmountNumber Helpers', () {
    test('formatAmountNumber formats integers with commas', () {
      expect(formatAmountNumber(1400), equals('1,400'));
      expect(formatAmountNumber(14000), equals('14,000'));
      expect(formatAmountNumber(140000), equals('1,40,000'));
      expect(formatAmountNumber(100), equals('100'));
    });

    test('formatAmountNumber formats decimals with commas', () {
      expect(formatAmountNumber(1400.5), equals('1,400.50'));
      expect(formatAmountNumber(1400.75), equals('1,400.75'));
    });

    test('parseAmountNumber safely parses comma strings', () {
      expect(parseAmountNumber('1,400'), equals(1400.0));
      expect(parseAmountNumber('1,40,000'), equals(140000.0));
      expect(parseAmountNumber('1,400.50'), equals(1400.50));
      expect(parseAmountNumber(''), equals(0.0));
      expect(parseAmountNumber(null), equals(0.0));
    });

    test('tryParseAmountNumber safely returns null on empty or invalid', () {
      expect(tryParseAmountNumber('1,400'), equals(1400.0));
      expect(tryParseAmountNumber('1,400.50'), equals(1400.50));
      expect(tryParseAmountNumber(''), isNull);
      expect(tryParseAmountNumber(null), isNull);
      expect(tryParseAmountNumber('abc'), isNull);
    });
  });
}
