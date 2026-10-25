import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';

class AppStrings {
  final String _languageCode;
  const AppStrings(this._languageCode);

  static AppStrings of(BuildContext context) => AppStrings(context.watch<LocaleProvider>().locale.languageCode);

  static const _kannada = {
    'home': 'ಮುಖಪುಟ', 'groups': 'ಗುಂಪುಗಳು', 'expenses': 'ಖರ್ಚುಗಳು', 'insights': 'ಒಳನೋಟಗಳು', 'profile': 'ಪ್ರೊಫೈಲ್',
    'addExpense': 'ಖರ್ಚು ಸೇರಿಸಿ', 'createGroup': 'ಗುಂಪು ರಚಿಸಿ', 'scanBill': 'ಬಿಲ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'recentExpenses': 'ಇತ್ತೀಚಿನ ಖರ್ಚುಗಳು', 'yourGroups': 'ನಿಮ್ಮ ಗುಂಪುಗಳು', 'seeAll': 'ಎಲ್ಲವನ್ನೂ ನೋಡಿ',
    'totalBalance': 'ಒಟ್ಟು ಬ್ಯಾಲೆನ್ಸ್', 'youOwe': 'ನೀವು ನೀಡಬೇಕಾಗಿರುವುದು', 'youAreOwed': 'ನಿಮಗೆ ಬರಬೇಕಾಗಿರುವುದು',
    'youHaveToSend': 'ನೀವು ಕಳುಹಿಸಬೇಕಾಗಿರುವುದು', 'youHaveToReceive': 'ನಿಮಗೆ ಬರಬೇಕಾಗಿರುವುದು',
    'allSettledUp': 'ಎಲ್ಲವೂ ಇತ್ಯರ್ಥವಾಗಿದೆ', 'noBalanceToSendOrReceive': 'ಕಳುಹಿಸಲು ಅಥವಾ ಪಡೆಯಲು ಬಾಕಿ ಇಲ್ಲ',
    'settledUpDescription': 'ಯಾವುದೇ ಬಾಕಿ ಹಣವಿಲ್ಲ',
    'noRecentExpenses': 'ಯಾವುದೇ ಇತ್ತೀಚಿನ ಖರ್ಚುಗಳಿಲ್ಲ', 'noGroups': 'ಇನ್ನೂ ಯಾವುದೇ ಗುಂಪುಗಳನ್ನು ರಚಿಸಲಾಗಿಲ್ಲ.',
    'profileSettings': 'ಪ್ರೊಫೈಲ್ ಮತ್ತು ಸೆಟ್ಟಿಂಗ್‌ಗಳು', 'chooseAvatar': 'ಅವತಾರ್ ಆಯ್ಕೆಮಾಡಿ', 'upiId': 'UPI ಐಡಿ (ಪಾವತಿಗಾಗಿ)',
    'settlePayments': 'ಗುಂಪಿನ ಪಾವತಿಗಳನ್ನು ಇತ್ಯರ್ಥಗೊಳಿಸಿ', 'darkMode': 'ಡಾರ್ಕ್ ಮೋಡ್', 'language': 'ಭಾಷೆ',
    'exportExpenses': 'ಖರ್ಚುಗಳನ್ನು ರಫ್ತು ಮಾಡಿ (PDF, Excel, CSV)', 'signOut': 'ಸೈನ್ ಔಟ್',
    'monthlyBudget': 'ಮಾಸಿಕ ಬಜೆಟ್ ಸ್ಥಿತಿ', 'categoryBreakdown': 'ವರ್ಗದ ವಿವರ',
    'predictedExpense': 'ಮುಂದಿನ ತಿಂಗಳ ಅಂದಾಜು ಖರ್ಚು', 'topCategory': 'ಹೆಚ್ಚು ಖರ್ಚಿನ ವರ್ಗ',
    'save': 'ಉಳಿಸಿ', 'cancel': 'ರದ್ದುಮಾಡಿ', 'today': 'ಇಂದು',
  };

