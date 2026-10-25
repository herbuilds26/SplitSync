import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';
import '../../services/ai_receipt_scanner.dart';
import 'add_expense_screen.dart';

class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});

  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  bool _isScanning = false;

  Future<void> _pickAndScan(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image == null || !mounted) return;

    setState(() => _isScanning = true);
    final result = await AiReceiptScanner.scanReceipt(File(image.path));
    if (!mounted) return;

    setState(() => _isScanning = false);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialAmount: result.amount,
          initialTitle: result.title == 'Scanned Receipt' ? '' : result.title,
          initialCategory: result.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.deepBerry;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Scan Bill'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSurface : AppColors.softBerryPink,
                  borderRadius: BorderRadius.circular(36),
                  border: isDark ? Border.all(color: AppColors.darkBorder, width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.berryRose.withAlpha(isDark ? 35 : 20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded, size: 76, color: AppColors.berryRose),
              ),
              const SizedBox(height: 28),
              Text(
                'Scan a bill',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Take a clear photo of your receipt or choose one from your gallery. We’ll read the total and fill in the expense for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              if (_isScanning) ...[
                const LinearProgressIndicator(color: AppColors.berryRose),
                const SizedBox(height: 14),
                Text(
                  'Reading your bill…',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.berryRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: isDark ? 0 : 2,
                    ),
                    onPressed: () => _pickAndScan(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                    label: const Text(
                      'Open Camera',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _pickAndScan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, color: AppColors.berryRose),
                    label: Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
