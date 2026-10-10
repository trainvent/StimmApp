import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';
import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/participants_list_page.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

void main() {
  test('profile picture URL survives parsing, copying and serialization', () {
    final profile = UserProfile.fromJson({
      'displayName': 'Participant',
      'profilePictureUrl': 'https://example.com/avatar.jpg',
    }, 'participant');
    expect(profile.profilePictureUrl, 'https://example.com/avatar.jpg');
    expect(
      profile.copyWith(displayName: 'Updated').profilePictureUrl,
      profile.profilePictureUrl,
    );
    expect(profile.toJson()['profilePictureUrl'], profile.profilePictureUrl);
    expect(profile.copyWith(profilePictureUrl: null).profilePictureUrl, isNull);
  });

  for (final withSignatures in [false, true]) {
    testWidgets(
      'loads participant avatar with fallback (signatures: $withSignatures)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ParticipantsListPage(
              participantsStream: Stream.value(const [
                UserProfile(
                  uid: 'picture',
                  displayName: 'With picture',
                  profilePictureUrl: 'https://example.com/avatar.jpg',
                ),
                UserProfile(uid: 'missing', displayName: 'Without picture'),
              ]),
              signaturesStream: withSignatures
                  ? Stream.value([
                      {'uid': 'picture', 'reason': ''},
                      {'uid': 'missing', 'reason': ''},
                      {'uid': 'unknown', 'reason': ''},
                    ])
                  : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          (image.image as NetworkImage).url,
          'https://example.com/avatar.jpg',
        );
        expect(
          image.errorBuilder!(
            tester.element(find.byType(Image)),
            Exception('failed download'),
            null,
          ),
          isA<CircleAvatar>(),
        );
        expect(find.text('With picture'), findsOneWidget);
        expect(find.text('Without picture'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final withSignatures in [false, true]) {
    testWidgets(
      'participant tile opens its public profile (signatures: $withSignatures)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              publicProfileProvider('participant')
                  .overrideWith((ref) => Stream.value(null)),
            ],
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: ParticipantsListPage(
                participantsStream: Stream.value(const [
                  UserProfile(uid: 'participant', displayName: 'Participant'),
                ]),
                signaturesStream: withSignatures
                    ? Stream.value([
                        {'uid': 'participant'},
                      ])
                    : null,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Participant'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PublicProfilePage>(find.byType(PublicProfilePage))
              .userId,
          'participant',
        );
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.widgetWithText(ListTile, 'Participant'), findsOneWidget);
      },
    );
  }

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
