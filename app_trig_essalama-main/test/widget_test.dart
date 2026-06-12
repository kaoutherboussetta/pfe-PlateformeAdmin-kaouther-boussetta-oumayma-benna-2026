// Basic smoke test: app builds with locale provider.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_trig_essalama/main.dart';
import 'package:app_trig_essalama/providers/locale_provider.dart';

void main() {
  testWidgets('MyApp builds', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final localeProvider = LocaleProvider();
    await localeProvider.loadInitial();

    await tester.pumpWidget(MyApp(localeProvider: localeProvider));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
