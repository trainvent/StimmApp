import 'package:flutter/foundation.dart';

class OnboardingPageKeys {
  final emailTextField = const Key('emailTestField');
  final passwordTextField = const Key('passwordTestField');
  final repeatPasswordTextField = const Key('repeatPasswordTextField');
  final registerButton = const Key('registerButton');
}

class EmailConfirmationPageKeys {
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
  final idApprovedListTile = const Key('idApprovedListTile');
  final formExportListTile = const Key('formExportListTile');
  final blockedUsersListTile = const Key('blockedUsersListTile');
  final userHistoryPageListTile = const Key('userHistoryPageListTile');
  final deleteAccountListTile = const Key('deleteAccountListTile');
  final logoutListTile = const Key('logoutListTile');
  final confirmLogoutButton = const Key('confirmLogoutButton');
  final cancelLogoutButton = const Key('cancelLogoutButton');
  final confirmDeleteButton = const Key('confirmDeleteButton');
  final cancelDeleteButton = const Key('cancelDeleteButton');
}

class SetUserDetailsPageKeys {
  final saveButton = const Key('saveButton');
  final surnameTextField = const Key('surnameTextField');
  final givenNameTextField = const Key('givenNameTextField');
  final displayNameTextField = const Key('displayNameTextField');
  final dateOfBirthTextField = const Key('dateOfBirthTextField');
  final addressTextField = const Key('addressTextField');
  final agreenmentCheckboxListTile = const Key('agreenmentCheckboxListTile');
}

class ResetPasswordPageKeys {
  final emailTextField = const Key('emailTestField');
  final sendLoginCodeButton = const Key('sendLoginCodeButton');
  final verificationCodeTextField = const Key('verificationCodeTextField');
  final confirmButton = const Key('confirmButton');
  final cancelButton = const Key('cancelButton');
  final error = const Key('error');
  final loading = const Key('loading');
}

class SetNewPasswordPageKeys {
  final newPasswordTextField = const Key('newPasswordTextField');
  final confirmPasswordTextField = const Key('confirmPasswordTextField');
  final confirmButton = const Key('confirmButton');
}

class DeleteAccountPageKeys {
  final emailTextField = const Key('deleteAccountEmailField');
  final passwordTextField = const Key('deleteAccountPasswordField');
  final deleteAccountButton = const Key('deleteAccountButton');
}

class VerificationWidgetKeys {
  final verificationCodeTextField = const Key('verificationCodeTextField');
  final resendCodeButton = const Key('resendCodeButton');
}

class PetitionDetailPageKeys {
  final signButton = const Key('signButton');
}

class Keys {
  final resetPasswordPage = ResetPasswordPageKeys();
  final loginPage = LoginPageKeys();
  final emailConfirmationPage = EmailConfirmationPageKeys();
  final onboardingPage = OnboardingPageKeys();
  final widgetTree = WidgetTreeKeys();
  final profilePage = ProfilePageKeys();
  final setUserDetailsPage = SetUserDetailsPageKeys();
  final setNewPasswordPage = SetNewPasswordPageKeys();
  final deleteAccountPage = DeleteAccountPageKeys();
  final verificationWidget = VerificationWidgetKeys();
  final petitionDetailPage = PetitionDetailPageKeys();
}

final keys = Keys();
