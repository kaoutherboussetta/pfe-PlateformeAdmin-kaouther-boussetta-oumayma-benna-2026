import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/pages/login_intervenant_page.dart';
import 'package:intervenant/services/app_settings_controller.dart';
import 'package:intervenant/services/auth_api_service.dart';
import 'package:intervenant/theme/app_theme_data.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('fr_FR');
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  } catch (_) {}
  await AuthApiService.loadSavedBaseUrl();
  await AuthApiService.autoDiscoverBackend();
  await AppSettingsController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSettingsController settings = AppSettingsController.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: 'TRIG Essalama',
          debugShowCheckedModeBanner: false,
          theme: AppThemeData.light(),
          darkTheme: AppThemeData.dark(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (Locale? locale, Iterable<Locale> supported) {
            if (locale == null) return supported.first;
            for (final Locale l in supported) {
              if (l.languageCode == locale.languageCode) return l;
            }
            return const Locale('fr');
          },
          home: LoginIntervenantPage(),
        );
      },
    );
  }
}
