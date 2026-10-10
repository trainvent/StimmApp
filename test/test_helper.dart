import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:stimmapp/core/data/repositories/public_profile_repository.dart';

import 'helpers/participant_access.dart';

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

Widget createTestWidget(Widget child, {Locale locale = const Locale('en')}) {
  initializeTestDependencies();

  final db = locator.databaseService.instance as FakeFirebaseFirestore;
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => ProviderScope(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(
          PublicProfileRepository(
            locator.databaseService,
            access: fakeParticipantAccess(db),
          ),
        ),
      ],
      child: child!,
    ),
    home: child,
  );
}
