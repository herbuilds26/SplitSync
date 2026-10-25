import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter that automatically adds thousand separators (commas) as the user types
/// numbers (e.g. typing 1400 becomes 1,400).
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter;
  final int maxDecimalDigits;

  ThousandsSeparatorInputFormatter({
    String locale = 'en_IN',
    this.maxDecimalDigits = 2,
  }) : _formatter = NumberFormat.decimalPattern(locale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    try {
      if (newValue.text.isEmpty) {
        return newValue;
      }

    String newText = newValue.text;
    int selectionIndex = newValue.selection.end;

    // Check if user hit backspace on a comma
    if (oldValue.text.length == newValue.text.length + 1 &&
        oldValue.selection.end > 0 &&
        oldValue.selection.end <= oldValue.text.length) {
      final deletedChar = oldValue.text[oldValue.selection.end - 1];
      if (deletedChar == ',') {
        final unformattedOld = oldValue.text.replaceAll(',', '');
        final commaIndexInOld = oldValue.selection.end - 1;
        int digitsBefore = 0;
        for (int i = 0; i < commaIndexInOld; i++) {
          if (oldValue.text[i] != ',') digitsBefore++;
        }
        if (digitsBefore > 0 && digitsBefore <= unformattedOld.length) {
          final adjusted = unformattedOld.substring(0, digitsBefore - 1) +
              unformattedOld.substring(digitsBefore);
          newText = adjusted;
          selectionIndex = commaIndexInOld - 1;
        }
      }
    }

    // Clean text: strip commas
    String clean = newText.replaceAll(',', '').trim();
    if (clean.isEmpty) {
      return const TextEditingValue(text: '');
    }

    if (clean.startsWith('.')) {
      clean = '0$clean';
      selectionIndex++;
    }

    // Disallow multiple decimal points
    final dotCount = '.'.allMatches(clean).length;
    if (dotCount > 1) {
      return oldValue;
    }

    // Check maximum decimal places
    if (dotCount == 1) {
      final parts = clean.split('.');
      if (parts.length > 1 && parts[1].length > maxDecimalDigits) {
        return oldValue;
      }
    }

    // Check only valid digits and optional decimal point
    if (!RegExp(r'^\d*(\.\d*)?$').hasMatch(clean)) {
      return oldValue;
    }

    final parts = clean.split('.');
    final integerPart = parts[0];
    final hasDot = clean.contains('.');
    final decimalPart = parts.length > 1 ? parts[1] : '';

    String formattedInt = '';
    if (integerPart.isNotEmpty) {
      final intVal = int.tryParse(integerPart);
      if (intVal != null) {
        formattedInt = _formatter.format(intVal);
      } else {
        formattedInt = integerPart;
      }
    } else if (hasDot) {
      formattedInt = '0';
    }

    final formattedText = hasDot
        ? '$formattedInt.$decimalPart'
        : formattedInt;

    // Calculate new cursor position by counting non-comma chars before cursor in newText
    int nonCommaCharsBeforeCursor = 0;
    for (int i = 0; i < selectionIndex && i < newText.length; i++) {
      if (newText[i] != ',') {
        nonCommaCharsBeforeCursor++;
      }
    }

    int newCursorPos = 0;
    int nonCommaCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (nonCommaCount >= nonCommaCharsBeforeCursor) {
        break;
      }
      if (formattedText[i] != ',') {
        nonCommaCount++;
      }
      newCursorPos = i + 1;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formattedText.length),
      ),
    );
    } catch (_) {
      return newValue;
    }
  }
}

/// Helper to format a double or integer into comma-separated text
String formatAmountNumber(num amount, {bool includeDecimalsIfZero = false}) {
  if (amount <= 0) return '';
  final formatter = NumberFormat.decimalPattern('en_IN');
  final isWhole = amount % 1 == 0;
  if (isWhole && !includeDecimalsIfZero) {
    return formatter.format(amount.toInt());
  } else {
    final intPart = formatter.format(amount.truncate());
    final decPart = ((amount - amount.truncate()) * 100).round().toString().padLeft(2, '0');
    return '$intPart.$decPart';
  }
}

/// Helper to safely parse any formatted amount string with commas to a nullable double
double? tryParseAmountNumber(String? text) {
  if (text == null) return null;
  final clean = text.replaceAll(',', '').trim();
  if (clean.isEmpty) return null;
  return double.tryParse(clean);
}

/// Helper to safely parse any formatted amount string with commas to a double
double parseAmountNumber(String? text) {
  if (text == null) return 0.0;
  final clean = text.replaceAll(',', '').trim();
  return double.tryParse(clean) ?? 0.0;
}
