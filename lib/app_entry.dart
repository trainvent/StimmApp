import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show
        PlatformDispatcher,
        TargetPlatform,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/layout/init_app_layout.dart';
import 'package:stimmapp/app/pages/main/home/petitions/petition_detail_page.dart';
import 'package:stimmapp/app/pages/main/home/polls/poll_detail_page.dart';
import 'package:stimmapp/app/pages/main/home/polls/survey_detail_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/delete_account_page.dart';
import 'package:stimmapp/app/pages/main/groups/group_entry_page.dart';
import 'package:stimmapp/app/pages/others/app_loading_page.dart';
import 'package:stimmapp/core/config/app_bootstrap.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/services/crash_reporting_service.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/core/theme/app_color_scheme.dart';
import 'package:stimmapp/core/theme/app_theme.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void>? _firebaseInit;

String _resolveRevenueCatApiKey() {
  if (kIsWeb) {
    return Environment.isDev
        ? IConst.revenueCatApiKeyDevWeb
        : IConst.revenueCatApiKeyProdWeb;
  }

  final bool isIos = defaultTargetPlatform == TargetPlatform.iOS;

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

Future<void> _configureFirestore() async {
  final firestore = FirebaseFirestore.instanceFor(app: Firebase.app());

  if (kIsWeb) {
    firestore.settings = const Settings(
      persistenceEnabled: false,
      webExperimentalAutoDetectLongPolling: true,
      ignoreUndefinedProperties: true,
    );
    debugPrint(
      '[Firestore] Configured web settings with memory cache and auto long-polling',
    );
  }
}

Future<void> _configureCrashReporting() async {
  final prefs = await SharedPreferences.getInstance();
  final collectionEnabled = prefs.getBool(IConst.crashLogsEnabledKey) ?? true;
  await CrashReportingService.instance.configure(
    collectionEnabled: collectionEnabled,
  );
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

  await _configureCrashReporting();
  await _configureFirestore();
  locator.init();
  final revenueCatApiKey = _resolveRevenueCatApiKey();
  if (revenueCatApiKey.isNotEmpty) {
    await PurchasesService.instance.init(
      apiKey: revenueCatApiKey,
      appUserId: authService.currentUser?.uid,
    );
  }
  if (!kIsWeb && kDebugMode) {
    await authService.setSettings(appVerificationDisabledForTesting: true);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final AppBootstrap _bootstrap = AppBootstrap();
  bool _initialized = false;
  Uri? _pendingDeepLink;
  bool _openingDeepLink = false;

  Uri _initialUri() {
    if (kIsWeb) {
      final uri = Uri.base;
      final requestedRoute = uri.queryParameters['open'];
      if (requestedRoute != null && requestedRoute.startsWith('/')) {
        return Uri.tryParse(requestedRoute) ?? uri;
      }
      return uri;
    }

    final routeName = PlatformDispatcher.instance.defaultRouteName;
    if (routeName.isEmpty) {
      return Uri(path: '/');
    }
    return Uri.tryParse(routeName) ?? Uri(path: routeName);
  }

  String? _routeNameForUri(Uri? uri) {
    if (uri == null || _pageForUri(uri) == null) return null;

    final isAppScheme = uri.scheme == 'stimmapp' || uri.scheme == 'vivot';
    final pathSegments = isAppScheme && uri.host.isNotEmpty
        ? <String>[uri.host, ...uri.pathSegments]
        : uri.pathSegments;
    final path = '/${pathSegments.join('/')}';
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }

  void _openPendingDeepLink() {
    final uri = _pendingDeepLink;
    if (!_initialized || uri == null) return;
    _pendingDeepLink = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openDeepLink(uri);
    });
  }

  void _openDeepLink(Uri uri) {
    final routeName = _routeNameForUri(uri);
    final navigator = navigatorKey.currentState;
    if (routeName == null || navigator == null || _openingDeepLink) return;

    _openingDeepLink = true;
    try {
      navigator.pushNamed<void>(routeName);
    } finally {
      _openingDeepLink = false;
    }
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    if (_routeNameForUri(uri) == null) return false;

    if (!_initialized || navigatorKey.currentState == null) {
      _pendingDeepLink = uri;
    } else {
      _openDeepLink(uri);
    }
    return true;
  }

  Widget? _pageForUri(Uri? uri) {
    if (uri == null) {
      return null;
    }

    final isAppScheme = uri.scheme == 'stimmapp' || uri.scheme == 'vivot';
    final pathSegments = isAppScheme && uri.host.isNotEmpty
        ? <String>[uri.host, ...uri.pathSegments]
        : uri.pathSegments;

    if (pathSegments.length == 1 && pathSegments.first == 'group-invite') {
      final groupId = uri.queryParameters['groupId'];
      if (groupId == null || groupId.isEmpty) {
        return null;
      }
      return GroupEntryPage(groupId: groupId);
    }

    if (pathSegments.isEmpty) {
      return null;
    }

    if (pathSegments.length != 2) return null;

    final id = pathSegments[1];
    switch (pathSegments[0]) {
      case 'petition':
        return PetitionDetailPage(id: id);
      case 'poll':
        return PollDetailPage(id: id);
      case 'survey':
        return SurveyDetailPage(id: id);
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pendingDeepLink = _initialUri();
    _bootstrap.init(ref).then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
      _openPendingDeepLink();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bootstrap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeScheme = ref.watch(themeSchemeProvider);
    final locale = ref.watch(appLocaleProvider);
    final selectedTheme = themeScheme ?? AppColorTheme.trainvent;

    final app = MaterialApp(
      navigatorKey: navigatorKey,
      title: (locale?.languageCode.toLowerCase() == 'en')
          ? 'Vivot'
          : 'StimmApp',
      theme: AppTheme.lightFor(selectedTheme),
      darkTheme: AppTheme.darkFor(selectedTheme),
      themeMode: themeMode,
      locale: locale,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxAllowedWidth = constraints.maxHeight * (5 / 6);
            if (constraints.maxWidth > maxAllowedWidth) {
              return ColoredBox(
                color: Colors.black,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxAllowedWidth),
                    child: ClipRect(child: child),
                  ),
                ),
              );
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
      // Custom schemes such as `stimmapp://petition/...` are not slash-based,
      // so Flutter's default initial-route generator would make the linked
      // form the only route in the stack. Always establish the app root first;
      // `_openPendingDeepLink` pushes the form once bootstrap is complete.
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          builder: (context) =>
              !_initialized ? const AppLoadingPage() : const InitAppLayout(),
          settings: const RouteSettings(name: '/'),
        ),
      ],
      onGenerateRoute: (settings) {
        final page = _pageForUri(
          settings.name == null ? null : Uri.tryParse(settings.name!),
        );
        if (page != null) {
          return MaterialPageRoute(
            builder: (context) => page,
            settings: settings,
          );
        }
        return null;
      },
      routes: {
        '/': (context) =>
            !_initialized ? const AppLoadingPage() : const InitAppLayout(),
        '/delete_account': (context) => const DeleteAccountPage(),
      },
      localizationsDelegates: const [
        S.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
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
  }
}
