import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:stimmapp/app/mobile/layout/init_app_layout.dart';
import 'package:stimmapp/app/mobile/pages/main/home/petitions/petition_detail_page.dart';
import 'package:stimmapp/app/mobile/pages/main/home/polls/poll_detail_page.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/delete_account_page.dart';
import 'package:stimmapp/app/mobile/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/config/app_bootstrap.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/notifiers/notifiers.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/core/theme/app_theme.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  if (kIsWeb) usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) => errorLogTool(
    exception: details.exception,
    errorCustomMessage: 'Flutter framework error',
  );
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogTool(exception: error, errorCustomMessage: 'Uncaught async error');
    return true;
  };

  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  locator.init();
  await PurchasesService.instance.init(
    apiKey: IConst.revenueCatApiKey,
    appUserId: authService.currentUser?.uid,
  );

  if (!kIsWeb && kDebugMode) {
    await authService.setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(const MyApp());
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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: appLocale,
          builder: (context, locale, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: IConst.appName,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              locale: locale,
              routes: {
                '/petition': (ctx) {
                  final args =
                      ModalRoute.of(ctx)?.settings.arguments as String?;
                  return PetitionDetailPage(id: args ?? '');
                },
                '/poll': (ctx) {
                  final args =
                      ModalRoute.of(ctx)?.settings.arguments as String?;
                  return PollDetailPage(id: args ?? '');
                },
                '/delete_account': (context) => const DeleteAccountPage(),
              },
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              debugShowCheckedModeBanner: false,
              home: _initialized
                  ? const InitAppLayout()
                  : const AppLoadingPage(),
            );
          },
        );
      },
    );
  }
}
