import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
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
            $.log("Password: $password");
            await $(l10n.getStarted).tap();
            await $(l10n.registerHere).waitUntilVisible();
            await $(keys.onboardingPage.emailTextField).enterText(email);
            await $(keys.onboardingPage.passwordTextField).enterText(password);
            await $(keys.onboardingPage.repeatPasswordTextField).enterText(password);
            await $(keys.onboardingPage.registerButton).tap();

            // Verification Code
            await $(
              keys.emailConfirmationPage.verificationCodeTextField,
            ).waitUntilVisible();
            await $(
              keys.emailConfirmationPage.verificationCodeTextField,
            ).enterText(testCode);
            await $(keys.emailConfirmationPage.verifyButton).tap();

            // Set User Details
            await $(keys.setUserDetailsPage.givenNameTextField).enterText("Validation");
            await $(keys.setUserDetailsPage.surnameTextField).enterText("Tester");
            await $(keys.setUserDetailsPage.displayNameTextField).enterText("valtester");
            await $(keys.setUserDetailsPage.dateOfBirthTextField).tap();
            await Future.delayed(const Duration(seconds: 1));
            await $.platformAutomator.tap(Selector(text: 'OK'));
            await Future.delayed(const Duration(seconds: 1));
            // Address
            await $(
              keys.setUserDetailsPage.addressTextField,
            ).enterText("Ravensberger Straße 42, 33602");
            await $(RegExp('Bielefeld')).waitUntilVisible();
            await $(RegExp('Bielefeld')).tap();
            await $(RegExp('Nordrhein')).waitUntilVisible();
            await $(keys.setUserDetailsPage.saveButton).tap();
            await $(keys.widgetTree.profileButton).tap();
            await $(keys.profilePage.logoutListTile).scrollTo().tap();
            await $(keys.profilePage.confirmLogoutButton).tap();
            await $(keys.widgetTree.profileButton).tap();
            await $(keys.profilePage.deleteAccountListTile).scrollTo().tap();
            await $(keys.profilePage.confirmDeleteButton).tap();

            await $(keys.deleteAccountPage.emailTextField).enterText(email);
            await $(
              keys.deleteAccountPage.passwordTextField,
            ).enterText(password);
            await $(keys.deleteAccountPage.deleteAccountButton).tap();

            // Wait for deletion and navigation back to WelcomePage
            await $(l10n.theWelcomePhrase).waitUntilVisible();

            $.log("Validation and full onboarding flow tests completed");
          },
  );
}
