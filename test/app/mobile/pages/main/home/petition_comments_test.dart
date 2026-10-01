import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/home/petitions/petition_comments.dart';
import 'package:stimmapp/core/data/repositories/petition_comment_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/petition_comments_provider.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class _User implements User {
  @override
  String get uid => 'reader';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore db;
  late PetitionCommentRepository repository;
  setUp(() async {
    db = FakeFirebaseFirestore();
    repository = PetitionCommentRepository(DatabaseService(db));
    await db.doc('petitions/p').set({'title': 'Petition'});
    await db.doc('users/author').set({'displayName': 'Comment author'});
    await db.doc('petitions/p/signatures/author').set({
      'reason': 'Please protect our park',
    });
  });

  Widget app({bool signedIn = true, Stream<Set<String>>? blocked}) =>
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(signedIn ? _User() : null),
          petitionCommentRepositoryProvider.overrideWithValue(repository),
          commentBlockedUserIdsProvider.overrideWith(
            (ref) => blocked ?? Stream.value(<String>{}),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: PetitionComments(petitionId: 'p'),
            ),
          ),
        ),
      );

  testWidgets('shows existing comment and updates like and unlike live', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Comment author'), findsOneWidget);
    expect(find.text('Please protect our park'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(await repository.watchLikes('p', 'author').first, {'reader'});
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(await repository.watchLikes('p', 'author').first, isEmpty);
  });

  testWidgets('signed-out readers can read but cannot like', (tester) async {
    await tester.pumpWidget(app(signedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('Please protect our park'), findsOneWidget);
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('comments disappear when their author is blocked', (
    tester,
  ) async {
    final blocked = StreamController<Set<String>>();
    addTearDown(blocked.close);
    await tester.pumpWidget(app(blocked: blocked.stream));
    blocked.add({});
    await tester.pumpAndSettle();
    expect(find.text('Please protect our park'), findsOneWidget);
    blocked.add({'author'});
    await tester.pumpAndSettle();
    expect(find.text('Please protect our park'), findsNothing);
    expect(find.text('No comments yet.'), findsOneWidget);
  });
}
