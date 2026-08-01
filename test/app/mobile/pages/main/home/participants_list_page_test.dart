import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/participants_list_page.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

void main() {
  testWidgets('shows a localized placeholder for an erroneous profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ParticipantsListPage(
          participantsStream: Stream.value(const [
            UserProfile(uid: 'working', displayName: 'Working User'),
            UserProfile.erroneous('broken'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Working User'), findsOneWidget);
    expect(find.text('<erroneous profile>'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
