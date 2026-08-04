class FirebaseSetup {
  static const String projectId = 'splitwise-ai-demo';
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enableCloudMessaging = true;

  static List<String> get supportedAuthProviders => [
    'google',
    'email',
    'phone',
  ];
}
