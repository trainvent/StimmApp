import 'package:flutter/foundation.dart';

class OnboardingPageKeys {
  final emailTextField = const Key('emailTestField');
  final passwordTextField = const Key('passwordTestField');
  final registerButton = const Key('registerButton');
}

class EmailConfirmationPageKeys {
  final verificationCodeTextField = const Key('verificationCodeTextField');
  final verifyButton = const Key('verifyButton');
  final resendCodeButton = const Key('resendCodeButton');
  final backButton = const Key('backButton');
}

class LoginPageKeys {
  final emailTextField = const Key('emailTestField');
  final passwordTextField = const Key('passwordTestField');
  final forgotPasswordButton = const Key('forgotPasswordButton');
  final signInButton = const Key('signInButton');
}

class WidgetTreeKeys {
  final profileButton = const Key('profileButton');
  final settingsButton = const Key('settingsButton');
}

class ProfilePageKeys {
  final heroWidget = const Key('heroWidget');
  final changeLivingAddressListTile = const Key('changeLivingAddressListTile');
  final changeEmailListTile = const Key('changeEmailListTile');
  final changeUserNameListTile = const Key('changeUserNameListTile');
  final changePasswordListTile = const Key('changePasswordListTile');
  final manageSubscriptionsListTile = const Key('manageSubscriptionsListTile');
  final adminDashboardListTile = const Key('adminDashboardListTile');
  final formExportListTile = const Key('formExportListTile');
  final userHistoryPageListTile = const Key('userHistoryPageListTile');
  final deleteAccountListTile = const Key('deleteAccountListTile');
  final logoutListTile = const Key('logoutListTile');
  final confirmLogoutButton = const Key('confirmLogoutButton');
  final cancelLogoutButton = const Key('cancelLogoutButton');
}

class Keys {
  final loginPage = LoginPageKeys();
  final emailConfirmationPage = EmailConfirmationPageKeys();
  final onboardingPage = OnboardingPageKeys();
  final widgetTree = WidgetTreeKeys();
  final profilePage = ProfilePageKeys();
}

final keys = Keys();
