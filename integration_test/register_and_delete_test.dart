import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_prod.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/l10n/app_localizations_en.dart';

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
    String email, password;
    if (!kIsWeb) {
      email = const String.fromEnvironment('EMAIL_MOB');
      password = const String.fromEnvironment('PASSWORD_MOB');
    } else {
      email = const String.fromEnvironment('EMAIL_WEB');
      password = const String.fromEnvironment('PASSWORD_WEB');
    }
    $.log(email);
    $.log(password);
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    await $(l10n.getStarted).tap();
    await $(l10n.registerHere).waitUntilVisible();
    await $(keys.onboardingPage.emailTextField).enterText(email);
    await $(
      keys.onboardingPage.passwordTextField,
    ).enterText(IConst.testSecurePassword);
    await $(keys.onboardingPage.registerButton).tap();
    await $(
      keys.emailConfirmationPage.verificationCodeTextField,
    ).waitUntilVisible();

    String? code;
    if (kIsWeb) {
      $.log("Using hardcoded verification code for test email");
      code = '123456';
    } else {
      $.log("fetching API");
      MailApi mailApi = MailApi(
        email: const String.fromEnvironment('EMAIL'),
        password: const String.fromEnvironment('PASSWORD'),
      );
      //read email data
      $.log("extract code from mail api");
      code = await mailApi.getVerificationCode();
      // Wait for the code
    }
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
    await $(keys.widgetTree.profileButton).tap();
    await Future.delayed(const Duration(seconds: 2));
  });
}
