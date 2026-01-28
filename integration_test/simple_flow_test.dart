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

void main() {
  final l10n = AppLocalizationsEn();
  patrolTest('navigate to login and back', ($) async {
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
    $.log("initialized");
    await $.pumpWidget(const MyApp());
    $.log('Reached login screen');
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    $.log('detected welcome phrase');
    await $(l10n.login).tap();
    await $(l10n.signIn).waitUntilVisible();
    await $(
      keys.loginPage.emailTextField,
    ).enterText(const String.fromEnvironment('EMAIL'));
    await $(
      keys.loginPage.passwordTextField,
    ).enterText(const String.fromEnvironment('PASSWORD'));
    await $(keys.loginPage.signInButton).tap();
    await $(keys.widgetTree.profileButton).tap();
    await $(keys.profilePage.logoutListTile).scrollTo().tap();
    await $(keys.profilePage.confirmLogoutButton).tap();
    await $(l10n.theWelcomePhrase).waitUntilVisible();
    await Future.delayed(const Duration(seconds: 2));
  });
}
