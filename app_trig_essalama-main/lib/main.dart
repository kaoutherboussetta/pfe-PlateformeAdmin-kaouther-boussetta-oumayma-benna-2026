import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_navigator.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/onboarding_analysis_page.dart';
import 'connexion/login_page.dart';
import 'connexion/register_page.dart';
import 'connexion/forgot_password_page.dart';
import 'widgets/video_background.dart';

import 'home_page.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

import 'screens/alert_push_detail_page.dart';
import 'screens/help_support_page.dart';
import 'services/api_client.dart';
import 'services/emergency_contacts_service.dart';
import 'services/feedback_service.dart';
import 'providers/alerts_feed_notifier.dart';
import 'services/alert_service.dart';
import 'services/fcm_service.dart';
import 'services/risque_service.dart';
import 'services/probleme_signale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isAndroid) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FcmService.setupForegroundHandlers();
  }

  // Initialise l'URL de l'API dynamiquement (Émulateur vs Réel)
  await initApiConfig();

  final localeProvider = LocaleProvider();
  await localeProvider.loadInitial();
  
  // 🛡️ Capture les erreurs Flutter pour éviter les crashs silencieux
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Précharge la vidéo d’arrière-plan pour qu’elle s’affiche dès l’ouverture de la connexion (sans fond noir)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    VideoBackground.preload();
  });
  runApp(MyApp(localeProvider: localeProvider));
}

class MyApp extends StatelessWidget {
  final LocaleProvider localeProvider;

  const MyApp({super.key, required this.localeProvider});

  /// Exposé pour [MaterialApp.routes] dans [_ThemedAppShell].
  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        '/onboarding': (context) => CompleteOnboardingPage(),
        '/onboarding-analysis': (context) => CompleteOnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int index = 0;
          if (args is int) {
            index = args;
          } else if (args is Map<String, dynamic>) {
            index = args['index'] ?? 0;
          }
          return HomePage(initialTabIndex: index);
        },
        '/carte': (context) => const HomePage(initialTabIndex: 1),
        '/profile': (context) => const HomePage(initialTabIndex: 3),
        '/help-support': (context) => const HelpSupportPage(),
        '/alert': (context) => const AlertPushDetailPage(),
      };

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AlertsFeedNotifier()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (context, auth, _) => ApiClient(
            baseUrl: kBaseUrl,
            auth: auth,
          ),
        ),
        ProxyProvider<ApiClient, EmergencyContactsService>(
          update: (context, api, _) => EmergencyContactsService(api),
        ),
        ProxyProvider<ApiClient, FeedbackService>(
          update: (context, api, _) => FeedbackService(api),
        ),
        ProxyProvider<ApiClient, AlertService>(
          update: (context, api, _) => AlertService(api),
        ),
        ProxyProvider<ApiClient, RisqueService>(
          update: (context, api, _) => RisqueService(api),
        ),
        ProxyProvider<ApiClient, ProblemeSignaleService>(
          update: (context, api, _) => ProblemeSignaleService(api),
        ),
      ],
      builder: (context, child) {
        // Enregistre le notifier pour que FcmService puisse mettre à jour la liste
        final notifier = Provider.of<AlertsFeedNotifier>(context, listen: false);
        FcmService.setNotifier(notifier);
        return child!;
      },
      child: const FcmRegistrar(
        child: _ThemedAppShell(),
      ),
    );
  }
}

/// Envoie le token FCM au backend une fois l’utilisateur connecté (JWT).
class FcmRegistrar extends StatefulWidget {
  final Widget child;

  const FcmRegistrar({super.key, required this.child});

  @override
  State<FcmRegistrar> createState() => _FcmRegistrarState();
}

class _FcmRegistrarState extends State<FcmRegistrar> {
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(FcmService.consumeInitialMessageIfAny());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoggedIn && auth.token != null) {
          if (!_wasLoggedIn) {
            _wasLoggedIn = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final api = Provider.of<ApiClient>(context, listen: false);
              unawaited(FcmService.registerTokenIfNeeded(api));
            });
          }
        } else {
          _wasLoggedIn = false;
        }
        return child!;
      },
      child: widget.child,
    );
  }
}

class _ThemedAppShell extends StatelessWidget {
  const _ThemedAppShell();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Trig Essalama',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: localeProvider.materialLocale,
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
          routes: MyApp.routes,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Pendant le chargement initial du token
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        // Si l'utilisateur est déjà connecté, on va direct à l'accueil
        if (auth.isLoggedIn) {
          return const HomePage();
        }

        // Sinon, on affiche l'onboarding (ou login selon votre choix)
        return CompleteOnboardingPage();
      },
    );
  }
}