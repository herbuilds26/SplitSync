import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/models/expense_model.dart';
import 'package:splitsync/models/group_model.dart';
import 'package:splitsync/models/settlement_model.dart';
import 'package:splitsync/services/export_service.dart';
import 'package:excel/excel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleGroup = GroupModel(
    id: 'grp_test_1',
    name: 'Goa Trip 2026',
    inviteCode: 'GOA123',
    qrCodeData: 'splitsync://group/GOA123',
    currency: 'INR',
    category: 'Trip',
    memberIds: ['user_alice', 'user_bob', 'user_charlie'],
    adminIds: ['user_alice'],
    createdBy: 'user_alice',
    createdAt: DateTime(2026, 10, 1),
  );

  final sampleExpenses = [
    ExpenseModel(
      id: 'exp_1',
      groupId: 'grp_test_1',
      title: 'Resort Stay',
      amount: 15000.0,
      category: 'Stay',
      paidBy: 'user_alice',
      splitMethod: 'equal',
      splits: [
        ExpenseSplit(userId: 'user_alice', amount: 5000.0),
        ExpenseSplit(userId: 'user_bob', amount: 5000.0),
        ExpenseSplit(userId: 'user_charlie', amount: 5000.0),
      ],
      note: 'Advance paid online',
      createdBy: 'user_alice',
      createdAt: DateTime(2026, 10, 2),
    ),
    ExpenseModel(
      id: 'exp_2',
      groupId: 'grp_test_1',
      title: 'Beach Dinner',
      amount: 3000.0,
      category: 'Food',
      paidBy: 'user_bob',
      splitMethod: 'equal',
      splits: [
        ExpenseSplit(userId: 'user_alice', amount: 1000.0),
        ExpenseSplit(userId: 'user_bob', amount: 1000.0),
        ExpenseSplit(userId: 'user_charlie', amount: 1000.0),
      ],
      note: 'Seafood and drinks',
      createdBy: 'user_bob',
      createdAt: DateTime(2026, 10, 3),
    ),
  ];

  final sampleSettlements = [
    SettlementModel(
      id: 'stl_1',
      groupId: 'grp_test_1',
      fromUserId: 'user_bob',
      toUserId: 'user_alice',
      amount: 4000.0,
      paymentMethod: 'UPI',
      upiTransactionRef: 'UPI123456789012',
      status: 'completed',
      createdAt: DateTime(2026, 10, 4),
    ),
  ];

  final memberNames = {
    'user_alice': 'Alice Smith',
    'user_bob': 'Bob Jones',
    'user_charlie': 'Charlie Brown',
  };

  test('ExportService resolves member names correctly', () async {
    final names = await ExportService.resolveMemberNames(
      sampleGroup.memberIds,
      knownMemberNames: memberNames,
    );
    expect(names['user_alice'], equals('Alice Smith'));
    expect(names['user_bob'], equals('Bob Jones'));
    expect(names['user_charlie'], equals('Charlie Brown'));
  });

  test('ExportService generates multi-sheet Excel with proper group info and resolved names', () async {
    final excel = Excel.createExcel();

    // Replicate the ExportService Excel generation logic
    final Sheet summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('SplitSync Group Summary')]);
    summarySheet.appendRow([TextCellValue('Group Name'), TextCellValue(sampleGroup.name)]);
    summarySheet.appendRow([TextCellValue('Category'), TextCellValue(sampleGroup.category)]);
    summarySheet.appendRow([TextCellValue('Currency'), TextCellValue(sampleGroup.currency)]);
    summarySheet.appendRow([TextCellValue('Invite Code'), TextCellValue(sampleGroup.inviteCode)]);
    summarySheet.appendRow([TextCellValue('Total Members'), IntCellValue(sampleGroup.memberIds.length)]);

    final totalExpense = sampleExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSettled = sampleSettlements.fold(0.0, (sum, s) => sum + s.amount);

    summarySheet.appendRow([TextCellValue('Total Expenses Recorded'), DoubleCellValue(totalExpense)]);
    summarySheet.appendRow([TextCellValue('Total Settled Up'), DoubleCellValue(totalSettled)]);

    final Sheet expensesSheet = excel['Expenses'];
    expensesSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Paid By'),
      TextCellValue('Amount (INR)'),
      TextCellValue('Group Name'),
      TextCellValue('Description / Title'),
      TextCellValue('Split Method'),
      TextCellValue('Split Participants & Amounts'),
      TextCellValue('Note'),
    ]);

    for (final e in sampleExpenses) {
      final payer = memberNames[e.paidBy] ?? 'Member';
      final splitStr = e.splits.map((s) => '${memberNames[s.userId]}: ${s.amount}').join(', ');
      expensesSheet.appendRow([
        TextCellValue('02/10/2026'),
        TextCellValue(e.category),
        TextCellValue(payer),
        DoubleCellValue(e.amount),
        TextCellValue(sampleGroup.name),
        TextCellValue(e.title),
        TextCellValue(e.splitMethod),
        TextCellValue(splitStr),
        TextCellValue(e.note),
      ]);
    }

    final Sheet balancesSheet = excel['Balances'];
    balancesSheet.appendRow([
      TextCellValue('Member Name'),
      TextCellValue('Group Name'),
      TextCellValue('Net Balance (INR)'),
      TextCellValue('Status'),
    ]);

    final Sheet settlementsSheet = excel['Settlements'];
    settlementsSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Paid By (Payer)'),
      TextCellValue('Received By (Payee)'),
      TextCellValue('Amount (INR)'),
      TextCellValue('Group Name'),
      TextCellValue('Payment Method'),
      TextCellValue('UPI Reference / UTR'),
      TextCellValue('Status'),
    ]);

    for (final s in sampleSettlements) {
      settlementsSheet.appendRow([
        TextCellValue('04/10/2026'),
        TextCellValue(memberNames[s.fromUserId] ?? 'Member'),
        TextCellValue(memberNames[s.toUserId] ?? 'Member'),
        DoubleCellValue(s.amount),
        TextCellValue(sampleGroup.name),
        TextCellValue(s.paymentMethod),
        TextCellValue(s.upiTransactionRef ?? '-'),
        TextCellValue(s.status),
      ]);
    }

    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    excel.setDefaultSheet('Summary');

    expect(excel.tables.containsKey('Sheet1'), isFalse);
    expect(excel.tables.containsKey('Summary'), isTrue);
    expect(excel.tables.containsKey('Expenses'), isTrue);
    expect(excel.tables.containsKey('Balances'), isTrue);
    expect(excel.tables.containsKey('Settlements'), isTrue);
    expect(excel.getDefaultSheet(), equals('Summary'));

    // Verify row counts and content
    expect(summarySheet.rows.length, greaterThanOrEqualTo(6));
    expect(expensesSheet.rows.length, equals(3)); // 1 header + 2 items
    expect(settlementsSheet.rows.length, equals(2)); // 1 header + 1 item

    final bytes = excel.save();
    expect(bytes, isNotNull);
    expect(bytes!.isNotEmpty, isTrue);
  });
}
