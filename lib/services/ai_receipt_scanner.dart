import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrResult {
  final double amount;
  final String title;
  final String category;
  final String rawText;

  ReceiptOcrResult({
    required this.amount,
    required this.title,
    required this.category,
    required this.rawText,
  });
}

class _AmountCandidate {
  final double amount;
  final int lineIndex;
  final String lineText;
  final double score;

  _AmountCandidate({
    required this.amount,
    required this.lineIndex,
    required this.lineText,
    required this.score,
  });
}

class AiReceiptScanner {
  /// Processes an image file, extracts text via ML Kit OCR, performs 2D spatial
  /// row reconstruction, and uses AI heuristics to parse total amount, vendor, and category.
  static Future<ReceiptOcrResult> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      // 1. Reconstruct spatially aligned lines from 2D bounding boxes (merges columns)
      final spatialLines = reconstructSpatialLines(recognizedText);

      // 2. Parse using spatially merged lines with rawText fallback
      return parseReceiptLines(spatialLines, recognizedText.text);
    } catch (e) {
      await textRecognizer.close();
      return ReceiptOcrResult(
        amount: 0.0,
        title: 'Receipt',
        category: 'Other',
        rawText: 'OCR failed: $e',
      );
    }
  }

  /// Parses raw text extracted from a bill/receipt image into structured information.
  static ReceiptOcrResult parseReceiptText(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return parseReceiptLines(lines, rawText);
  }

  /// Converts RecognizedText with 2D bounding boxes into spatially ordered lines.
  /// Merges horizontally aligned text elements (e.g. "Total" on left and "500.00" on right).
  static List<String> reconstructSpatialLines(RecognizedText recognizedText) {
    final List<TextLine> allLines = [];
    for (final block in recognizedText.blocks) {
      allLines.addAll(block.lines);
    }
    if (allLines.isEmpty) {
      return recognizedText.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
    }

    // Sort lines primarily by vertical center: (top + bottom) / 2
    allLines.sort((a, b) {
      final aCenter = (a.boundingBox.top + a.boundingBox.bottom) / 2;
      final bCenter = (b.boundingBox.top + b.boundingBox.bottom) / 2;
      return aCenter.compareTo(bCenter);
    });

    // Group lines that share roughly the same horizontal row (vertical overlap)
    final List<List<TextLine>> rows = [];
    for (final line in allLines) {
      final lineCenter = (line.boundingBox.top + line.boundingBox.bottom) / 2;
      final lineHeight = line.boundingBox.height;

      bool added = false;
      for (final row in rows) {
        final rowCenter = row
            .map((l) => (l.boundingBox.top + l.boundingBox.bottom) / 2)
            .reduce((a, b) => a + b) / row.length;
        final avgHeight = row
            .map((l) => l.boundingBox.height)
            .reduce((a, b) => a + b) / row.length;
        final tolerance = (lineHeight > 0 && avgHeight > 0)
            ? (lineHeight + avgHeight) / 4
            : 15.0;

        if ((lineCenter - rowCenter).abs() <= tolerance) {
          row.add(line);
          added = true;
          break;
        }
      }
      if (!added) {
        rows.add([line]);
      }
    }

    final List<String> mergedLines = [];
    for (final row in rows) {
      // Sort left to right within row
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final rowText = row.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join('  ');
      if (rowText.isNotEmpty) {
        mergedLines.add(rowText);
      }
    }

    return mergedLines;
  }

  /// Parses extracted lines into structured information.
  static ReceiptOcrResult parseReceiptLines(List<String> lines, String rawText) {
    String title = 'Scanned Receipt';
    String category = 'Other';

    // 1. Extract Vendor / Store Title (top non-trivial line)
    for (final line in lines) {
      if (line.length > 2 &&
          !RegExp(
            r'^(tax|total|subtotal|receipt|cash|card|date|invoice|bill|gst|order|\d+|[#:=])',
            caseSensitive: false,
          ).hasMatch(line)) {
        title = line;
        break;
      }
    }

    // 2. Infer Category based on keywords
    final lowerText = rawText.toLowerCase();
    if (lowerText.contains('restaurant') ||
        lowerText.contains('café') ||
        lowerText.contains('cafe') ||
        lowerText.contains('food') ||
        lowerText.contains('dinner') ||
        lowerText.contains('lunch') ||
        lowerText.contains('pizza') ||
        lowerText.contains('kitchen') ||
        lowerText.contains('burger') ||
        lowerText.contains('coffee') ||
        lowerText.contains('bake') ||
        lowerText.contains('brew')) {
      category = 'Food';
    } else if (lowerText.contains('market') ||
        lowerText.contains('grocery') ||
        lowerText.contains('supermarket') ||
        lowerText.contains('mart') ||
        lowerText.contains('store') ||
        lowerText.contains('provisions')) {
      category = 'Groceries';
    } else if (lowerText.contains('fuel') ||
        lowerText.contains('petrol') ||
        lowerText.contains('gas') ||
        lowerText.contains('cab') ||
        lowerText.contains('uber') ||
        lowerText.contains('ola') ||
        lowerText.contains('transport') ||
        lowerText.contains('toll')) {
      category = 'Fuel & Transport';
    } else if (lowerText.contains('mall') ||
        lowerText.contains('apparel') ||
        lowerText.contains('fashion') ||
        lowerText.contains('cloth') ||
        lowerText.contains('clothing') ||
        lowerText.contains('shopping') ||
        lowerText.contains('retail')) {
      category = 'Shopping';
    } else if (lowerText.contains('bill') ||
        lowerText.contains('electric') ||
        lowerText.contains('utility') ||
        lowerText.contains('water') ||
        lowerText.contains('power') ||
        lowerText.contains('internet') ||
        lowerText.contains('broadband')) {
      category = 'Bills & Utilities';
    }

    // 3. Extract Total Amount
    final extractedAmount = _extractTotalAmount(lines);

    return ReceiptOcrResult(
      amount: extractedAmount,
      title: title,
      category: category,
      rawText: rawText,
    );
  }

  // --- Regex Definitions ---

  static final RegExp _grandTotalRegex = RegExp(
    r'\b(?:grand\s*total|g\.?\s*total|g\.?\s*tot|net\s*total|net\s*amount|net\s*payable|net\s*amt|final\s*total|final\s*amt|final\s*amount|bill\s*total|bill\s*amount|b\.?\s*amt|amount\s*payable|total\s*payable|total\s*due|balance\s*due|total\s*bill|to\s*pay|total\s*inr|total\s*rs|tot\s*rs|tot\s*inr|total\s*amt|total\s*amount|total\s*paid|net\s*paid|ಒಟ್ಟು|ಮೊತ್ತ|कुल\s*राशि|कुल\s*योग|कुल)\b',
    caseSensitive: false,
  );

  static final RegExp _standaloneTotalRegex = RegExp(
    r'\b(?:total|tot|ttl)\b',
    caseSensitive: false,
  );

  static final RegExp _subtotalRegex = RegExp(
    r'\b(?:sub\s*total|subtotal|sub\s*tot|item\s*total)\b',
    caseSensitive: false,
  );

  static final RegExp _taxLineRegex = RegExp(
    r'\b(?:cgst|sgst|igst|vat|tax|cess|gst|service\s*tax|stax)\b',
    caseSensitive: false,
  );

  static final RegExp _discountLineRegex = RegExp(
    r'\b(?:discount|disc|saved|saving|savings|you\s*saved|coupon|cashback|cash\s*back|rebate|off\b)',
    caseSensitive: false,
  );

  static final RegExp _itemsCountRegex = RegExp(
    r'\b(?:total\s*(?:items?|qty|quantit(?:y|ies)|pcs|pieces|nos|count)|items?\s*count|qty\s*count|nos\s*count)\b',
    caseSensitive: false,
  );

  static final RegExp _dishItemRegex = RegExp(
    r'\b(?:chicken|paneer|biryani|pizza|burger|curry|naan|roti|rice|dal|dosa|idli|vada|sambar|coffee|tea|brew|drink|coke|pepsi|water|beverage|juice|shake|fries|roll|sandwich|pasta|salad|soup|dessert|cake|ice\s*cream|gravy|tikka|masala|chilli|fried|combo|meal|plate|cup|qty|nos|pcs|kg|gm|gram|thali|paratha|bhature|chole|sweets|mithai|snack|biscuits|bread|milk|butter|cheese|egg|fish|mutton|prawn|noodle|manchurian|momos|chaat|puri|bhel|sev|lassi|shirt|pant|jeans|cloth|medicine|tablet|syrup)\b|\b\d+\s*[xX]\b|\b[xX]\s*\d+\b|^\s*\d+[\s\.\-]+[A-Za-z]',
    caseSensitive: false,
  );

  static final RegExp _tableHeaderRegex = RegExp(
    r'\b(?:item|items|particulars|description|sr\.?\s*no|sn|sl\.?\s*no)\b.*\b(?:qty|rate|price|amount|mrp|amt)\b',
    caseSensitive: false,
  );

  static final RegExp _paymentTenderedRegex = RegExp(
    r'\b(?:cash\s+paid|cash\s+tendered|cash\s+recd|cash\s+received|cash\s+tender|tendered|change\s+due|change\s+returned|change\b|balance\s+returned|bal\s+returned|refund|upi\s+ref|card\s+payment|card\s+recd|card\s+swipe|auth\s*code|approval\s*code)\b',
    caseSensitive: false,
  );

  static final RegExp _separatorLineRegex = RegExp(
    r'^[_\-=\.]{2,}$',
  );

  /// Advanced multi-signal candidate scoring total extraction.
  static double _extractTotalAmount(List<String> lines) {
    if (lines.isEmpty) return 0.0;

    final List<double> allAmounts = [];
    final List<double> itemAmounts = [];

    // Collect all valid monetary amounts across the receipt
    for (final line in lines) {
      if (_paymentTenderedRegex.hasMatch(line) && !_grandTotalRegex.hasMatch(line)) {
        continue;
      }
      final amounts = _extractAmountsFromLine(line);
      allAmounts.addAll(amounts);

      // Collect pure item amounts (ignoring headers, tax, subtotal, and totals)
      if (!_grandTotalRegex.hasMatch(line) &&
          !_standaloneTotalRegex.hasMatch(line) &&
          !_subtotalRegex.hasMatch(line) &&
          !_taxLineRegex.hasMatch(line) &&
          !_discountLineRegex.hasMatch(line) &&
          !_itemsCountRegex.hasMatch(line) &&
          !_tableHeaderRegex.hasMatch(line)) {
        itemAmounts.addAll(amounts);
      }
    }

    final double maxOverallAmount = allAmounts.isNotEmpty
        ? allAmounts.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final double maxItemAmount = itemAmounts.isNotEmpty
        ? itemAmounts.reduce((a, b) => a > b ? a : b)
        : 0.0;

    final List<_AmountCandidate> candidates = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineAmounts = _extractAmountsFromLine(line);

      // Check immediate preceding lines for total labels (multi-line OCR)
      final prev1 = i > 0 ? lines[i - 1] : '';
      final prev2 = i > 1 ? lines[i - 2] : '';

      final bool isGrandTotalLine = _grandTotalRegex.hasMatch(line) &&
          !_taxLineRegex.hasMatch(line) &&
          !_discountLineRegex.hasMatch(line) &&
          !_itemsCountRegex.hasMatch(line) &&
          !_paymentTenderedRegex.hasMatch(line) &&
          !_tableHeaderRegex.hasMatch(line);

      final bool isStandaloneTotalLine = _standaloneTotalRegex.hasMatch(line) &&
          !_subtotalRegex.hasMatch(line) &&
          !_taxLineRegex.hasMatch(line) &&
          !_discountLineRegex.hasMatch(line) &&
          !_itemsCountRegex.hasMatch(line) &&
          !_paymentTenderedRegex.hasMatch(line) &&
          !_tableHeaderRegex.hasMatch(line);

      final bool isSubtotalLine = _subtotalRegex.hasMatch(line) &&
          !_taxLineRegex.hasMatch(line) &&
          !_discountLineRegex.hasMatch(line);

      final bool prev1IsGrandTotal = _grandTotalRegex.hasMatch(prev1) &&
          !_taxLineRegex.hasMatch(prev1) &&
          !_discountLineRegex.hasMatch(prev1);

      final bool prev1IsTotal = _standaloneTotalRegex.hasMatch(prev1) &&
          !_subtotalRegex.hasMatch(prev1) &&
          !_taxLineRegex.hasMatch(prev1) &&
          !_discountLineRegex.hasMatch(prev1);

      final bool prev2IsGrandTotal = _grandTotalRegex.hasMatch(prev2) &&
          !_taxLineRegex.hasMatch(prev2) &&
          !_discountLineRegex.hasMatch(prev2);

      final bool isSeparatorAbove = _separatorLineRegex.hasMatch(prev1.trim()) ||
          _separatorLineRegex.hasMatch(prev2.trim());

      final bool isTaxLine = _taxLineRegex.hasMatch(line);
      final bool isDiscountLine = _discountLineRegex.hasMatch(line);
      final bool isItemsCountLine = _itemsCountRegex.hasMatch(line);
      final bool isPaymentLine = _paymentTenderedRegex.hasMatch(line);
      final bool isTableHeader = _tableHeaderRegex.hasMatch(line);
      final bool isDishLine = _dishItemRegex.hasMatch(line);

      for (final rawAmt in lineAmounts) {
        final amt = _resolveRupeeArtifactCandidate(rawAmt, itemAmounts);
        double score = 0.0;

        // 1. Keyword context
        if (isGrandTotalLine) {
          score += 200.0;
        } else if (prev1IsGrandTotal) {
          score += 180.0;
        } else if (prev2IsGrandTotal) {
          score += 150.0;
        } else if (isStandaloneTotalLine) {
          score += 130.0;
        } else if (prev1IsTotal) {
          score += 110.0;
        } else if (isSubtotalLine) {
          score += 55.0;
        }

        // 2. Separator line context
        if (isSeparatorAbove && !isDishLine) {
          score += 35.0;
        }

        // 3. Negative keyword penalties
        if (isTaxLine) score -= 250.0;
        if (isDiscountLine) score -= 250.0;
        if (isItemsCountLine) score -= 250.0;
        if (isPaymentLine && !isGrandTotalLine) score -= 180.0;
        if (isTableHeader) score -= 150.0;
        if (isDishLine) score -= 90.0;

        // 4. Position score (Grand total is almost always near bottom)
        final positionFraction = lines.length > 1 ? i / (lines.length - 1) : 0.5;
        score += positionFraction * 30.0;

        // 5. Magnitude and Item Price Consistency
        // The total must be >= max individual dish item!
        if (maxItemAmount > 0 && amt < maxItemAmount) {
          score -= 100.0;
        }

        // Maximum monetary amount bonus
        if (amt == maxOverallAmount && !isPaymentLine) {
          score += 45.0;
        }

        candidates.add(_AmountCandidate(
          amount: amt,
          lineIndex: i,
          lineText: line,
          score: score,
        ));
      }
    }

    // Mathematical sum match bonus: does candidate equal sum of individual items?
    if (itemAmounts.length >= 2) {
      final sumItems = itemAmounts.fold(0.0, (sum, a) => sum + a);
      if (sumItems > 0) {
        for (int c = 0; c < candidates.length; c++) {
          final cand = candidates[c];
          final diff = (cand.amount - sumItems).abs();
          if (diff <= 1.0 || diff / sumItems <= 0.05) {
            candidates[c] = _AmountCandidate(
              amount: cand.amount,
              lineIndex: cand.lineIndex,
              lineText: cand.lineText,
              score: cand.score + 60.0,
            );
          }
        }
      }
    }

    // Sort candidates by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));

    if (candidates.isNotEmpty && candidates.first.score > 0) {
      return candidates.first.amount;
    }

    // Fallback: If no candidate scored positively, check mathematical sum
    if (itemAmounts.length >= 2) {
      final mathTotal = _findMathematicalSumTotal(allAmounts, itemAmounts);
      if (mathTotal != null && mathTotal > 0) {
        return mathTotal;
      }
    }

    // Ultimate fallback: max monetary amount on receipt
    return _resolveRupeeArtifactCandidate(maxOverallAmount, itemAmounts);
  }

  /// Resolves whether a candidate number like 7450 on a total line is
  /// actually 450 where '7' was a misread '₹' symbol.
  static double _resolveRupeeArtifactCandidate(double candidate, List<double> otherAmounts) {
    if (candidate < 70) return candidate;
    final isWhole = candidate.truncateToDouble() == candidate;
    final str = candidate.toStringAsFixed(isWhole ? 0 : 2);
    if (!str.startsWith('7')) return candidate;

    final strippedStr = str.substring(1);
    final stripped = double.tryParse(strippedStr);
    if (stripped == null || stripped <= 0) return candidate;

    if (otherAmounts.isNotEmpty) {
      final sumOthers = otherAmounts.fold(0.0, (sum, a) => sum + a);
      final maxOther = otherAmounts.reduce((a, b) => a > b ? a : b);

      // Only strip 7 if stripped amount closely matches sum of items or max item
      if ((sumOthers - stripped).abs() <= 5.0 ||
          (sumOthers > 0 && (sumOthers - stripped).abs() / sumOthers < 0.08) ||
          (stripped - maxOther).abs() <= 1.0) {
        return stripped;
      }
    }

    return candidate;
  }

  /// Checks if one of the candidate totals is the mathematical sum of the individual
  /// items on the receipt (with or without taxes/discounts).
  static double? _findMathematicalSumTotal(List<double> candidateTotals, List<double> itemAmounts) {
    if (itemAmounts.length < 2) return null;

    final sumItems = itemAmounts.fold(0.0, (sum, a) => sum + a);
    if (sumItems <= 0) return null;

    for (final candidate in candidateTotals) {
      final diff = (candidate - sumItems).abs();
      if (diff <= 1.0 || diff / sumItems <= 0.05) {
        return candidate;
      }

      final stripped = _resolveRupeeArtifactCandidate(candidate, itemAmounts);
      if (stripped != candidate) {
        final diffStripped = (stripped - sumItems).abs();
        if (diffStripped <= 1.0 || diffStripped / sumItems <= 0.05) {
          return stripped;
        }
      }
    }
    return null;
  }

  /// Extracts all valid monetary amounts from a line of text, handling:
  /// - Indian Rupee `₹` misread as `7`, `?`, `z`, `r` with spaces or separators
  /// - Indian notation `/-`, `/=`
  /// - Currency symbols `$`, `€`, `£`, `Rs.`, `INR`
  /// - Dot leaders (`..........`), dashes (`----------`), parenthetical item counts
  /// - Stripping dates, times, phone numbers, and IDs
  static List<double> _extractAmountsFromLine(String line) {
    var s = line.trim();
    if (s.isEmpty) return [];

    // 1. Filter out date patterns (e.g. 23/09/2026, 23-09-2026, 2026.09.23, 23.09.26)
    s = s.replaceAll(RegExp(r'\b\d{1,4}[/\-.]\d{1,2}[/\-.]\d{2,4}\b'), ' ');

    // 2. Filter out time patterns (e.g. 12:30:45, 14:30 PM, 2:30pm)
    s = s.replaceAll(RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?(?:\s*[AaPp][Mm])?\b'), ' ');

    // 3. Filter out phone numbers / long serials (7+ continuous digits without decimals, e.g. 9876543210, 1002345)
    s = s.replaceAll(RegExp(r'\b\d{7,}\b'), ' ');

    // 4. Filter out table/bill/order/invoice number labels with their ID (e.g. "Table 4", "Order #123", "Bill No: 45")
    s = s.replaceAll(
      RegExp(r'\b(?:table|order|bill\s+no|invoice\s+no|token|counter|receipt\s+no|tax\s+invoice|tin|gstin|fssai|inv)\s*[:#\-]?\s*\d+\b', caseSensitive: false),
      ' ',
    );

    // 5. Filter out item quantity/count parentheticals (e.g. "(3 items)", "Qty: 2", "Total items 4")
    s = s.replaceAll(RegExp(r'\b(?:items?|qty|nos|pcs|count)\s*[:#\-]?\s*\d+\b|\b\d+\s*(?:items?|nos|pcs)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\(\s*\d+\s*(?:items?|qty|nos)?\s*\)', caseSensitive: false), ' ');

    // 6. Handle Rupee and other currency symbol OCR artifacts:
    // When Indian notation /-, /= is present with leading 7 (e.g. "7450/-" -> "450", "71250/-" -> "1250", "750/-" -> "50")
    s = s.replaceAllMapped(
      RegExp(r'(?:^|(?<=\s|[A-Za-z:=]))[7?zZrRFf](\d{2,}(?:\.\d{1,2})?)\s*(?:[\/\\][-=]|\/+)'),
      (m) => ' ${m.group(1)} ',
    );

    // When 7 / ? / z / r / F / R is followed by space/separator and digits (e.g. "7 450.00", "7. 450", "7-450", "z 500")
    s = s.replaceAllMapped(
      RegExp(r'(?:^|(?<=\s|[A-Za-z:=]))[7?zZrRFf](?:\s*[:.\-\/]\s*|\s+)(?=\d)', caseSensitive: false),
      (m) => '',
    );

    // When directly attached currency keywords/symbols precede digits (e.g. "₹450", "Rs450", "Rs.450", "$50", "INR500")
    s = s.replaceAll(
      RegExp(r'(?:^|(?<=\s|[A-Za-z:=]))(?:₹|\$|€|£|Rs\.?|INR|USD|EUR|GBP)\s*(?=\d)', caseSensitive: false),
      ' ',
    );

    // Strip Indian notation /-, /=, /
    s = s.replaceAll(RegExp(r'[\/\\][-=]|\/+$'), ' ');

    // Replace dot leaders and dashes with spaces
    s = s.replaceAll(RegExp(r'[.\-_=]{2,}'), ' ');

    final List<double> amounts = [];
    final numberRegex = RegExp(r'\b\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?\b|\b\d+(?:\.\d{1,2})?\b');
    for (final match in numberRegex.allMatches(s)) {
      var numStr = match.group(0)!;
      numStr = numStr.replaceAll(',', '');
      final val = double.tryParse(numStr);
      if (val != null && val > 0 && val < 500000) {
        // Discard isolated small integers 0-9 without decimals (likely item quantities or counts like "1", "2")
        // unless it has explicit decimals (like 5.50 or 7.00)
        if (val >= 10 || numStr.contains('.')) {
          amounts.add(val);
        }
      }
    }
    return amounts;
  }
}
