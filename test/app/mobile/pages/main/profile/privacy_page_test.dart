import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/app/pages/main/profile/list/privacy_page.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/public_profile_settings_dialog.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';

import '../../../../../test_helper.dart';

class _Owner extends Mock implements User {
  @override
  String get uid => 'owner';
}

Widget ownerApp(Widget page) {
  final app = createTestWidget(page);
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWithValue(_Owner()),
      userProfileProvider.overrideWith(
        (ref) => locator.databaseService.instance
            .collection('users')
            .doc('owner')
            .snapshots()
            .map(
              (snapshot) => UserProfile.fromJson(snapshot.data()!, snapshot.id),
            ),
      ),
    ],
    child: app,
  );
}

void main() {
  testWidgets(
    'Privacy opens public profile settings; only history is on by default and choices save together',
    (tester) async {
      final app = ownerApp(const PrivacyPage());
      final db = locator.databaseService.instance;
      await db.collection('users').doc('owner').set({
        'displayName': 'Profile owner',
        'givenName': 'Ada',
        'surname': 'Example',
        'address': 'Example street 12',
        'websiteUrl': 'https://example.org',
        'analyticsCollectionEnabled': false,
      });
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hide_publications')), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('public_profile_settings_link')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PublicProfilePage), findsOneWidget);
      expect(find.byType(PublicProfileSettingsDialog), findsOneWidget);
      final history = find.byKey(
        const ValueKey('public_profile_show_publications'),
      );
      expect(tester.widget<SwitchListTile>(history).value, isTrue);
      for (final field in ['full_name', 'address', 'link']) {
        final toggle = find.byKey(ValueKey('public_profile_show_$field'));
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(history);
      await tester.tap(history);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicProfileSettingsDialog), findsNothing);
      final saved = (await db.collection('users').doc('owner').get()).data()!;
      expect(saved['hidePublications'], isTrue);
      expect(saved['publicProfileShowFullName'], isTrue);
      expect(saved['publicProfileShowAddress'], isTrue);
      expect(saved['publicProfileShowLink'], isTrue);
      expect(saved['websiteUrl'], 'https://example.org');
      expect(saved['analyticsCollectionEnabled'], false);
      expect(find.text('Ada Example'), findsOneWidget);
      expect(find.text('Example street 12'), findsOneWidget);
      expect(find.text('Open profile link'), findsOneWidget);
      expect(find.byKey(const ValueKey('publications_hidden')), findsOneWidget);
    },
  );

  testWidgets(
    'cancel discards visibility changes and leaves personal details hidden',
    (tester) async {
      final app = ownerApp(
        const PublicProfilePage(userId: 'owner', openSettings: true),
      );
      final db = locator.databaseService.instance;
      await db.collection('users').doc('owner').set({
        'displayName': 'Profile owner',
        'address': 'Private street 12',
      });
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('public_profile_show_address'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await db.collection('users').doc('owner').get())
            .data()!['publicProfileShowAddress'],
        isNull,
      );
      expect(find.text('Private street 12'), findsNothing);
    },
  );
}
