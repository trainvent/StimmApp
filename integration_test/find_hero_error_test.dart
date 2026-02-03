import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/l10n/app_localizations_de.dart';


void main() {
  final l10n = AppLocalizationsDe();
  const email = String.fromEnvironment('TEST_EMAIL');
  const password = String.fromEnvironment('TEST_PASSWORD');
  const testCode = String.fromEnvironment('TEST_CODE');

  patrolTest(
      'onboarding validation test: invalid email, weak password, and mismatched passwords',
          ($) async {
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
            await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

            locator.init();
            await PurchasesService.instance.init(
              apiKey: IConst.revenueCatApiKey,
              appUserId: authService.currentUser?.uid,
            );

            if (!kIsWeb && kDebugMode) {
              await authService.setSettings(appVerificationDisabledForTesting: true);
            }


            await $.pumpWidgetAndSettle(const MyApp());
            await $(l10n.theWelcomePhrase).waitUntilVisible();
            $.log("Validation and full onboarding flow tests completed");
          },
  );
}
