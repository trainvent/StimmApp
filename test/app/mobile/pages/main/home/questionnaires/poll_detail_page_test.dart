import 'package:stimmapp/core/data/models/publication_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/main/home/questionnaires/poll_detail_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';

import '../../../../../../test_helper.dart';

void main() {
  testWidgets(
    'supporting links and questions stay reachable on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final poll = Poll(
        id: 'with-links',
        title: 'A questionnaire with supporting information',
        description: 'Please read the information and watch the video before choosing an answer.',
        links: const PublicationLinks(
          youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
          websiteUrl: 'https://example.org/background',
        ),
        questionTitle: 'Which approach do you prefer?',
        tags: const [],
        options: const [
          PollOption(id: 'a', label: 'First approach'),
          PollOption(id: 'b', label: 'Second approach'),
        ],
        votes: const {},
        createdBy: 'author',
        createdAt: DateTime.now(),
      );
      final app = ProviderScope(
        overrides: [currentUserProvider.overrideWithValue(null)],
        child: createTestWidget(PollDetailPage(id: poll.id)),
      );
      await locator.databaseService.instance
          .collection('polls')
          .doc(poll.id)
          .set(Poll.toFirestore(poll, null));
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Watch video'), findsOneWidget);
      expect(find.text('Open website'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('First approach').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('published poll displays its question above the answer options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final widget = ProviderScope(
      overrides: [currentUserProvider.overrideWithValue(null)],
      child: createTestWidget(
        const PollDetailPage(id: 'published'),
        locale: const Locale('de'),
      ),
    );
    final poll = Poll(
      id: 'published',
      title: 'Workplace satisfaction',
      description: 'Please share your experience at work.',
      questionTitle: 'How satisfied are you with your workplace?',
      tags: const [],
      options: const [
        PollOption(id: 'yes', label: 'Very satisfied'),
        PollOption(id: 'no', label: 'Not satisfied'),
      ],
      votes: const {},
      createdBy: 'author',
      createdAt: DateTime.now(),
    );
    await locator.databaseService.instance
        .collection('polls')
        .doc(poll.id)
        .set(Poll.toFirestore(poll, null));
    await locator.databaseService.instance
        .collection('users')
        .doc('author')
        .set({'displayName': 'Poll Creator'});
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    final question = find.text(poll.questionTitle);
    final answer = find.text('Very satisfied');
    expect(question, findsOneWidget);
    expect(answer, findsOneWidget);
    expect(
      tester.getTopLeft(question).dy,
      lessThan(tester.getTopLeft(answer).dy),
    );
    expect(find.text('Teilnehmer'), findsNothing);
    await tester.tap(find.text(poll.title));
    await tester.pumpAndSettle();
    expect(find.text('Ersteller'), findsOneWidget);
    expect(find.text('Poll Creator'), findsOneWidget);
    await locator.databaseService.instance
        .collection('users')
        .doc('author')
        .update({'displayName': 'Updated Creator'});
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();
    expect(find.text('Updated Creator'), findsOneWidget);
    expect(find.text('Poll Creator'), findsNothing);
    final metadata = find.byKey(const Key('form_participation_metadata'));
    expect(metadata, findsOneWidget);
    expect(
      find.descendant(of: find.byType(ExpansionTile), matching: metadata),
      findsOneWidget,
    );
    final expiration = find.byKey(const Key('form_expiration_metadata'));
    expect(expiration, findsOneWidget);
    expect(
      tester.getTopLeft(expiration).dy,
      lessThan(tester.getTopLeft(metadata).dy),
    );
    expect(
      find.descendant(
        of: metadata,
        matching: find.byIcon(Icons.schedule_outlined),
      ),
      findsNothing,
    );
    expect(find.text('Teilnehmer'), findsOneWidget);
    await tester.tap(find.text(poll.title));
    await tester.pumpAndSettle();
    expect(find.text('Teilnehmer'), findsNothing);
    await tester.tap(find.text(poll.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Updated Creator'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfilePage), findsOneWidget);
    expect(find.text('Updated Creator'), findsOneWidget);
  });
}
