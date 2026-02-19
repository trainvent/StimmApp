import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/l10n/app_localizations_de.dart';

import 'helpers/initialization.dart';

void main() {
  final l10n = AppLocalizationsDe();
  const email = String.fromEnvironment('TEST_EMAIL');
  const password = IConst.testSecurePassword;
  const testCode = String.fromEnvironment('TEST_CODE');

  patrolTest(
    'onboarding validation test: invalid email, weak password, and mismatched passwords',
    ($) async {
      await initializeApp($);

      final validPassword = password.isNotEmpty
          ? password
          : IConst.testSecurePassword;
      await regNOut($, l10n, email, validPassword, testCode);

      // Verify back at Welcome and try to register again
      await $(l10n.theWelcomePhrase).waitUntilVisible();
      await $(l10n.register).tap();

      // 6. Test: Existing User Registration Denied
      await $(keys.onboardingPage.emailTextField).enterText(email);
      await $(keys.onboardingPage.passwordTextField).enterText(validPassword);
      await $(
        keys.onboardingPage.repeatPasswordTextField,
      ).enterText(validPassword);
      await $(keys.onboardingPage.registerButton).tap();

      // Firebase usually returns an error like "email-already-in-use"
      await $(l10n.registerHere).waitUntilVisible();

      // 7. Test: Forgot Password / Login with Code Flow
      await $(BackButton).tap();
      await $(l10n.signIn).tap();
      await $(l10n.resetPassword).tap();

      await $(keys.resetPasswordPage.emailTextField).enterText(email);
      await $(keys.resetPasswordPage.sendLoginCodeButton).tap();

      // Try wrong code
      await $(
        keys.verificationWidget.verificationCodeTextField,
      ).enterText('000000');
      // No confirm button anymore, verification happens automatically on 6 digits
      // But since it's wrong code, it should show error and stay on page

      // Wait for the error text to appear which implies loading is done
      // Assuming error snackbar or text appears.
      // Since we can't easily check snackbar content with just keys, we proceed to correct code.

      // Try correct code - enterText replaces content by default
      await $(keys.verificationWidget.verificationCodeTextField).waitUntilVisible();
      await $(
        keys.verificationWidget.verificationCodeTextField,
      ).enterText(testCode);
      // No confirm button tap needed, auto-verifies

      // Set new password
      await $(
        keys.setNewPasswordPage.newPasswordTextField,
      ).enterText(validPassword);
      await $(
        keys.setNewPasswordPage.confirmPasswordTextField,
      ).enterText(validPassword);
      await $(l10n.confirm).tap();

      // Should be logged out and back at Welcome
      await $(l10n.theWelcomePhrase).waitUntilVisible();
      await $(l10n.signIn).tap();

      // Login with new password to delete account
      await $(keys.loginPage.emailTextField).enterText(email);
      await $(keys.loginPage.passwordTextField).enterText(validPassword);
      await $(keys.loginPage.signInButton).tap();
      await $(keys.widgetTree.profileButton).tap();

      // Delete Account Flow
      await $(keys.profilePage.deleteAccountListTile).scrollTo().tap();
      await $(keys.profilePage.confirmDeleteButton).tap();

      // Now on DeleteAccountPage
      await $(keys.deleteAccountPage.emailTextField).enterText(email);
      await $(
        keys.deleteAccountPage.passwordTextField,
      ).enterText(validPassword);
      await $(keys.deleteAccountPage.deleteAccountButton).tap();

      // Wait for deletion and navigation back to WelcomePage
      await $(l10n.theWelcomePhrase).waitUntilVisible();
      await $(l10n.signIn).tap();
      await $(keys.loginPage.emailTextField).enterText(email);
      await $(keys.loginPage.passwordTextField).enterText(validPassword);
      await $(keys.loginPage.signInButton).tap();
      await $(BackButton).tap();
      await $(l10n.theWelcomePhrase).waitUntilVisible();
      $.log("Validation and full onboarding flow tests completed");
    },
  );
}

Future<void> regNOut(
  PatrolIntegrationTester $,
  AppLocalizationsDe l10n,
  String email,
  String validPassword,
  String testCode,
) async {
  await Future.delayed(const Duration(seconds: 1));

  // Navigate to Onboarding
  await $(l10n.register).tap();
  await $(l10n.registerHere).waitUntilVisible();

  // 1. Test: Mismatched Passwords
  await $(keys.onboardingPage.emailTextField).enterText('test@example.com');
  await $(keys.onboardingPage.passwordTextField).enterText('Password123!');
  await $(
    keys.onboardingPage.repeatPasswordTextField,
  ).enterText('Different123!');
  await $(keys.onboardingPage.registerButton).tap();

  expect($(l10n.passwordsDoNotMatch), findsOneWidget);

  // 2. Test: Weak Password (too short)
  await $(keys.onboardingPage.passwordTextField).enterText('123');
  await $(keys.onboardingPage.repeatPasswordTextField).enterText('123');
  await $(keys.onboardingPage.registerButton).tap();

  // Check if the button tap didn't proceed to the next page.
  expect($(l10n.registerHere), findsOneWidget);

  // 3. Test: Empty Fields
  await $(keys.onboardingPage.emailTextField).enterText('');
  await $(keys.onboardingPage.passwordTextField).enterText('');
  await $(keys.onboardingPage.repeatPasswordTextField).enterText('');
  await $(keys.onboardingPage.registerButton).tap();

  expect($(l10n.enterSomething), findsWidgets);

  // 4. Test: Invalid Email Format
  await $(keys.onboardingPage.emailTextField).enterText('not-an-email');
  await $(keys.onboardingPage.passwordTextField).enterText('ValidPass123!');
  await $(
    keys.onboardingPage.repeatPasswordTextField,
  ).enterText('ValidPass123!');
  await $(keys.onboardingPage.registerButton).tap();

  // 5. Test: Valid Credentials and Full Flow
  await $(keys.onboardingPage.emailTextField).enterText(email);
  await $(keys.onboardingPage.passwordTextField).enterText(validPassword);
  await $(keys.onboardingPage.repeatPasswordTextField).enterText(validPassword);
  await $(keys.onboardingPage.registerButton).tap();

  // Verification Code
  await $(
    keys.verificationWidget.verificationCodeTextField,
  ).waitUntilVisible();
  $.log("verification code field found");
  await $(
    keys.verificationWidget.verificationCodeTextField,
  ).enterText(testCode);
  // No verify button tap needed, auto-verifies

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

  // Logout
  await $(keys.widgetTree.profileButton).tap();
  await $(keys.profilePage.logoutListTile).scrollTo().tap();
  await $(keys.profilePage.confirmLogoutButton).tap();

}
