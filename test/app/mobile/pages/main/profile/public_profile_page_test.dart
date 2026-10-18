import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/app/pages/main/profile/profile_settings/update_profile_field_page.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';

import '../../../../../test_helper.dart';

class _Owner extends Mock implements User {
  @override
  String get uid => 'author';
}

void main() {
  testWidgets(
    'public profile shows nickname and public forms without personal details',
    (tester) async {
      final widget = createTestWidget(
        const ProviderScope(child: PublicProfilePage(userId: 'author')),
      );
      final db = locator.databaseService.instance;
      await db.collection('users').doc('author').set({
        'displayName': 'Creator nickname',
        'email': 'private@example.com',
        'givenName': 'Private name',
        'address': 'Private address',
        'websiteUrl': 'https://example.org/me',
        'publicProfileShowLink': true,
      });
      await db.collection('polls').doc('public').set({
        'createdBy': 'author',
        'title': 'Public poll',
        'visibility': 'public',
      });
      await db.collection('polls').doc('private').set({
        'createdBy': 'author',
        'title': 'Group-only poll',
        'visibility': 'group',
      });
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.text('Creator nickname'), findsOneWidget);
      expect(find.text('Open profile link'), findsOneWidget);
      expect(find.text('example.org'), findsOneWidget);
      expect(find.text('Public poll'), findsOneWidget);
      expect(find.text('Group-only poll'), findsNothing);
      expect(find.text('private@example.com'), findsNothing);
      expect(find.text('Private name'), findsNothing);
      expect(find.text('Private address'), findsNothing);
    },
  );

  testWidgets('missing public profile shows not found', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const ProviderScope(child: PublicProfilePage(userId: 'missing')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not found'), findsOneWidget);
  });
  testWidgets(
    'the owner can add a link and the editor accepts an empty value for removal',
    (tester) async {
      final app = createTestWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(_Owner())],
          child: const PublicProfilePage(userId: 'author'),
        ),
      );
      await locator.databaseService.instance
          .collection('users')
          .doc('author')
          .set({'displayName': 'Creator'});
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('public_profile_settings')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add link'));
      await tester.tap(find.text('Add link'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateProfileFieldPage), findsOneWidget);
      final field = find.byType(TextFormField);
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      await tester.enterText(field, 'javascript:alert(1)');
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pump();
      await tester.enterText(field, 'https://www.instagram.com/example/');
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.url,
      );
    },
  );

  testWidgets(
    'visitors cannot edit links and invalid destinations are hidden',
    (tester) async {
      final app = createTestWidget(
        const ProviderScope(
          overrides: [],
          child: PublicProfilePage(userId: 'unsafe'),
        ),
      );
      await locator.databaseService.instance
          .collection('users')
          .doc('unsafe')
          .set({'displayName': 'Creator', 'websiteUrl': 'javascript:alert(1)'});
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Open profile link'), findsNothing);
      expect(find.text('Add link'), findsNothing);
      expect(find.text('Edit link'), findsNothing);
    },
  );
  testWidgets(
    'hidden publications show a lock while nickname and profile link stay visible',
    (tester) async {
      final app = createTestWidget(
        const ProviderScope(child: PublicProfilePage(userId: 'hidden-author')),
      );
      final db = locator.databaseService.instance;
      await db.collection('users').doc('hidden-author').set({
        'displayName': 'Private creator',
        'hidePublications': true,
        'websiteUrl': 'https://example.org',
        'publicProfileShowLink': true,
      });
      await db.collection('petitions').doc('hidden-publication').set({
        'title': 'Do not list this petition',
        'createdBy': 'hidden-author',
      });
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('publications_hidden')), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Publications are hidden'), findsOneWidget);
      expect(find.text('Do not list this petition'), findsNothing);
      expect(find.text('Private creator'), findsOneWidget);
      expect(find.text('Open profile link'), findsOneWidget);
    },
  );
}
