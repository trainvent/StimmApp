import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:stimmapp/core/constants/integration_test_constants.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/l10n/app_localizations_de.dart';

import '../helpers/initialization.dart';

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
      await $(l10n.register).tap();
      await $(l10n.registerHere).waitUntilVisible();
      await $(keys.onboardingPage.emailTextField).enterText(email);
      await $(keys.onboardingPage.passwordTextField).enterText(validPassword);
      await $(
        keys.onboardingPage.repeatPasswordTextField,
      ).enterText(validPassword);
      await $(keys.onboardingPage.registerButton).tap();
      // Verification Code
      await $(
        keys.verificationWidget.verificationCodeTextField,
      ).waitUntilVisible();
      $.log("verification code field found");
      await $(
        keys.verificationWidget.verificationCodeTextField,
      ).enterText(testCode);
      await $(
        keys.setUserDetailsPage.givenNameTextField,
      ).enterText("Validation");
      await $(keys.setUserDetailsPage.surnameTextField).enterText("Tester");
      await $(
        keys.setUserDetailsPage.displayNameTextField,
      ).enterText("valtester");
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
    },
  );
}
