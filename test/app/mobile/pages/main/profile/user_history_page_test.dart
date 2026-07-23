import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/list/user_history_page.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: child,
  );
}

void main() {
  testWidgets(
    'shows participation and publications with distinct icons in activity order',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      const uid = 'user-1';

      await firestore.collection('petitions').doc('created-petition').set({
        'title': 'Newest publication',
        'createdBy': uid,
        'createdAt': DateTime(2026, 1, 4),
      });
      await firestore.collection('polls').doc('voted-poll').set({
        'title': 'Recent vote',
        'createdBy': 'someone-else',
        'createdAt': DateTime(2025),
      });
      await firestore.collection('polls').doc('created-poll').set({
        'title': 'Older publication',
        'createdBy': uid,
        'createdAt': DateTime(2026, 1, 2),
      });
      await firestore.collection('petitions').doc('signed-petition').set({
        'title': 'Oldest signature',
        'createdBy': 'someone-else',
        'createdAt': DateTime(2026, 1, 5),
      });

      final user = firestore.collection('users').doc(uid);
      await user.collection('votedPolls').doc('voted-poll').set({
        'votedAt': DateTime(2026, 1, 3),
      });
      await user.collection('signedPetitions').doc('signed-petition').set({
        'signedAt': DateTime(2026, 1, 1),
      });

      await tester.pumpWidget(
        _testApp(UserHistoryPage(uid: uid, database: firestore)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Newest publication'), findsOneWidget);
      expect(find.text('Recent vote'), findsOneWidget);
      expect(find.text('Older publication'), findsOneWidget);
      expect(find.text('Oldest signature'), findsOneWidget);
      expect(find.text('Petition created'), findsOneWidget);
      expect(find.text('Voted'), findsOneWidget);
      expect(find.text('Poll created'), findsOneWidget);
      expect(find.text('Signed'), findsOneWidget);

      expect(find.byIcon(Icons.publish_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.how_to_vote_outlined), findsNWidgets(2));

      final verticalPositions = [
        'Newest publication',
        'Recent vote',
        'Older publication',
        'Oldest signature',
      ].map((title) => tester.getTopLeft(find.text(title)).dy).toList();
      expect(verticalPositions, orderedEquals([...verticalPositions]..sort()));
    },
  );
}
