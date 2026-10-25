import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitsync/l10n/app_strings.dart';
import 'package:splitsync/providers/locale_provider.dart';
import 'package:splitsync/providers/theme_provider.dart';

void main() {
  group('Kannada Overflow & Responsive Layout Tests', () {
    testWidgets('Bottom nav bar renders all 5 Kannada tabs without overflow on narrow screens', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final localeProvider = LocaleProvider();
      await localeProvider.setLocale(const Locale('kn'));
      final themeProvider = ThemeProvider();

      for (final width in [320.0, 360.0, 375.0, 390.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: localeProvider),
              ChangeNotifierProvider.value(value: themeProvider),
            ],
            child: MaterialApp(
              locale: const Locale('kn'),
              home: Builder(
                builder: (context) {
                  final t = AppStrings.of(context);
                  return Scaffold(
                    bottomNavigationBar: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.home),
                                Text(t.t('home'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.groups),
                                Text(t.t('groups'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt),
                                Text(t.t('expenses'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insights),
                                Text(t.t('insights'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person),
                                Text(t.t('profile'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Profile header row with long Kannada text does not overflow', (tester) async {
      final localeProvider = LocaleProvider();
      await localeProvider.setLocale(const Locale('kn'));

      for (final width in [320.0, 360.0, 390.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: localeProvider,
            child: MaterialApp(
              locale: const Locale('kn'),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final t = AppStrings.of(context);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              t.t('profileSettings'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: const Text('Status'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
