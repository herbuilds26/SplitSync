import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/services/ai_receipt_scanner.dart';

void main() {
  group('AiReceiptScanner parseReceiptText Tests', () {
    test('Correctly extracts amount when Rupee is read as 7 with space', () {
      final res = AiReceiptScanner.parseReceiptText('Total: 7 500.00');
      expect(res.amount, 500.0);
    });

    test('Correctly extracts amount when Rupee is read as 7 without decimals', () {
      final res = AiReceiptScanner.parseReceiptText('Total: 7 500');
      expect(res.amount, 500.0);
    });

    test('Correctly extracts amount when Rupee is read as 7 with dot or dash', () {
      final res1 = AiReceiptScanner.parseReceiptText('Total: 7. 500.00');
      expect(res1.amount, 500.0);

      final res2 = AiReceiptScanner.parseReceiptText('Total: 7-500.00');
      expect(res2.amount, 500.0);

      final res3 = AiReceiptScanner.parseReceiptText('Total: 7/ 500');
      expect(res3.amount, 500.0);
    });

    test('Correctly extracts amount when total is multi-line', () {
      final res1 = AiReceiptScanner.parseReceiptText('TOTAL AMOUNT\n7 500.00');
      expect(res1.amount, 500.0);

      final res2 = AiReceiptScanner.parseReceiptText('TOTAL\n7\n500.00');
      expect(res2.amount, 500.0);
    });

    test('Correctly extracts amount with ₹ symbol', () {
      final res = AiReceiptScanner.parseReceiptText('Grand Total : ₹ 500.00');
      expect(res.amount, 500.0);
    });

    test('Correctly extracts amount with Indian notation /-', () {
      final res = AiReceiptScanner.parseReceiptText('Amount: 7 250/-');
      expect(res.amount, 250.0);
    });

    test('Correctly handles when Total label and 7 are on one line and digits on next', () {
      final res = AiReceiptScanner.parseReceiptText('TOTAL : 7\n500.00');
      expect(res.amount, 500.0);
    });

    test('Correctly handles small and large amounts with 7 currency artifact', () {
      expect(AiReceiptScanner.parseReceiptText('Total: 7 50').amount, 50.0);
      expect(AiReceiptScanner.parseReceiptText('Total: 7 70.50').amount, 70.50);
      expect(AiReceiptScanner.parseReceiptText('Total: 7 1200').amount, 1200.0);
      expect(AiReceiptScanner.parseReceiptText('Total: 7 99.99').amount, 99.99);
      expect(AiReceiptScanner.parseReceiptText('Total: 7 15000').amount, 15000.0);
    });

    test('Correctly handles other OCR glyph variations like ?, z, r for Rupee', () {
      expect(AiReceiptScanner.parseReceiptText('Total: ? 500.00').amount, 500.0);
      expect(AiReceiptScanner.parseReceiptText('Total: z 500.00').amount, 500.0);
      expect(AiReceiptScanner.parseReceiptText('Total: r 500.00').amount, 500.0);
    });

    test('Full fake bill scenario', () {
      const bill = '''
CAFE MINT
1x Cold Brew    150.00
1x Croissant    200.00
Subtotal        350.00
Tax              25.00
Total: 7 375.00
Thank you for visiting!
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 375.0);
      expect(res.category, 'Food');
    });

    test('Never picks dish amount over total in multi-column OCR', () {
      const bill = '''
SPICE BISTRO
Paneer Butter Masala
Garlic Naan
Jeera Rice
Total
280.00
60.00
140.00
480.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      // Must pick 480.0 (Grand Total), NOT 280.0 (Paneer Butter Masala)!
      expect(res.amount, 480.0);
    });

    test('Correctly extracts total from fake bill with dot leaders', () {
      const bill = '''
FOOD PARADISE
1. Chicken Biryani .......... 250.00
2. Chicken Tikka ............ 180.00
3. Roti 2x .................. 40.00
TOTAL AMOUNT ................ 470.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 470.0);
    });

    test('Correctly extracts total when table header has AMOUNT', () {
      const bill = '''
BURGER KING
ITEM DESCRIPTION   QTY   PRICE   AMOUNT
Whopper Meal        1    220.00  220.00
King Fries          1     90.00   90.00
TOTAL                            310.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 310.0);
    });

    test('Correctly extracts total with item count on total line', () {
      const bill = '''
DOMINOS PIZZA
1 Peppy Paneer     380.00
1 Garlic Bread     110.00
Total (2 Items) :  490.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 490.0);
    });

    test('Correctly extracts total when total is larger than any individual dish', () {
      const bill = '''
TASTY CORNER
Veg Fried Rice   160.00
Chilli Paneer    220.00
Grand Total      380.00
Cash Paid        500.00
Change Due       120.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 380.0);
    });

    test('Correctly extracts total from handwritten bill with Tot = 350/-', () {
      const bill = '''
TEA STALL
Tea 20
Idli 40
Vada 30
Dosa 70
Tot = 160/-
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 160.0);
    });

    test('Correctly extracts total from handwritten bill with G.Tot: 850/-', () {
      const bill = '''
KIRANA STORE
Sugar 85
Oil 190
Atta 75
Rice 500
G.Tot: 850/-
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 850.0);
    });

    test('Correctly extracts total from informal unwritten bill with separator line', () {
      const bill = '''
100
150
50
---
300
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 300.0);
    });

    test('Correctly resolves Rupee misread as 7 directly attached without space', () {
      const bill = '''
HOTEL UDUPI
Masala Dosa 120.00
Filter Coffee 40.00
Total 7160/-
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 160.0);
    });

    test('Correctly handles dollar symbol on bill', () {
      const bill = '''
COFFEE HOUSE
Espresso 15.00
Muffin 30.00
Total \$45.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 45.0);
    });

    test('Correctly handles Kannada total keyword ಒಟ್ಟು', () {
      const bill = '''
ಶಾಂತಿ ಸಾಗರ್
ಮಸಾಲೆ ದೋಸೆ 80.00
ಕಾಫಿ 30.00
ಒಟ್ಟು 110.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 110.0);
    });

    test('Never picks a single large dish amount over the grand total', () {
      const bill = '''
ROYAL DINE
Mutton Biryani  480.00
Thums Up         40.00
Raita            30.00
Net Payable     550.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 550.0);
    });

    test('Never picks tax lines at bottom over Grand Total', () {
      const bill = '''
HOTEL PARADISE
Chicken Biryani 240.00
Mutton Curry    320.00
Grand Total     560.00
CGST 2.5% Amt    14.00
SGST 2.5% Amt    14.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 560.0);
    });

    test('Never picks discount or savings line over Total Amount', () {
      const bill = '''
MEGA MART
T-Shirt 499.00
Jeans 899.00
Total Amount 1398.00
Savings Amt 200.00
You Saved 200.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 1398.0);
    });

    test('Never picks total items or total qty count over Total', () {
      const bill = '''
GROCERY STORE
Milk 32.00
Bread 45.00
Eggs 75.00
Total Items 3
Total 152.00
Total Qty 3
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 152.0);
    });

    test('Correctly preserves valid bills that start with digit 7 without stripping', () {
      const bill = '''
RESTAURANT BUFFET
Dinner Buffet 750.00
Total: 750.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 750.0);
    });

    test('Never picks cash tendered or change due over Net Payable', () {
      const bill = '''
CAFE CENTRAL
Cold Coffee 140.00
Veg Sandwich 90.00
Net Payable 230.00
Cash Tendered 500.00
Change Due 270.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 230.0);
    });

    test('Correctly extracts total when item rows have Amt column header', () {
      const bill = '''
DHABA JUNCTION
Item Name        Qty   Amt
Paneer Tikka      1   220.00
Dal Makhani       1   180.00
Total                 400.00
''';
      final res = AiReceiptScanner.parseReceiptText(bill);
      expect(res.amount, 400.0);
    });
  });
}


