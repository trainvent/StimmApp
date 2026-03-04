import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/blocked_users_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

void main() {
  Widget buildTestApp(Widget child) {
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

  group('BlockedUsersPage', () {
    late FakeFirebaseFirestore fakeFirebaseFirestore;

    setUp(() async {
      fakeFirebaseFirestore = FakeFirebaseFirestore();
      locator.setDatabaseForTest(fakeFirebaseFirestore);

      await fakeFirebaseFirestore.collection('users').doc('viewer').set({
        'displayName': 'Viewer',
        'email': 'viewer@example.com',
      });
      await fakeFirebaseFirestore.collection('users').doc('blocked-user').set({
        'displayName': 'Blocked Person',
        'email': 'blocked@example.com',
      });
    });

    testWidgets('shows blocked users and allows unblocking', (tester) async {
      await fakeFirebaseFirestore
          .collection('users')
          .doc('viewer')
          .collection('blockedUsers')
          .doc('blocked-user')
          .set({
        'blockedUserId': 'blocked-user',
      });

      await tester.pumpWidget(
        buildTestApp(
          const BlockedUsersPage(userId: 'viewer'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked Person'), findsOneWidget);
      expect(find.text('blocked@example.com'), findsOneWidget);
      expect(find.text('Unblock'), findsOneWidget);

      await tester.tap(find.byKey(const Key('unblock_blocked-user')));
      await tester.pumpAndSettle();

      expect(find.text('You have not blocked anyone.'), findsOneWidget);
    });
  });
}
