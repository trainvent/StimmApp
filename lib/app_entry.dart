import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:stimmapp/app/mobile/layout/init_app_layout.dart';
import 'package:stimmapp/app/mobile/pages/main/home/petitions/petition_detail_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/polls/poll_detail_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/delete_account_page.dart';
import 'package:stimmapp/app/mobile/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/config/app_bootstrap.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/core/theme/app_theme.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void>? _firebaseInit;

String _resolveRevenueCatApiKey() {
  final bool isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  if (Environment.isDev) {
    return isIos
        ? IConst.revenueCatApiKeyDevIos
        : IConst.revenueCatApiKeyDevAndroid;
  }
  return isIos
      ? IConst.revenueCatApiKeyProdIos
      : IConst.revenueCatApiKeyProdAndroid;
}

Future<void> _initFirebase(FirebaseOptions firebaseOptions) async {
  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Native side already created DEFAULT (e.g., FirebaseInitProvider).
      // Just bind to it.
      Firebase.app();
    } else if (e.code == 'no-app') {
      await Firebase.initializeApp(options: firebaseOptions);
    } else {
      rethrow;
    }
  }
}

Future<void> startApp({required FirebaseOptions firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  FlutterError.onError = (details) => errorLogTool(
    exception: details.exception,
    errorCustomMessage: 'Flutter framework error',
  );
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogTool(exception: error, errorCustomMessage: 'Uncaught async error');
    return true;
  };

  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

  // Debug: log Firebase app state early to diagnose duplicate-app on device.
  debugPrint(
    'Firebase apps before init: ${Firebase.apps.map((a) => a.name).toList()}',
  );
  // Initialize Firebase once, even if startApp is triggered twice.
  _firebaseInit ??= _initFirebase(firebaseOptions);
  await _firebaseInit;
  debugPrint(
    'Firebase apps after init: ${Firebase.apps.map((a) => a.name).toList()}',
  );

  locator.init();
  await PurchasesService.instance.init(
    apiKey: _resolveRevenueCatApiKey(),
    appUserId: authService.currentUser?.uid,
  );
  if (!kIsWeb && kDebugMode) {
    await authService.setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppBootstrap _bootstrap = AppBootstrap();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap.init().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _bootstrap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: appLocale,
          builder: (context, locale, child) {
            final app = MaterialApp(
              navigatorKey: navigatorKey,
              title: IConst.appName,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              locale: locale,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Enforce a maximum aspect ratio of 2/3 (mobile-like)
                    // If the screen is wider than this ratio, constrain the width.
                    final maxAllowedWidth = constraints.maxHeight * (5 / 6);
                    if (constraints.maxWidth > maxAllowedWidth) {
                      return ColoredBox(
                        color: Colors.black, // Background for the empty space
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxAllowedWidth,
                            ),
                            child: ClipRect(child: child),
                          ),
                        ),
                      );
                    }
                    return child ?? const SizedBox.shrink();
                  },
                );
              },
              onGenerateRoute: (settings) {
                if (settings.name != null) {
                  final uri = Uri.parse(settings.name!);
                  if (uri.pathSegments.length == 2) {
                    final id = uri.pathSegments[1];
                    if (uri.pathSegments[0] == 'petition') {
                      return MaterialPageRoute(
                        builder: (context) => PetitionDetailPage(id: id),
                        settings: settings,
                      );
                    } else if (uri.pathSegments[0] == 'poll') {
                      return MaterialPageRoute(
                        builder: (context) => PollDetailPage(id: id),
                        settings: settings,
                      );
                    }
                  }
                }
                return null;
              },
              routes: {
                '/delete_account': (context) => const DeleteAccountPage(),
              },
              localizationsDelegates: const [
                S.delegate,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              debugShowCheckedModeBanner: false,
              home: _initialized
                  ? const InitAppLayout()
                  : const AppLoadingPage(),
            );

            if (Environment.isDev) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: Banner(
                  message: 'TEST',
                  location: BannerLocation.topStart,
                  color: Colors.red,
                  child: app,
                ),
              );
            }
            return app;
          },
        );
      },
    );
  }
}
