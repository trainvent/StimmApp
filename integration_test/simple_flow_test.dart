import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart'; // Import app_entry for MyApp
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart' as dev;
// Import both configurations
import 'package:stimmapp/core/data/firebase/firebase_options_prod.dart' as prod;
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';
import 'package:stimmapp/core/services/purchases_service.dart';
import 'package:stimmapp/l10n/app_localizations_de.dart';

import 'helpers/mail_api.dart';

void main() {
  final l10n = AppLocalizationsDe();
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

    // Determine Flavor
    const flavor = String.fromEnvironment('FLAVOR');
    final isDev = flavor == 'dev';

    // Initialize Environment
    Environment.init(isDev ? EnvironmentType.dev : EnvironmentType.prod);

    // Select Firebase Options
    final firebaseOptions = isDev
        ? dev.DefaultFirebaseOptions.currentPlatform
        : prod.DefaultFirebaseOptions.currentPlatform;

    await Firebase.initializeApp(options: firebaseOptions);

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

    // Read variables passed via --dart-define
    const email = String.fromEnvironment('EMAIL');
    const password = String.fromEnvironment('PASSWORD');
    const testCode = String.fromEnvironment('TEST_CODE');

    $.log("Flavor: $flavor");
    $.log("Email: $email");

    await Future.delayed(const Duration(seconds: 1));
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    await $(l10n.getStarted).tap();
    await $(l10n.registerHere).waitUntilVisible();
    await $(keys.onboardingPage.emailTextField).enterText(email);
    await $(
      keys.onboardingPage.passwordTextField,
    ).enterText(password.isNotEmpty ? password : IConst.testSecurePassword);
    await $(
      keys.onboardingPage.repeatPasswordTextField,
    ).enterText(password.isNotEmpty ? password : IConst.testSecurePassword);
    await $(keys.onboardingPage.registerButton).tap();
    await $(
      keys.emailConfirmationPage.verificationCodeTextField,
    ).waitUntilVisible();

    String? code;
    if (testCode.isNotEmpty) {
      $.log("Using provided test code via --dart-define");
      code = testCode;
    } else {
      $.log("fetching API");
      //read email data
      final mailApi = MailApi(email: email, password: password, logger: $.log);
      $.log("extract code from mail api");
      // Wait for the code
      await Future.delayed(const Duration(seconds: 5));
      code = await mailApi.getVerificationCode();
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
    await $(keys.setUserDetailsPage.givenNameTextField).enterText("Tester");
    await $(keys.setUserDetailsPage.surnameTextField).enterText("Georg");

    // Interact with the Date Picker natively
    await $(keys.setUserDetailsPage.dateOfBirthTextField).tap();
    // Wait for dialog animation
    await Future.delayed(const Duration(seconds: 1));
    // Tap OK to select the default date (today)
    await $.platformAutomator.tap(Selector(text: 'OK'));

    // Enter partial address so the suggestion contains unique texts
    await $(keys.setUserDetailsPage.addressTextField).tap();
    const partialAddress = "Ravensberger Straße 42, 33602";
    await $(keys.setUserDetailsPage.addressTextField).enterText(partialAddress);

    // Wait for Google Places suggestions to appear
    await Future.delayed(const Duration(seconds: 2));

    // Tap the suggestion containing "Bielefeld".
    await $(RegExp('Bielefeld')).tap();
    await $(RegExp('Nordrhein-Westfalen')).waitUntilVisible();
    await $(keys.setUserDetailsPage.saveButton).tap();
    await $(keys.widgetTree.profileButton).tap();

    // Delete Account Flow
    await $(keys.profilePage.deleteAccountListTile).scrollTo().tap();
    await $(keys.profilePage.confirmDeleteButton).tap();

    // Now on DeleteAccountPage
    await $(const Key('deleteAccountEmailField')).enterText(email);
    await $(
      const Key('deleteAccountPasswordField'),
    ).enterText(password.isNotEmpty ? password : IConst.testSecurePassword);
    await $(const Key('deleteAccountButton')).tap();

    // Wait for deletion and navigation back to WelcomePage
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    await Future.delayed(const Duration(seconds: 2));
  });
}
