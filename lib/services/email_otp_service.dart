import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that handles generation, storage, dispatch, and verification of 
/// 6-digit email OTP verification codes.
class EmailOtpService {
  static const int otpLength = 6;
  static const int maxAttempts = 5;
  static const Duration otpValidity = Duration(minutes: 10);

  /// Optional email provider API keys (Resend or Brevo) for sending real 6-digit OTP emails
  static String resendApiKey = '';
  static String brevoApiKey = '';

  /// Dispatches the custom professional SplitSync HTML email with OTP code
  /// via Brevo or Resend REST API if configured.
  static Future<bool> dispatchCustomEmail({
    required String email,
    required String code,
    String? userName,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return false;

    // 1. Resend API
    if (resendApiKey.isNotEmpty) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse('https://api.resend.com/emails'));
        request.headers.set('Authorization', 'Bearer $resendApiKey');
        request.headers.set('Content-Type', 'application/json');
        final payload = jsonEncode({
          'from': 'SplitSync <onboarding@resend.dev>',
          'to': [cleanEmail],
          'subject': 'Your SplitSync Verification Code: $code',
          'html': getHtmlTemplate(code, userName),
        });
        request.write(payload);
        final response = await request.close();
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Dispatched SplitSync OTP email via Resend to $cleanEmail');
          return true;
        }
      } catch (e) {
        debugPrint('Error sending via Resend: $e');
      }
    }

    // 2. Brevo API
    if (brevoApiKey.isNotEmpty) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse('https://api.brevo.com/v3/smtp/email'));
        request.headers.set('api-key', brevoApiKey);
        request.headers.set('Content-Type', 'application/json');
        final payload = jsonEncode({
          'sender': {'name': 'SplitSync', 'email': 'notifications@splitsync.app'},
          'to': [{'email': cleanEmail, 'name': userName ?? 'User'}],
          'subject': 'Your SplitSync Verification Code: $code',
          'htmlContent': getHtmlTemplate(code, userName),
        });
        request.write(payload);
        final response = await request.close();
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Dispatched SplitSync OTP email via Brevo to $cleanEmail');
          return true;
        }
      } catch (e) {
        debugPrint('Error sending via Brevo: $e');
      }
    }

    return false;
  }

  /// Retrieves the active generated OTP for a user (useful for test/demo environments)
  static Future<String?> getLocalOtpForTesting(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('splitsync_otp_$uid');
    } catch (_) {
      return null;
    }
  }

  /// Generates a secure 6-digit OTP code, stores it, and triggers delivery.
  static Future<String> generateAndSendOtp({
    required String uid,
    required String email,
    String? userName,
  }) async {
    // 1. Generate random 6-digit numeric string
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();
    final now = DateTime.now();
    final expiry = now.add(otpValidity);

    // 2. Cache in local SharedPreferences for instant zero-latency verification
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitsync_otp_$uid', code);
      await prefs.setString('splitsync_otp_expiry_$uid', expiry.toIso8601String());
      await prefs.setInt('splitsync_otp_attempts_$uid', 0);
    } catch (e) {
      debugPrint('Error saving OTP to SharedPreferences: $e');
    }

    // 3. Store in Firestore under /email_verifications/{uid}
    try {
      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(uid)
          .set({
        'uid': uid,
        'email': email.trim(),
        'code': code,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiry),
        'attempts': 0,
      }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Notice: Storing OTP to Firestore: $e');
    }

    // 4. Queue email in Firestore /mail collection for Firebase Trigger Email extension
    try {
      await FirebaseFirestore.instance.collection('mail').add({
        'to': [email.trim()],
        'message': {
          'subject': 'Your SplitSync Verification Code: $code',
          'html': getHtmlTemplate(code, userName),
          'text': 'Your SplitSync verification code is: $code. Enter this code in the app to verify your email. Valid for 10 minutes.',
        },
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));
    } catch (_) {
      // If /mail collection is not used, silent continue
    }

    // 5. Attempt direct REST dispatch if email provider is configured
    try {
      await dispatchCustomEmail(
        email: email,
        code: code,
        userName: userName,
      );
    } catch (_) {}

    // 6. Always print clearly to debug console for testing & logging
    debugPrint('\n======================================================');
    debugPrint('📩 SPLITSYNC 6-DIGIT EMAIL VERIFICATION CODE');
    debugPrint('   Recipient : $email');
    debugPrint('   OTP Code  : $code');
    debugPrint('   Expires In: 10 minutes');
    debugPrint('======================================================\n');

    return code;
  }

  /// Verifies the entered 6-digit OTP code against stored records.
  static Future<bool> verifyOtp({
    required String uid,
    required String enteredCode,
  }) async {
    final cleanCode = enteredCode.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleanCode.length != otpLength) return false;

    final now = DateTime.now();

    // 1. Check local SharedPreferences first (fastest, offline-resilient)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCode = prefs.getString('splitsync_otp_$uid');
      final expiryStr = prefs.getString('splitsync_otp_expiry_$uid');
      final attempts = prefs.getInt('splitsync_otp_attempts_$uid') ?? 0;

      if (attempts >= maxAttempts) {
        debugPrint('Maximum OTP attempts exceeded for user: $uid');
        return false;
      }

      if (localCode != null && expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && now.isBefore(expiry)) {
          if (localCode == cleanCode) {
            await markEmailVerified(uid);
            await clearOtp(uid);
            return true;
          } else {
            await prefs.setInt('splitsync_otp_attempts_$uid', attempts + 1);
          }
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP locally: $e');
    }

    // 2. Check Firestore /email_verifications/{uid}
    try {
      final doc = await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final serverCode = data['code'] as String?;
          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
          final attempts = (data['attempts'] as num?)?.toInt() ?? 0;

          if (attempts >= maxAttempts) return false;

          if (expiresAt != null && now.isBefore(expiresAt)) {
            if (serverCode == cleanCode) {
              await markEmailVerified(uid);
              await clearOtp(uid);
              return true;
            } else {
              await doc.reference.update({'attempts': attempts + 1});
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP via Firestore: $e');
    }

    return false;
  }

  /// Marks a user as verified in local SharedPreferences and Firestore
  static Future<void> markEmailVerified(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('splitsync_email_verified_$uid', true);
    } catch (_) {}

    try {
      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(uid)
          .set({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Checks if the user was verified by OTP
  static Future<bool> isEmailVerifiedLocally(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('splitsync_email_verified_$uid') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Clears stored OTP data once used
  static Future<void> clearOtp(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('splitsync_otp_$uid');
      await prefs.remove('splitsync_otp_expiry_$uid');
      await prefs.remove('splitsync_otp_attempts_$uid');
    } catch (_) {}

    try {
      await FirebaseFirestore.instance
          .collection('email_verifications')
          .doc(uid)
          .delete();
    } catch (_) {}
  }

  /// HTML email template containing the official 6-digit OTP code
  static String getHtmlTemplate(String code, String? userName) {
    final displayName = userName?.trim().isNotEmpty == true ? userName!.trim() : 'Friend';
    final digits = code.split('').join(' &nbsp; ');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your SplitSync Verification Code</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #F8F5F7;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #2D2429;
    }
    .container {
      max-width: 540px;
      margin: 36px auto;
      background: #FFFFFF;
      border-radius: 24px;
      overflow: hidden;
      border: 1px solid #F1E5EC;
      box-shadow: 0 10px 30px rgba(74, 21, 75, 0.08);
    }
    .header {
      background: linear-gradient(135deg, #4A154B 0%, #D81B60 100%);
      padding: 34px 28px;
      text-align: center;
    }
    .logo-box {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 72px;
      height: 72px;
      background: #FFFFFF;
      border-radius: 20px;
      box-shadow: 0 6px 16px rgba(0,0,0,0.12);
      margin-bottom: 12px;
    }
    .title {
      color: #FFFFFF;
      font-size: 24px;
      font-weight: 800;
      margin: 0;
    }
    .tagline {
      color: #FFD1E3;
      font-size: 13px;
      margin-top: 4px;
    }
    .body-content {
      padding: 34px 30px;
      text-align: center;
    }
    .greeting {
      font-size: 20px;
      font-weight: 700;
      color: #381A2D;
      margin-bottom: 12px;
    }
    .desc {
      font-size: 15px;
      line-height: 1.55;
      color: #5C4D56;
      margin-bottom: 26px;
    }
    .otp-card {
      background: #FFF5F8;
      border: 2px dashed #D81B60;
      border-radius: 18px;
      padding: 22px 18px;
      margin: 24px auto;
      max-width: 340px;
    }
    .otp-label {
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #7D6B75;
      margin-bottom: 8px;
    }
    .otp-code {
      font-size: 36px;
      font-weight: 800;
      color: #D81B60;
      letter-spacing: 6px;
      font-family: 'Courier New', Courier, monospace;
    }
    .expiry {
      font-size: 13px;
      color: #8C7B85;
      margin-top: 14px;
    }
    .security {
      margin-top: 26px;
      padding: 12px 14px;
      background: #FDF9FB;
      border-radius: 12px;
      font-size: 12.5px;
      color: #6A4B5B;
      line-height: 1.45;
    }
    .footer {
      background: #F8F5F7;
      border-top: 1px solid #F1E5EC;
      padding: 20px 24px;
      text-align: center;
      font-size: 12px;
      color: #8C7B85;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo-box">
        <svg width="44" height="44" viewBox="0 0 24 24" fill="none">
          <rect x="2" y="5" width="20" height="15" rx="3.5" fill="#4A154B"/>
          <path d="M16 11C15.4477 11 15 11.4477 15 12C15 12.5523 15.4477 13 16 13H22V11H16Z" fill="#D81B60"/>
          <circle cx="17.5" cy="12" r="1.5" fill="#FFFFFF"/>
          <path d="M4 8.5C4 7.67157 4.67157 7 5.5 7H18.5C19.3284 7 20 7.67157 20 8.5V9.5H4V8.5Z" fill="#F48FB1"/>
        </svg>
      </div>
      <h1 class="title">SplitSync</h1>
      <div class="tagline">Expense Sharing Made Effortless</div>
    </div>
    <div class="body-content">
      <div class="greeting">Hi $displayName! 👋</div>
      <p class="desc">
        Here is your verification code to confirm your email and activate your SplitSync account:
      </p>

      <div class="otp-card">
        <div class="otp-label">Verification Code</div>
        <div class="otp-code">$digits</div>
      </div>

      <div class="expiry">⏱️ This code expires in <strong>10 minutes</strong>.</div>

      <div class="security">
        🔒 <strong>Notice:</strong> Enter this 6-digit code in the SplitSync app. Do not share this code with anyone.
      </div>
    </div>
    <div class="footer">
      <strong>SplitSync</strong> &bull; Safe &amp; Synchronized Group Expenses<br>
      &copy; 2026 SplitSync. All rights reserved.
    </div>
  </div>
</body>
</html>
''';
  }
}
