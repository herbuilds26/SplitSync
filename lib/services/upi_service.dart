import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Builds a standard UPI Payment URI (`upi://pay?...`).
  static Uri buildUpiUri({
    required String upiId,
    required String payeeName,
    required double amount,
    String note = 'SplitSync Settlement',
  }) {
    final cleanUpiId = upiId.trim();
    final cleanPayeeName = Uri.encodeComponent(payeeName.trim());
    final formattedAmount = amount.toStringAsFixed(2);
    final cleanNote = Uri.encodeComponent(note);

    final uriString =
        'upi://pay?pa=$cleanUpiId&pn=$cleanPayeeName&am=$formattedAmount&cu=INR&tn=$cleanNote';
    return Uri.parse(uriString);
  }

  /// Returns the raw UPI payment URI string (useful for QR code generation).
  static String buildUpiUriString({
    required String upiId,
    required String payeeName,
    required double amount,
    String note = 'SplitSync Settlement',
  }) {
    return buildUpiUri(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      note: note,
    ).toString();
  }

  /// Attempts to launch UPI payment app on Android/iOS.
  static Future<bool> launchUpiPayment({
    required String upiId,
    required String payeeName,
    required double amount,
    String note = 'SplitSync Settlement',
  }) async {
    final uri = buildUpiUri(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      note: note,
    );

    // 1. Try launching with standard canLaunchUrl check
    try {
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (success) return true;
      }
    } catch (_) {}

    // 2. Direct launch attempt: on Android 11+, canLaunchUrl may return false
    // even when an intent handler exists if queries are bypassed or during debug.
    try {
      final directSuccess = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (directSuccess) return true;
    } catch (_) {}

    // 3. Fallback: Try launching via Android intent URI format
    try {
      final intentUri = Uri.parse(
        'intent://pay?pa=${upiId.trim()}&pn=${Uri.encodeComponent(payeeName.trim())}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}#Intent;scheme=upi;end',
      );
      if (await canLaunchUrl(intentUri)) {
        return await launchUrl(intentUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return false;
  }
}
