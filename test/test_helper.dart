
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

void initializeTestDependencies() {
  TestWidgetsFlutterBinding.ensureInitialized();
  locator.setDatabaseForTest(FakeFirebaseFirestore());
}

Widget createTestWidget(Widget child) {
  initializeTestDependencies();

  return MaterialApp(
    locale: const Locale('en', ''),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''),
    ],
    home: child,
  );
}
