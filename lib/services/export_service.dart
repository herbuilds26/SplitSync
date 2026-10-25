import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/settlement_model.dart';
import '../services/debt_calculator.dart';
import '../services/firestore_service.dart';

class ExportService {
  /// Helper to resolve member names map without raw IDs or fallback strings
  static Future<Map<String, String>> resolveMemberNames(
    List<String> memberIds, {
    Map<String, String>? knownMemberNames,
  }) async {
    final names = <String, String>{};
    if (knownMemberNames != null) {
      names.addAll(knownMemberNames);
    }

    for (final uid in memberIds) {
      if (names.containsKey(uid) && names[uid]!.isNotEmpty && names[uid] != uid) {
        continue;
      }
      try {
        final user = await FirestoreService.getUser(uid);
        if (user != null && user.name.trim().isNotEmpty) {
          names[uid] = user.name.trim();
        } else {
          names.putIfAbsent(uid, () => 'Member');
        }
      } catch (_) {
        names.putIfAbsent(uid, () => 'Member');
      }
    }
    return names;
  }

  /// Helper to fetch settlements for the group if not supplied
  static Future<List<SettlementModel>> fetchSettlements(String groupId) async {
    try {
      return await FirestoreService.getGroupSettlements(groupId);
    } catch (_) {
      return [];
    }
  }

  /// Exports expenses and group summary to a beautifully styled, presentable PDF document.
  static Future<void> exportToPdf({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    List<SettlementModel>? settlements,
    Map<String, String>? memberNames,
  }) async {
    final nameMap = await resolveMemberNames(group.memberIds, knownMemberNames: memberNames);
    final settlementList = settlements ?? await fetchSettlements(group.id);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final totalAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);
          final totalSettled = settlementList.fold(0.0, (sum, item) => sum + item.amount);