  static const _hindi = {
    'home': 'होम', 'groups': 'ग्रुप्स', 'expenses': 'खर्च', 'insights': 'खर्च की जानकारी', 'profile': 'प्रोफ़ाइल',
    'addExpense': 'खर्च जोड़ें', 'createGroup': 'ग्रुप बनाएँ', 'scanBill': 'बिल स्कैन करें',
    'recentExpenses': 'हाल के खर्च', 'yourGroups': 'आपके ग्रुप्स', 'seeAll': 'सभी देखें',
    'totalBalance': 'कुल बैलेंस', 'youOwe': 'आपको देना है', 'youAreOwed': 'आपको मिलना है',
    'youHaveToSend': 'आपको भेजना है', 'youHaveToReceive': 'आपको मिलना है',
    'allSettledUp': 'सब चुकता हो गया', 'noBalanceToSendOrReceive': 'लेन-देन के लिए कोई बाकी नहीं है',
    'settledUpDescription': 'कोई बकाया राशि नहीं है',
    'noRecentExpenses': 'कोई हाल का खर्च नहीं', 'noGroups': 'अभी कोई ग्रुप नहीं बनाया गया है',
    'profileSettings': 'प्रोफ़ाइल और सेटिंग्स', 'chooseAvatar': 'अवतार चुनें', 'upiId': 'UPI आईडी (भुगतान के लिए)',
    'settlePayments': 'ग्रुप भुगतान निपटाएँ', 'darkMode': 'डार्क मोड', 'language': 'भाषा',
    'exportExpenses': 'खर्च एक्सपोर्ट करें (PDF, Excel, CSV)', 'signOut': 'साइन आउट',
    'monthlyBudget': 'मासिक बजट स्थिति', 'categoryBreakdown': 'श्रेणी विवरण',
    'predictedExpense': 'अगले महीने का अनुमानित खर्च', 'topCategory': 'सबसे अधिक खर्च की श्रेणी',
    'save': 'सेव करें', 'cancel': 'रद्द करें', 'today': 'आज',
  };

  String t(String key) {
    if (_languageCode == 'kn') return _kannada[key] ?? _english[key] ?? key;
    if (_languageCode == 'hi') return _hindi[key] ?? _english[key] ?? key;
    return _english[key] ?? key;
  }

  static const _english = {
    'home': 'Home', 'groups': 'Groups', 'expenses': 'Expenses', 'insights': 'Insights', 'profile': 'Profile',
    'addExpense': 'Add Expense', 'createGroup': 'Create Group', 'scanBill': 'Scan Bill',
    'recentExpenses': 'Recent Expenses', 'yourGroups': 'Your Groups', 'seeAll': 'See all',
    'totalBalance': 'Total Balance', 'youOwe': 'You owe', 'youAreOwed': 'You are owed',
    'youHaveToSend': 'You have to send', 'youHaveToReceive': 'You have to receive',
    'allSettledUp': 'All settled up', 'noBalanceToSendOrReceive': 'No balance to send or receive',
    'settledUpDescription': "You don't owe and no one owes you",
    'noRecentExpenses': 'No recent expenses', 'noGroups': 'No groups created yet.',
    'profileSettings': 'Profile & Settings', 'chooseAvatar': 'Choose avatar', 'upiId': 'UPI ID (For Payments)',
    'settlePayments': 'Settle group payments', 'darkMode': 'Dark Mode', 'language': 'Language',
    'exportExpenses': 'Export Expenses (PDF, Excel, CSV)', 'signOut': 'Sign Out',
    'monthlyBudget': 'Monthly Budget Status', 'categoryBreakdown': 'Category Breakdown',
    'predictedExpense': 'Predicted Next Month Expense', 'topCategory': 'Top Category Insight',
    'save': 'Save', 'cancel': 'Cancel', 'today': 'Today',
  };
}
