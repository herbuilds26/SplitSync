import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _notificationIdCounter = 100;

  static const String _prefKeyNotificationsEnabled = 'splitsync_push_notifications_enabled';

  static const List<Map<String, String>> _engagementTips = [
    {
      'title': '💡 Planning a Trip or Dinner?',
      'body': 'Create a SplitSync group to easily split bills, travel expenses, and cabs with friends!',
    },
    {
      'title': '📊 Monthly Budget Predictions',
      'body': 'Check out your spending forecast and expense analytics in the Insights tab!',
    },
    {
      'title': '🧾 Snap & Split Bills in Seconds',
      'body': 'Have a paper receipt? Use the AI bill scanner to auto-extract totals and split items!',
    },
    {
      'title': '💰 Settle Up on UPI',
      'body': 'See who owes what in your groups and settle up instantly with GPay, PhonePe, or Paytm.',
    },
  ];

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Firebase Messaging Permission (safe timeout)
      try {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}

      // 2. Local Notifications Initialization
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 3. Create Android notification channels
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();

        const activityChannel = AndroidNotificationChannel(
          'splitsync_activity',
          'Group & Expense Activity',
          description: 'Instant updates when someone adds an expense, joins a group, or settles up',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        const tipsChannel = AndroidNotificationChannel(
          'splitsync_tips',
          'SplitSync Tips & Budget Reminders',
          description: 'Helpful reminders about your monthly budget predictions and group expense tips',
          importance: Importance.defaultImportance,
          playSound: true,
        );

        await androidImplementation.createNotificationChannel(activityChannel);
        await androidImplementation.createNotificationChannel(tipsChannel);
      }

      // 4. Firebase foreground messaging handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? message.data['title'] ?? 'SplitSync';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        showNotification(title: title, body: body);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, enabled);
  }

  static Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  // ================= NOTIFICATION DISPATCHERS =================

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'splitsync_activity',
    String channelName = 'Group & Expense Activity',
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final id = _notificationIdCounter++;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      color: AppColors.berryRose,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to display local notification: $e');
    }
  }

  /// Triggered when user is added to a group or a new group appears
  static Future<void> showGroupAddedNotification({required String groupName}) async {
    await showNotification(
      title: 'New Group! 👥',
      body: 'You are now part of "$groupName". Start adding expenses or invite friends!',
      payload: 'group_added',
    );
  }

  /// Triggered when someone adds an expense to a group
  static Future<void> showExpenseAddedNotification({
    required String groupName,
    required String expenseTitle,
    required double amount,
    required String payerName,
    String currency = '₹',
  }) async {
    await showNotification(
      title: 'New Expense in $groupName 💸',
      body: '$payerName added "$expenseTitle" for $currency${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}.',
      payload: 'expense_added',
    );
  }

  /// Triggered when a settlement is recorded
  static Future<void> showSettlementNotification({
    required String groupName,
    required String payerName,
    required String payeeName,
    required double amount,
    String currency = '₹',
  }) async {
    await showNotification(
      title: 'Payment Settled 🤝',
      body: '$payerName recorded a payment of $currency${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} to $payeeName in "$groupName".',
      payload: 'settlement',
    );
  }

  /// Triggered when the user exits or minimizes the app (smart engagement tip / budget reminder - at most once per day)
  static Future<void> showEngagementTipNotification() async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    final lastTimeMs = prefs.getInt('splitsync_last_tip_notification_timestamp');
    final now = DateTime.now();

    // Strict cooldown: at most 1 notification per day (24 hours)
    if (lastTimeMs != null) {
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
      if (now.difference(lastTime).inHours < 24) {
        return;
      }
    }

    await prefs.setInt('splitsync_last_tip_notification_timestamp', now.millisecondsSinceEpoch);

    final random = Random();
    final tip = _engagementTips[random.nextInt(_engagementTips.length)];

    await showNotification(
      title: tip['title']!,
      body: tip['body']!,
      channelId: 'splitsync_tips',
      channelName: 'SplitSync Tips & Reminders',
      payload: 'app_tip',
    );
  }
}
