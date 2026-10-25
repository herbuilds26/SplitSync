import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitsync/l10n/app_strings.dart';
import 'package:splitsync/providers/locale_provider.dart';

void main() {
  group('Kannada Language & Localization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppStrings resolves Kannada translations correctly for kn locale', () {
      const strings = AppStrings('kn');

      expect(strings.t('home'), 'ಮುಖಪುಟ');
      expect(strings.t('groups'), 'ಗುಂಪುಗಳು');
      expect(strings.t('expenses'), 'ಖರ್ಚುಗಳು');
      expect(strings.t('insights'), 'ಒಳನೋಟಗಳು');
      expect(strings.t('profile'), 'ಪ್ರೊಫೈಲ್');
      expect(strings.t('addExpense'), 'ಖರ್ಚು ಸೇರಿಸಿ');
      expect(strings.t('createGroup'), 'ಗುಂಪು ರಚಿಸಿ');
      expect(strings.t('scanBill'), 'ಬಿಲ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ');
      expect(strings.t('recentExpenses'), 'ಇತ್ತೀಚಿನ ಖರ್ಚುಗಳು');
      expect(strings.t('yourGroups'), 'ನಿಮ್ಮ ಗುಂಪುಗಳು');
      expect(strings.t('totalBalance'), 'ಒಟ್ಟು ಬ್ಯಾಲೆನ್ಸ್');
      expect(strings.t('youOwe'), 'ನೀವು ನೀಡಬೇಕಾಗಿರುವುದು');
      expect(strings.t('youAreOwed'), 'ನಿಮಗೆ ಬರಬೇಕಾಗಿರುವುದು');
      expect(strings.t('youHaveToSend'), 'ನೀವು ಕಳುಹಿಸಬೇಕಾಗಿರುವುದು');
      expect(strings.t('youHaveToReceive'), 'ನಿಮಗೆ ಬರಬೇಕಾಗಿರುವುದು');
      expect(strings.t('allSettledUp'), 'ಎಲ್ಲವೂ ಇತ್ಯರ್ಥವಾಗಿದೆ');
      expect(strings.t('noBalanceToSendOrReceive'), 'ಕಳುಹಿಸಲು ಅಥವಾ ಪಡೆಯಲು ಬಾಕಿ ಇಲ್ಲ');
      expect(strings.t('profileSettings'), 'ಪ್ರೊಫೈಲ್ ಮತ್ತು ಸೆಟ್ಟಿಂಗ್‌ಗಳು');
      expect(strings.t('chooseAvatar'), 'ಅವತಾರ್ ಆಯ್ಕೆಮಾಡಿ');
      expect(strings.t('language'), 'ಭಾಷೆ');
      expect(strings.t('darkMode'), 'ಡಾರ್ಕ್ ಮೋಡ್');
      expect(strings.t('signOut'), 'ಸೈನ್ ಔಟ್');
      expect(strings.t('monthlyBudget'), 'ಮಾಸಿಕ ಬಜೆಟ್ ಸ್ಥಿತಿ');
      expect(strings.t('categoryBreakdown'), 'ವರ್ಗದ ವಿವರ');
      expect(strings.t('predictedExpense'), 'ಮುಂದಿನ ತಿಂಗಳ ಅಂದಾಜು ಖರ್ಚು');
      expect(strings.t('topCategory'), 'ಹೆಚ್ಚು ಖರ್ಚಿನ ವರ್ಗ');
      expect(strings.t('save'), 'ಉಳಿಸಿ');
      expect(strings.t('cancel'), 'ರದ್ದುಮಾಡಿ');
    });

    test('AppStrings gracefully falls back to English for unknown keys', () {
      const strings = AppStrings('kn');
      expect(strings.t('unknown_nonexistent_key'), 'unknown_nonexistent_key');
    });

    test('LocaleProvider updates locale to kn and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();

      expect(provider.locale.languageCode, 'en');

      await provider.setLocale(const Locale('kn'));
      expect(provider.locale.languageCode, 'kn');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('splitsync_language'), 'kn');
    });

    test('LocaleProvider restores saved kn locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'splitsync_language': 'kn'});
      final provider = LocaleProvider();

      // Allow async load from prefs to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(provider.locale.languageCode, 'kn');
    });
  });
}
