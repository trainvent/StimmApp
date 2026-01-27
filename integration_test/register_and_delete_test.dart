import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/l10n/app_localizations_en.dart';
import 'package:stimmapp/main.dart';

import 'helpers/mail_api.dart';

void main() {
  final l10n = AppLocalizationsEn();
  patrolTest('register a new user, delete him and fail to sign in', ($) async {
    if (kIsWeb) usePathUrlStrategy();
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) => errorLogTool(
      exception: details.exception,
      errorCustomMessage: 'Flutter framework error',
    );
    PlatformDispatcher.instance.onError = (error, stack) {
      errorLogTool(
        exception: error,
        errorCustomMessage: 'Uncaught async error',
      );
      return true;
    };

    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    locator.init();
    await PurchasesService.instance.init(
      apiKey: IConst.revenueCatApiKey,
      appUserId: authService.currentUser?.uid,
    );

    if (!kIsWeb && kDebugMode) {
      await authService.setSettings(appVerificationDisabledForTesting: true);
    }

    await $.pumpWidget(const MyApp());
    await Future.delayed(const Duration(seconds: 1));
    $.log(const String.fromEnvironment('EMAIL'));
    $.log(const String.fromEnvironment('PASSWORD'));
    await Future.delayed(const Duration(seconds: 1));
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    await $(l10n.getStarted).tap();
    await $(l10n.registerHere).waitUntilVisible();
    await $(
      keys.onboardingPage.emailTextField,
    ).enterText(const String.fromEnvironment('EMAIL'));
    await $(
      keys.onboardingPage.passwordTextField,
    ).enterText(IConst.testSecurePassword);
    await $(keys.onboardingPage.registerButton).tap();
    await $(
      keys.emailConfirmationPage.verificationCodeTextField,
    ).waitUntilVisible();
    $.log("fetching API");
    //read email data
    final mailApi = MailApi(
      email: const String.fromEnvironment('EMAIL'),
      password: const String.fromEnvironment('PASSWORD'),
      logger: $.log,
    );
    $.log("extract code from mail api");
    // Wait for the code
    await Future.delayed(const Duration(seconds: 5));
    final code = await mailApi.getVerificationCode();
    $.log("received code: $code");
    if (code == null) {
      $.log("Code is null, failing test");
      throw Exception("Verification code not found");
    }
    await $(
      keys.emailConfirmationPage.verificationCodeTextField,
    ).waitUntilVisible();
    await $(
      keys.emailConfirmationPage.verificationCodeTextField,
    ).enterText(code);
    await $(keys.emailConfirmationPage.verifyButton).tap();
    await Future.delayed(const Duration(seconds: 2));
  });
}
