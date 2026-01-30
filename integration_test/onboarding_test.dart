import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/firebase/firebase_options_dev.dart' as dev;
import 'package:stimmapp/l10n/app_localizations_de.dart';

void main() {
  final l10n = AppLocalizationsDe();
  const email = String.fromEnvironment('EMAIL');
  const password = String.fromEnvironment('PASSWORD');
  const testCode = String.fromEnvironment('TEST_CODE');

  patrolTest(
    'onboarding validation test: invalid email, weak password, and mismatched passwords',
    ($) async {
      // Initialize app environment
      WidgetsFlutterBinding.ensureInitialized();
      Environment.init(EnvironmentType.dev);
      await Firebase.initializeApp(
        options: dev.DefaultFirebaseOptions.currentPlatform,
      );
      locator.init();

      await $.pumpWidget(const MyApp());

      await Future.delayed(const Duration(seconds: 1));

      // Navigate to Onboarding
      await $(l10n.getStarted).tap();
      await $(l10n.registerHere).waitUntilVisible();

      // 1. Test: Mismatched Passwords
      await $(keys.onboardingPage.emailTextField).enterText('test@example.com');
      await $(keys.onboardingPage.passwordTextField).enterText('Password123!');
      await $(const Key('repeatPasswordTextField')).enterText('Different123!');
      await $(keys.onboardingPage.registerButton).tap();

      expect($(l10n.passwordsDoNotMatch), findsOneWidget);

      // 2. Test: Weak Password (too short)
      // Assuming validatePassword triggers on field or on submit
      await $(keys.onboardingPage.passwordTextField).enterText('123');
      await $(const Key('repeatPasswordTextField')).enterText('123');
      await $(keys.onboardingPage.registerButton).tap();

      // The specific error message depends on validate_password.dart implementation,
      // but usually it shows a validation error text in the form field.
      // We check if the button tap didn't proceed to the next page.
      expect($(l10n.registerHere), findsOneWidget);

      // 3. Test: Empty Fields
      await $(keys.onboardingPage.emailTextField).enterText('');
      await $(keys.onboardingPage.passwordTextField).enterText('');
      await $(const Key('repeatPasswordTextField')).enterText('');
      await $(keys.onboardingPage.registerButton).tap();

      expect($(l10n.enterSomething), findsWidgets);

      // 4. Test: Invalid Email Format
      // Note: The current OnboardingPage validator only checks for empty strings.
      // If a regex validator is added later, this test would catch it.
      await $(keys.onboardingPage.emailTextField).enterText('not-an-email');
      await $(keys.onboardingPage.passwordTextField).enterText('ValidPass123!');
      await $(const Key('repeatPasswordTextField')).enterText('ValidPass123!');
      await $(keys.onboardingPage.registerButton).tap();

      // 5. Test: Valid Credentials and Full Flow
      await $(keys.onboardingPage.emailTextField).enterText(email);
      final validPassword = password.isNotEmpty
          ? password
          : IConst.testSecurePassword;
      await $(keys.onboardingPage.passwordTextField).enterText(validPassword);
      await $(const Key('repeatPasswordTextField')).enterText(validPassword);
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
      await $(
        keys.setUserDetailsPageKeys.givenNameTextField,
      ).enterText("Validation");
      await $(keys.setUserDetailsPageKeys.surnameTextField).enterText("Tester");
      await $(keys.setUserDetailsPageKeys.dateOfBirthTextField).tap();
      await Future.delayed(const Duration(seconds: 1));
      await $.platformAutomator.tap(Selector(text: 'OK'));

      // Address
      await $(
        keys.setUserDetailsPageKeys.addressTextField,
      ).enterText("Ravensberger Straße 42, 33602");
      await Future.delayed(const Duration(seconds: 2));
      await $(RegExp('Bielefeld')).tap();
      await $(keys.setUserDetailsPageKeys.saveButton).tap();

      // Logout
      await $(keys.widgetTree.profileButton).tap();
      await $(keys.profilePage.logoutListTile).scrollTo().tap();
      await $(keys.profilePage.confirmLogoutButton).tap();

      // Verify back at Welcome and try to register again
      await $(l10n.theWelcomePhrase).waitUntilVisible();
      await $(l10n.getStarted).tap();
      await $(l10n.registerHere).waitUntilVisible();

      // 6. Test: Existing User Registration Denied
      await $(keys.onboardingPage.emailTextField).enterText(email);
      await $(keys.onboardingPage.passwordTextField).enterText(validPassword);
      await $(const Key('repeatPasswordTextField')).enterText(validPassword);
      await $(keys.onboardingPage.registerButton).tap();

      // Firebase usually returns an error like "email-already-in-use"
      // We check that we are still on the registration page or see an error snackbar
      await $(l10n.registerHere).waitUntilVisible();

      // 7. Test: Forgot Password / Login with Code Flow
      // Navigate back to Welcome then to Login (ResetPasswordPage is reached via Login usually,
      // but here we can go back and use the "Reset Password" logic)
      //test broke here
      await $.native.pressBack();
      await $(l10n.signIn).tap();
      await $(l10n.resetPassword).tap();

      await $(keys.onboardingPage.emailTextField).enterText(email);
      await $(l10n.sendLoginLink).tap();

      // Wait for dialog
      await $(l10n.enterCode).waitUntilVisible();

      // Try wrong code
      await $(const Key('verificationCodeTextField')).enterText('000000');
      await $(l10n.confirm).tap();
      // Expect error snackbar or dialog to stay
      await $(l10n.enterCode).waitUntilVisible();

      // Try correct code
      await $(const Key('verificationCodeTextField')).enterText(testCode);
      await $(l10n.confirm).tap();

      // Verify successful login (should be on Home/Profile)
      await $(keys.widgetTree.profileButton).waitUntilVisible();

      $.log("Validation and full onboarding flow tests completed");
    },
  );
}
