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

  patrolTest(
    'onboarding validation test: invalid email, weak password, and mismatched passwords',
    ($) async {
      await initializeApp($);
      final validPassword = password.isNotEmpty
          ? password
          : IConst.testSecurePassword;
      await $(l10n.signIn).tap();

      // Login with new password to delete account
      await $(keys.loginPage.emailTextField).enterText(email);
      await $(keys.loginPage.passwordTextField).enterText(validPassword);
      await $(keys.loginPage.signInButton).tap();
      await $(l10n.petitions).tap();
      await Future.delayed(const Duration(seconds: 2)); // Wait for list to load
      
      // Try to tap the first ListTile found in the scrollable list.
      // Using `at(0)` on `$(ListTile)` might find other ListTiles on screen (e.g. in drawer or headers).
      // We specifically want the one inside the main scroll view.
      // Also, sometimes tapping the center of a large tile is safer.
      await $(ListTile).at(0).tap();

      // Now in Petition Detail Page
      await $(l10n.sign).waitUntilVisible();

      // Go back to list
      await $(BackButton).tap();
      await $(l10n.closed).tap();
      await Future.delayed(const Duration(seconds: 2)); // Wait for list to load

      // Try to tap the first ListTile found in the scrollable list.
      await $(ListTile).at(0).tap();

      await $(BackButton).tap();
      await $(keys.widgetTree.profileButton).tap();
      await $(keys.profilePage.logoutListTile).scrollTo().tap();
      await $(keys.profilePage.confirmLogoutButton).tap();
    },
  );
}