          return [
            // Header with App Branding and Group Name
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 14),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF7B2948), width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SplitSync',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF7B2948),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Official Group Expense & Settlement Report',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        group.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF380C1E),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Category: ${group.category}  |  Code: ${group.inviteCode}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Metadata & Summary Statistics Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFBF4F6),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFECCFD8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Expenses', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${group.currency} ${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF7B2948),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('${expenses.length} transactions', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF1F7F3),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFC7E1CE)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Total Settled Up', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${group.currency} ${totalSettled.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF2A643E),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('${settlementList.length} settlements', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF5F6F8),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFD6D9E0)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Group Members', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${group.memberIds.length}',
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF333333),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Active participants', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Itemized Expenses Table
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Itemized Expenses',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF380C1E)),
                ),
                pw.Text(
                  'Group: ${group.name}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF7B2948)),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            if (expenses.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFAF9FA),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text('No expenses recorded in this group yet.', style: pw.TextStyle(color: PdfColors.grey600)),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Category', 'Paid By', 'Amount (${group.currency})', 'Description', 'Group Name'],
                data: expenses.map((e) {
                  final payerName = e.paidBy == 'everyone'
                      ? 'Everyone'
                      : (nameMap[e.paidBy] ?? 'Member');
                  return [
                    '${e.createdAt.day.toString().padLeft(2, '0')}/${e.createdAt.month.toString().padLeft(2, '0')}/${e.createdAt.year}',
                    e.category,
                    payerName,
                    e.amount.toStringAsFixed(2),
                    e.title,
                    group.name,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7B2948)),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                ),
                cellHeight: 22,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                },
              ),

            // Settlements History Table
            if (settlementList.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Settlement & Payment History',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2A643E)),
                  ),
                  pw.Text(
                    '${settlementList.length} completed payments',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Paid By', 'Received By', 'Amount (${group.currency})', 'Payment Method', 'UTR / Ref', 'Group Name'],
                data: settlementList.map((s) {
                  return [
                    '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}',
                    nameMap[s.fromUserId] ?? 'Member',
                    nameMap[s.toUserId] ?? 'Member',
                    s.amount.toStringAsFixed(2),
                    s.paymentMethod,
                    s.upiTransactionRef ?? '-',
                    group.name,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2A643E)),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                ),
                cellHeight: 22,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerLeft,
                  6: pw.Alignment.centerLeft,
                },
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by SplitSync on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Group: ${group.name} (${group.currency})', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final sanitizedName = group.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File("${output.path}/${sanitizedName}_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'SplitSync PDF Report for ${group.name}');
  }

  /// Exports comprehensive group information to an Excel (.xlsx) workbook.
  /// Features:
  /// - Group Name prominently stated in every sheet header and data rows.
  /// - Clear human usernames for Paid By (no cryptic IDs or fallback words).
  /// - Formatted Date (DD/MM/YYYY), Category, Amount with currency, Description, Split Breakdown, Notes.
  /// - Styled sheets: Summary, Expenses, Member Balances, Settlements.
  static Future<void> exportToExcel({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    List<SettlementModel>? settlements,
    Map<String, String>? memberNames,
  }) async {
    final nameMap = await resolveMemberNames(group.memberIds, knownMemberNames: memberNames);
    final settlementList = settlements ?? await fetchSettlements(group.id);

    final excel = Excel.createExcel();

    // -------------------------------------------------------------
    // SHEET 1: Summary Sheet
    // -------------------------------------------------------------
    final Sheet summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('SplitSync Group Summary Report')]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([TextCellValue('Field'), TextCellValue('Details')]);
    summarySheet.appendRow([TextCellValue('Group Name'), TextCellValue(group.name)]);
    summarySheet.appendRow([TextCellValue('Category'), TextCellValue(group.category)]);
    summarySheet.appendRow([TextCellValue('Currency'), TextCellValue(group.currency)]);
    summarySheet.appendRow([TextCellValue('Invite Code'), TextCellValue(group.inviteCode)]);
    summarySheet.appendRow([
      TextCellValue('Created On'),
      TextCellValue('${group.createdAt.day.toString().padLeft(2, '0')}/${group.createdAt.month.toString().padLeft(2, '0')}/${group.createdAt.year}'),
    ]);
    summarySheet.appendRow([TextCellValue('Total Group Members'), IntCellValue(group.memberIds.length)]);

    final totalExpenseAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSettlementAmount = settlementList.fold(0.0, (sum, s) => sum + s.amount);

    summarySheet.appendRow([TextCellValue('Total Expenses (${group.currency})'), DoubleCellValue(totalExpenseAmount)]);
    summarySheet.appendRow([TextCellValue('Total Settled Up (${group.currency})'), DoubleCellValue(totalSettlementAmount)]);
    summarySheet.appendRow([TextCellValue('Total Expense Records'), IntCellValue(expenses.length)]);
    summarySheet.appendRow([TextCellValue('Total Settlement Records'), IntCellValue(settlementList.length)]);

    // -------------------------------------------------------------
    // SHEET 2: Expenses Sheet
    // Columns: Date, Category, Paid By, Amount, Group Name, Title, Split Method, Split Breakdown, Note
    // -------------------------------------------------------------
    final Sheet expensesSheet = excel['Expenses'];
    expensesSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Paid By'),
      TextCellValue('Amount (${group.currency})'),
      TextCellValue('Group Name'),
      TextCellValue('Description / Title'),
      TextCellValue('Split Method'),
      TextCellValue('Split Participants & Amounts'),
      TextCellValue('Note'),
    ]);

    if (expenses.isEmpty) {
      expensesSheet.appendRow([
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        DoubleCellValue(0.0),
        TextCellValue(group.name),
        TextCellValue('No expenses recorded'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
      ]);
    } else {
      for (final e in expenses) {
        final payerName = e.paidBy == 'everyone'
            ? 'Everyone'
            : (nameMap[e.paidBy] ?? 'Member');

        final splitBreakdown = e.splits.map((s) {
          final mName = nameMap[s.userId] ?? 'Member';
          return '$mName: ${s.amount.toStringAsFixed(2)}';
        }).join(', ');

        expensesSheet.appendRow([
          TextCellValue('${e.createdAt.day.toString().padLeft(2, '0')}/${e.createdAt.month.toString().padLeft(2, '0')}/${e.createdAt.year}'),
          TextCellValue(e.category),
          TextCellValue(payerName),
          DoubleCellValue(e.amount),
          TextCellValue(group.name),
          TextCellValue(e.title),
          TextCellValue(e.splitMethod),
          TextCellValue(splitBreakdown),
          TextCellValue(e.note),
        ]);
      }
    }

    // -------------------------------------------------------------
    // SHEET 3: Member Balances Sheet
    // -------------------------------------------------------------
    final Sheet balancesSheet = excel['Balances'];
    balancesSheet.appendRow([
      TextCellValue('Member Name'),
      TextCellValue('Group Name'),
      TextCellValue('Net Balance (${group.currency})'),
      TextCellValue('Status'),
    ]);

    final netBalances = DebtCalculator.calculateNetBalances(
      expenses: expenses,
      settlements: settlementList,
      memberIds: group.memberIds,
    );

    for (final b in netBalances) {
      final mName = nameMap[b.userId] ?? 'Member';
      final status = b.amount > 0.01
          ? 'Gets back ${group.currency} ${b.amount.toStringAsFixed(2)}'
          : b.amount < -0.01
              ? 'Owes ${group.currency} ${(-b.amount).toStringAsFixed(2)}'
              : 'Settled Up';

      balancesSheet.appendRow([
        TextCellValue(mName),
        TextCellValue(group.name),
        DoubleCellValue(b.amount),
        TextCellValue(status),
      ]);
    }

    // -------------------------------------------------------------
    // SHEET 4: Settlements Sheet
    // -------------------------------------------------------------
    final Sheet settlementsSheet = excel['Settlements'];
    settlementsSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Paid By (Payer)'),
      TextCellValue('Received By (Payee)'),
      TextCellValue('Amount (${group.currency})'),
      TextCellValue('Group Name'),
      TextCellValue('Payment Method'),
      TextCellValue('UPI Reference / UTR'),
      TextCellValue('Status'),
    ]);

    if (settlementList.isEmpty) {
      settlementsSheet.appendRow([
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        DoubleCellValue(0.0),
        TextCellValue(group.name),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('No settlements recorded yet'),
      ]);
    } else {
      for (final s in settlementList) {
        settlementsSheet.appendRow([
          TextCellValue('${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}'),
          TextCellValue(nameMap[s.fromUserId] ?? 'Member'),
          TextCellValue(nameMap[s.toUserId] ?? 'Member'),
          DoubleCellValue(s.amount),
          TextCellValue(group.name),
          TextCellValue(s.paymentMethod),
          TextCellValue(s.upiTransactionRef ?? '-'),
          TextCellValue(s.status),
        ]);
      }
    }

    // Remove empty default 'Sheet1' created by Excel library and set 'Summary' as default
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    excel.setDefaultSheet('Summary');

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final output = await getTemporaryDirectory();
      final sanitizedName = group.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File("${output.path}/${sanitizedName}_report.xlsx");
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'SplitSync Excel Export for ${group.name}');
    }
  }

  /// Exports expenses list to CSV spreadsheet file with proper columns and usernames.
  static Future<void> exportToCsv({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    Map<String, String>? memberNames,
  }) async {
    final nameMap = await resolveMemberNames(group.memberIds, knownMemberNames: memberNames);

    final List<List<dynamic>> rows = [
      [
        'Date',
        'Category',
        'Paid By',
        'Amount (${group.currency})',
        'Group Name',
        'Description',
        'Split Method',
        'Split Breakdown',
        'Note',
      ],
    ];

    for (final e in expenses) {
      final payerName = e.paidBy == 'everyone'
          ? 'Everyone'
          : (nameMap[e.paidBy] ?? 'Member');

      final splitBreakdown = e.splits.map((s) {
        final mName = nameMap[s.userId] ?? 'Member';
        return '$mName: ${s.amount.toStringAsFixed(2)}';
      }).join('; ');

      rows.add([
        '${e.createdAt.day.toString().padLeft(2, '0')}/${e.createdAt.month.toString().padLeft(2, '0')}/${e.createdAt.year}',
        e.category,
        payerName,
        e.amount,
        group.name,
        e.title,
        e.splitMethod,
        splitBreakdown,
        e.note,
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);

    final output = await getTemporaryDirectory();
    final sanitizedName = group.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File("${output.path}/${sanitizedName}_expenses.csv");
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'SplitSync CSV Export for ${group.name}');
  }
}

