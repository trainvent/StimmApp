import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart' as dev;
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';

Future<void> initializeApp(PatrolIntegrationTester $) async {
  // Initialize app environment
  WidgetsFlutterBinding.ensureInitialized();
  Environment.init(EnvironmentType.dev);
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

  // Initialize Firebase with the provided options (Prod or Dev)

  await Firebase.initializeApp(
    options: dev.DefaultFirebaseOptions.currentPlatform,
  );
  locator.init();
  if (!kIsWeb && kDebugMode) {
    await authService.setSettings(appVerificationDisabledForTesting: true);
  }
  await $.pumpWidgetAndSettle(const ProviderScope(child: MyApp()));
}
